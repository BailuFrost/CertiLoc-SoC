`timescale 1ns / 1ps

module tb_localization_command_ctrl;

	reg clk_i;
	reg reset_i;
	reg command_valid_i;
	wire command_ready_o;
	reg [7:0] command_code_i;
	reg [15:0] command_sequence_i;
	reg command_config_matches_i;
	reg [4:0] command_observation_count_i;
	reg observation_write_valid_i;
	wire observation_write_ready_o;
	reg [4:0] observation_write_address_i;
	reg signed [31:0] observation_x_i;
	reg signed [31:0] observation_y_i;
	reg [17:0] observation_phase_i;
	wire response_valid_o;
	reg response_ready_i;
	wire [7:0] response_type_o;
	wire [7:0] response_request_command_o;
	wire [15:0] response_sequence_o;
	wire [7:0] response_error_code_o;
	wire [31:0] response_context_o;
	wire busy_o;
	wire [7:0] engine_state_o;
	wire configured_o;
	wire observations_loaded_o;
	wire [4:0] active_observation_count_o;
	wire [4:0] active_observation_index_o;
	wire job_done_o;
	wire result_valid_o;
	wire result_trusted_o;
	wire [15:0] result_job_sequence_o;
	wire [7:0] result_region_type_o;
	wire result_vertex_buffer_o;
	wire [10:0] result_vertex_count_o;
	wire [65:0] result_maximum_distance_squared_o;
	wire [9:0] result_farthest_first_index_o;
	wire [9:0] result_farthest_second_index_o;
	wire [31:0] result_core_cycle_count_o;
	wire [7:0] result_error_flags_o;
	reg result_vertex_read_enable_i;
	wire result_vertex_read_ready_o;
	reg [9:0] result_vertex_read_address_i;
	wire [63:0] result_vertex_read_data_o;
	wire result_vertex_read_valid_o;

	integer failure_count;
	integer wait_count;
	integer t14_case_index;
	integer t14_observation_index;
	integer t14_vertex_index;
	integer t14_expected_index;
	integer t14_stress_index;
	integer t14_observation_offset;
	integer t14_observation_count;
	integer t14_vertex_offset;
	integer t14_vertex_count;
	reg [255:0] t14_case_meta [0:23];
	reg [95:0] t14_observations [0:255];
	reg [63:0] t14_expected_vertices [0:255];
	reg [63:0] t14_actual_vertices [0:1023];
	reg [65:0] t14_expected_distance;
	reg t14_expected_trusted;
	reg [7:0] t14_expected_region;
	reg [7:0] t14_expected_flags;
	reg t14_vertex_matched;
	reg signed [32:0] t14_delta_x;
	reg signed [32:0] t14_delta_y;
	reg [65:0] t14_selected_distance;
	reg t14_stress_active;
	reg [63:0] first_result_vertex;

	localization_command_ctrl dut
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.command_valid_i(command_valid_i),
		.command_ready_o(command_ready_o),
		.command_code_i(command_code_i),
		.command_sequence_i(command_sequence_i),
		.command_config_matches_i(command_config_matches_i),
		.command_observation_count_i(command_observation_count_i),
		.observation_write_valid_i(observation_write_valid_i),
		.observation_write_ready_o(observation_write_ready_o),
		.observation_write_address_i(observation_write_address_i),
		.observation_x_i(observation_x_i),
		.observation_y_i(observation_y_i),
		.observation_phase_i(observation_phase_i),
		.response_valid_o(response_valid_o),
		.response_ready_i(response_ready_i),
		.response_type_o(response_type_o),
		.response_request_command_o(response_request_command_o),
		.response_sequence_o(response_sequence_o),
		.response_error_code_o(response_error_code_o),
		.response_context_o(response_context_o),
		.busy_o(busy_o),
		.engine_state_o(engine_state_o),
		.configured_o(configured_o),
		.observations_loaded_o(observations_loaded_o),
		.active_observation_count_o(active_observation_count_o),
		.active_observation_index_o(active_observation_index_o),
		.job_done_o(job_done_o),
		.result_valid_o(result_valid_o),
		.result_trusted_o(result_trusted_o),
		.result_job_sequence_o(result_job_sequence_o),
		.result_region_type_o(result_region_type_o),
		.result_vertex_buffer_o(result_vertex_buffer_o),
		.result_vertex_count_o(result_vertex_count_o),
		.result_maximum_distance_squared_o(result_maximum_distance_squared_o),
		.result_farthest_first_index_o(result_farthest_first_index_o),
		.result_farthest_second_index_o(result_farthest_second_index_o),
		.result_core_cycle_count_o(result_core_cycle_count_o),
		.result_error_flags_o(result_error_flags_o),
		.result_vertex_read_enable_i(result_vertex_read_enable_i),
		.result_vertex_read_ready_o(result_vertex_read_ready_o),
		.result_vertex_read_address_i(result_vertex_read_address_i),
		.result_vertex_read_data_o(result_vertex_read_data_o),
		.result_vertex_read_valid_o(result_vertex_read_valid_o)
	);

	always #5 clk_i = ~clk_i;

	task check_condition;
		input condition;
		input [8*96-1:0] message;
		begin
			if(condition !== 1'b1) begin
				$display("FAIL: %0s", message);
				failure_count = failure_count + 1;
			end
		end
	endtask

	task issue_command;
		input [7:0] command_code;
		input [15:0] sequence;
		input config_matches;
		input [4:0] observation_count;
		input [7:0] expected_type;
		input [7:0] expected_error;
		begin
			while(command_ready_o !== 1'b1) @(posedge clk_i);
			command_code_i = command_code;
			command_sequence_i = sequence;
			command_config_matches_i = config_matches;
			command_observation_count_i = observation_count;
			command_valid_i = 1'b1;
			@(posedge clk_i);
			#1;
			command_valid_i = 1'b0;
			wait_count = 0;
			while((response_valid_o !== 1'b1) && (wait_count < 20)) begin
				@(posedge clk_i);
				#1;
				wait_count = wait_count + 1;
			end
			check_condition(response_valid_o, "command response missing");
			check_condition(response_type_o == expected_type, "unexpected response type");
			check_condition(response_error_code_o == expected_error, "unexpected response error code");
			check_condition(response_request_command_o == command_code, "response command mismatch");
			check_condition(response_sequence_o == sequence, "response sequence mismatch");
			@(posedge clk_i);
			#1;
		end
	endtask

	task write_observation;
		input [4:0] address;
		input signed [31:0] sensor_x;
		input signed [31:0] sensor_y;
		input [17:0] phase;
		begin
			while(observation_write_ready_o !== 1'b1) @(posedge clk_i);
			observation_write_address_i = address;
			observation_x_i = sensor_x;
			observation_y_i = sensor_y;
			observation_phase_i = phase;
			observation_write_valid_i = 1'b1;
			@(posedge clk_i);
			#1;
			observation_write_valid_i = 1'b0;
		end
	endtask

	task wait_for_job;
		input integer maximum_cycles;
		begin
			wait_count = 0;
			while((job_done_o !== 1'b1) && (wait_count < maximum_cycles)) begin
				@(posedge clk_i);
				#1;
				wait_count = wait_count + 1;
			end
			check_condition(job_done_o, "job completion timeout");
			if(!t14_stress_active) begin
				$display("INFO: job cycles=%0d vertices=%0d distance2=%0d flags=%02x",
					result_core_cycle_count_o, result_vertex_count_o,
					result_maximum_distance_squared_o, result_error_flags_o);
			end
		end
	endtask

	task load_t14_case_observations;
		input integer case_number;
		begin
			t14_observation_offset = t14_case_meta[case_number][15:0];
			t14_observation_count = t14_case_meta[case_number][20:16];
			for(t14_observation_index = 0; t14_observation_index < t14_observation_count;
				t14_observation_index = t14_observation_index + 1) begin
				write_observation(
					t14_observation_index[4:0],
					t14_observations[t14_observation_offset + t14_observation_index][31:0],
					t14_observations[t14_observation_offset + t14_observation_index][63:32],
					t14_observations[t14_observation_offset + t14_observation_index][81:64]
				);
			end
			issue_command(8'h11, 16'h7100 + case_number, 1'b0,
				t14_observation_count[4:0], 8'h80, 8'h00);
		end
	endtask

	task run_t14_vector_case;
		input integer case_number;
		begin
			load_t14_case_observations(case_number);
			t14_vertex_offset = t14_case_meta[case_number][36:21];
			t14_vertex_count = t14_case_meta[case_number][47:37];
			t14_expected_distance = t14_case_meta[case_number][113:48];
			t14_expected_trusted = t14_case_meta[case_number][114];
			t14_expected_region = t14_case_meta[case_number][122:115];
			t14_expected_flags = t14_case_meta[case_number][130:123];
			issue_command(8'h12, 16'h7200 + case_number, 1'b0, 5'd0, 8'h80, 8'h00);
			wait_for_job(2000000);
			check_condition(result_valid_o, "T14 vector result not valid");
			check_condition(result_job_sequence_o == 16'h7200 + case_number,
				"T14 vector sequence mismatch");
			check_condition(result_trusted_o == t14_expected_trusted,
				"T14 vector trust mismatch");
			check_condition(result_region_type_o == t14_expected_region,
				"T14 vector region mismatch");
			check_condition(result_vertex_count_o == t14_vertex_count,
				"T14 vector vertex count mismatch");
			check_condition(result_maximum_distance_squared_o == t14_expected_distance,
				"T14 vector diameter mismatch");
			check_condition(result_error_flags_o == t14_expected_flags,
				"T14 vector flags mismatch");
			for(t14_vertex_index = 0; t14_vertex_index < t14_vertex_count;
				t14_vertex_index = t14_vertex_index + 1) begin
				while(result_vertex_read_ready_o !== 1'b1) @(posedge clk_i);
				result_vertex_read_address_i = t14_vertex_index[9:0];
				result_vertex_read_enable_i = 1'b1;
				@(posedge clk_i);
				#1;
				result_vertex_read_enable_i = 1'b0;
				check_condition(result_vertex_read_valid_o, "T14 vector vertex read missing");
				t14_actual_vertices[t14_vertex_index] = result_vertex_read_data_o;
				t14_vertex_matched = 1'b0;
				for(t14_expected_index = 0; t14_expected_index < t14_vertex_count;
					t14_expected_index = t14_expected_index + 1) begin
					if(result_vertex_read_data_o ==
						t14_expected_vertices[t14_vertex_offset + t14_expected_index]) begin
						t14_vertex_matched = 1'b1;
					end
				end
				check_condition(t14_vertex_matched, "T14 vector vertex set mismatch");
			end
			if(t14_vertex_count > 1) begin
				t14_delta_x = $signed(t14_actual_vertices[result_farthest_first_index_o][31:0]) -
					$signed(t14_actual_vertices[result_farthest_second_index_o][31:0]);
				t14_delta_y = $signed(t14_actual_vertices[result_farthest_first_index_o][63:32]) -
					$signed(t14_actual_vertices[result_farthest_second_index_o][63:32]);
				t14_selected_distance = t14_delta_x * t14_delta_x +
					t14_delta_y * t14_delta_y;
				check_condition(t14_selected_distance == result_maximum_distance_squared_o,
					"T14 farthest indices do not select the diameter");
			end
		end
	endtask

	task run_t14_continuous_stress;
		begin
			// Case 1 is the deterministic empty-region boundary and completes quickly.
			load_t14_case_observations(1);
			t14_stress_active = 1'b1;
			for(t14_stress_index = 0; t14_stress_index < 1000;
				t14_stress_index = t14_stress_index + 1) begin
				issue_command(8'h12, 16'h8000 + t14_stress_index, 1'b0, 5'd0,
					8'h80, 8'h00);
				wait_for_job(2000000);
				check_condition(result_valid_o && result_trusted_o,
					"T14 stress result invalid or untrusted");
				check_condition(result_job_sequence_o == 16'h8000 + t14_stress_index,
					"T14 stress sequence contamination");
				check_condition(result_region_type_o == 8'h00 &&
					result_vertex_count_o == 11'd0 &&
					result_maximum_distance_squared_o == 66'd0,
					"T14 stress result state contamination");
			end
			t14_stress_active = 1'b0;
			$display("INFO: T14 continuous stress completed 1000 jobs");
		end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		command_valid_i = 1'b0;
		command_code_i = 8'd0;
		command_sequence_i = 16'd0;
		command_config_matches_i = 1'b0;
		command_observation_count_i = 5'd0;
		observation_write_valid_i = 1'b0;
		observation_write_address_i = 5'd0;
		observation_x_i = 32'sd0;
		observation_y_i = 32'sd0;
		observation_phase_i = 18'd0;
		response_ready_i = 1'b1;
		result_vertex_read_enable_i = 1'b0;
		result_vertex_read_address_i = 10'd0;
		failure_count = 0;
		first_result_vertex = 64'd0;
		t14_stress_active = 1'b0;
		$readmemh("t14_case_meta.mem", t14_case_meta);
		$readmemh("t14_observations.mem", t14_observations);
		$readmemh("t14_expected_vertices.mem", t14_expected_vertices);
		repeat(5) @(posedge clk_i);
		reset_i = 1'b0;
		repeat(2) @(posedge clk_i);

		// Reject START before configuration and reject an invalid observation count.
		issue_command(8'h12, 16'h0001, 1'b0, 5'd0, 8'hff, 8'h06);
		issue_command(8'h11, 16'h0002, 1'b0, 5'd1, 8'hff, 8'h08);
		issue_command(8'h10, 16'h0003, 1'b0, 5'd0, 8'hff, 8'h06);
		issue_command(8'h10, 16'h0004, 1'b1, 5'd0, 8'h80, 8'h00);
		check_condition(configured_o, "valid SET_CONFIG was not committed");

		// Two inward-facing sensors produce a narrow four-vertex region.
		write_observation(5'd0, -32'sd65536000, 32'sd0, 18'd0);
		write_observation(5'd1, 32'sd65536000, 32'sd0, 18'd131072);
		issue_command(8'h11, 16'h0005, 1'b0, 5'd2, 8'h80, 8'h00);
		check_condition(observations_loaded_o, "observation commit missing");
		check_condition(active_observation_count_o == 5'd2, "observation count mismatch");
		issue_command(8'h12, 16'h1234, 1'b0, 5'd0, 8'h80, 8'h00);

		// A second START while running must be rejected as busy.
		while(busy_o !== 1'b1) @(posedge clk_i);
		issue_command(8'h12, 16'h1235, 1'b0, 5'd0, 8'hff, 8'h07);
		wait_for_job(2000000);
		check_condition(result_valid_o, "normal result not valid");
		check_condition(result_trusted_o, "normal result unexpectedly untrusted");
		check_condition(result_job_sequence_o == 16'h1234, "job sequence mismatch");
		check_condition(result_region_type_o == 8'h03, "normal region is not polygon");
		check_condition(result_vertex_count_o == 11'd4, "normal vertex count mismatch");
		check_condition(result_maximum_distance_squared_o == 66'd17179868135424016,
			"normal diameter mismatch");
		check_condition(result_farthest_first_index_o == 10'd0, "normal first index mismatch");
		check_condition(result_farthest_second_index_o == 10'd2, "normal second index mismatch");
		check_condition(result_error_flags_o == 8'h41, "normal result flags mismatch");

		// Result RAM window must return a stored vertex after computation.
		check_condition(result_vertex_read_ready_o, "result vertex window not ready");
		result_vertex_read_address_i = 10'd0;
		result_vertex_read_enable_i = 1'b1;
		@(posedge clk_i);
		#1;
		result_vertex_read_enable_i = 1'b0;
		check_condition(result_vertex_read_valid_o, "result vertex read missing");
		first_result_vertex = result_vertex_read_data_o;
		check_condition(first_result_vertex !== 64'd0, "result vertex unexpectedly zero");
		issue_command(8'h14, 16'h0006, 1'b0, 5'd0, 8'h90, 8'h00);

		// Start another job, abort it, then prove that the pipeline can restart.
		issue_command(8'h12, 16'h2000, 1'b0, 5'd0, 8'h80, 8'h00);
		while(engine_state_o != 8'h02) @(posedge clk_i);
		repeat(20) @(posedge clk_i);
		issue_command(8'h1f, 16'h2001, 1'b0, 5'd0, 8'h80, 8'h00);
		repeat(3) @(posedge clk_i);
		check_condition(!busy_o, "ABORT did not return controller to idle");
		check_condition(!result_valid_o, "ABORT did not invalidate result");
		check_condition(result_error_flags_o == 8'h80, "ABORT flag mismatch");

		// Opposing outward bearings produce a valid empty result after restart.
		write_observation(5'd0, -32'sd65536000, 32'sd0, 18'd131072);
		write_observation(5'd1, 32'sd65536000, 32'sd0, 18'd0);
		issue_command(8'h11, 16'h2002, 1'b0, 5'd2, 8'h80, 8'h00);
		issue_command(8'h12, 16'h5678, 1'b0, 5'd0, 8'h80, 8'h00);
		wait_for_job(2000000);
		check_condition(result_valid_o, "empty result not valid");
		check_condition(result_trusted_o, "empty result unexpectedly untrusted");
		check_condition(result_job_sequence_o == 16'h5678, "restart job sequence mismatch");
		check_condition(result_region_type_o == 8'h00, "empty region type mismatch");
		check_condition(result_vertex_count_o == 11'd0, "empty vertex count mismatch");
		check_condition(result_maximum_distance_squared_o == 66'd0, "empty diameter mismatch");
		check_condition(result_error_flags_o == 8'h41, "empty result flags mismatch");

		// T14: 位精确随机/边界向量、无序顶点集、最远点对及连续任务污染检查。
		for(t14_case_index = 0; t14_case_index < 24;
			t14_case_index = t14_case_index + 1) begin
			run_t14_vector_case(t14_case_index);
		end
		run_t14_continuous_stress;

		// Inject a child protocol fault to verify fatal error lifting and INVALID classification.
		issue_command(8'h12, 16'h6000, 1'b0, 5'd0, 8'h80, 8'h00);
		while(engine_state_o != 8'h02) @(posedge clk_i);
		force dut.loader_protocol_error = 1'b1;
		@(posedge clk_i);
		#1;
		release dut.loader_protocol_error;
		wait_for_job(100);
		check_condition(result_valid_o, "fatal result not valid");
		check_condition(!result_trusted_o, "fatal result unexpectedly trusted");
		check_condition(result_region_type_o == 8'hff, "fatal result region is not INVALID");
		check_condition(result_error_flags_o[5], "fatal child protocol flag was not lifted");

		if(failure_count == 0) begin
			$display("PASS: localization_command_ctrl command, restart, RAM and geometry integration");
		end else begin
			$display("FAIL: localization_command_ctrl failures=%0d", failure_count);
		end
		$finish;
	end

endmodule
