`timescale 1ns / 1ps

module tb_bearing_constraint_gen;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg signed [31:0] sensor_x_i;
	reg signed [31:0] sensor_y_i;
	reg [17:0] bearing_phase_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire constraint_valid_o;
	wire constraint_upper_o;
	wire signed [31:0] coefficient_a_o;
	wire signed [31:0] coefficient_b_o;
	wire signed [65:0] constant_c_o;

	integer vector_file;
	integer scan_count;
	integer vector_count;
	integer failure_count;
	integer cycle_count;
	integer valid_count;
	integer protocol_error_count;
	integer expected_phase;
	reg [31:0] expected_x;
	reg [31:0] expected_y;
	reg [31:0] expected_lower_a;
	reg [31:0] expected_lower_b;
	reg [65:0] expected_lower_c;
	reg [31:0] expected_upper_a;
	reg [31:0] expected_upper_b;
	reg [65:0] expected_upper_c;
	reg [1023:0] line_buffer;

	bearing_constraint_gen dut
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(start_i),
		.sensor_x_i(sensor_x_i),
		.sensor_y_i(sensor_y_i),
		.bearing_phase_i(bearing_phase_i),
		.busy_o(busy_o),
		.done_o(done_o),
		.protocol_error_o(protocol_error_o),
		.constraint_valid_o(constraint_valid_o),
		.constraint_upper_o(constraint_upper_o),
		.coefficient_a_o(coefficient_a_o),
		.coefficient_b_o(coefficient_b_o),
		.constant_c_o(constant_c_o)
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task check_constraint;
		input expected_upper;
		input [31:0] expected_a;
		input [31:0] expected_b;
		input [65:0] expected_c;
	begin
		if(constraint_upper_o !== expected_upper) begin
			$display("FAIL: boundary tag vector=%0d expected=%0d observed=%0d", vector_count, expected_upper, constraint_upper_o);
			failure_count = failure_count + 1;
		end
		if(coefficient_a_o !== expected_a) begin
			$display("FAIL: coefficient a vector=%0d expected=%h observed=%h", vector_count, expected_a, coefficient_a_o);
			failure_count = failure_count + 1;
		end
		if(coefficient_b_o !== expected_b) begin
			$display("FAIL: coefficient b vector=%0d expected=%h observed=%h", vector_count, expected_b, coefficient_b_o);
			failure_count = failure_count + 1;
		end
		if(constant_c_o !== expected_c) begin
			$display("FAIL: constant c vector=%0d expected=%h observed=%h", vector_count, expected_c, constant_c_o);
			failure_count = failure_count + 1;
		end
	end
	endtask

	task run_vector;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		sensor_x_i = expected_x;
		sensor_y_i = expected_y;
		bearing_phase_i = expected_phase[17:0];
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		cycle_count = 0;
		valid_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			cycle_count = cycle_count + 1;
			if((inject_busy_start == 1'b1) && (cycle_count == 4)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 5)) begin
				start_i = 1'b0;
			end
			if(constraint_valid_o == 1'b1) begin
				valid_count = valid_count + 1;
				if(valid_count == 1) begin
					if(cycle_count != 25) begin
						$display("FAIL: lower latency vector=%0d expected=25 observed=%0d", vector_count, cycle_count);
						failure_count = failure_count + 1;
					end
					check_constraint(1'b0, expected_lower_a, expected_lower_b, expected_lower_c);
				end else begin
					check_constraint(1'b1, expected_upper_a, expected_upper_b, expected_upper_c);
				end
			end
			if(cycle_count > 55) begin
				$display("FAIL: constraint generator timeout vector=%0d", vector_count);
				failure_count = failure_count + 1;
				disable run_vector;
			end
		end
		if(cycle_count != 45) begin
			$display("FAIL: completion latency vector=%0d expected=45 observed=%0d", vector_count, cycle_count);
			failure_count = failure_count + 1;
		end
		if(valid_count != 2) begin
			$display("FAIL: constraint pulse count vector=%0d expected=2 observed=%0d", vector_count, valid_count);
			failure_count = failure_count + 1;
		end
		@(negedge clk_i);
		if((done_o != 1'b0) || (constraint_valid_o != 1'b0)) begin
			$display("FAIL: output pulses must be one cycle vector=%0d", vector_count);
			failure_count = failure_count + 1;
		end
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		sensor_x_i = 32'sd0;
		sensor_y_i = 32'sd0;
		bearing_phase_i = 18'd0;
		vector_count = 0;
		failure_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		vector_file = $fopen("bearing_constraint_vectors.csv", "r");
		if(vector_file == 0) begin
			$display("FAIL: unable to open bearing_constraint_vectors.csv");
			$finish;
		end
		scan_count = $fgets(line_buffer, vector_file);
		while(!$feof(vector_file)) begin
			scan_count = $fscanf(
				vector_file,
				"%h,%h,%d,%h,%h,%h,%h,%h,%h\n",
				expected_x,
				expected_y,
				expected_phase,
				expected_lower_a,
				expected_lower_b,
				expected_lower_c,
				expected_upper_a,
				expected_upper_b,
				expected_upper_c
			);
			if(scan_count == 9) begin
				run_vector(vector_count == 0);
				vector_count = vector_count + 1;
			end
		end
		$fclose(vector_file);

		if(vector_count != 10) begin
			$display("FAIL: expected 10 vectors observed=%0d", vector_count);
			failure_count = failure_count + 1;
		end
		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: bearing_constraint_gen matched %0d bit-exact observations", vector_count);
		end else begin
			$display("FAIL: bearing_constraint_gen failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(10000) @(posedge clk_i);
		$display("FAIL: bearing_constraint_gen watchdog timeout");
		$finish;
	end

endmodule
