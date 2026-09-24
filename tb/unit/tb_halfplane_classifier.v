`timescale 1ns / 1ps

module tb_halfplane_classifier;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg signed [31:0] point_x_i;
	reg signed [31:0] point_y_i;
	reg signed [31:0] coefficient_a_i;
	reg signed [31:0] coefficient_b_i;
	reg signed [65:0] constant_c_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire signed [65:0] function_value_o;
	wire inside_o;
	wire margin_used_o;
	wire arithmetic_saturated_o;

	integer failure_count;
	integer vector_count;
	integer protocol_error_count;
	integer cycle_count;

	halfplane_classifier dut
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(start_i),
		.point_x_i(point_x_i),
		.point_y_i(point_y_i),
		.coefficient_a_i(coefficient_a_i),
		.coefficient_b_i(coefficient_b_i),
		.constant_c_i(constant_c_i),
		.busy_o(busy_o),
		.done_o(done_o),
		.protocol_error_o(protocol_error_o),
		.function_value_o(function_value_o),
		.inside_o(inside_o),
		.margin_used_o(margin_used_o),
		.arithmetic_saturated_o(arithmetic_saturated_o)
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task run_vector;
		input signed [31:0] test_x;
		input signed [31:0] test_y;
		input signed [31:0] test_a;
		input signed [31:0] test_b;
		input signed [65:0] test_c;
		input signed [65:0] expected_f;
		input expected_inside;
		input expected_margin;
		input expected_saturation;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		point_x_i = test_x;
		point_y_i = test_y;
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
			if((inject_busy_start == 1'b1) && (cycle_count == 1)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 2)) begin
				start_i = 1'b0;
			end
			if(cycle_count > 8) begin
				$display("FAIL: halfplane classifier timeout vector=%0d", vector_count);
				failure_count = failure_count + 1;
				disable run_vector;
			end
		end
		if(cycle_count != 4) begin
			$display("FAIL: classifier latency vector=%0d expected=4 observed=%0d", vector_count, cycle_count);
			failure_count = failure_count + 1;
		end
		if(function_value_o !== expected_f) begin
			$display("FAIL: function value vector=%0d expected=%0d observed=%0d", vector_count, expected_f, function_value_o);
			failure_count = failure_count + 1;
		end
		if(inside_o !== expected_inside) begin
			$display("FAIL: inside vector=%0d expected=%0d observed=%0d", vector_count, expected_inside, inside_o);
			failure_count = failure_count + 1;
		end
		if(margin_used_o !== expected_margin) begin
			$display("FAIL: margin vector=%0d expected=%0d observed=%0d", vector_count, expected_margin, margin_used_o);
			failure_count = failure_count + 1;
		end
		if(arithmetic_saturated_o !== expected_saturation) begin
			$display("FAIL: saturation vector=%0d expected=%0d observed=%0d", vector_count, expected_saturation, arithmetic_saturated_o);
			failure_count = failure_count + 1;
		end
		@(negedge clk_i);
		if(done_o != 1'b0) begin
			$display("FAIL: done must be a one-cycle pulse vector=%0d", vector_count);
			failure_count = failure_count + 1;
		end
		vector_count = vector_count + 1;
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		point_x_i = 32'sd0;
		point_y_i = 32'sd0;
		coefficient_a_i = 32'sd0;
		coefficient_b_i = 32'sd0;
		constant_c_i = 66'sd0;
		failure_count = 0;
		vector_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		// a=1.0 in Q2.30 and one coordinate LSB produces one Q46 LSB group.
		run_vector(32'sd1, 32'sd0, 32'sh40000000, 32'sd0, 66'sd0,
			66'sd1073741824, 1'b1, 1'b0, 1'b0, 1'b1);
		run_vector(32'sd0, 32'sd0, 32'sh40000000, 32'sd0, 66'sd0,
			66'sd0, 1'b1, 1'b0, 1'b0, 1'b0);
		run_vector(-32'sd1, 32'sd0, 32'sh40000000, 32'sd0, 66'sd0,
			-66'sd1073741824, 1'b1, 1'b1, 1'b0, 1'b0);
		run_vector(-32'sd2, 32'sd0, 32'sh40000000, 32'sd0, 66'sd0,
			-66'sd2147483648, 1'b0, 1'b0, 1'b0, 1'b0);
		run_vector(32'sd65536, -32'sd32768, 32'sh20000000, 32'shC0000000,
			66'sd70368744177664, 66'sd0, 1'b1, 1'b0, 1'b0, 1'b0);
		run_vector(32'sh7FFFFFFF, 32'sh7FFFFFFF, 32'sh7FFFFFFF, 32'sh7FFFFFFF,
			66'sh20000000000000000, 66'sh1FFFFFFFFFFFFFFFF,
			1'b1, 1'b0, 1'b1, 1'b0);

		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: halfplane_classifier matched %0d directed vectors", vector_count);
		end else begin
			$display("FAIL: halfplane_classifier failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(500) @(posedge clk_i);
		$display("FAIL: halfplane_classifier watchdog timeout");
		$finish;
	end
endmodule
