`timescale 1ns / 1ps

// 将T05完整合法帧转换为T12语义命令，并在提交前完成载荷字段校验
module protocol_command_adapter
(
	input wire clk_i,
	input wire reset_i,
	input wire frame_valid_i,
	output wire frame_ready_o,
	input wire [7:0] frame_command_i,
	input wire [15:0] frame_sequence_i,
	input wire [7:0] frame_payload_length_i,
	output wire payload_read_enable_o,
	output wire [7:0] payload_read_address_o,
	input wire [7:0] payload_read_data_i,
	input wire payload_read_valid_i,

	output wire command_valid_o,
	input wire command_ready_i,
	output wire [7:0] command_code_o,
	output wire [15:0] command_sequence_o,
	output wire command_config_matches_o,
	output wire [4:0] command_observation_count_o,
	output wire observation_write_valid_o,
	input wire observation_write_ready_i,
	output wire [4:0] observation_write_address_o,
	output wire signed [31:0] observation_x_o,
	output wire signed [31:0] observation_y_o,
	output wire [17:0] observation_phase_o,

	output wire error_valid_o,
	input wire error_ready_i,
	output wire [7:0] error_command_o,
	output wire [15:0] error_sequence_o,
	output wire [7:0] error_code_o,
	output wire [31:0] error_context_o,

	output wire [7:0] read_result_kind_o,
	output wire [15:0] read_result_start_index_o,
	output wire [4:0] read_result_maximum_vertices_o,
	output wire busy_o
);

	localparam [7:0] COMMAND_GET_INFO = 8'h01;
	localparam [7:0] COMMAND_SET_CONFIG = 8'h10;
	localparam [7:0] COMMAND_LOAD_OBSERVATIONS = 8'h11;
	localparam [7:0] COMMAND_START_LOCALIZATION = 8'h12;
	localparam [7:0] COMMAND_GET_STATUS = 8'h13;
	localparam [7:0] COMMAND_READ_RESULT = 8'h14;
	localparam [7:0] COMMAND_ABORT = 8'h1f;

	localparam [7:0] ERROR_COMMAND = 8'h02;
	localparam [7:0] ERROR_LENGTH = 8'h03;
	localparam [7:0] ERROR_PARAMETER = 8'h06;
	localparam [7:0] ERROR_OBSERVATION_COUNT = 8'h08;
	localparam [7:0] ERROR_RESERVED = 8'h09;

	localparam [3:0] STATE_IDLE = 4'd0;
	localparam [3:0] STATE_READ_REQUEST = 4'd1;
	localparam [3:0] STATE_READ_WAIT = 4'd2;
	localparam [3:0] STATE_VALIDATE = 4'd3;
	localparam [3:0] STATE_WRITE_OBSERVATIONS = 4'd4;
	localparam [3:0] STATE_DISPATCH = 4'd5;
	localparam [3:0] STATE_ERROR = 4'd6;

	reg [3:0] state_current;
	reg [3:0] state_next;
	reg [7:0] command_saved;
	reg [15:0] sequence_saved;
	reg [7:0] payload_length_saved;
	reg [7:0] payload_index;
	reg [4:0] observation_count_saved;
	reg [4:0] observation_build_index;
	reg [3:0] observation_field_index;
	reg [4:0] observation_write_index;
	reg signed [31:0] observation_x_work;
	reg signed [31:0] observation_y_work;
	reg [31:0] observation_phase_work;
	reg signed [31:0] observation_x_memory [0:19];
	reg signed [31:0] observation_y_memory [0:19];
	reg [17:0] observation_phase_memory [0:19];
	reg config_mismatch_saved;
	reg reserved_nonzero_saved;
	reg phase_high_nonzero_saved;
	reg [7:0] read_result_kind_saved;
	reg [15:0] read_result_start_saved;
	reg [4:0] read_result_maximum_saved;
	reg read_result_maximum_high_saved;
	reg [7:0] error_code_result;
	reg [31:0] error_context_result;
	reg [7:0] expected_config_byte;
	reg validation_error;
	reg [7:0] validation_error_code;

	wire empty_payload_command;
	wire payload_command;
	wire command_accept;
	wire observation_accept;
	wire error_accept;
	wire [8:0] expected_observation_length;

	assign empty_payload_command = (frame_command_i == COMMAND_GET_INFO) ||
		(frame_command_i == COMMAND_START_LOCALIZATION) ||
		(frame_command_i == COMMAND_GET_STATUS) ||
		(frame_command_i == COMMAND_ABORT);
	assign payload_command = (frame_command_i == COMMAND_SET_CONFIG) ||
		(frame_command_i == COMMAND_LOAD_OBSERVATIONS) ||
		(frame_command_i == COMMAND_READ_RESULT);
	assign expected_observation_length = 9'd4 +
		({4'd0, observation_count_saved} * 4'd12);
	assign command_accept = command_valid_o && command_ready_i;
	assign observation_accept = observation_write_valid_o && observation_write_ready_i;
	assign error_accept = error_valid_o && error_ready_i;

	assign frame_ready_o = command_accept || error_accept;
	assign payload_read_enable_o = (state_current == STATE_READ_REQUEST);
	assign payload_read_address_o = payload_index;
	assign command_valid_o = (state_current == STATE_DISPATCH);
	assign command_code_o = command_saved;
	assign command_sequence_o = sequence_saved;
	assign command_config_matches_o = (command_saved == COMMAND_SET_CONFIG) &&
		!config_mismatch_saved;
	assign command_observation_count_o = observation_count_saved;
	assign observation_write_valid_o = (state_current == STATE_WRITE_OBSERVATIONS);
	assign observation_write_address_o = observation_write_index;
	assign observation_x_o = observation_x_memory[observation_write_index];
	assign observation_y_o = observation_y_memory[observation_write_index];
	assign observation_phase_o = observation_phase_memory[observation_write_index];
	assign error_valid_o = (state_current == STATE_ERROR);
	assign error_command_o = command_saved;
	assign error_sequence_o = sequence_saved;
	assign error_code_o = error_code_result;
	assign error_context_o = error_context_result;
	assign read_result_kind_o = read_result_kind_saved;
	assign read_result_start_index_o = read_result_start_saved;
	assign read_result_maximum_vertices_o = read_result_maximum_saved;
	assign busy_o = (state_current != STATE_IDLE);

	// The fixed T03 configuration is compared byte-for-byte in little-endian order.
	always @(*) begin
		expected_config_byte = 8'd0;
		case(payload_index)
			8'd0: expected_config_byte = 8'h00;
			8'd1: expected_config_byte = 8'h00;
			8'd2: expected_config_byte = 8'h08;
			8'd3: expected_config_byte = 8'h07;
			8'd4: expected_config_byte = 8'hdc;
			8'd5: expected_config_byte = 8'h02;
			8'd6: expected_config_byte = 8'h00;
			8'd7: expected_config_byte = 8'h00;
			8'd8: expected_config_byte = 8'h00;
			8'd9: expected_config_byte = 8'h00;
			8'd10: expected_config_byte = 8'h00;
			8'd11: expected_config_byte = 8'h40;
			8'd12: expected_config_byte = 8'h00;
			8'd13: expected_config_byte = 8'h00;
			8'd14: expected_config_byte = 8'h00;
			8'd15: expected_config_byte = 8'h00;
			8'd16: expected_config_byte = 8'h00;
			8'd17: expected_config_byte = 8'h00;
			8'd18: expected_config_byte = 8'h00;
			8'd19: expected_config_byte = 8'h40;
			8'd20: expected_config_byte = 8'h00;
			8'd21: expected_config_byte = 8'h00;
			8'd22: expected_config_byte = 8'h00;
			8'd23: expected_config_byte = 8'h00;
			8'd24: expected_config_byte = 8'hd0;
			8'd25: expected_config_byte = 8'h02;
			8'd26: expected_config_byte = 8'h00;
			8'd27: expected_config_byte = 8'h04;
			default: expected_config_byte = 8'd0;
		endcase
	end

	// Validation is evaluated only after every requested payload byte has returned.
	always @(*) begin
		validation_error = 1'b0;
		validation_error_code = 8'd0;
		case(command_saved)
			COMMAND_SET_CONFIG: begin
				if(config_mismatch_saved) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_PARAMETER;
				end
			end
			COMMAND_LOAD_OBSERVATIONS: begin
				if((observation_count_saved < 5'd2) ||
					(observation_count_saved > 5'd20)) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_OBSERVATION_COUNT;
				end else if(payload_length_saved != expected_observation_length[7:0]) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_LENGTH;
				end else if(reserved_nonzero_saved) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_RESERVED;
				end else if(phase_high_nonzero_saved) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_PARAMETER;
				end else if(observation_build_index != observation_count_saved) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_LENGTH;
				end
			end
			COMMAND_READ_RESULT: begin
				if(reserved_nonzero_saved) begin
					validation_error = 1'b1;
					validation_error_code = ERROR_RESERVED;
				end else if(read_result_kind_saved == 8'd0) begin
					if((read_result_start_saved != 16'd0) ||
						(read_result_maximum_saved != 5'd0) ||
						read_result_maximum_high_saved) begin
						validation_error = 1'b1;
						validation_error_code = ERROR_PARAMETER;
					end
				end else if(read_result_kind_saved == 8'd1) begin
					if((read_result_start_saved[15:10] != 6'd0) ||
						(read_result_maximum_saved < 5'd1) ||
						(read_result_maximum_saved > 5'd16) ||
						read_result_maximum_high_saved) begin
						validation_error = 1'b1;
						validation_error_code = ERROR_PARAMETER;
					end
				end else begin
					validation_error = 1'b1;
					validation_error_code = ERROR_PARAMETER;
				end
			end
			default: begin
				validation_error = 1'b1;
				validation_error_code = ERROR_COMMAND;
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
				if(frame_valid_i) begin
					if(empty_payload_command) begin
						state_next = (frame_payload_length_i == 8'd0) ?
							STATE_DISPATCH : STATE_ERROR;
					end else if(payload_command) begin
						if(((frame_command_i == COMMAND_SET_CONFIG) &&
							(frame_payload_length_i != 8'd28)) ||
							((frame_command_i == COMMAND_READ_RESULT) &&
							(frame_payload_length_i != 8'd8)) ||
							((frame_command_i == COMMAND_LOAD_OBSERVATIONS) &&
							((frame_payload_length_i < 8'd28) ||
							 (frame_payload_length_i > 8'd244)))) begin
							state_next = STATE_ERROR;
						end else begin
							state_next = STATE_READ_REQUEST;
						end
					end else begin
						state_next = STATE_ERROR;
					end
				end
			end
			STATE_READ_REQUEST: state_next = STATE_READ_WAIT;
			STATE_READ_WAIT: begin
				if(payload_read_valid_i) begin
					state_next = (payload_index + 1'b1 >= payload_length_saved) ?
						STATE_VALIDATE : STATE_READ_REQUEST;
				end
			end
			STATE_VALIDATE: begin
				if(validation_error) begin
					state_next = STATE_ERROR;
				end else if(command_saved == COMMAND_LOAD_OBSERVATIONS) begin
					state_next = STATE_WRITE_OBSERVATIONS;
				end else begin
					state_next = STATE_DISPATCH;
				end
			end
			STATE_WRITE_OBSERVATIONS: begin
				if(observation_accept &&
					(observation_write_index + 1'b1 >= observation_count_saved)) begin
					state_next = STATE_DISPATCH;
				end
			end
			STATE_DISPATCH: begin
				if(command_accept) begin
					state_next = STATE_IDLE;
				end
			end
			STATE_ERROR: begin
				if(error_accept) begin
					state_next = STATE_IDLE;
				end
			end
			default: state_next = STATE_ERROR;
		endcase
	end

	// Payload bytes are captured only while the decoder holds the validated frame.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i) begin
			command_saved <= 8'd0;
			sequence_saved <= 16'd0;
			payload_length_saved <= 8'd0;
			payload_index <= 8'd0;
			observation_count_saved <= 5'd0;
			observation_build_index <= 5'd0;
			observation_field_index <= 4'd0;
			observation_write_index <= 5'd0;
			observation_x_work <= 32'sd0;
			observation_y_work <= 32'sd0;
			observation_phase_work <= 32'd0;
			config_mismatch_saved <= 1'b0;
			reserved_nonzero_saved <= 1'b0;
			phase_high_nonzero_saved <= 1'b0;
			read_result_kind_saved <= 8'd0;
			read_result_start_saved <= 16'd0;
			read_result_maximum_saved <= 5'd0;
			read_result_maximum_high_saved <= 1'b0;
			error_code_result <= 8'd0;
			error_context_result <= 32'd0;
		end else begin
			if((state_current == STATE_IDLE) && frame_valid_i) begin
				command_saved <= frame_command_i;
				sequence_saved <= frame_sequence_i;
				payload_length_saved <= frame_payload_length_i;
				payload_index <= 8'd0;
				observation_count_saved <= 5'd0;
				observation_build_index <= 5'd0;
				observation_field_index <= 4'd0;
				observation_write_index <= 5'd0;
				observation_x_work <= 32'sd0;
				observation_y_work <= 32'sd0;
				observation_phase_work <= 32'd0;
				config_mismatch_saved <= 1'b0;
				reserved_nonzero_saved <= 1'b0;
				phase_high_nonzero_saved <= 1'b0;
				read_result_kind_saved <= 8'd0;
				read_result_start_saved <= 16'd0;
				read_result_maximum_saved <= 5'd0;
				read_result_maximum_high_saved <= 1'b0;
				if((empty_payload_command && (frame_payload_length_i != 8'd0)) ||
					((frame_command_i == COMMAND_SET_CONFIG) &&
					 (frame_payload_length_i != 8'd28)) ||
					((frame_command_i == COMMAND_READ_RESULT) &&
					 (frame_payload_length_i != 8'd8)) ||
					((frame_command_i == COMMAND_LOAD_OBSERVATIONS) &&
					 ((frame_payload_length_i < 8'd28) ||
					  (frame_payload_length_i > 8'd244)))) begin
					error_code_result <= ERROR_LENGTH;
					error_context_result <= {24'd0, frame_payload_length_i};
				end else if(!empty_payload_command && !payload_command) begin
					error_code_result <= ERROR_COMMAND;
					error_context_result <= {24'd0, frame_command_i};
				end
			end
			if((state_current == STATE_READ_WAIT) && payload_read_valid_i) begin
				if(command_saved == COMMAND_SET_CONFIG) begin
					if(payload_read_data_i != expected_config_byte) begin
						config_mismatch_saved <= 1'b1;
					end
				end else if(command_saved == COMMAND_LOAD_OBSERVATIONS) begin
					if(payload_index == 8'd0) begin
						observation_count_saved <= payload_read_data_i[4:0];
						if(payload_read_data_i[7:5] != 3'd0) begin
							observation_count_saved <= 5'd31;
						end
					end else if(payload_index < 8'd4) begin
						if(payload_read_data_i != 8'd0) begin
							reserved_nonzero_saved <= 1'b1;
						end
					end else begin
						case(observation_field_index)
							4'd0: observation_x_work[7:0] <= payload_read_data_i;
							4'd1: observation_x_work[15:8] <= payload_read_data_i;
							4'd2: observation_x_work[23:16] <= payload_read_data_i;
							4'd3: begin
								observation_x_memory[observation_build_index] <=
									{payload_read_data_i, observation_x_work[23:0]};
							end
							4'd4: observation_y_work[7:0] <= payload_read_data_i;
							4'd5: observation_y_work[15:8] <= payload_read_data_i;
							4'd6: observation_y_work[23:16] <= payload_read_data_i;
							4'd7: begin
								observation_y_memory[observation_build_index] <=
									{payload_read_data_i, observation_y_work[23:0]};
							end
							4'd8: observation_phase_work[7:0] <= payload_read_data_i;
							4'd9: observation_phase_work[15:8] <= payload_read_data_i;
							4'd10: observation_phase_work[23:16] <= payload_read_data_i;
							4'd11: begin
								observation_phase_memory[observation_build_index] <=
									observation_phase_work[17:0];
								if((payload_read_data_i != 8'd0) ||
									(observation_phase_work[23:18] != 6'd0)) begin
									phase_high_nonzero_saved <= 1'b1;
								end
								observation_build_index <= observation_build_index + 1'b1;
							end
							default: begin
							end
						endcase
						if(observation_field_index == 4'd11) begin
							observation_field_index <= 4'd0;
							observation_x_work <= 32'sd0;
							observation_y_work <= 32'sd0;
							observation_phase_work <= 32'd0;
						end else begin
							observation_field_index <= observation_field_index + 1'b1;
						end
					end
				end else if(command_saved == COMMAND_READ_RESULT) begin
					case(payload_index)
						8'd0: read_result_kind_saved <= payload_read_data_i;
						8'd1: begin
							if(payload_read_data_i != 8'd0) reserved_nonzero_saved <= 1'b1;
						end
						8'd2: read_result_start_saved[7:0] <= payload_read_data_i;
						8'd3: read_result_start_saved[15:8] <= payload_read_data_i;
						8'd4: begin
							read_result_maximum_saved <= payload_read_data_i[4:0];
							read_result_maximum_high_saved <= |payload_read_data_i[7:5];
						end
						8'd5, 8'd6, 8'd7: begin
							if(payload_read_data_i != 8'd0) reserved_nonzero_saved <= 1'b1;
						end
						default: begin
						end
					endcase
				end
				if(payload_index + 1'b1 < payload_length_saved) begin
					payload_index <= payload_index + 1'b1;
				end
			end
			if(state_current == STATE_VALIDATE) begin
				if(validation_error) begin
					error_code_result <= validation_error_code;
					error_context_result <= {16'd0, payload_length_saved, payload_index};
				end else begin
					observation_write_index <= 5'd0;
				end
			end
			if(observation_accept &&
				(observation_write_index + 1'b1 < observation_count_saved)) begin
				observation_write_index <= observation_write_index + 1'b1;
			end
		end
	end

endmodule
