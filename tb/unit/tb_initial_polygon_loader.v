`timescale 1ns / 1ps

module tb_initial_polygon_loader;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg target_buffer_i;
	wire busy_o;
	wire done_o;
	wire protocol_error_o;
	wire loader_write_enable;
	wire loader_write_buffer;
	wire [9:0] loader_write_address;
	wire [63:0] loader_write_data;
	wire [10:0] loaded_vertex_count_o;
	reg test_port_enable;
	reg test_port_write;
	reg test_port_buffer;
	reg [9:0] test_port_address;
	reg [63:0] test_port_write_data;
	wire [63:0] test_port_read_data;
	wire test_port_read_valid;
	wire [63:0] unused_loader_read_data;
	wire unused_loader_read_valid;
	reg [63:0] golden_vertices [0:719];
	integer index;
	integer failure_count;
	integer protocol_error_count;
	integer cycle_count;

	initial_polygon_loader dut_loader
	(
		.clk_i(clk_i), .reset_i(reset_i), .start_i(start_i),
		.target_buffer_i(target_buffer_i), .busy_o(busy_o), .done_o(done_o),
		.protocol_error_o(protocol_error_o), .ram_write_enable_o(loader_write_enable),
		.ram_write_buffer_o(loader_write_buffer), .ram_write_address_o(loader_write_address),
		.ram_write_data_o(loader_write_data), .loaded_vertex_count_o(loaded_vertex_count_o)
	);

	vertex_ram_dual_buffer dut_ram
	(
		.clk_i(clk_i), .reset_i(reset_i),
		.port_0_enable_i(loader_write_enable), .port_0_write_i(1'b1),
		.port_0_buffer_i(loader_write_buffer), .port_0_address_i(loader_write_address),
		.port_0_write_data_i(loader_write_data), .port_0_read_data_o(unused_loader_read_data),
		.port_0_read_valid_o(unused_loader_read_valid),
		.port_1_enable_i(test_port_enable), .port_1_write_i(test_port_write),
		.port_1_buffer_i(test_port_buffer), .port_1_address_i(test_port_address),
		.port_1_write_data_i(test_port_write_data), .port_1_read_data_o(test_port_read_data),
		.port_1_read_valid_o(test_port_read_valid)
	);

	always #5 clk_i = ~clk_i;

	always @(posedge clk_i) begin
		if(protocol_error_o == 1'b1) begin
			protocol_error_count = protocol_error_count + 1;
		end
	end

	task load_buffer;
		input buffer_value;
		input inject_busy_start;
	begin
		wait(busy_o == 1'b0);
		@(negedge clk_i);
		target_buffer_i = buffer_value;
		start_i = 1'b1;
		@(negedge clk_i);
		start_i = 1'b0;
		cycle_count = 0;
		while(done_o != 1'b1) begin
			@(negedge clk_i);
			cycle_count = cycle_count + 1;
			if((inject_busy_start == 1'b1) && (cycle_count == 10)) begin
				start_i = 1'b1;
			end
			if((inject_busy_start == 1'b1) && (cycle_count == 11)) begin
				start_i = 1'b0;
			end
			if(cycle_count > 730) begin
				$display("FAIL: loader timeout buffer=%0d", buffer_value);
				failure_count = failure_count + 1;
				disable load_buffer;
			end
		end
		if(cycle_count != 721) begin
			$display("FAIL: loader latency buffer=%0d expected=721 observed=%0d", buffer_value, cycle_count);
			failure_count = failure_count + 1;
		end
		if(loaded_vertex_count_o != 11'd720) begin
			$display("FAIL: loader count buffer=%0d expected=720 observed=%0d", buffer_value, loaded_vertex_count_o);
			failure_count = failure_count + 1;
		end
		@(negedge clk_i);
		if(done_o != 1'b0) begin
			$display("FAIL: loader done must be one cycle");
			failure_count = failure_count + 1;
		end
	end
	endtask

	task check_vertex;
		input buffer_value;
		input [9:0] address_value;
		input [63:0] expected_value;
	begin
		@(negedge clk_i);
		test_port_enable = 1'b1;
		test_port_write = 1'b0;
		test_port_buffer = buffer_value;
		test_port_address = address_value;
		@(negedge clk_i);
		test_port_enable = 1'b0;
		if((test_port_read_valid != 1'b1) || (test_port_read_data !== expected_value)) begin
			$display("FAIL: vertex buffer=%0d address=%0d expected=%h observed=%h", buffer_value, address_value, expected_value, test_port_read_data);
			failure_count = failure_count + 1;
		end
	end
	endtask

	initial begin
		$readmemh("initial_polygon_720_q16_16.mem", golden_vertices);
		clk_i = 1'b0;
		reset_i = 1'b1;
		start_i = 1'b0;
		target_buffer_i = 1'b0;
		test_port_enable = 1'b0;
		test_port_write = 1'b0;
		test_port_buffer = 1'b0;
		test_port_address = 10'd0;
		test_port_write_data = 64'd0;
		failure_count = 0;
		protocol_error_count = 0;
		repeat(4) @(posedge clk_i);
		@(negedge clk_i);
		reset_i = 1'b0;

		load_buffer(1'b0, 1'b1);
		for(index = 0; index < 720; index = index + 1) begin
			check_vertex(1'b0, index[9:0], golden_vertices[index]);
		end

		load_buffer(1'b1, 1'b0);
		for(index = 0; index < 720; index = index + 1) begin
			check_vertex(1'b1, index[9:0], golden_vertices[index]);
		end
		// Confirm loading buffer B did not alter representative buffer A entries.
		check_vertex(1'b0, 10'd0, golden_vertices[0]);
		check_vertex(1'b0, 10'd359, golden_vertices[359]);
		check_vertex(1'b0, 10'd719, golden_vertices[719]);

		if(protocol_error_count != 1) begin
			$display("FAIL: loader busy-start pulses expected=1 observed=%0d", protocol_error_count);
			failure_count = failure_count + 1;
		end
		if(failure_count == 0) begin
			$display("PASS: initial_polygon_loader copied both 720-vertex buffers bit-exactly");
		end else begin
			$display("FAIL: initial_polygon_loader failures=%0d", failure_count);
		end
		$finish;
	end

	initial begin
		repeat(10000) @(posedge clk_i);
		$display("FAIL: initial_polygon_loader watchdog timeout");
		$finish;
	end
endmodule
