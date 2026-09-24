`timescale 1ns / 1ps

module tb_segment_intersection;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg signed [31:0] start_x_i;
	reg signed [31:0] start_y_i;
	reg signed [31:0] end_x_i;
	reg signed [31:0] end_y_i;
	reg signed [65:0] start_value_i;
	reg signed [65:0] end_value_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire intersection_valid_o;
	wire parallel_o;
	wire arithmetic_saturated_o;
	wire [30:0] ratio_q2_30_o;
	wire signed [31:0] intersection_x_o;
	wire signed [31:0] intersection_y_o;

	integer failure_count;
	integer vector_count;
	integer protocol_error_count;
	integer cycle_count;

	segment_intersection dut
	(
		.clk_i(clk_i), .reset_i(reset_i), .start_i(start_i),
		.start_x_i(start_x_i), .start_y_i(start_y_i),
		.end_x_i(end_x_i), .end_y_i(end_y_i),
		.start_value_i(start_value_i), .end_value_i(end_value_i),
		.busy_o(busy_o), .done_o(done_o), .protocol_error_o(protocol_error_o),
		.intersection_valid_o(intersection_valid_o), .parallel_o(parallel_o),
		.arithmetic_saturated_o(arithmetic_saturated_o),
		.ratio_q2_30_o(ratio_q2_30_o),
		.intersection_x_o(intersection_x_o), .intersection_y_o(intersection_y_o)
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task run_vector;
		input signed [31:0] test_start_x;
		input signed [31:0] test_start_y;
		input signed [31:0] test_end_x;
		input signed [31:0] test_end_y;
		input signed [65:0] test_start_value;
		input signed [65:0] test_end_value;
		input expected_valid;
		input expected_parallel;
		input [30:0] expected_ratio;
		input signed [31:0] expected_x;
		input signed [31:0] expected_y;
		input integer expected_latency;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		start_x_i = test_start_x;
		start_y_i = test_start_y;
		end_x_i = test_end_x;
		end_y_i = test_end_y;
		start_value_i = test_start_value;
		end_value_i = test_end_value;
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		cycle_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			cycle_count = cycle_count + 1;
			if((inject_busy_start == 1'b1) && (cycle_count == 3)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 4)) begin
				start_i = 1'b0;
			end
			if(cycle_count > 45) begin
				$display("FAIL: segment intersection timeout vector=%0d", vector_count);
				failure_count = failure_count + 1;
				disable run_vector;
			end
		end
		if(cycle_count != expected_latency) begin
			$display("FAIL: intersection latency vector=%0d expected=%0d observed=%0d", vector_count, expected_latency, cycle_count);
			failure_count = failure_count + 1;
		end
		if(intersection_valid_o !== expected_valid) begin
			$display("FAIL: valid vector=%0d expected=%0d observed=%0d", vector_count, expected_valid, intersection_valid_o);
			failure_count = failure_count + 1;
		end
		if(parallel_o !== expected_parallel) begin
			$display("FAIL: parallel vector=%0d expected=%0d observed=%0d", vector_count, expected_parallel, parallel_o);
			failure_count = failure_count + 1;
		end
		if(expected_valid == 1'b1) begin
			if(ratio_q2_30_o !== expected_ratio) begin
				$display("FAIL: ratio vector=%0d expected=%0d observed=%0d", vector_count, expected_ratio, ratio_q2_30_o);
				failure_count = failure_count + 1;
			end
			if((intersection_x_o !== expected_x) || (intersection_y_o !== expected_y)) begin
				$display("FAIL: point vector=%0d expected=(%0d,%0d) observed=(%0d,%0d)", vector_count, expected_x, expected_y, intersection_x_o, intersection_y_o);
				failure_count = failure_count + 1;
			end
			if(arithmetic_saturated_o !== 1'b0) begin
				$display("FAIL: unexpected saturation vector=%0d", vector_count);
				failure_count = failure_count + 1;
			end
		end
		@(negedge clk_i);
		if((done_o != 1'b0) || (intersection_valid_o != 1'b0) || (parallel_o != 1'b0)) begin
			$display("FAIL: status outputs must be one-cycle pulses vector=%0d", vector_count);
			failure_count = failure_count + 1;
		end
		vector_count = vector_count + 1;
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		start_x_i = 32'sd0;
		start_y_i = 32'sd0;
		end_x_i = 32'sd0;
		end_y_i = 32'sd0;
		start_value_i = 66'sd0;
		end_value_i = 66'sd0;
		failure_count = 0;
		vector_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		run_vector(-32'sd65536, -32'sd65536, 32'sd65536, 32'sd65536,
			-66'sd70368744177664, 66'sd70368744177664,
			1'b1, 1'b0, 31'd536870912, 32'sd0, 32'sd0, 37, 1'b1);
		run_vector(32'sd0, 32'sd0, 32'sd196608, 32'sd131072,
			66'sd2199023255552, -66'sd4398046511104,
			1'b1, 1'b0, 31'd357913941, 32'sd65536, 32'sd43691, 37, 1'b0);
		run_vector(32'sd0, 32'sd0, 32'sd196608, -32'sd196608,
			66'sd4398046511104, -66'sd2199023255552,
			1'b1, 1'b0, 31'd715827883, 32'sd131072, -32'sd131072, 37, 1'b0);
		run_vector(32'sd12345, -32'sd54321, 32'sd100000, 32'sd200000,
			66'sd0, -66'sd3298534883328,
			1'b1, 1'b0, 31'd0, 32'sd12345, -32'sd54321, 6, 1'b0);
		run_vector(32'sd0, 32'sd0, 32'sd65536, 32'sd65536,
			66'sd536870913, -66'sd536870912,
			1'b1, 1'b0, 31'd536870912, 32'sd32768, 32'sd32768, 37, 1'b0);
		run_vector(32'sd111, 32'sd222, 32'sd333, 32'sd444,
			66'sd536870912, -66'sd536870912,
			1'b0, 1'b1, 31'd0, 32'sd0, 32'sd0, 2, 1'b0);

		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: segment_intersection matched %0d directed vectors", vector_count);
		end else begin
			$display("FAIL: segment_intersection failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(2000) @(posedge clk_i);
		$display("FAIL: segment_intersection watchdog timeout");
		$finish;
	end
endmodule
