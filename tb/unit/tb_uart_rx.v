`timescale 1ns / 1ps

// T04 UART接收器自检平台
module tb_uart_rx;

	localparam C_CLKS_PER_BIT = 868;
	localparam C_HALF_BIT_CLKS = 434;
	localparam C_CLOCK_PERIOD_NS = 10;

	reg i_clk;
	reg i_reset;
	reg i_uart_rx;
	reg i_data_ready;
	wire [7:0] o_data;
	wire o_data_valid;
	wire o_frame_error;
	wire o_busy;
	integer int_error_count;
	integer int_frame_error_count;
	integer int_bit_index;

	uart_rx
	#(
		.C_CLKS_PER_BIT(C_CLKS_PER_BIT),
		.C_HALF_BIT_CLKS(C_HALF_BIT_CLKS)
	)
	uart_rx_Inst
	(
		.i_clk(i_clk),
		.i_reset(i_reset),
		.i_uart_rx(i_uart_rx),
		.i_data_ready(i_data_ready),
		.o_data(o_data),
		.o_data_valid(o_data_valid),
		.o_frame_error(o_frame_error),
		.o_busy(o_busy)
	);

	always #(C_CLOCK_PERIOD_NS / 2) i_clk = ~i_clk;

	always@(posedge i_clk)begin
		if(o_frame_error == 1'b1)begin
			int_frame_error_count = int_frame_error_count + 1;
		end
	end

	task apply_reset;
	begin
		i_reset = 1'b1;
		i_uart_rx = 1'b1;
		i_data_ready = 1'b1;
		repeat(4) @(posedge i_clk);
		@(negedge i_clk);
		i_reset = 1'b0;
	end
	endtask

	task drive_serial_bit;
		input bit_value;
		input integer bit_clocks;
	begin
		i_uart_rx = bit_value;
		repeat(bit_clocks) @(posedge i_clk);
	end
	endtask

	task send_frame;
		input [7:0] data_value;
		input integer bit_clocks;
		input stop_value;
	begin
		@(negedge i_clk);
		drive_serial_bit(1'b0, bit_clocks);
		for(int_bit_index = 0; int_bit_index < 8; int_bit_index = int_bit_index + 1)begin
			drive_serial_bit(data_value[int_bit_index], bit_clocks);
		end
		drive_serial_bit(stop_value, bit_clocks);
		i_uart_rx = 1'b1;
	end
	endtask

	task expect_byte;
		input [7:0] expected_data;
	begin
		wait(o_data_valid == 1'b1);
		if(o_data !== expected_data)begin
			$display("FAIL: RX expected %02x, observed %02x", expected_data, o_data);
			int_error_count = int_error_count + 1;
		end
		@(posedge i_clk);
	end
	endtask

	initial begin
		i_clk = 1'b0;
		i_reset = 1'b0;
		i_uart_rx = 1'b1;
		i_data_ready = 1'b1;
		int_error_count = 0;
		int_frame_error_count = 0;
		apply_reset;

		fork
			send_frame(8'hA5, C_CLKS_PER_BIT, 1'b1);
			expect_byte(8'hA5);
		join

		fork
			send_frame(8'h96, 851, 1'b1);
			expect_byte(8'h96);
		join

		fork
			send_frame(8'h69, 885, 1'b1);
			expect_byte(8'h69);
		join

		i_data_ready = 1'b0;
		fork
			send_frame(8'h3C, C_CLKS_PER_BIT, 1'b1);
			expect_byte(8'h3C);
		join
		repeat(20) @(posedge i_clk);
		if((o_data_valid !== 1'b1) || (o_data !== 8'h3C))begin
			$display("FAIL: RX output changed while backpressured");
			int_error_count = int_error_count + 1;
		end
		i_data_ready = 1'b1;
		@(posedge i_clk);

		send_frame(8'h5A, C_CLKS_PER_BIT, 1'b0);
		repeat(4) @(posedge i_clk);
		if(int_frame_error_count != 1)begin
			$display("FAIL: RX frame error pulse count is %0d", int_frame_error_count);
			int_error_count = int_error_count + 1;
		end
		if(o_data_valid == 1'b1)begin
			$display("FAIL: RX accepted a byte with an invalid stop bit");
			int_error_count = int_error_count + 1;
		end

		@(negedge i_clk);
		i_uart_rx = 1'b0;
		repeat(100) @(posedge i_clk);
		i_uart_rx = 1'b1;
		repeat(C_CLKS_PER_BIT) @(posedge i_clk);
		if(o_data_valid == 1'b1)begin
			$display("FAIL: RX accepted a false start pulse");
			int_error_count = int_error_count + 1;
		end

		if(int_error_count == 0)begin
			$display("PASS: uart_rx directed checks completed");
		end else begin
			$display("FAIL: uart_rx reported %0d mismatches", int_error_count);
			$finish;
		end
		$finish;
	end

	initial begin
		repeat(100000) @(posedge i_clk);
		$display("FAIL: uart_rx watchdog timeout");
		$finish;
	end

endmodule
