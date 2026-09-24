`timescale 1ns / 1ps

// Basys 3阶段1无线电示向定位系统顶层
module radio_localization_fpga_top
#(
	parameter C_UART_CLKS_PER_BIT = 868,
	parameter C_UART_HALF_BIT_CLKS = 434,
	parameter C_DECODER_TIMEOUT_CLKS = 10000000,
	parameter C_ROM_INIT_FILE = "initial_polygon_720_q16_16.mem"
)
(
	input wire clk_100mhz_i,
	input wire reset_btn_i,
	input wire uart_rx_i,
	output wire uart_tx_o,
	output wire [3:0] status_led_o,
	output wire debug_trigger_o
);

	reg [1:0] reset_release_pipe;
	reg error_latched;
	wire internal_reset;

	wire [7:0] uart_rx_data;
	wire uart_rx_data_valid;
	wire uart_rx_data_ready;
	wire uart_rx_frame_error;
	wire uart_rx_busy;
	wire [7:0] uart_tx_data;
	wire uart_tx_data_valid;
	wire uart_tx_data_ready;
	wire uart_tx_busy;

	wire decoder_frame_valid;
	wire decoder_frame_ready;
	wire [7:0] decoder_frame_command;
	wire [15:0] decoder_frame_sequence;
	wire [7:0] decoder_frame_payload_length;
	wire decoder_payload_read_enable;
	wire [7:0] decoder_payload_read_address;
	wire [7:0] decoder_payload_read_data;
	wire decoder_payload_read_valid;
	wire decoder_error_valid;
	wire decoder_error_ready;
	wire [7:0] decoder_error_code;
	wire [7:0] decoder_error_command;
	wire [15:0] decoder_error_sequence;
	wire [31:0] decoder_error_context;

	wire semantic_command_valid;
	wire semantic_command_ready;
	wire [7:0] semantic_command_code;
	wire [15:0] semantic_command_sequence;
	wire semantic_config_matches;
	wire [4:0] semantic_observation_count;
	wire semantic_observation_write_valid;
	wire semantic_observation_write_ready;
	wire [4:0] semantic_observation_write_address;
	wire signed [31:0] semantic_observation_x;
	wire signed [31:0] semantic_observation_y;
	wire [17:0] semantic_observation_phase;
	wire command_adapter_error_valid;
	wire command_adapter_error_ready;
	wire [7:0] command_adapter_error_command;
	wire [15:0] command_adapter_error_sequence;
	wire [7:0] command_adapter_error_code;
	wire [31:0] command_adapter_error_context;
	wire [7:0] read_result_kind;
	wire [15:0] read_result_start_index;
	wire [4:0] read_result_maximum_vertices;
	wire command_adapter_busy;

	wire controller_response_valid;
	wire controller_response_ready;
	wire [7:0] controller_response_type;
	wire [7:0] controller_response_request_command;
	wire [15:0] controller_response_sequence;
	wire [7:0] controller_response_error_code;
	wire [31:0] controller_response_context;
	(* mark_debug = "true" *) wire controller_busy;
	(* mark_debug = "true" *) wire [7:0] controller_engine_state;
	wire controller_configured;
	wire controller_observations_loaded;
	wire [4:0] controller_observation_count;
	(* mark_debug = "true" *) wire [4:0] controller_active_observation_index;
	(* mark_debug = "true" *) wire controller_job_done;
	(* mark_debug = "true" *) wire result_valid;
	(* mark_debug = "true" *) wire result_trusted;
	wire [15:0] result_job_sequence;
	wire [7:0] result_region_type;
	wire result_vertex_buffer;
	(* mark_debug = "true" *) wire [10:0] result_vertex_count;
	wire [65:0] result_maximum_distance;
	wire [9:0] result_first_index;
	wire [9:0] result_second_index;
	(* mark_debug = "true" *) wire [31:0] result_core_cycles;
	(* mark_debug = "true" *) wire [7:0] result_error_flags;
	wire result_vertex_read_enable;
	wire result_vertex_read_ready;
	wire [9:0] result_vertex_read_address;
	wire [63:0] result_vertex_read_data;
	wire result_vertex_read_valid;

	reg selected_response_valid;
	reg [7:0] selected_response_type;
	reg [7:0] selected_response_request_command;
	reg [15:0] selected_response_sequence;
	reg [7:0] selected_response_error_code;
	reg [31:0] selected_response_context;
	wire selected_response_ready;

	wire encoder_frame_valid;
	wire encoder_frame_ready;
	wire [7:0] encoder_frame_command;
	wire [15:0] encoder_frame_sequence;
	wire [7:0] encoder_frame_payload_length;
	wire [7:0] encoder_payload_data;
	wire encoder_payload_valid;
	wire encoder_payload_ready;
	wire response_adapter_busy;
	wire encoder_busy;
	wire encoder_frame_done;
	wire encoder_length_error;
	wire start_command_accept;

	assign internal_reset = reset_release_pipe[1];
	assign decoder_error_ready = selected_response_ready && decoder_error_valid;
	assign command_adapter_error_ready = selected_response_ready &&
		!decoder_error_valid && command_adapter_error_valid;
	assign controller_response_ready = selected_response_ready &&
		!decoder_error_valid && !command_adapter_error_valid && controller_response_valid;
	assign start_command_accept = semantic_command_valid && semantic_command_ready &&
		(semantic_command_code == 8'h12) && controller_configured &&
		controller_observations_loaded && !controller_busy;

	assign status_led_o[0] = !controller_busy && !command_adapter_busy &&
		!response_adapter_busy && !encoder_busy && !uart_tx_busy;
	assign status_led_o[1] = uart_rx_busy || decoder_frame_valid || command_adapter_busy;
	assign status_led_o[2] = controller_busy;
	assign status_led_o[3] = error_latched;
	assign debug_trigger_o = controller_job_done;

	// External reset asserts asynchronously and releases after two clean clock edges.
	always @(posedge clk_100mhz_i or posedge reset_btn_i) begin
		if(reset_btn_i) begin
			reset_release_pipe <= 2'b11;
		end else begin
			reset_release_pipe <= {reset_release_pipe[0], 1'b0};
		end
	end

	always @(posedge clk_100mhz_i or posedge internal_reset) begin
		if(internal_reset) begin
			error_latched <= 1'b0;
		end else if(start_command_accept) begin
			error_latched <= 1'b0;
		end else if(uart_rx_frame_error || decoder_error_valid ||
			command_adapter_error_valid || encoder_length_error ||
			(controller_response_valid && (controller_response_type == 8'hff)) ||
			(result_valid && !result_trusted)) begin
			error_latched <= 1'b1;
		end
	end

	// Response priority preserves parser errors before semantic and controller replies.
	always @(*) begin
		selected_response_valid = 1'b0;
		selected_response_type = 8'hff;
		selected_response_request_command = 8'd0;
		selected_response_sequence = 16'd0;
		selected_response_error_code = 8'd0;
		selected_response_context = 32'd0;
		if(decoder_error_valid) begin
			selected_response_valid = 1'b1;
			selected_response_request_command = decoder_error_command;
			selected_response_sequence = decoder_error_sequence;
			selected_response_error_code = decoder_error_code;
			selected_response_context = decoder_error_context;
		end else if(command_adapter_error_valid) begin
			selected_response_valid = 1'b1;
			selected_response_request_command = command_adapter_error_command;
			selected_response_sequence = command_adapter_error_sequence;
			selected_response_error_code = command_adapter_error_code;
			selected_response_context = command_adapter_error_context;
		end else if(controller_response_valid) begin
			selected_response_valid = 1'b1;
			selected_response_type = controller_response_type;
			selected_response_request_command = controller_response_request_command;
			selected_response_sequence = controller_response_sequence;
			selected_response_error_code = controller_response_error_code;
			selected_response_context = controller_response_context;
		end
	end

	uart_rx
	#(
		.C_CLKS_PER_BIT(C_UART_CLKS_PER_BIT),
		.C_HALF_BIT_CLKS(C_UART_HALF_BIT_CLKS)
	)
	uart_rx_instance
	(
		.i_clk(clk_100mhz_i),
		.i_reset(internal_reset),
		.i_uart_rx(uart_rx_i),
		.i_data_ready(uart_rx_data_ready),
		.o_data(uart_rx_data),
		.o_data_valid(uart_rx_data_valid),
		.o_frame_error(uart_rx_frame_error),
		.o_busy(uart_rx_busy)
	);

	packet_decoder
	#(
		.C_MAX_PAYLOAD_LENGTH(244),
		.C_TIMEOUT_CLKS(C_DECODER_TIMEOUT_CLKS)
	)
	packet_decoder_instance
	(
		.i_clk(clk_100mhz_i),
		.i_reset(internal_reset),
		.i_data(uart_rx_data),
		.i_data_valid(uart_rx_data_valid),
		.o_data_ready(uart_rx_data_ready),
		.o_frame_valid(decoder_frame_valid),
		.i_frame_ready(decoder_frame_ready),
		.o_frame_command(decoder_frame_command),
		.o_frame_sequence(decoder_frame_sequence),
		.o_frame_payload_length(decoder_frame_payload_length),
		.i_payload_read_enable(decoder_payload_read_enable),
		.i_payload_read_address(decoder_payload_read_address),
		.o_payload_read_data(decoder_payload_read_data),
		.o_payload_read_valid(decoder_payload_read_valid),
		.o_error_valid(decoder_error_valid),
		.i_error_ready(decoder_error_ready),
		.o_error_code(decoder_error_code),
		.o_error_command(decoder_error_command),
		.o_error_sequence(decoder_error_sequence),
		.o_error_context(decoder_error_context)
	);

	protocol_command_adapter protocol_command_adapter_instance
	(
		.clk_i(clk_100mhz_i),
		.reset_i(internal_reset),
		.frame_valid_i(decoder_frame_valid),
		.frame_ready_o(decoder_frame_ready),
		.frame_command_i(decoder_frame_command),
		.frame_sequence_i(decoder_frame_sequence),
		.frame_payload_length_i(decoder_frame_payload_length),
		.payload_read_enable_o(decoder_payload_read_enable),
		.payload_read_address_o(decoder_payload_read_address),
		.payload_read_data_i(decoder_payload_read_data),
		.payload_read_valid_i(decoder_payload_read_valid),
		.command_valid_o(semantic_command_valid),
		.command_ready_i(semantic_command_ready),
		.command_code_o(semantic_command_code),
		.command_sequence_o(semantic_command_sequence),
		.command_config_matches_o(semantic_config_matches),
		.command_observation_count_o(semantic_observation_count),
		.observation_write_valid_o(semantic_observation_write_valid),
		.observation_write_ready_i(semantic_observation_write_ready),
		.observation_write_address_o(semantic_observation_write_address),
		.observation_x_o(semantic_observation_x),
		.observation_y_o(semantic_observation_y),
		.observation_phase_o(semantic_observation_phase),
		.error_valid_o(command_adapter_error_valid),
		.error_ready_i(command_adapter_error_ready),
		.error_command_o(command_adapter_error_command),
		.error_sequence_o(command_adapter_error_sequence),
		.error_code_o(command_adapter_error_code),
		.error_context_o(command_adapter_error_context),
		.read_result_kind_o(read_result_kind),
		.read_result_start_index_o(read_result_start_index),
		.read_result_maximum_vertices_o(read_result_maximum_vertices),
		.busy_o(command_adapter_busy)
	);

	localization_command_ctrl
	#(
		.C_ROM_INIT_FILE(C_ROM_INIT_FILE)
	)
	localization_command_ctrl_instance
	(
		.clk_i(clk_100mhz_i),
		.reset_i(internal_reset),
		.command_valid_i(semantic_command_valid),
		.command_ready_o(semantic_command_ready),
		.command_code_i(semantic_command_code),
		.command_sequence_i(semantic_command_sequence),
		.command_config_matches_i(semantic_config_matches),
		.command_observation_count_i(semantic_observation_count),
		.observation_write_valid_i(semantic_observation_write_valid),
		.observation_write_ready_o(semantic_observation_write_ready),
		.observation_write_address_i(semantic_observation_write_address),
		.observation_x_i(semantic_observation_x),
		.observation_y_i(semantic_observation_y),
		.observation_phase_i(semantic_observation_phase),
		.response_valid_o(controller_response_valid),
		.response_ready_i(controller_response_ready),
		.response_type_o(controller_response_type),
		.response_request_command_o(controller_response_request_command),
		.response_sequence_o(controller_response_sequence),
		.response_error_code_o(controller_response_error_code),
		.response_context_o(controller_response_context),
		.busy_o(controller_busy),
		.engine_state_o(controller_engine_state),
		.configured_o(controller_configured),
		.observations_loaded_o(controller_observations_loaded),
		.active_observation_count_o(controller_observation_count),
		.active_observation_index_o(controller_active_observation_index),
		.job_done_o(controller_job_done),
		.result_valid_o(result_valid),
		.result_trusted_o(result_trusted),
		.result_job_sequence_o(result_job_sequence),
		.result_region_type_o(result_region_type),
		.result_vertex_buffer_o(result_vertex_buffer),
		.result_vertex_count_o(result_vertex_count),
		.result_maximum_distance_squared_o(result_maximum_distance),
		.result_farthest_first_index_o(result_first_index),
		.result_farthest_second_index_o(result_second_index),
		.result_core_cycle_count_o(result_core_cycles),
		.result_error_flags_o(result_error_flags),
		.result_vertex_read_enable_i(result_vertex_read_enable),
		.result_vertex_read_ready_o(result_vertex_read_ready),
		.result_vertex_read_address_i(result_vertex_read_address),
		.result_vertex_read_data_o(result_vertex_read_data),
		.result_vertex_read_valid_o(result_vertex_read_valid)
	);

	protocol_response_adapter protocol_response_adapter_instance
	(
		.clk_i(clk_100mhz_i),
		.reset_i(internal_reset),
		.response_valid_i(selected_response_valid),
		.response_ready_o(selected_response_ready),
		.response_type_i(selected_response_type),
		.response_request_command_i(selected_response_request_command),
		.response_sequence_i(selected_response_sequence),
		.response_error_code_i(selected_response_error_code),
		.response_context_i(selected_response_context),
		.read_result_kind_i(read_result_kind),
		.read_result_start_index_i(read_result_start_index),
		.read_result_maximum_vertices_i(read_result_maximum_vertices),
		.engine_state_i(controller_engine_state),
		.observation_count_i(controller_observation_count),
		.active_observation_index_i(controller_active_observation_index),
		.result_valid_i(result_valid),
		.result_trusted_i(result_trusted),
		.result_job_sequence_i(result_job_sequence),
		.result_region_type_i(result_region_type),
		.result_vertex_count_i(result_vertex_count),
		.result_maximum_distance_squared_i(result_maximum_distance),
		.result_farthest_first_index_i(result_first_index),
		.result_farthest_second_index_i(result_second_index),
		.result_core_cycle_count_i(result_core_cycles),
		.result_error_flags_i(result_error_flags),
		.result_vertex_read_enable_o(result_vertex_read_enable),
		.result_vertex_read_ready_i(result_vertex_read_ready),
		.result_vertex_read_address_o(result_vertex_read_address),
		.result_vertex_read_data_i(result_vertex_read_data),
		.result_vertex_read_valid_i(result_vertex_read_valid),
		.frame_valid_o(encoder_frame_valid),
		.frame_ready_i(encoder_frame_ready),
		.frame_command_o(encoder_frame_command),
		.frame_sequence_o(encoder_frame_sequence),
		.frame_payload_length_o(encoder_frame_payload_length),
		.payload_data_o(encoder_payload_data),
		.payload_valid_o(encoder_payload_valid),
		.payload_ready_i(encoder_payload_ready),
		.frame_done_i(encoder_frame_done),
		.busy_o(response_adapter_busy)
	);

	packet_encoder packet_encoder_instance
	(
		.i_clk(clk_100mhz_i),
		.i_reset(internal_reset),
		.i_frame_valid(encoder_frame_valid),
		.o_frame_ready(encoder_frame_ready),
		.i_frame_command(encoder_frame_command),
		.i_frame_sequence(encoder_frame_sequence),
		.i_frame_payload_length(encoder_frame_payload_length),
		.i_payload_data(encoder_payload_data),
		.i_payload_valid(encoder_payload_valid),
		.o_payload_ready(encoder_payload_ready),
		.o_data(uart_tx_data),
		.o_data_valid(uart_tx_data_valid),
		.i_data_ready(uart_tx_data_ready),
		.o_busy(encoder_busy),
		.o_frame_done(encoder_frame_done),
		.o_length_error(encoder_length_error)
	);

	uart_tx
	#(
		.C_CLKS_PER_BIT(C_UART_CLKS_PER_BIT)
	)
	uart_tx_instance
	(
		.i_clk(clk_100mhz_i),
		.i_reset(internal_reset),
		.i_data(uart_tx_data),
		.i_data_valid(uart_tx_data_valid),
		.o_data_ready(uart_tx_data_ready),
		.o_uart_tx(uart_tx_o),
		.o_busy(uart_tx_busy)
	);

endmodule
