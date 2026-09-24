`timescale 1ns / 1ps

module tb_polygon_diameter_engine;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg vertex_buffer_i;
	reg [10:0] vertex_count_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire empty_o;
	wire result_trusted_o;
	wire arithmetic_saturated_o;
	wire input_count_error_o;
	wire [65:0] maximum_distance_squared_o;
	wire [9:0] farthest_first_index_o;
	wire [9:0] farthest_second_index_o;
	wire [19:0] evaluated_pair_count_o;
	wire first_read_enable;
	wire first_read_buffer;
	wire [9:0] first_read_address;
	wire [63:0] first_read_data;
	wire first_read_valid;
	wire second_read_enable;
	wire second_read_buffer;
	wire [9:0] second_read_address;
	wire [63:0] second_read_data;
	wire second_read_valid;
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
	integer vertex_index;

	assign port_0_enable = busy_o ? first_read_enable : setup_enable;
	assign port_0_write = busy_o ? 1'b0 : setup_write;
	assign port_0_buffer = busy_o ? first_read_buffer : setup_buffer;
	assign port_0_address = busy_o ? first_read_address : setup_address;
	assign port_0_write_data = setup_write_data;

	polygon_diameter_engine dut
	(
		.clk_i(clk_i), .reset_i(reset_i), .start_i(start_i),
		.vertex_buffer_i(vertex_buffer_i), .vertex_count_i(vertex_count_i),
		.busy_o(busy_o), .done_o(done_o), .protocol_error_o(protocol_error_o),
		.empty_o(empty_o), .result_trusted_o(result_trusted_o),
		.arithmetic_saturated_o(arithmetic_saturated_o),
		.input_count_error_o(input_count_error_o),
		.maximum_distance_squared_o(maximum_distance_squared_o),
		.farthest_first_index_o(farthest_first_index_o),
		.farthest_second_index_o(farthest_second_index_o),
		.evaluated_pair_count_o(evaluated_pair_count_o),
		.ram_first_read_enable_o(first_read_enable),
		.ram_first_read_buffer_o(first_read_buffer),
		.ram_first_read_address_o(first_read_address),
		.ram_first_read_data_i(first_read_data),
		.ram_first_read_valid_i(first_read_valid),
		.ram_second_read_enable_o(second_read_enable),
		.ram_second_read_buffer_o(second_read_buffer),
		.ram_second_read_address_o(second_read_address),
		.ram_second_read_data_i(second_read_data),
		.ram_second_read_valid_i(second_read_valid)
	);

	vertex_ram_dual_buffer vertex_memory
	(
		.clk_i(clk_i), .reset_i(reset_i),
		.port_0_enable_i(port_0_enable), .port_0_write_i(port_0_write),
		.port_0_buffer_i(port_0_buffer), .port_0_address_i(port_0_address),
		.port_0_write_data_i(port_0_write_data), .port_0_read_data_o(first_read_data),
		.port_0_read_valid_o(first_read_valid),
		.port_1_enable_i(second_read_enable), .port_1_write_i(1'b0),
		.port_1_buffer_i(second_read_buffer), .port_1_address_i(second_read_address),
		.port_1_write_data_i(64'd0), .port_1_read_data_o(second_read_data),
		.port_1_read_valid_o(second_read_valid)
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

	task run_case;
		input test_buffer;
		input [10:0] test_count;
		input [65:0] expected_distance;
		input [9:0] expected_first;
		input [9:0] expected_second;
		input [19:0] expected_pairs;
		input expected_empty;
		input expected_trusted;
		input expected_count_error;
		input inject_busy_start;
		integer expected_latency;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		vertex_buffer_i = test_buffer;
		vertex_count_i = test_count;
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		cycle_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			cycle_count = cycle_count + 1;
			if((inject_busy_start == 1'b1) && (cycle_count == 4)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 5)) begin
				start_i = 1'b0;
			end
			if(cycle_count > 300000) begin
				$display("FAIL: diameter engine timeout count=%0d", test_count);
				failure_count = failure_count + 1;
				disable run_case;
			end
		end
		if(test_count < 11'd2 || test_count > 11'd1024) begin
			expected_latency = 1;
		end else begin
			expected_latency = expected_pairs + 4;
		end
		if(cycle_count != expected_latency) begin
			$display("FAIL: latency count=%0d expected=%0d observed=%0d",
				test_count, expected_latency, cycle_count);
			failure_count = failure_count + 1;
		end
		if(maximum_distance_squared_o !== expected_distance) begin
			$display("FAIL: distance count=%0d expected=%0d observed=%0d",
				test_count, expected_distance, maximum_distance_squared_o);
			failure_count = failure_count + 1;
		end
		if((farthest_first_index_o !== expected_first) ||
			(farthest_second_index_o !== expected_second)) begin
			$display("FAIL: indices count=%0d expected=(%0d,%0d) observed=(%0d,%0d)",
				test_count, expected_first, expected_second,
				farthest_first_index_o, farthest_second_index_o);
			failure_count = failure_count + 1;
		end
		if(evaluated_pair_count_o !== expected_pairs) begin
			$display("FAIL: pair count expected=%0d observed=%0d",
				expected_pairs, evaluated_pair_count_o);
			failure_count = failure_count + 1;
		end
		if((empty_o !== expected_empty) || (result_trusted_o !== expected_trusted) ||
			(input_count_error_o !== expected_count_error)) begin
			$display("FAIL: status count=%0d empty=%0d trusted=%0d count_error=%0d",
				test_count, empty_o, result_trusted_o, input_count_error_o);
			failure_count = failure_count + 1;
		end
		if(arithmetic_saturated_o !== 1'b0) begin
			$display("FAIL: unexpected distance saturation count=%0d", test_count);
			failure_count = failure_count + 1;
		end
		@(negedge clk_i);
		if(done_o != 1'b0) begin
			$display("FAIL: done must be a one-cycle pulse count=%0d", test_count);
			failure_count = failure_count + 1;
		end
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		vertex_buffer_i = 1'b0;
		vertex_count_i = 11'd0;
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

		run_case(1'b0, 11'd0, 66'd0, 10'd0, 10'd0, 20'd0,
			1'b1, 1'b1, 1'b0, 1'b0);

		write_vertex(1'b0, 10'd0, -32'sd65536, 32'sd131072);
		run_case(1'b0, 11'd1, 66'd0, 10'd0, 10'd0, 20'd0,
			1'b0, 1'b1, 1'b0, 1'b0);

		write_vertex(1'b0, 10'd0, 32'sd0, 32'sd0);
		write_vertex(1'b0, 10'd1, 32'sd196608, 32'sd262144);
		run_case(1'b0, 11'd2, 66'd107374182400, 10'd0, 10'd1, 20'd1,
			1'b0, 1'b1, 1'b0, 1'b0);

		// Rectangle has two equal diagonals; strict greater-than keeps pair (0,2).
		write_vertex(1'b1, 10'd0, -32'sd65536, -32'sd131072);
		write_vertex(1'b1, 10'd1, 32'sd196608, -32'sd131072);
		write_vertex(1'b1, 10'd2, 32'sd196608, 32'sd65536);
		write_vertex(1'b1, 10'd3, -32'sd65536, 32'sd65536);
		run_case(1'b1, 11'd4, 66'd107374182400, 10'd0, 10'd2, 20'd6,
			1'b0, 1'b1, 1'b0, 1'b1);

		// Five signed-coordinate vertices exercise the complete pair traversal order.
		write_vertex(1'b0, 10'd0, -32'sd196608, 32'sd65536);
		write_vertex(1'b0, 10'd1, 32'sd131072, -32'sd262144);
		write_vertex(1'b0, 10'd2, 32'sd393216, 32'sd0);
		write_vertex(1'b0, 10'd3, 32'sd65536, 32'sd458752);
		write_vertex(1'b0, 10'd4, -32'sd327680, 32'sd327680);
		run_case(1'b0, 11'd5, 66'd627065225216, 10'd2, 10'd4, 20'd10,
			1'b0, 1'b1, 1'b0, 1'b0);

		// Equal points verify that the first lexicographic pair wins a zero tie.
		write_vertex(1'b1, 10'd0, -32'sd77, 32'sd55);
		write_vertex(1'b1, 10'd1, -32'sd77, 32'sd55);
		write_vertex(1'b1, 10'd2, -32'sd77, 32'sd55);
		run_case(1'b1, 11'd3, 66'd0, 10'd0, 10'd1, 20'd3,
			1'b0, 1'b1, 1'b0, 1'b0);

		// Full signed coordinate span proves the 66-bit output range without saturation.
		write_vertex(1'b0, 10'd0, 32'sh80000000, 32'sh80000000);
		write_vertex(1'b0, 10'd1, 32'sh7FFFFFFF, 32'sh7FFFFFFF);
		run_case(1'b0, 11'd2, 66'd36893488130239234050, 10'd0, 10'd1, 20'd1,
			1'b0, 1'b1, 1'b0, 1'b0);

		// Counts beyond the physical RAM capacity fail before any read request.
		run_case(1'b0, 11'd1025, 66'd0, 10'd0, 10'd1, 20'd0,
			1'b0, 1'b0, 1'b1, 1'b0);

		// The stage-one 720-vertex baseline verifies sustained one-pair-per-clock issue.
		for(vertex_index = 0; vertex_index < 720; vertex_index = vertex_index + 1) begin
			write_vertex(1'b1, vertex_index[9:0], 32'sd0, 32'sd0);
		end
		run_case(1'b1, 11'd720, 66'd0, 10'd0, 10'd1, 20'd258840,
			1'b0, 1'b1, 1'b0, 1'b0);

		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: polygon_diameter_engine completed nine directed scenarios");
		end else begin
			$display("FAIL: polygon_diameter_engine failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(400000) @(posedge clk_i);
		$display("FAIL: polygon_diameter_engine global watchdog timeout");
		$finish;
	end

endmodule
