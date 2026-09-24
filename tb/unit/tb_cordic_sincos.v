`timescale 1ns / 1ps

module tb_cordic_sincos;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg [17:0] phase_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire signed [31:0] sine_o;
	wire signed [31:0] cosine_o;

	integer vector_file;
	integer scan_count;
	integer vector_count;
	integer failure_count;
	integer latency_count;
	integer expected_phase;
	integer expected_sine;
	integer expected_cosine;
	integer expected_residual;
	integer protocol_error_count;
	real expected_angle;
	reg [31:0] expected_sine_hex;
	reg [31:0] expected_cosine_hex;
	reg [1023:0] line_buffer;

	cordic_sincos dut
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(start_i),
		.phase_i(phase_i),
		.busy_o(busy_o),
		.done_o(done_o),
		.protocol_error_o(protocol_error_o),
		.sine_o(sine_o),
		.cosine_o(cosine_o)
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task run_vector;
		input [17:0] phase_value;
		input signed [31:0] sine_value;
		input signed [31:0] cosine_value;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		phase_i = phase_value;
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		latency_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			latency_count = latency_count + 1;
			if((inject_busy_start == 1'b1) && (latency_count == 4)) begin
				phase_i = 18'd65536;
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (latency_count == 5)) begin
				start_i = 1'b0;
			end
			if(latency_count > 24) begin
				$display("FAIL: CORDIC timeout phase=%0d", phase_value);
				failure_count = failure_count + 1;
				disable run_vector;
			end
		end
		if(latency_count != 19) begin
			$display("FAIL: latency phase=%0d expected=19 observed=%0d", phase_value, latency_count);
			failure_count = failure_count + 1;
		end
		if($signed(sine_o) !== sine_value) begin
			$display("FAIL: sine phase=%0d expected=%0d observed=%0d", phase_value, sine_value, $signed(sine_o));
			failure_count = failure_count + 1;
		end
		if($signed(cosine_o) !== cosine_value) begin
			$display("FAIL: cosine phase=%0d expected=%0d observed=%0d", phase_value, cosine_value, $signed(cosine_o));
			failure_count = failure_count + 1;
		end
		@(negedge clk_i);
		if(done_o != 1'b0) begin
			$display("FAIL: done_o must be a single-cycle pulse phase=%0d", phase_value);
			failure_count = failure_count + 1;
		end
	end
	endtask

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		phase_i = 18'd0;
		vector_count = 0;
		failure_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		vector_file = $fopen("cordic_q2_30_vectors.csv", "r");
		if(vector_file == 0) begin
			$display("FAIL: unable to open cordic_q2_30_vectors.csv");
			$finish;
		end
		scan_count = $fgets(line_buffer, vector_file);
		while(!$feof(vector_file)) begin
			scan_count = $fscanf(
				vector_file,
				"%d,%f,%d,%d,%h,%h,%d\n",
				expected_phase,
				expected_angle,
				expected_sine,
				expected_cosine,
				expected_sine_hex,
				expected_cosine_hex,
				expected_residual
			);
			if(scan_count == 7) begin
				run_vector(
					expected_phase[17:0],
					expected_sine,
					expected_cosine,
					(vector_count == 0)
				);
				vector_count = vector_count + 1;
			end
		end
		$fclose(vector_file);

		if(vector_count != 74) begin
			$display("FAIL: expected 74 vectors observed=%0d", vector_count);
			failure_count = failure_count + 1;
		end
		if(protocol_error_count != 1) begin
			$display("FAIL: busy-start error pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: cordic_sincos matched %0d bit-exact vectors", vector_count);
		end else begin
			$display("FAIL: cordic_sincos failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(3000) @(posedge clk_i);
		$display("FAIL: cordic_sincos watchdog timeout");
		$finish;
	end

endmodule
