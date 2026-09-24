`timescale 1ns / 1ps

module tb_polygon_clip_engine;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg input_buffer_i;
	reg [10:0] input_vertex_count_i;
	reg signed [31:0] coefficient_a_i;
	reg signed [31:0] coefficient_b_i;
	reg signed [65:0] constant_c_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire output_buffer_o;
	wire [10:0] output_vertex_count_o;
	wire empty_o;
	wire result_trusted_o;
	wire parallel_edge_o;
	wire arithmetic_saturated_o;
	wire capacity_overflow_o;
	wire quantization_margin_used_o;
	wire residual_violation_o;
	wire engine_read_enable;
	wire engine_read_buffer;
	wire [9:0] engine_read_address;
	wire [63:0] ram_read_data;
	wire ram_read_valid;
	wire engine_write_enable;
	wire engine_write_buffer;
	wire [9:0] engine_write_address;
	wire [63:0] engine_write_data;
	reg setup_enable;
	reg setup_write;
	reg setup_buffer;
	reg [9:0] setup_address;
	reg [63:0] setup_write_data;
	wire port_0_enable;
	wire port_0_write;
	wire port_0_buffer;
	wire [9:0] port_0_address;
	wire [63:0] port_0_write_data;

	integer failure_count;
	integer protocol_error_count;
	integer cycle_count;
	integer index;
	reg [63:0] observed_vertex;

	assign port_0_enable = busy_o ? engine_read_enable : setup_enable;
	assign port_0_write = busy_o ? 1'b0 : setup_write;
	assign port_0_buffer = busy_o ? engine_read_buffer : setup_buffer;
	assign port_0_address = busy_o ? engine_read_address : setup_address;
	assign port_0_write_data = setup_write_data;

	polygon_clip_engine dut
	(
		.clk_i(clk_i), .reset_i(reset_i), .start_i(start_i),
		.input_buffer_i(input_buffer_i), .input_vertex_count_i(input_vertex_count_i),
		.coefficient_a_i(coefficient_a_i), .coefficient_b_i(coefficient_b_i),
		.constant_c_i(constant_c_i), .busy_o(busy_o), .done_o(done_o),
		.protocol_error_o(protocol_error_o), .output_buffer_o(output_buffer_o),
		.output_vertex_count_o(output_vertex_count_o), .empty_o(empty_o),
		.result_trusted_o(result_trusted_o), .parallel_edge_o(parallel_edge_o),
		.arithmetic_saturated_o(arithmetic_saturated_o),
		.capacity_overflow_o(capacity_overflow_o),
		.quantization_margin_used_o(quantization_margin_used_o),
		.residual_violation_o(residual_violation_o),
		.ram_read_enable_o(engine_read_enable), .ram_read_buffer_o(engine_read_buffer),
		.ram_read_address_o(engine_read_address), .ram_read_data_i(ram_read_data),
		.ram_read_valid_i(ram_read_valid), .ram_write_enable_o(engine_write_enable),
		.ram_write_buffer_o(engine_write_buffer), .ram_write_address_o(engine_write_address),
		.ram_write_data_o(engine_write_data)
	);

	vertex_ram_dual_buffer vertex_memory
	(
		.clk_i(clk_i), .reset_i(reset_i),
		.port_0_enable_i(port_0_enable), .port_0_write_i(port_0_write),
		.port_0_buffer_i(port_0_buffer), .port_0_address_i(port_0_address),
		.port_0_write_data_i(port_0_write_data), .port_0_read_data_o(ram_read_data),
		.port_0_read_valid_o(ram_read_valid),
		.port_1_enable_i(engine_write_enable), .port_1_write_i(1'b1),
		.port_1_buffer_i(engine_write_buffer), .port_1_address_i(engine_write_address),
		.port_1_write_data_i(engine_write_data), .port_1_read_data_o(),
		.port_1_read_valid_o()
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task write_vertex;
		input target_buffer;
		input [9:0] target_address;
		input signed [31:0] target_x;
		input signed [31:0] target_y;
	begin
		@(negedge clk_i);
		setup_enable = 1'b1;
		setup_write = 1'b1;
		setup_buffer = target_buffer;
		setup_address = target_address;
		setup_write_data = {target_x, target_y};
		@(negedge clk_i);
		setup_enable = 1'b0;
		setup_write = 1'b0;
	end
	endtask

	task read_vertex;
		input target_buffer;
		input [9:0] target_address;
	begin
		@(negedge clk_i);
		setup_enable = 1'b1;
		setup_write = 1'b0;
		setup_buffer = target_buffer;
		setup_address = target_address;
		@(negedge clk_i);
		setup_enable = 1'b0;
		wait(ram_read_valid == 1'b1);
		observed_vertex = ram_read_data;
	end
	endtask

	task check_vertex;
		input target_buffer;
		input [9:0] target_address;
		input signed [31:0] expected_x;
		input signed [31:0] expected_y;
	begin
		read_vertex(target_buffer, target_address);
		if(observed_vertex !== {expected_x, expected_y}) begin
			$display("FAIL: vertex address=%0d expected=(%0d,%0d) observed=%h",
				target_address, expected_x, expected_y, observed_vertex);
			failure_count = failure_count + 1;
		end
	end
	endtask

	task run_clip;
		input source_buffer;
		input [10:0] source_count;
		input signed [31:0] test_a;
		input signed [31:0] test_b;
		input signed [65:0] test_c;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		input_buffer_i = source_buffer;
		input_vertex_count_i = source_count;
		coefficient_a_i = test_a;
		coefficient_b_i = test_b;
		constant_c_i = test_c;
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		cycle_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			cycle_count = cycle_count + 1;
			if((inject_busy_start == 1'b1) && (cycle_count == 5)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 6)) begin
				start_i = 1'b0;
			end
			if(cycle_count > 100000) begin
				$display("FAIL: polygon clip watchdog source_count=%0d", source_count);
				failure_count = failure_count + 1;
				disable run_clip;
			end
		end
		@(negedge clk_i);
		if(done_o != 1'b0) begin
			$display("FAIL: done must be a one-cycle pulse");
			failure_count = failure_count + 1;
		end
	end
	endtask

	task check_common_flags;
		input expected_trusted;
		input expected_parallel;
		input expected_capacity;
		input expected_margin;
	begin
		if(result_trusted_o !== expected_trusted) begin
			$display("FAIL: trusted expected=%0d observed=%0d", expected_trusted, result_trusted_o);
			failure_count = failure_count + 1;
		end
		if(parallel_edge_o !== expected_parallel) begin
			$display("FAIL: parallel expected=%0d observed=%0d", expected_parallel, parallel_edge_o);
			failure_count = failure_count + 1;
		end
		if(capacity_overflow_o !== expected_capacity) begin
			$display("FAIL: capacity expected=%0d observed=%0d", expected_capacity, capacity_overflow_o);
			failure_count = failure_count + 1;
		end
		if(quantization_margin_used_o !== expected_margin) begin
			$display("FAIL: margin expected=%0d observed=%0d", expected_margin, quantization_margin_used_o);
			failure_count = failure_count + 1;
		end
		if((arithmetic_saturated_o != 1'b0) || (residual_violation_o != 1'b0)) begin
			$display("FAIL: unexpected arithmetic or residual failure");
			failure_count = failure_count + 1;
		end
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		input_buffer_i = 1'b0;
		input_vertex_count_i = 11'd0;
		coefficient_a_i = 32'sd0;
		coefficient_b_i = 32'sd0;
		constant_c_i = 66'sd0;
		setup_enable = 1'b0;
		setup_write = 1'b0;
		setup_buffer = 1'b0;
		setup_address = 10'd0;
		setup_write_data = 64'd0;
		failure_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		// Square clipped by x >= 0 covers all four Sutherland-Hodgman edge states.
		write_vertex(1'b0, 10'd0, -32'sd65536, -32'sd65536);
		write_vertex(1'b0, 10'd1, 32'sd65536, -32'sd65536);
		write_vertex(1'b0, 10'd2, 32'sd65536, 32'sd65536);
		write_vertex(1'b0, 10'd3, -32'sd65536, 32'sd65536);
		run_clip(1'b0, 11'd4, 32'sh40000000, 32'sd0, 66'sd0, 1'b1);
		if((output_buffer_o != 1'b1) || (output_vertex_count_o != 11'd4) || (empty_o != 1'b0)) begin
			$display("FAIL: square clip result metadata");
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b1, 1'b0, 1'b0, 1'b0);
		check_vertex(1'b1, 10'd0, 32'sd0, -32'sd65536);
		check_vertex(1'b1, 10'd1, 32'sd65536, -32'sd65536);
		check_vertex(1'b1, 10'd2, 32'sd65536, 32'sd65536);
		check_vertex(1'b1, 10'd3, 32'sd0, 32'sd65536);

		// Preserve an all-inside polygon while switching back to buffer A.
		run_clip(1'b1, 11'd4, 32'sh40000000, 32'sd0,
			-66'sd140737488355328, 1'b0);
		if((output_buffer_o != 1'b0) || (output_vertex_count_o != 11'd4) || (empty_o != 1'b0)) begin
			$display("FAIL: all-inside result metadata");
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b1, 1'b0, 1'b0, 1'b0);

		// A boundary endpoint generated twice is filtered to one adjacent copy.
		write_vertex(1'b0, 10'd0, 32'sd0, 32'sd0);
		write_vertex(1'b0, 10'd1, -32'sd65536, 32'sd65536);
		write_vertex(1'b0, 10'd2, 32'sd65536, 32'sd65536);
		run_clip(1'b0, 11'd3, 32'sh40000000, 32'sd0, 66'sd0, 1'b0);
		if(output_vertex_count_o != 11'd3) begin
			$display("FAIL: duplicate filtering count expected=3 observed=%0d", output_vertex_count_o);
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b1, 1'b0, 1'b0, 1'b0);
		check_vertex(1'b1, 10'd0, 32'sd0, 32'sd0);
		check_vertex(1'b1, 10'd1, 32'sd0, 32'sd65536);
		check_vertex(1'b1, 10'd2, 32'sd65536, 32'sd65536);

		// Exact denominator epsilon takes the conservative near-parallel branch.
		write_vertex(1'b0, 10'd0, -32'sd1, 32'sd0);
		write_vertex(1'b0, 10'd1, -32'sd2, 32'sd0);
		run_clip(1'b0, 11'd2, 32'sh40000000, 32'sd0, 66'sd0, 1'b0);
		if(output_vertex_count_o != 11'd1) begin
			$display("FAIL: near-parallel count expected=1 observed=%0d", output_vertex_count_o);
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b0, 1'b1, 1'b0, 1'b1);
		check_vertex(1'b1, 10'd0, -32'sd1, 32'sd0);

		// All vertices outside produce an empty output.
		write_vertex(1'b0, 10'd0, -32'sd65536, -32'sd65536);
		write_vertex(1'b0, 10'd1, 32'sd65536, -32'sd65536);
		write_vertex(1'b0, 10'd2, 32'sd65536, 32'sd65536);
		write_vertex(1'b0, 10'd3, -32'sd65536, 32'sd65536);
		run_clip(1'b0, 11'd4, 32'sh40000000, 32'sd0,
			66'sd140737488355328, 1'b0);
		if((output_vertex_count_o != 11'd0) || (empty_o != 1'b1)) begin
			$display("FAIL: all-outside polygon must be empty");
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b1, 1'b0, 1'b0, 1'b0);

		// Empty input completes without RAM access.
		run_clip(1'b1, 11'd0, 32'sh40000000, 32'sd0, 66'sd0, 1'b0);
		if((output_buffer_o != 1'b0) || (output_vertex_count_o != 11'd0) || (empty_o != 1'b1)) begin
			$display("FAIL: empty input metadata");
			failure_count = failure_count + 1;
		end
		check_common_flags(1'b1, 1'b0, 1'b0, 1'b0);

		// Alternating in/out points force more than 1024 candidate writes.
		for(index = 0; index < 1024; index = index + 1) begin
			if((index & 1) == 0) begin
				write_vertex(1'b0, index[9:0], 32'sd2, index);
			end else begin
				write_vertex(1'b0, index[9:0], -32'sd2, index);
			end
		end
		run_clip(1'b0, 11'd1024, 32'sh40000000, 32'sd0, 66'sd0, 1'b0);
		if((output_vertex_count_o != 11'd1024) || (capacity_overflow_o != 1'b1) ||
			(result_trusted_o != 1'b0)) begin
			$display("FAIL: capacity boundary metadata count=%0d overflow=%0d trusted=%0d",
				output_vertex_count_o, capacity_overflow_o, result_trusted_o);
			failure_count = failure_count + 1;
		end

		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: polygon_clip_engine completed seven directed scenarios");
		end else begin
			$display("FAIL: polygon_clip_engine failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(150000) @(posedge clk_i);
		$display("FAIL: polygon_clip_engine global watchdog timeout");
		$finish;
	end

endmodule
