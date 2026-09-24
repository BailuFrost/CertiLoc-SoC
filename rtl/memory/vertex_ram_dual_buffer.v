`timescale 1ns / 1ps

// 两块1024深度、64位宽的双端口顶点缓冲RAM
module vertex_ram_dual_buffer
(
	input wire clk_i,
	input wire reset_i,
	input wire port_0_enable_i,
	input wire port_0_write_i,
	input wire port_0_buffer_i,
	input wire [9:0] port_0_address_i,
	input wire [63:0] port_0_write_data_i,
	output wire [63:0] port_0_read_data_o,
	output wire port_0_read_valid_o,
	input wire port_1_enable_i,
	input wire port_1_write_i,
	input wire port_1_buffer_i,
	input wire [9:0] port_1_address_i,
	input wire [63:0] port_1_write_data_i,
	output wire [63:0] port_1_read_data_o,
	output wire port_1_read_valid_o
);

	// The buffer selector is the most-significant physical address bit.  Keeping
	// both logical buffers in one array matches Vivado's true-dual-port template.
	(* ram_style = "block" *) reg [63:0] vertex_memory [0:2047];
	wire [10:0] port_0_physical_address;
	wire [10:0] port_1_physical_address;
	reg [63:0] port_0_read_data_result;
	reg port_0_read_valid_result;
	reg [63:0] port_1_read_data_result;
	reg port_1_read_valid_result;

	assign port_0_read_data_o = port_0_read_data_result;
	assign port_0_read_valid_o = port_0_read_valid_result;
	assign port_1_read_data_o = port_1_read_data_result;
	assign port_1_read_valid_o = port_1_read_valid_result;
	assign port_0_physical_address = {port_0_buffer_i, port_0_address_i};
	assign port_1_physical_address = {port_1_buffer_i, port_1_address_i};

	// Port 0 independently addresses either physical buffer.
	always @(posedge clk_i) begin
		if(reset_i == 1'b1) begin
			port_0_read_data_result <= 64'd0;
			port_0_read_valid_result <= 1'b0;
		end else begin
			port_0_read_valid_result <= 1'b0;
			if(port_0_enable_i == 1'b1) begin
				if(port_0_write_i == 1'b1) begin
					vertex_memory[port_0_physical_address] <= port_0_write_data_i;
				end else begin
					port_0_read_data_result <= vertex_memory[port_0_physical_address];
					port_0_read_valid_result <= 1'b1;
				end
			end
		end
	end

	// Port 1 supports a concurrent read or write to either buffer.
	always @(posedge clk_i) begin
		if(reset_i == 1'b1) begin
			port_1_read_data_result <= 64'd0;
			port_1_read_valid_result <= 1'b0;
		end else begin
			port_1_read_valid_result <= 1'b0;
			if(port_1_enable_i == 1'b1) begin
				if(port_1_write_i == 1'b1) begin
					vertex_memory[port_1_physical_address] <= port_1_write_data_i;
				end else begin
					port_1_read_data_result <= vertex_memory[port_1_physical_address];
					port_1_read_valid_result <= 1'b1;
				end
			end
		end
	end

endmodule
