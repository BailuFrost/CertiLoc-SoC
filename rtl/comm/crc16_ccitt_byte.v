`timescale 1ns / 1ps

// CRC-16/CCITT-FALSE逐字节迭代引擎
module crc16_ccitt_byte
#(
	parameter C_INITIAL_VALUE = 16'hFFFF,
	parameter C_POLYNOMIAL = 16'h1021
)
(
	input i_clk,
	input i_reset,
	input i_start,
	input i_clear,
	input [7:0] i_data,
	output o_busy,
	output o_done,
	output [15:0] o_crc
);

	reg [15:0] reg_crc = C_INITIAL_VALUE;
	reg [7:0] reg_data = 0;
	reg [2:0] cnt_bit = 0;
	reg flag_busy = 0;
	reg flag_done = 0;
	wire flag_feedback;
	wire rstn_internal;
	wire busy_o;
	wire done_o;
	wire [15:0] crc_o;

	assign flag_feedback = reg_crc[15] ^ reg_data[7];
	assign rstn_internal = ~i_reset;
	assign busy_o = flag_busy;
	assign done_o = flag_done;
	assign crc_o = reg_crc;
	assign o_busy = busy_o;
	assign o_done = done_o;
	assign o_crc = crc_o;

	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_crc <= C_INITIAL_VALUE;
			reg_data <= 8'd0;
			cnt_bit <= 3'd0;
			flag_busy <= 1'b0;
			flag_done <= 1'b0;
		end else begin
			flag_done <= 1'b0;
			if((i_start == 1'b1) && (flag_busy == 1'b0))begin
				if(i_clear == 1'b1)begin
					reg_crc <= C_INITIAL_VALUE;
				end
				reg_data <= i_data;
				cnt_bit <= 3'd0;
				flag_busy <= 1'b1;
			end else if(flag_busy == 1'b1)begin
				if(flag_feedback == 1'b1)begin
					reg_crc <= {reg_crc[14:0], 1'b0} ^ C_POLYNOMIAL;
				end else begin
					reg_crc <= {reg_crc[14:0], 1'b0};
				end
				reg_data <= {reg_data[6:0], 1'b0};
				if(cnt_bit == 3'd7)begin
					cnt_bit <= 3'd0;
					flag_busy <= 1'b0;
					flag_done <= 1'b1;
				end else begin
					cnt_bit <= cnt_bit + 1'b1;
				end
			end
		end
	end

endmodule
