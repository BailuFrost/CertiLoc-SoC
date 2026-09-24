`timescale 1ns / 1ps

// T04 UART发送器自检平台
module tb_uart_tx;

	localparam C_CLKS_PER_BIT = 868;
	localparam C_HALF_BIT_CLKS = 434;
	localparam C_CLOCK_PERIOD_NS = 10;

	reg i_clk;
	reg i_reset;
	reg [7:0] i_data;
	reg i_data_valid;
	wire o_data_ready;
	wire o_uart_tx;
	wire o_busy;
	integer int_error_count;
	integer int_bit_index;
	reg [7:0] reg_expected_data;

	uart_tx
	#(
		.C_CLKS_PER_BIT(C_CLKS_PER_BIT)
	)
	uart_tx_Inst
	(
		.i_clk(i_clk),
		.i_reset(i_reset),
		.i_data(i_data),
		.i_data_valid(i_data_valid),
		.o_data_ready(o_data_ready),
		.o_uart_tx(o_uart_tx),
		.o_busy(o_busy)
	);

	always #(C_CLOCK_PERIOD_NS / 2) i_clk = ~i_clk;

	task apply_reset;
	begin
		i_reset = 1'b1;
		i_data_valid = 1'b0;
		i_data = 8'd0;
		repeat(4) @(posedge i_clk);
		@(negedge i_clk);
		i_reset = 1'b0;
	end
	endtask

	task send_and_check;
		input [7:0] data_value;
	begin
		wait(o_data_ready == 1'b1);
		@(negedge i_clk);
		i_data = data_value;
		i_data_valid = 1'b1;
		@(negedge i_clk);
		i_data_valid = 1'b0;
		reg_expected_data = data_value;

		repeat(C_HALF_BIT_CLKS) @(posedge i_clk);
		if(o_uart_tx !== 1'b0)begin
			$display("FAIL: TX start bit is not low");
			int_error_count = int_error_count + 1;
		end

		for(int_bit_index = 0; int_bit_index < 8; int_bit_index = int_bit_index + 1)begin
			repeat(C_CLKS_PER_BIT) @(posedge i_clk);
			if(o_uart_tx !== reg_expected_data[int_bit_index])begin
				$display("FAIL: TX data bit %0d mismatch", int_bit_index);
				int_error_count = int_error_count + 1;
			end
		end

		repeat(C_CLKS_PER_BIT) @(posedge i_clk);
		if(o_uart_tx !== 1'b1)begin
			$display("FAIL: TX stop bit is not high");
			int_error_count = int_error_count + 1;
		end
		wait(o_busy == 1'b0);
	end
	endtask

	initial begin
		i_clk = 1'b0;
		i_reset = 1'b0;
		i_data = 8'd0;
		i_data_valid = 1'b0;
		int_error_count = 0;
		reg_expected_data = 8'd0;
		apply_reset;

		if((o_uart_tx !== 1'b1) || (o_data_ready !== 1'b1))begin
			$display("FAIL: TX reset outputs are invalid");
			int_error_count = int_error_count + 1;
		end

		send_and_check(8'h00);
		send_and_check(8'hFF);
		send_and_check(8'hA5);
		send_and_check(8'h3C);

		if(int_error_count == 0)begin
			$display("PASS: uart_tx directed checks completed");
		end else begin
			$display("FAIL: uart_tx reported %0d mismatches", int_error_count);
			$finish;
		end
		$finish;
	end

	initial begin
		repeat(50000) @(posedge i_clk);
		$display("FAIL: uart_tx watchdog timeout");
		$finish;
	end

endmodule
