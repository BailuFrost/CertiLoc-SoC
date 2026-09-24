`timescale 1ns / 1ps

module tb_vertex_ram_dual_buffer;
	reg clk_i;
	reg reset_i;
	reg port_0_enable_i;
	reg port_0_write_i;
	reg port_0_buffer_i;
	reg [9:0] port_0_address_i;
	reg [63:0] port_0_write_data_i;
	wire [63:0] port_0_read_data_o;
	wire port_0_read_valid_o;
	reg port_1_enable_i;
	reg port_1_write_i;
	reg port_1_buffer_i;
	reg [9:0] port_1_address_i;
	reg [63:0] port_1_write_data_i;
	wire [63:0] port_1_read_data_o;
	wire port_1_read_valid_o;
	integer failure_count;

	vertex_ram_dual_buffer dut
	(
		.clk_i(clk_i), .reset_i(reset_i),
		.port_0_enable_i(port_0_enable_i), .port_0_write_i(port_0_write_i),
		.port_0_buffer_i(port_0_buffer_i), .port_0_address_i(port_0_address_i),
		.port_0_write_data_i(port_0_write_data_i), .port_0_read_data_o(port_0_read_data_o),
		.port_0_read_valid_o(port_0_read_valid_o),
		.port_1_enable_i(port_1_enable_i), .port_1_write_i(port_1_write_i),
		.port_1_buffer_i(port_1_buffer_i), .port_1_address_i(port_1_address_i),
		.port_1_write_data_i(port_1_write_data_i), .port_1_read_data_o(port_1_read_data_o),
		.port_1_read_valid_o(port_1_read_valid_o)
	);

	always #5 clk_i = ~clk_i;

	initial begin
		clk_i = 1'b0;
		reset_i = 1'b1;
		port_0_enable_i = 1'b0;
		port_0_write_i = 1'b0;
		port_0_buffer_i = 1'b0;
		port_0_address_i = 10'd0;
		port_0_write_data_i = 64'd0;
		port_1_enable_i = 1'b0;
		port_1_write_i = 1'b0;
		port_1_buffer_i = 1'b0;
		port_1_address_i = 10'd0;
		port_1_write_data_i = 64'd0;
		failure_count = 0;
		repeat(3) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		// Write different physical buffers concurrently.
		port_0_enable_i = 1'b1;
		port_0_write_i = 1'b1;
		port_0_buffer_i = 1'b0;
		port_0_address_i = 10'd3;
		port_0_write_data_i = 64'h1111222233334444;
		port_1_enable_i = 1'b1;
		port_1_write_i = 1'b1;
		port_1_buffer_i = 1'b1;
		port_1_address_i = 10'd7;
		port_1_write_data_i = 64'hAAAABBBBCCCCDDDD;
		@(negedge clk_i);

		// Read both buffers concurrently through independent ports.
		port_0_write_i = 1'b0;
		port_1_write_i = 1'b0;
		@(negedge clk_i);
		if((port_0_read_valid_o != 1'b1) || (port_0_read_data_o !== 64'h1111222233334444)) begin
			$display("FAIL: RAM port 0 independent buffer read");
			failure_count = failure_count + 1;
		end
		if((port_1_read_valid_o != 1'b1) || (port_1_read_data_o !== 64'hAAAABBBBCCCCDDDD)) begin
			$display("FAIL: RAM port 1 independent buffer read");
			failure_count = failure_count + 1;
		end

		// Concurrent writes to distinct addresses in the same buffer are supported.
		port_0_write_i = 1'b1;
		port_0_address_i = 10'd10;
		port_0_write_data_i = 64'h0102030405060708;
		port_1_write_i = 1'b1;
		port_1_buffer_i = 1'b0;
		port_1_address_i = 10'd11;
		port_1_write_data_i = 64'h1020304050607080;
		@(negedge clk_i);
		port_0_write_i = 1'b0;
		port_0_address_i = 10'd11;
		port_1_write_i = 1'b0;
		port_1_address_i = 10'd10;
		@(negedge clk_i);
		if((port_0_read_data_o !== 64'h1020304050607080) ||
			(port_1_read_data_o !== 64'h0102030405060708)) begin
			$display("FAIL: RAM concurrent same-buffer distinct-address access");
			failure_count = failure_count + 1;
		end
		port_0_enable_i = 1'b0;
		port_1_enable_i = 1'b0;
		@(negedge clk_i);
		if((port_0_read_valid_o != 1'b0) || (port_1_read_valid_o != 1'b0)) begin
			$display("FAIL: RAM read-valid pulses must clear");
			failure_count = failure_count + 1;
		end

		if(failure_count == 0) begin
			$display("PASS: vertex_ram_dual_buffer concurrent access checks completed");
		end else begin
			$display("FAIL: vertex_ram_dual_buffer failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(100) @(posedge clk_i);
		$display("FAIL: vertex_ram_dual_buffer watchdog timeout");
		$finish;
	end
endmodule
