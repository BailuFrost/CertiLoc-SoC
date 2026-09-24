`timescale 1ns / 1ps

// 阶段1定位命令控制器：提交观测、调度几何流水线并保持最终结果
module localization_command_ctrl
#(
	parameter C_ROM_INIT_FILE = "initial_polygon_720_q16_16.mem",
	parameter [31:0] C_CHILD_TIMEOUT_CYCLES = 32'd10000000
)
(
	input wire clk_i,
	input wire reset_i,

	// T05在完整帧校验通过后提交一个语义命令。
	input wire command_valid_i,
	output wire command_ready_o,
	input wire [7:0] command_code_i,
	input wire [15:0] command_sequence_i,
	input wire command_config_matches_i,
	input wire [4:0] command_observation_count_i,

	// LOAD_OBSERVATIONS命令前写入暂存观测；提交命令原子更新有效数量。
	input wire observation_write_valid_i,
	output wire observation_write_ready_o,
	input wire [4:0] observation_write_address_i,
	input wire signed [31:0] observation_x_i,
	input wire signed [31:0] observation_y_i,
	input wire [17:0] observation_phase_i,

	// 响应描述符由后续包编码适配器扩展成协议载荷。
	output wire response_valid_o,
	input wire response_ready_i,
	output wire [7:0] response_type_o,
	output wire [7:0] response_request_command_o,
	output wire [15:0] response_sequence_o,
	output wire [7:0] response_error_code_o,
	output wire [31:0] response_context_o,

	output wire busy_o,
	output wire [7:0] engine_state_o,
	output wire configured_o,
	output wire observations_loaded_o,
	output wire [4:0] active_observation_count_o,
	output wire [4:0] active_observation_index_o,
	output wire job_done_o,

	output wire result_valid_o,
	output wire result_trusted_o,
	output wire [15:0] result_job_sequence_o,
	output wire [7:0] result_region_type_o,
	output wire result_vertex_buffer_o,
	output wire [10:0] result_vertex_count_o,
	output wire [65:0] result_maximum_distance_squared_o,
	output wire [9:0] result_farthest_first_index_o,
	output wire [9:0] result_farthest_second_index_o,
	output wire [31:0] result_core_cycle_count_o,
	output wire [7:0] result_error_flags_o,

	// READ_RESULT发送顶点时使用的只读窗口，仅在控制器空闲时开放。
	input wire result_vertex_read_enable_i,
	output wire result_vertex_read_ready_o,
	input wire [9:0] result_vertex_read_address_i,
	output wire [63:0] result_vertex_read_data_o,
	output wire result_vertex_read_valid_o
);

	localparam [7:0] COMMAND_GET_INFO = 8'h01;
	localparam [7:0] COMMAND_SET_CONFIG = 8'h10;
	localparam [7:0] COMMAND_LOAD_OBSERVATIONS = 8'h11;
	localparam [7:0] COMMAND_START_LOCALIZATION = 8'h12;
	localparam [7:0] COMMAND_GET_STATUS = 8'h13;
	localparam [7:0] COMMAND_READ_RESULT = 8'h14;
	localparam [7:0] COMMAND_ABORT = 8'h1f;

	localparam [7:0] RESPONSE_ACK = 8'h80;
	localparam [7:0] RESPONSE_INFO = 8'h81;
	localparam [7:0] RESPONSE_STATUS = 8'h82;
	localparam [7:0] RESPONSE_RESULT_HEADER = 8'h90;
	localparam [7:0] RESPONSE_ERROR = 8'hff;

	localparam [7:0] ERROR_UNKNOWN_COMMAND = 8'h02;
	localparam [7:0] ERROR_PARAMETER = 8'h06;
	localparam [7:0] ERROR_BUSY = 8'h07;
	localparam [7:0] ERROR_OBSERVATION_COUNT = 8'h08;
	localparam [7:0] ERROR_RESULT_UNAVAILABLE = 8'h0a;

	localparam [7:0] REGION_EMPTY = 8'h00;
	localparam [7:0] REGION_POINT = 8'h01;
	localparam [7:0] REGION_SEGMENT = 8'h02;
	localparam [7:0] REGION_POLYGON = 8'h03;
	localparam [7:0] REGION_INVALID = 8'hff;

	localparam [4:0] STATE_IDLE = 5'd0;
	localparam [4:0] STATE_LOAD_START = 5'd1;
	localparam [4:0] STATE_LOAD_WAIT = 5'd2;
	localparam [4:0] STATE_CONSTRAINT_START = 5'd3;
	localparam [4:0] STATE_CONSTRAINT_WAIT = 5'd4;
	localparam [4:0] STATE_CLIP_LOWER_START = 5'd5;
	localparam [4:0] STATE_CLIP_LOWER_WAIT = 5'd6;
	localparam [4:0] STATE_CLIP_UPPER_START = 5'd7;
	localparam [4:0] STATE_CLIP_UPPER_WAIT = 5'd8;
	localparam [4:0] STATE_DIAMETER_START = 5'd9;
	localparam [4:0] STATE_DIAMETER_WAIT = 5'd10;
	localparam [4:0] STATE_JOB_FINISH = 5'd11;
	localparam [4:0] STATE_JOB_ERROR = 5'd12;

	reg [4:0] state_current;
	reg [4:0] state_next;
	reg configured_result;
	reg observations_loaded_result;
	reg [4:0] active_observation_count_result;
	reg signed [31:0] observation_x_memory [0:19];
	reg signed [31:0] observation_y_memory [0:19];
	reg [17:0] observation_phase_memory [0:19];
	(* mark_debug = "true" *) reg [4:0] active_observation_index;
	(* mark_debug = "true" *) reg current_vertex_buffer;
	(* mark_debug = "true" *) reg [10:0] current_vertex_count;
	reg signed [31:0] lower_coefficient_a;
	reg signed [31:0] lower_coefficient_b;
	reg signed [65:0] lower_constant_c;
	reg signed [31:0] upper_coefficient_a;
	reg signed [31:0] upper_coefficient_b;
	reg signed [65:0] upper_constant_c;
	reg lower_constraint_received;
	reg upper_constraint_received;
	reg [31:0] child_watchdog_count;
	reg child_reset_result;
	reg [31:0] core_cycle_count_work;
	reg [7:0] error_flags_work;
	reg diameter_empty_saved;
	reg [65:0] diameter_distance_saved;
	reg [9:0] diameter_first_index_saved;
	reg [9:0] diameter_second_index_saved;

	reg response_valid_result;
	reg [7:0] response_type_result;
	reg [7:0] response_request_command_result;
	reg [15:0] response_sequence_result;
	reg [7:0] response_error_code_result;
	reg [31:0] response_context_result;
	reg job_done_result;
	reg result_valid_result;
	reg result_trusted_result;
	reg [15:0] result_job_sequence_result;
	reg [7:0] result_region_type_result;
	reg result_vertex_buffer_result;
	reg [10:0] result_vertex_count_result;
	reg [65:0] result_maximum_distance_result;
	reg [9:0] result_first_index_result;
	reg [9:0] result_second_index_result;
	reg [31:0] result_core_cycle_count_result;
	reg [7:0] result_error_flags_result;
	reg external_read_pending;

	wire command_accept;
	wire abort_command_accept;
	wire start_command_accept;
	wire child_reset;
	wire watchdog_expired;
	wire internal_busy;

	wire loader_start;
	wire loader_busy;
	wire loader_done;
	wire loader_protocol_error;
	wire loader_ram_write_enable;
	wire loader_ram_write_buffer;
	wire [9:0] loader_ram_write_address;
	wire [63:0] loader_ram_write_data;
	wire [10:0] loader_vertex_count;

	(* mark_debug = "true" *) wire constraint_start;
	wire constraint_busy;
	(* mark_debug = "true" *) wire constraint_done;
	wire constraint_protocol_error;
	wire constraint_valid;
	wire constraint_upper;
	wire signed [31:0] constraint_a;
	wire signed [31:0] constraint_b;
	wire signed [65:0] constraint_c;

	(* mark_debug = "true" *) wire clip_start;
	wire clip_busy;
	(* mark_debug = "true" *) wire clip_done;
	wire clip_protocol_error;
	wire clip_output_buffer;
	wire [10:0] clip_output_vertex_count;
	wire clip_empty;
	wire clip_result_trusted;
	wire clip_parallel_edge;
	wire clip_arithmetic_saturated;
	wire clip_capacity_overflow;
	wire clip_quantization_margin;
	wire clip_residual_violation;
	wire clip_ram_read_enable;
	wire clip_ram_read_buffer;
	wire [9:0] clip_ram_read_address;
	wire clip_ram_write_enable;
	wire clip_ram_write_buffer;
	wire [9:0] clip_ram_write_address;
	wire [63:0] clip_ram_write_data;
	wire signed [31:0] selected_clip_a;
	wire signed [31:0] selected_clip_b;
	wire signed [65:0] selected_clip_c;
	wire clip_fatal_error;

	(* mark_debug = "true" *) wire diameter_start;
	wire diameter_busy;
	(* mark_debug = "true" *) wire diameter_done;
	wire diameter_protocol_error;
	wire diameter_empty;
	wire diameter_result_trusted;
	wire diameter_arithmetic_saturated;
	wire diameter_input_count_error;
	wire [65:0] diameter_maximum_distance;
	wire [9:0] diameter_first_index;
	wire [9:0] diameter_second_index;
	wire [19:0] diameter_pair_count;
	wire diameter_first_read_enable;
	wire diameter_first_read_buffer;
	wire [9:0] diameter_first_read_address;
	wire diameter_second_read_enable;
	wire diameter_second_read_buffer;
	wire [9:0] diameter_second_read_address;
	wire diameter_fatal_error;

	reg ram_port_0_enable;
	reg ram_port_0_write;
	reg ram_port_0_buffer;
	reg [9:0] ram_port_0_address;
	reg [63:0] ram_port_0_write_data;
	reg ram_port_1_enable;
	reg ram_port_1_write;
	reg ram_port_1_buffer;
	reg [9:0] ram_port_1_address;
	reg [63:0] ram_port_1_write_data;
	wire [63:0] ram_port_0_read_data;
	wire ram_port_0_read_valid;
	wire [63:0] ram_port_1_read_data;
	wire ram_port_1_read_valid;

	assign command_ready_o = ~response_valid_result;
	assign command_accept = command_valid_i && command_ready_o;
	assign abort_command_accept = command_accept && (command_code_i == COMMAND_ABORT);
	assign start_command_accept = command_accept &&
		(command_code_i == COMMAND_START_LOCALIZATION) &&
		(state_current == STATE_IDLE) && configured_result &&
		observations_loaded_result &&
		(active_observation_count_result >= 5'd2) &&
		(active_observation_count_result <= 5'd20);
	assign observation_write_ready_o = (state_current == STATE_IDLE) &&
		(observation_write_address_i < 5'd20);
	assign child_reset = reset_i || child_reset_result;
	assign internal_busy = (state_current != STATE_IDLE) &&
		(state_current != STATE_JOB_FINISH) &&
		(state_current != STATE_JOB_ERROR);
	assign busy_o = internal_busy;
	assign watchdog_expired = (child_watchdog_count >= (C_CHILD_TIMEOUT_CYCLES - 1'b1));

	assign loader_start = (state_current == STATE_LOAD_START);
	assign constraint_start = (state_current == STATE_CONSTRAINT_START);
	assign clip_start = (state_current == STATE_CLIP_LOWER_START) ||
		(state_current == STATE_CLIP_UPPER_START);
	assign selected_clip_a = ((state_current == STATE_CLIP_UPPER_START) ||
		(state_current == STATE_CLIP_UPPER_WAIT)) ? upper_coefficient_a : lower_coefficient_a;
	assign selected_clip_b = ((state_current == STATE_CLIP_UPPER_START) ||
		(state_current == STATE_CLIP_UPPER_WAIT)) ? upper_coefficient_b : lower_coefficient_b;
	assign selected_clip_c = ((state_current == STATE_CLIP_UPPER_START) ||
		(state_current == STATE_CLIP_UPPER_WAIT)) ? upper_constant_c : lower_constant_c;
	assign clip_fatal_error = clip_protocol_error || clip_arithmetic_saturated ||
		clip_capacity_overflow || clip_residual_violation;
	assign diameter_start = (state_current == STATE_DIAMETER_START);
	assign diameter_fatal_error = diameter_protocol_error ||
		diameter_arithmetic_saturated || diameter_input_count_error;

	assign response_valid_o = response_valid_result;
	assign response_type_o = response_type_result;
	assign response_request_command_o = response_request_command_result;
	assign response_sequence_o = response_sequence_result;
	assign response_error_code_o = response_error_code_result;
	assign response_context_o = response_context_result;
	assign configured_o = configured_result;
	assign observations_loaded_o = observations_loaded_result;
	assign active_observation_count_o = active_observation_count_result;
	assign active_observation_index_o = active_observation_index;
	assign job_done_o = job_done_result;
	assign result_valid_o = result_valid_result;
	assign result_trusted_o = result_trusted_result;
	assign result_job_sequence_o = result_job_sequence_result;
	assign result_region_type_o = result_region_type_result;
	assign result_vertex_buffer_o = result_vertex_buffer_result;
	assign result_vertex_count_o = result_vertex_count_result;
	assign result_maximum_distance_squared_o = result_maximum_distance_result;
	assign result_farthest_first_index_o = result_first_index_result;
	assign result_farthest_second_index_o = result_second_index_result;
	assign result_core_cycle_count_o = result_core_cycle_count_result;
	assign result_error_flags_o = result_error_flags_result;
	assign result_vertex_read_ready_o = (state_current == STATE_IDLE) && result_valid_result;
	assign result_vertex_read_data_o = ram_port_0_read_data;
	assign result_vertex_read_valid_o = ram_port_0_read_valid && external_read_pending;

	assign engine_state_o = (state_current == STATE_IDLE) ?
		(result_valid_result ? 8'h06 : 8'h00) :
		(((state_current == STATE_LOAD_START) || (state_current == STATE_LOAD_WAIT)) ? 8'h02 :
		(((state_current == STATE_CONSTRAINT_START) || (state_current == STATE_CONSTRAINT_WAIT)) ? 8'h03 :
		(((state_current == STATE_CLIP_LOWER_START) || (state_current == STATE_CLIP_LOWER_WAIT) ||
		  (state_current == STATE_CLIP_UPPER_START) || (state_current == STATE_CLIP_UPPER_WAIT)) ? 8'h04 :
		(((state_current == STATE_DIAMETER_START) || (state_current == STATE_DIAMETER_WAIT)) ? 8'h05 :
		((state_current == STATE_JOB_ERROR) ? 8'hfe : 8'h06)))));

	initial_polygon_loader
	#(
		.C_ROM_INIT_FILE(C_ROM_INIT_FILE)
	)
	initial_polygon_loader_instance
	(
		.clk_i(clk_i),
		.reset_i(child_reset),
		.start_i(loader_start),
		.target_buffer_i(1'b0),
		.busy_o(loader_busy),
		.done_o(loader_done),
		.protocol_error_o(loader_protocol_error),
		.ram_write_enable_o(loader_ram_write_enable),
		.ram_write_buffer_o(loader_ram_write_buffer),
		.ram_write_address_o(loader_ram_write_address),
		.ram_write_data_o(loader_ram_write_data),
		.loaded_vertex_count_o(loader_vertex_count)
	);

	bearing_constraint_gen bearing_constraint_gen_instance
	(
		.clk_i(clk_i),
		.reset_i(child_reset),
		.start_i(constraint_start),
		.sensor_x_i(observation_x_memory[active_observation_index]),
		.sensor_y_i(observation_y_memory[active_observation_index]),
		.bearing_phase_i(observation_phase_memory[active_observation_index]),
		.busy_o(constraint_busy),
		.done_o(constraint_done),
		.protocol_error_o(constraint_protocol_error),
		.constraint_valid_o(constraint_valid),
		.constraint_upper_o(constraint_upper),
		.coefficient_a_o(constraint_a),
		.coefficient_b_o(constraint_b),
		.constant_c_o(constraint_c)
	);

	polygon_clip_engine polygon_clip_engine_instance
	(
		.clk_i(clk_i),
		.reset_i(child_reset),
		.start_i(clip_start),
		.input_buffer_i(current_vertex_buffer),
		.input_vertex_count_i(current_vertex_count),
		.coefficient_a_i(selected_clip_a),
		.coefficient_b_i(selected_clip_b),
		.constant_c_i(selected_clip_c),
		.busy_o(clip_busy),
		.done_o(clip_done),
		.protocol_error_o(clip_protocol_error),
		.output_buffer_o(clip_output_buffer),
		.output_vertex_count_o(clip_output_vertex_count),
		.empty_o(clip_empty),
		.result_trusted_o(clip_result_trusted),
		.parallel_edge_o(clip_parallel_edge),
		.arithmetic_saturated_o(clip_arithmetic_saturated),
		.capacity_overflow_o(clip_capacity_overflow),
		.quantization_margin_used_o(clip_quantization_margin),
		.residual_violation_o(clip_residual_violation),
		.ram_read_enable_o(clip_ram_read_enable),
		.ram_read_buffer_o(clip_ram_read_buffer),
		.ram_read_address_o(clip_ram_read_address),
		.ram_read_data_i(ram_port_0_read_data),
		.ram_read_valid_i(ram_port_0_read_valid),
		.ram_write_enable_o(clip_ram_write_enable),
		.ram_write_buffer_o(clip_ram_write_buffer),
		.ram_write_address_o(clip_ram_write_address),
		.ram_write_data_o(clip_ram_write_data)
	);

	polygon_diameter_engine polygon_diameter_engine_instance
	(
		.clk_i(clk_i),
		.reset_i(child_reset),
		.start_i(diameter_start),
		.vertex_buffer_i(current_vertex_buffer),
		.vertex_count_i(current_vertex_count),
		.busy_o(diameter_busy),
		.done_o(diameter_done),
		.protocol_error_o(diameter_protocol_error),
		.empty_o(diameter_empty),
		.result_trusted_o(diameter_result_trusted),
		.arithmetic_saturated_o(diameter_arithmetic_saturated),
		.input_count_error_o(diameter_input_count_error),
		.maximum_distance_squared_o(diameter_maximum_distance),
		.farthest_first_index_o(diameter_first_index),
		.farthest_second_index_o(diameter_second_index),
		.evaluated_pair_count_o(diameter_pair_count),
		.ram_first_read_enable_o(diameter_first_read_enable),
		.ram_first_read_buffer_o(diameter_first_read_buffer),
		.ram_first_read_address_o(diameter_first_read_address),
		.ram_first_read_data_i(ram_port_0_read_data),
		.ram_first_read_valid_i(ram_port_0_read_valid),
		.ram_second_read_enable_o(diameter_second_read_enable),
		.ram_second_read_buffer_o(diameter_second_read_buffer),
		.ram_second_read_address_o(diameter_second_read_address),
		.ram_second_read_data_i(ram_port_1_read_data),
		.ram_second_read_valid_i(ram_port_1_read_valid)
	);

	vertex_ram_dual_buffer vertex_ram_dual_buffer_instance
	(
		.clk_i(clk_i),
		.reset_i(child_reset),
		.port_0_enable_i(ram_port_0_enable),
		.port_0_write_i(ram_port_0_write),
		.port_0_buffer_i(ram_port_0_buffer),
		.port_0_address_i(ram_port_0_address),
		.port_0_write_data_i(ram_port_0_write_data),
		.port_0_read_data_o(ram_port_0_read_data),
		.port_0_read_valid_o(ram_port_0_read_valid),
		.port_1_enable_i(ram_port_1_enable),
		.port_1_write_i(ram_port_1_write),
		.port_1_buffer_i(ram_port_1_buffer),
		.port_1_address_i(ram_port_1_address),
		.port_1_write_data_i(ram_port_1_write_data),
		.port_1_read_data_o(ram_port_1_read_data),
		.port_1_read_valid_o(ram_port_1_read_valid)
	);

	// Each phase has exclusive ownership of the shared dual-port vertex RAM.
	always @(*) begin
		ram_port_0_enable = 1'b0;
		ram_port_0_write = 1'b0;
		ram_port_0_buffer = 1'b0;
		ram_port_0_address = 10'd0;
		ram_port_0_write_data = 64'd0;
		ram_port_1_enable = 1'b0;
		ram_port_1_write = 1'b0;
		ram_port_1_buffer = 1'b0;
		ram_port_1_address = 10'd0;
		ram_port_1_write_data = 64'd0;
		if((state_current == STATE_LOAD_START) || (state_current == STATE_LOAD_WAIT)) begin
			ram_port_0_enable = loader_ram_write_enable;
			ram_port_0_write = 1'b1;
			ram_port_0_buffer = loader_ram_write_buffer;
			ram_port_0_address = loader_ram_write_address;
			ram_port_0_write_data = loader_ram_write_data;
		end else if((state_current == STATE_CLIP_LOWER_START) ||
			(state_current == STATE_CLIP_LOWER_WAIT) ||
			(state_current == STATE_CLIP_UPPER_START) ||
			(state_current == STATE_CLIP_UPPER_WAIT)) begin
			ram_port_0_enable = clip_ram_read_enable;
			ram_port_0_buffer = clip_ram_read_buffer;
			ram_port_0_address = clip_ram_read_address;
			ram_port_1_enable = clip_ram_write_enable;
			ram_port_1_write = 1'b1;
			ram_port_1_buffer = clip_ram_write_buffer;
			ram_port_1_address = clip_ram_write_address;
			ram_port_1_write_data = clip_ram_write_data;
		end else if((state_current == STATE_DIAMETER_START) ||
			(state_current == STATE_DIAMETER_WAIT)) begin
			ram_port_0_enable = diameter_first_read_enable;
			ram_port_0_buffer = diameter_first_read_buffer;
			ram_port_0_address = diameter_first_read_address;
			ram_port_1_enable = diameter_second_read_enable;
			ram_port_1_buffer = diameter_second_read_buffer;
			ram_port_1_address = diameter_second_read_address;
		end else if(result_vertex_read_ready_o && result_vertex_read_enable_i) begin
			ram_port_0_enable = 1'b1;
			ram_port_0_buffer = result_vertex_buffer_result;
			ram_port_0_address = result_vertex_read_address_i;
		end
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			state_current <= STATE_IDLE;
		end else if(abort_command_accept == 1'b1) begin
			state_current <= STATE_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	always @(*) begin
		state_next = state_current;
		case(state_current)
			STATE_IDLE: begin
				if(start_command_accept == 1'b1) begin
					state_next = STATE_LOAD_START;
				end
			end
			STATE_LOAD_START: state_next = STATE_LOAD_WAIT;
			STATE_LOAD_WAIT: begin
				if(loader_protocol_error || watchdog_expired) begin
					state_next = STATE_JOB_ERROR;
				end else if(loader_done) begin
					state_next = STATE_CONSTRAINT_START;
				end
			end
			STATE_CONSTRAINT_START: state_next = STATE_CONSTRAINT_WAIT;
			STATE_CONSTRAINT_WAIT: begin
				if(constraint_protocol_error || watchdog_expired) begin
					state_next = STATE_JOB_ERROR;
				end else if(constraint_done) begin
					state_next = (lower_constraint_received ||
						(constraint_valid && !constraint_upper)) &&
						(upper_constraint_received ||
						(constraint_valid && constraint_upper)) ?
						STATE_CLIP_LOWER_START : STATE_JOB_ERROR;
				end
			end
			STATE_CLIP_LOWER_START: state_next = STATE_CLIP_LOWER_WAIT;
			STATE_CLIP_LOWER_WAIT: begin
				if(watchdog_expired) begin
					state_next = STATE_JOB_ERROR;
				end else if(clip_done) begin
					if(clip_fatal_error) begin
						state_next = STATE_JOB_ERROR;
					end else if(clip_empty) begin
						state_next = STATE_DIAMETER_START;
					end else begin
						state_next = STATE_CLIP_UPPER_START;
					end
				end
			end
			STATE_CLIP_UPPER_START: state_next = STATE_CLIP_UPPER_WAIT;
			STATE_CLIP_UPPER_WAIT: begin
				if(watchdog_expired) begin
					state_next = STATE_JOB_ERROR;
				end else if(clip_done) begin
					if(clip_fatal_error) begin
						state_next = STATE_JOB_ERROR;
					end else if(clip_empty ||
						(active_observation_index + 1'b1 >= active_observation_count_result)) begin
						state_next = STATE_DIAMETER_START;
					end else begin
						state_next = STATE_CONSTRAINT_START;
					end
				end
			end
			STATE_DIAMETER_START: state_next = STATE_DIAMETER_WAIT;
			STATE_DIAMETER_WAIT: begin
				if(watchdog_expired) begin
					state_next = STATE_JOB_ERROR;
				end else if(diameter_done) begin
					state_next = diameter_fatal_error ? STATE_JOB_ERROR : STATE_JOB_FINISH;
				end
			end
			STATE_JOB_FINISH: state_next = STATE_IDLE;
			STATE_JOB_ERROR: state_next = STATE_IDLE;
			default: state_next = STATE_JOB_ERROR;
		endcase
	end

	// Command responses are held until the downstream packet adapter accepts them.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			configured_result <= 1'b0;
			observations_loaded_result <= 1'b0;
			active_observation_count_result <= 5'd0;
			response_valid_result <= 1'b0;
			response_type_result <= RESPONSE_ACK;
			response_request_command_result <= 8'd0;
			response_sequence_result <= 16'd0;
			response_error_code_result <= 8'd0;
			response_context_result <= 32'd0;
			child_reset_result <= 1'b0;
		end else begin
			child_reset_result <= 1'b0;
			if(response_valid_result && response_ready_i) begin
				response_valid_result <= 1'b0;
			end
			if(observation_write_valid_i && observation_write_ready_o) begin
				observation_x_memory[observation_write_address_i] <= observation_x_i;
				observation_y_memory[observation_write_address_i] <= observation_y_i;
				observation_phase_memory[observation_write_address_i] <= observation_phase_i;
			end
			if(command_accept) begin
				response_valid_result <= 1'b1;
				response_request_command_result <= command_code_i;
				response_sequence_result <= command_sequence_i;
				response_error_code_result <= 8'd0;
				response_context_result <= 32'd0;
				case(command_code_i)
					COMMAND_GET_INFO: response_type_result <= RESPONSE_INFO;
					COMMAND_GET_STATUS: begin
						response_type_result <= RESPONSE_STATUS;
						response_context_result <= {engine_state_o, 3'd0,
							active_observation_count_result, result_error_flags_result, 8'd0};
					end
					COMMAND_READ_RESULT: begin
						if(result_valid_result) begin
							response_type_result <= RESPONSE_RESULT_HEADER;
							response_context_result <= {result_region_type_result,
								5'd0, result_vertex_count_result, result_error_flags_result};
						end else begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_RESULT_UNAVAILABLE;
						end
					end
					COMMAND_ABORT: begin
						response_type_result <= RESPONSE_ACK;
						child_reset_result <= 1'b1;
					end
					COMMAND_SET_CONFIG: begin
						if(state_current != STATE_IDLE) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_BUSY;
						end else if(!command_config_matches_i) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_PARAMETER;
						end else begin
							response_type_result <= RESPONSE_ACK;
							configured_result <= 1'b1;
						end
					end
					COMMAND_LOAD_OBSERVATIONS: begin
						if(state_current != STATE_IDLE) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_BUSY;
						end else if((command_observation_count_i < 5'd2) ||
							(command_observation_count_i > 5'd20)) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_OBSERVATION_COUNT;
						end else begin
							response_type_result <= RESPONSE_ACK;
							active_observation_count_result <= command_observation_count_i;
							observations_loaded_result <= 1'b1;
						end
					end
					COMMAND_START_LOCALIZATION: begin
						if(state_current != STATE_IDLE) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_BUSY;
						end else if(!configured_result) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_PARAMETER;
						end else if(!observations_loaded_result ||
							(active_observation_count_result < 5'd2) ||
							(active_observation_count_result > 5'd20)) begin
							response_type_result <= RESPONSE_ERROR;
							response_error_code_result <= ERROR_OBSERVATION_COUNT;
						end else begin
							response_type_result <= RESPONSE_ACK;
						end
					end
					default: begin
						response_type_result <= RESPONSE_ERROR;
						response_error_code_result <= ERROR_UNKNOWN_COMMAND;
					end
				endcase
			end
		end
	end

	// Pipeline bookkeeping and unified error/status lifting.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			active_observation_index <= 5'd0;
			current_vertex_buffer <= 1'b0;
			current_vertex_count <= 11'd0;
			lower_coefficient_a <= 32'sd0;
			lower_coefficient_b <= 32'sd0;
			lower_constant_c <= 66'sd0;
			upper_coefficient_a <= 32'sd0;
			upper_coefficient_b <= 32'sd0;
			upper_constant_c <= 66'sd0;
			lower_constraint_received <= 1'b0;
			upper_constraint_received <= 1'b0;
			child_watchdog_count <= 32'd0;
			core_cycle_count_work <= 32'd0;
			error_flags_work <= 8'd0;
			diameter_empty_saved <= 1'b1;
			diameter_distance_saved <= 66'd0;
			diameter_first_index_saved <= 10'd0;
			diameter_second_index_saved <= 10'd0;
			job_done_result <= 1'b0;
			result_valid_result <= 1'b0;
			result_trusted_result <= 1'b0;
			result_job_sequence_result <= 16'd0;
			result_region_type_result <= REGION_INVALID;
			result_vertex_buffer_result <= 1'b0;
			result_vertex_count_result <= 11'd0;
			result_maximum_distance_result <= 66'd0;
			result_first_index_result <= 10'd0;
			result_second_index_result <= 10'd0;
			result_core_cycle_count_result <= 32'd0;
			result_error_flags_result <= 8'd0;
			external_read_pending <= 1'b0;
		end else begin
			job_done_result <= 1'b0;
			external_read_pending <= result_vertex_read_ready_o && result_vertex_read_enable_i;
			if(abort_command_accept) begin
				result_valid_result <= 1'b0;
				result_trusted_result <= 1'b0;
				result_error_flags_result <= 8'h80;
				error_flags_work <= 8'h80;
				core_cycle_count_work <= 32'd0;
			end else begin
				if(command_accept && (command_code_i == COMMAND_LOAD_OBSERVATIONS) &&
					(state_current == STATE_IDLE) &&
					(command_observation_count_i >= 5'd2) &&
					(command_observation_count_i <= 5'd20)) begin
					result_valid_result <= 1'b0;
				end
				if(start_command_accept) begin
					active_observation_index <= 5'd0;
					current_vertex_buffer <= 1'b0;
					current_vertex_count <= 11'd0;
					core_cycle_count_work <= 32'd0;
					error_flags_work <= 8'd0;
					result_valid_result <= 1'b0;
					result_trusted_result <= 1'b0;
					result_job_sequence_result <= command_sequence_i;
				end else if(internal_busy) begin
					core_cycle_count_work <= core_cycle_count_work + 1'b1;
				end

				if((state_current == STATE_LOAD_WAIT) && loader_done) begin
					current_vertex_buffer <= 1'b0;
					current_vertex_count <= loader_vertex_count;
				end
				if(state_current == STATE_CONSTRAINT_START) begin
					lower_constraint_received <= 1'b0;
					upper_constraint_received <= 1'b0;
				end
				if((state_current == STATE_CONSTRAINT_WAIT) && constraint_valid) begin
					if(constraint_upper) begin
						upper_coefficient_a <= constraint_a;
						upper_coefficient_b <= constraint_b;
						upper_constant_c <= constraint_c;
						upper_constraint_received <= 1'b1;
					end else begin
						lower_coefficient_a <= constraint_a;
						lower_coefficient_b <= constraint_b;
						lower_constant_c <= constraint_c;
						lower_constraint_received <= 1'b1;
					end
				end
				if(((state_current == STATE_CLIP_LOWER_WAIT) ||
					(state_current == STATE_CLIP_UPPER_WAIT)) && clip_done) begin
					current_vertex_buffer <= clip_output_buffer;
					current_vertex_count <= clip_output_vertex_count;
					if(clip_quantization_margin) error_flags_work[0] <= 1'b1;
					if(clip_parallel_edge) error_flags_work[1] <= 1'b1;
					if(clip_arithmetic_saturated || clip_residual_violation ||
						clip_protocol_error) error_flags_work[2] <= 1'b1;
					if(clip_capacity_overflow) error_flags_work[3] <= 1'b1;
					if((state_current == STATE_CLIP_UPPER_WAIT) && !clip_fatal_error &&
						!clip_empty &&
						(active_observation_index + 1'b1 < active_observation_count_result)) begin
						active_observation_index <= active_observation_index + 1'b1;
					end
				end
				if((state_current == STATE_DIAMETER_WAIT) && diameter_done) begin
					diameter_empty_saved <= diameter_empty;
					diameter_distance_saved <= diameter_maximum_distance;
					diameter_first_index_saved <= diameter_first_index;
					diameter_second_index_saved <= diameter_second_index;
					if(diameter_arithmetic_saturated || diameter_input_count_error ||
						diameter_protocol_error) error_flags_work[2] <= 1'b1;
				end

				if((state_current == STATE_LOAD_WAIT) ||
					(state_current == STATE_CONSTRAINT_WAIT) ||
					(state_current == STATE_CLIP_LOWER_WAIT) ||
					(state_current == STATE_CLIP_UPPER_WAIT) ||
					(state_current == STATE_DIAMETER_WAIT)) begin
					if(state_next != state_current) begin
						child_watchdog_count <= 32'd0;
					end else begin
						child_watchdog_count <= child_watchdog_count + 1'b1;
					end
				end else begin
					child_watchdog_count <= 32'd0;
				end
				if(watchdog_expired &&
					((state_current == STATE_LOAD_WAIT) ||
					 (state_current == STATE_CONSTRAINT_WAIT) ||
					 (state_current == STATE_CLIP_LOWER_WAIT) ||
					 (state_current == STATE_CLIP_UPPER_WAIT) ||
					 (state_current == STATE_DIAMETER_WAIT))) begin
					error_flags_work[4] <= 1'b1;
				end
				if((state_current == STATE_CONSTRAINT_WAIT) && constraint_done &&
					!((lower_constraint_received || (constraint_valid && !constraint_upper)) &&
					  (upper_constraint_received || (constraint_valid && constraint_upper)))) begin
					error_flags_work[5] <= 1'b1;
				end
				if(loader_protocol_error || constraint_protocol_error) begin
					error_flags_work[5] <= 1'b1;
				end
			end

			if(state_current == STATE_JOB_FINISH) begin
				result_valid_result <= 1'b1;
				result_trusted_result <= ~(error_flags_work[1] || error_flags_work[2] ||
					error_flags_work[3] || error_flags_work[4] || error_flags_work[5]);
				result_region_type_result <= diameter_empty_saved ? REGION_EMPTY :
					((current_vertex_count == 11'd1) ? REGION_POINT :
					((current_vertex_count == 11'd2) ? REGION_SEGMENT : REGION_POLYGON));
				result_vertex_buffer_result <= current_vertex_buffer;
				result_vertex_count_result <= current_vertex_count;
				result_maximum_distance_result <= diameter_distance_saved;
				result_first_index_result <= diameter_first_index_saved;
				result_second_index_result <= diameter_second_index_saved;
				result_core_cycle_count_result <= core_cycle_count_work + 1'b1;
				result_error_flags_result <= error_flags_work | 8'h40;
				job_done_result <= 1'b1;
			end else if(state_current == STATE_JOB_ERROR) begin
				result_valid_result <= 1'b1;
				result_trusted_result <= 1'b0;
				result_region_type_result <= REGION_INVALID;
				result_vertex_buffer_result <= current_vertex_buffer;
				result_vertex_count_result <= current_vertex_count;
				result_maximum_distance_result <= 66'd0;
				result_first_index_result <= 10'd0;
				result_second_index_result <= 10'd0;
				result_core_cycle_count_result <= core_cycle_count_work + 1'b1;
				result_error_flags_result <= (error_flags_work == 8'd0) ? 8'h20 : error_flags_work;
				job_done_result <= 1'b1;
			end
		end
	end

endmodule
