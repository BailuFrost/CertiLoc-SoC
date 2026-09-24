`timescale 1ns / 1ps

// 将控制器或接收路径的响应描述符转换为T03规定的响应载荷字节流
module protocol_response_adapter
(
	input wire clk_i,
	input wire reset_i,
	input wire response_valid_i,
	output wire response_ready_o,
	input wire [7:0] response_type_i,
	input wire [7:0] response_request_command_i,
	input wire [15:0] response_sequence_i,
	input wire [7:0] response_error_code_i,
	input wire [31:0] response_context_i,
	input wire [7:0] read_result_kind_i,
	input wire [15:0] read_result_start_index_i,
	input wire [4:0] read_result_maximum_vertices_i,

	input wire [7:0] engine_state_i,
	input wire [4:0] observation_count_i,
	input wire [4:0] active_observation_index_i,
	input wire result_valid_i,
	input wire result_trusted_i,
	input wire [15:0] result_job_sequence_i,
	input wire [7:0] result_region_type_i,
	input wire [10:0] result_vertex_count_i,
	input wire [65:0] result_maximum_distance_squared_i,
	input wire [9:0] result_farthest_first_index_i,
	input wire [9:0] result_farthest_second_index_i,
	input wire [31:0] result_core_cycle_count_i,
	input wire [7:0] result_error_flags_i,

	output wire result_vertex_read_enable_o,
	input wire result_vertex_read_ready_i,
	output wire [9:0] result_vertex_read_address_o,
	input wire [63:0] result_vertex_read_data_i,
	input wire result_vertex_read_valid_i,

	output wire frame_valid_o,
	input wire frame_ready_i,
	output wire [7:0] frame_command_o,
	output wire [15:0] frame_sequence_o,
	output wire [7:0] frame_payload_length_o,
	output wire [7:0] payload_data_o,
	output wire payload_valid_o,
	input wire payload_ready_i,
	input wire frame_done_i,
	output wire busy_o
);

	localparam [7:0] RESPONSE_ACK = 8'h80;
	localparam [7:0] RESPONSE_INFO = 8'h81;
	localparam [7:0] RESPONSE_STATUS = 8'h82;
	localparam [7:0] RESPONSE_RESULT_HEADER = 8'h90;
	localparam [7:0] RESPONSE_RESULT_VERTICES = 8'h91;
	localparam [7:0] RESPONSE_ERROR = 8'hff;
	localparam [7:0] ERROR_RESULT_UNAVAILABLE = 8'h0a;

	localparam [1:0] STATE_IDLE = 2'd0;
	localparam [1:0] STATE_FRAME = 2'd1;
	localparam [1:0] STATE_SEND = 2'd2;

	reg [1:0] state_current;
	reg [1:0] state_next;
	reg [7:0] response_type_saved;
	reg [7:0] request_command_saved;
	reg [15:0] sequence_saved;
	reg [7:0] error_code_saved;
	reg [31:0] context_saved;
	reg [7:0] engine_state_saved;
	reg [4:0] observation_count_saved;
	reg [4:0] active_observation_index_saved;
	reg result_valid_saved;
	reg result_trusted_saved;
	reg [15:0] result_job_sequence_saved;
	reg [7:0] result_region_type_saved;
	reg [10:0] result_vertex_count_saved;
	reg [65:0] result_distance_saved;
	reg [9:0] result_first_index_saved;
	reg [9:0] result_second_index_saved;
	reg [31:0] result_core_cycles_saved;
	reg [7:0] result_error_flags_saved;
	reg [15:0] result_start_index_saved;
	reg [4:0] result_chunk_count_saved;
	reg [7:0] payload_length_saved;
	reg [7:0] payload_index;
	reg [63:0] vertex_data_saved;
	reg vertex_data_valid_saved;
	reg [4:0] vertex_data_number_saved;
	reg vertex_read_pending;
	reg [9:0] vertex_read_address_saved;
	reg [7:0] payload_data_mux;
	reg resolved_vertices;
	reg [4:0] resolved_vertex_count;
	reg [7:0] resolved_response_type;
	reg [7:0] resolved_error_code;
	reg [31:0] resolved_context;
	reg [7:0] resolved_payload_length;

	wire response_accept;
	wire frame_accept;
	wire payload_accept;
	wire vertex_read_accept;
	wire [4:0] payload_vertex_number;
	wire [2:0] payload_vertex_byte;
	wire vertex_payload_ready;

	assign response_accept = response_valid_i && response_ready_o;
	assign frame_accept = frame_valid_o && frame_ready_i;
	assign payload_accept = payload_valid_o && payload_ready_i;
	assign vertex_read_accept = result_vertex_read_enable_o && result_vertex_read_ready_i;
	assign payload_vertex_number = (payload_index - 8'd8) >> 3;
	assign payload_vertex_byte = (payload_index - 8'd8) & 3'b111;
	assign vertex_payload_ready = vertex_data_valid_saved &&
		(vertex_data_number_saved == payload_vertex_number);

	assign response_ready_o = (state_current == STATE_IDLE);
	assign frame_valid_o = (state_current == STATE_FRAME);
	assign frame_command_o = response_type_saved;
	assign frame_sequence_o = sequence_saved;
	assign frame_payload_length_o = payload_length_saved;
	assign payload_data_o = payload_data_mux;
	assign payload_valid_o = (state_current == STATE_SEND) &&
		((response_type_saved != RESPONSE_RESULT_VERTICES) ||
		 (payload_index < 8'd8) || vertex_payload_ready);
	assign result_vertex_read_enable_o = vertex_read_pending;
	assign result_vertex_read_address_o = vertex_read_address_saved;
	assign busy_o = (state_current != STATE_IDLE);

	// Resolve a READ_RESULT vertex request before the packet encoder sees a frame.
	always @(*) begin
		resolved_vertices = 1'b0;
		resolved_vertex_count = 5'd0;
		resolved_response_type = response_type_i;
		resolved_error_code = response_error_code_i;
		resolved_context = response_context_i;
		if((response_type_i == RESPONSE_RESULT_HEADER) &&
			(response_request_command_i == 8'h14) &&
			(read_result_kind_i == 8'd1)) begin
			if(!result_valid_i ||
				(read_result_start_index_i >= result_vertex_count_i) ||
				(read_result_maximum_vertices_i < 5'd1) ||
				(read_result_maximum_vertices_i > 5'd16)) begin
				resolved_response_type = RESPONSE_ERROR;
				resolved_error_code = ERROR_RESULT_UNAVAILABLE;
				resolved_context = {read_result_start_index_i, 5'd0,
					result_vertex_count_i};
			end else begin
				resolved_vertices = 1'b1;
				resolved_response_type = RESPONSE_RESULT_VERTICES;
				if(({6'd0, read_result_start_index_i} +
					 {17'd0, read_result_maximum_vertices_i}) >
					 {11'd0, result_vertex_count_i}) begin
					resolved_vertex_count = result_vertex_count_i -
						read_result_start_index_i;
				end else begin
					resolved_vertex_count = read_result_maximum_vertices_i;
				end
			end
		end
		case(resolved_response_type)
			RESPONSE_ACK: resolved_payload_length = 8'd4;
			RESPONSE_INFO: resolved_payload_length = 8'd24;
			RESPONSE_STATUS: resolved_payload_length = 8'd16;
			RESPONSE_RESULT_HEADER: resolved_payload_length = 8'd27;
			RESPONSE_RESULT_VERTICES: resolved_payload_length =
				8'd8 + {resolved_vertex_count, 3'b000};
			default: resolved_payload_length = 8'd8;
		endcase
	end

	// Payload mux uses snapshots so a long UART transmission cannot tear status data.
	always @(*) begin
		payload_data_mux = 8'd0;
		case(response_type_saved)
			RESPONSE_ACK: begin
				case(payload_index)
					8'd0: payload_data_mux = request_command_saved;
					default: payload_data_mux = 8'd0;
				endcase
			end
			RESPONSE_INFO: begin
				case(payload_index)
					8'd0: payload_data_mux = 8'h01;
					8'd1: payload_data_mux = 8'hb3;
					8'd2: payload_data_mux = 8'h01;
					8'd3: payload_data_mux = 8'h3f;
					8'd4: payload_data_mux = 8'h00;
					8'd5: payload_data_mux = 8'he1;
					8'd6: payload_data_mux = 8'hf5;
					8'd7: payload_data_mux = 8'h05;
					8'd8: payload_data_mux = 8'h00;
					8'd9: payload_data_mux = 8'hc2;
					8'd10: payload_data_mux = 8'h01;
					8'd11: payload_data_mux = 8'h00;
					8'd12: payload_data_mux = 8'd16;
					8'd13: payload_data_mux = 8'd30;
					8'd14: payload_data_mux = 8'd18;
					8'd15: payload_data_mux = 8'd18;
					8'd16: payload_data_mux = 8'd20;
					8'd17: payload_data_mux = 8'd16;
					8'd18: payload_data_mux = 8'hd0;
					8'd19: payload_data_mux = 8'h02;
					8'd20: payload_data_mux = 8'h00;
					8'd21: payload_data_mux = 8'h04;
					default: payload_data_mux = 8'd0;
				endcase
			end
			RESPONSE_STATUS: begin
				case(payload_index)
					8'd0: payload_data_mux = engine_state_saved;
					8'd1: payload_data_mux = {7'd0, result_valid_saved};
					8'd2: payload_data_mux = {7'd0, result_trusted_saved};
					8'd3: payload_data_mux = result_region_type_saved;
					8'd4: payload_data_mux = {3'd0, observation_count_saved};
					8'd5: payload_data_mux = {3'd0, active_observation_index_saved};
					8'd6: payload_data_mux = result_vertex_count_saved[7:0];
					8'd7: payload_data_mux = {5'd0, result_vertex_count_saved[10:8]};
					8'd8: payload_data_mux = result_error_flags_saved;
					8'd12: payload_data_mux = result_core_cycles_saved[7:0];
					8'd13: payload_data_mux = result_core_cycles_saved[15:8];
					8'd14: payload_data_mux = result_core_cycles_saved[23:16];
					8'd15: payload_data_mux = result_core_cycles_saved[31:24];
					default: payload_data_mux = 8'd0;
				endcase
			end
			RESPONSE_RESULT_HEADER: begin
				case(payload_index)
					8'd0: payload_data_mux = result_job_sequence_saved[7:0];
					8'd1: payload_data_mux = result_job_sequence_saved[15:8];
					8'd2: payload_data_mux = {7'd0, result_trusted_saved};
					8'd3: payload_data_mux = result_region_type_saved;
					8'd4: payload_data_mux = result_vertex_count_saved[7:0];
					8'd5: payload_data_mux = {5'd0, result_vertex_count_saved[10:8]};
					8'd6: payload_data_mux = result_distance_saved[7:0];
					8'd7: payload_data_mux = result_distance_saved[15:8];
					8'd8: payload_data_mux = result_distance_saved[23:16];
					8'd9: payload_data_mux = result_distance_saved[31:24];
					8'd10: payload_data_mux = result_distance_saved[39:32];
					8'd11: payload_data_mux = result_distance_saved[47:40];
					8'd12: payload_data_mux = result_distance_saved[55:48];
					8'd13: payload_data_mux = result_distance_saved[63:56];
					8'd14: payload_data_mux = {6'd0, result_distance_saved[65:64]};
					8'd15: payload_data_mux = result_first_index_saved[7:0];
					8'd16: payload_data_mux = {6'd0, result_first_index_saved[9:8]};
					8'd17: payload_data_mux = result_second_index_saved[7:0];
					8'd18: payload_data_mux = {6'd0, result_second_index_saved[9:8]};
					8'd19: payload_data_mux = result_core_cycles_saved[7:0];
					8'd20: payload_data_mux = result_core_cycles_saved[15:8];
					8'd21: payload_data_mux = result_core_cycles_saved[23:16];
					8'd22: payload_data_mux = result_core_cycles_saved[31:24];
					8'd23: payload_data_mux = result_error_flags_saved;
					default: payload_data_mux = 8'd0;
				endcase
			end
			RESPONSE_RESULT_VERTICES: begin
				if(payload_index < 8'd8) begin
					case(payload_index)
						8'd0: payload_data_mux = result_job_sequence_saved[7:0];
						8'd1: payload_data_mux = result_job_sequence_saved[15:8];
						8'd2: payload_data_mux = result_start_index_saved[7:0];
						8'd3: payload_data_mux = result_start_index_saved[15:8];
						8'd4: payload_data_mux = {3'd0, result_chunk_count_saved};
						default: payload_data_mux = 8'd0;
					endcase
				end else begin
					case(payload_vertex_byte)
						3'd0: payload_data_mux = vertex_data_saved[39:32];
						3'd1: payload_data_mux = vertex_data_saved[47:40];
						3'd2: payload_data_mux = vertex_data_saved[55:48];
						3'd3: payload_data_mux = vertex_data_saved[63:56];
						3'd4: payload_data_mux = vertex_data_saved[7:0];
						3'd5: payload_data_mux = vertex_data_saved[15:8];
						3'd6: payload_data_mux = vertex_data_saved[23:16];
						default: payload_data_mux = vertex_data_saved[31:24];
					endcase
				end
			end
			default: begin
				case(payload_index)
					8'd0: payload_data_mux = request_command_saved;
					8'd1: payload_data_mux = error_code_saved;
					8'd2: payload_data_mux = engine_state_saved;
					8'd4: payload_data_mux = context_saved[7:0];
					8'd5: payload_data_mux = context_saved[15:8];
					8'd6: payload_data_mux = context_saved[23:16];
					8'd7: payload_data_mux = context_saved[31:24];
					default: payload_data_mux = 8'd0;
				endcase
			end
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i) begin
			state_current <= STATE_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	always @(*) begin
		state_next = state_current;
		case(state_current)
			STATE_IDLE: begin
				if(response_accept) begin
					state_next = STATE_FRAME;
				end
			end
			STATE_FRAME: begin
				if(frame_accept) begin
					state_next = STATE_SEND;
				end
			end
			STATE_SEND: begin
				if(frame_done_i) begin
					state_next = STATE_IDLE;
				end
			end
			default: state_next = STATE_IDLE;
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i) begin
			response_type_saved <= RESPONSE_ERROR;
			request_command_saved <= 8'd0;
			sequence_saved <= 16'd0;
			error_code_saved <= 8'd0;
			context_saved <= 32'd0;
			engine_state_saved <= 8'd0;
			observation_count_saved <= 5'd0;
			active_observation_index_saved <= 5'd0;
			result_valid_saved <= 1'b0;
			result_trusted_saved <= 1'b0;
			result_job_sequence_saved <= 16'd0;
			result_region_type_saved <= 8'hff;
			result_vertex_count_saved <= 11'd0;
			result_distance_saved <= 66'd0;
			result_first_index_saved <= 10'd0;
			result_second_index_saved <= 10'd0;
			result_core_cycles_saved <= 32'd0;
			result_error_flags_saved <= 8'd0;
			result_start_index_saved <= 16'd0;
			result_chunk_count_saved <= 5'd0;
			payload_length_saved <= 8'd8;
			payload_index <= 8'd0;
			vertex_data_saved <= 64'd0;
			vertex_data_valid_saved <= 1'b0;
			vertex_data_number_saved <= 5'd0;
			vertex_read_pending <= 1'b0;
			vertex_read_address_saved <= 10'd0;
		end else begin
			if(response_accept) begin
				response_type_saved <= resolved_response_type;
				request_command_saved <= response_request_command_i;
				sequence_saved <= response_sequence_i;
				error_code_saved <= resolved_error_code;
				context_saved <= resolved_context;
				engine_state_saved <= engine_state_i;
				observation_count_saved <= observation_count_i;
				active_observation_index_saved <= active_observation_index_i;
				result_valid_saved <= result_valid_i;
				result_trusted_saved <= result_trusted_i;
				result_job_sequence_saved <= result_job_sequence_i;
				result_region_type_saved <= result_region_type_i;
				result_vertex_count_saved <= result_vertex_count_i;
				result_distance_saved <= result_maximum_distance_squared_i;
				result_first_index_saved <= result_farthest_first_index_i;
				result_second_index_saved <= result_farthest_second_index_i;
				result_core_cycles_saved <= result_core_cycle_count_i;
				result_error_flags_saved <= result_error_flags_i;
				result_start_index_saved <= read_result_start_index_i;
				result_chunk_count_saved <= resolved_vertex_count;
				payload_length_saved <= resolved_payload_length;
				payload_index <= 8'd0;
				vertex_data_valid_saved <= 1'b0;
				vertex_data_number_saved <= 5'd0;
				if(resolved_vertices) begin
					vertex_read_pending <= 1'b1;
					vertex_read_address_saved <= read_result_start_index_i[9:0];
				end else begin
					vertex_read_pending <= 1'b0;
				end
			end
			if(vertex_read_accept) begin
				vertex_read_pending <= 1'b0;
			end
			if(result_vertex_read_valid_i) begin
				vertex_data_saved <= result_vertex_read_data_i;
				vertex_data_valid_saved <= 1'b1;
			end
			if(payload_accept) begin
				if(payload_index + 1'b1 < payload_length_saved) begin
					payload_index <= payload_index + 1'b1;
				end
				if((response_type_saved == RESPONSE_RESULT_VERTICES) &&
					(payload_index >= 8'd8) &&
					(payload_vertex_byte == 3'd7)) begin
					vertex_data_valid_saved <= 1'b0;
					if(payload_vertex_number + 1'b1 < result_chunk_count_saved) begin
						vertex_data_number_saved <= payload_vertex_number + 1'b1;
						vertex_read_address_saved <= result_start_index_saved[9:0] +
							payload_vertex_number + 1'b1;
						vertex_read_pending <= 1'b1;
					end
				end
			end
		end
	end

endmodule
