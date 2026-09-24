`timescale 1ns / 1ps

// 将720个初始多边形顶点连续装入选定顶点缓冲区
module initial_polygon_loader
#(
	parameter C_ROM_INIT_FILE = "initial_polygon_720_q16_16.mem"
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire target_buffer_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire ram_write_enable_o,
	output wire ram_write_buffer_o,
	output wire [9:0] ram_write_address_o,
	output wire [63:0] ram_write_data_o,
	output wire [10:0] loaded_vertex_count_o
);

	localparam [1:0] STATE_IDLE = 2'd0;
	localparam [1:0] STATE_STREAM = 2'd1;
	localparam [1:0] STATE_DRAIN = 2'd2;

	reg [1:0] state_current;
	reg [1:0] state_next;
	reg target_buffer_saved;
	reg [9:0] request_address;
	reg [9:0] response_address;
	reg [10:0] loaded_vertex_count_result;
	reg done_result;
	reg protocol_error_result;

	wire rom_read_enable;
	wire [63:0] rom_read_data;
	wire rom_read_valid;
	wire loader_active;

	assign loader_active = (state_current == STATE_STREAM) ||
		(state_current == STATE_DRAIN);
	assign rom_read_enable = (state_current == STATE_STREAM);
	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign ram_write_enable_o = loader_active && rom_read_valid;
	assign ram_write_buffer_o = target_buffer_saved;
	assign ram_write_address_o = response_address;
	assign ram_write_data_o = rom_read_data;
	assign loaded_vertex_count_o = loaded_vertex_count_result;

	initial_polygon_rom
	#(
		.C_INIT_FILE(C_ROM_INIT_FILE)
	)
	initial_polygon_rom_instance
	(
		.clk_i(clk_i),
		.read_enable_i(rom_read_enable),
		.read_address_i(request_address),
		.read_data_o(rom_read_data),
		.read_valid_o(rom_read_valid)
	);

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			state_current <= STATE_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	always @(*) begin
		state_next = state_current;
		case(state_current)
			STATE_IDLE: begin
				if(start_i == 1'b1) begin
					state_next = STATE_STREAM;
				end
			end
			STATE_STREAM: begin
				if(request_address == 10'd719) begin
					state_next = STATE_DRAIN;
				end
			end
			STATE_DRAIN: begin
				if(rom_read_valid == 1'b1) begin
					state_next = STATE_IDLE;
				end
			end
			default: state_next = STATE_IDLE;
		endcase
	end

	// Address and count registers align each synchronous ROM response with one RAM write.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			target_buffer_saved <= 1'b0;
			request_address <= 10'd0;
			response_address <= 10'd0;
			loaded_vertex_count_result <= 11'd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					if(start_i == 1'b1) begin
						target_buffer_saved <= target_buffer_i;
						request_address <= 10'd0;
						response_address <= 10'd0;
						loaded_vertex_count_result <= 11'd0;
					end
				end
				STATE_STREAM: begin
					response_address <= request_address;
					if(request_address < 10'd719) begin
						request_address <= request_address + 1'b1;
					end
					if(rom_read_valid == 1'b1) begin
						loaded_vertex_count_result <= loaded_vertex_count_result + 1'b1;
					end
				end
				STATE_DRAIN: begin
					if(rom_read_valid == 1'b1) begin
						loaded_vertex_count_result <= loaded_vertex_count_result + 1'b1;
						done_result <= 1'b1;
					end
				end
				default: begin
					request_address <= 10'd0;
				end
			endcase
		end
	end

endmodule
