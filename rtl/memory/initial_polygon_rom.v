`timescale 1ns / 1ps

// 720个逆时针Q16.16初始多边形顶点同步只读存储器
module initial_polygon_rom
#(
	parameter C_INIT_FILE = "initial_polygon_720_q16_16.mem"
)
(
	input wire clk_i,
	input wire read_enable_i,
	input wire [9:0] read_address_i,
	output wire [63:0] read_data_o,
	output wire read_valid_o
);

	reg [63:0] vertex_memory [0:719];
	reg [63:0] read_data_result;
	reg read_valid_result;

	assign read_data_o = read_data_result;
	assign read_valid_o = read_valid_result;

	initial begin
		$readmemh(C_INIT_FILE, vertex_memory);
	end

	always @(posedge clk_i) begin
		read_valid_result <= 1'b0;
		if(read_enable_i == 1'b1) begin
			if(read_address_i < 10'd720) begin
				read_data_result <= vertex_memory[read_address_i];
			end else begin
				read_data_result <= 64'd0;
			end
			read_valid_result <= 1'b1;
		end
	end

endmodule
