`timescale 1ns / 1ps

module tb_crc16_ccitt_byte;
	reg i_clk;
	reg i_reset;
	reg i_start;
	reg i_clear;
	reg [7:0] i_data;
	wire o_busy;
	wire o_done;
	wire [15:0] o_crc;
	integer int_index;
	reg [7:0] reg_vector [0:8];

	crc16_ccitt_byte dut
	(
		.i_clk(i_clk), .i_reset(i_reset), .i_start(i_start), .i_clear(i_clear),
		.i_data(i_data), .o_busy(o_busy), .o_done(o_done), .o_crc(o_crc)
	);

	always #5 i_clk = ~i_clk;

	task send_byte;
		input [7:0] data_value;
		input clear_value;
	begin
		wait(o_busy == 1'b0);
		@(negedge i_clk);
		i_data = data_value;
		i_clear = clear_value;
		i_start = 1'b1;
		@(negedge i_clk);
		i_start = 1'b0;
		i_clear = 1'b0;
		wait(o_done == 1'b1);
	end
	endtask

	initial begin
		i_clk = 1'b0;
		i_reset = 1'b1;
		i_start = 1'b0;
		i_clear = 1'b0;
		i_data = 8'd0;
		reg_vector[0] = "1"; reg_vector[1] = "2"; reg_vector[2] = "3";
		reg_vector[3] = "4"; reg_vector[4] = "5"; reg_vector[5] = "6";
		reg_vector[6] = "7"; reg_vector[7] = "8"; reg_vector[8] = "9";
		repeat(4) @(posedge i_clk);
		@(negedge i_clk);
		i_reset = 1'b0;
		for(int_index = 0; int_index < 9; int_index = int_index + 1)begin
			send_byte(reg_vector[int_index], int_index == 0);
		end
		if(o_crc !== 16'h29B1)begin
			$display("FAIL: crc expected 29B1 observed %04x", o_crc);
		end else begin
			$display("PASS: crc16_ccitt_byte standard vector completed");
		end
		$finish;
	end

	initial begin
		repeat(500) @(posedge i_clk);
		$display("FAIL: crc watchdog timeout");
		$finish;
	end
endmodule
