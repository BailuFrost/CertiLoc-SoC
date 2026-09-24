`timescale 1ns / 1ps

// T03二进制协议流式帧解析器
module packet_decoder
#(
	parameter C_MAX_PAYLOAD_LENGTH = 244,
	parameter C_TIMEOUT_CLKS = 10000000
)
(
	input i_clk,
	input i_reset,
	input [7:0] i_data,
	input i_data_valid,
	output o_data_ready,
	output o_frame_valid,
	input i_frame_ready,
	output [7:0] o_frame_command,
	output [15:0] o_frame_sequence,
	output [7:0] o_frame_payload_length,
	input i_payload_read_enable,
	input [7:0] i_payload_read_address,
	output [7:0] o_payload_read_data,
	output o_payload_read_valid,
	output o_error_valid,
	input i_error_ready,
	output [7:0] o_error_code,
	output [7:0] o_error_command,
	output [15:0] o_error_sequence,
	output [31:0] o_error_context
);

	localparam ST_SEARCH_FIRST = 4'd0;
	localparam ST_SEARCH_SECOND = 4'd1;
	localparam ST_VERSION = 4'd2;
	localparam ST_COMMAND = 4'd3;
	localparam ST_SEQUENCE_LOW = 4'd4;
	localparam ST_SEQUENCE_HIGH = 4'd5;
	localparam ST_LENGTH_LOW = 4'd6;
	localparam ST_LENGTH_HIGH = 4'd7;
	localparam ST_PAYLOAD = 4'd8;
	localparam ST_CRC_LOW = 4'd9;
	localparam ST_CRC_HIGH = 4'd10;
	localparam ST_FRAME_HOLD = 4'd11;
	localparam ST_ERROR_HOLD = 4'd12;

	localparam C_ERROR_VERSION = 8'h01;
	localparam C_ERROR_COMMAND = 8'h02;
	localparam C_ERROR_LENGTH = 8'h03;
	localparam C_ERROR_CRC = 8'h04;
	localparam C_ERROR_TIMEOUT = 8'h05;

	reg [3:0] state_current = ST_SEARCH_FIRST;
	reg [3:0] state_next = ST_SEARCH_FIRST;
	reg [7:0] reg_command = 0;
	reg [15:0] reg_sequence = 0;
	reg [7:0] reg_payload_length = 0;
	reg [7:0] reg_payload_index = 0;
	reg [7:0] reg_crc_low = 0;
	reg [7:0] reg_error_code = 0;
	reg [7:0] reg_error_command = 0;
	reg [15:0] reg_error_sequence = 0;
	reg [31:0] reg_error_context = 0;
	reg [23:0] cnt_timeout = 0;
	reg [7:0] mem_payload [0:C_MAX_PAYLOAD_LENGTH - 1];
	reg [7:0] reg_payload_read_data = 0;
	reg flag_payload_read_valid = 0;
	reg flag_crc_wait = 0;
	reg flag_crc_start = 0;
	reg flag_crc_clear = 0;
	reg [7:0] reg_crc_data = 0;

	wire flag_byte_accept;
	wire flag_command_supported;
	wire flag_timeout_active;
	wire flag_timeout_hit;
	wire data_ready_o;
	wire frame_valid_o;
	wire error_valid_o;
	wire crc_busy;
	wire crc_done;
	wire [15:0] crc_value;
	wire rstn_internal;

	assign flag_command_supported = (i_data == 8'h01) || (i_data == 8'h10) ||
		(i_data == 8'h11) || (i_data == 8'h12) || (i_data == 8'h13) ||
		(i_data == 8'h14) || (i_data == 8'h1F);
	assign flag_timeout_active = (state_current >= ST_VERSION) && (state_current <= ST_CRC_HIGH);
	assign flag_timeout_hit = flag_timeout_active && (cnt_timeout == C_TIMEOUT_CLKS - 1);
	assign data_ready_o = (flag_crc_wait == 1'b0) &&
		(state_current != ST_FRAME_HOLD) && (state_current != ST_ERROR_HOLD);
	assign flag_byte_accept = i_data_valid & data_ready_o;
	assign frame_valid_o = (state_current == ST_FRAME_HOLD);
	assign error_valid_o = (state_current == ST_ERROR_HOLD);
	assign rstn_internal = ~i_reset;

	assign o_data_ready = data_ready_o;
	assign o_frame_valid = frame_valid_o;
	assign o_frame_command = reg_command;
	assign o_frame_sequence = reg_sequence;
	assign o_frame_payload_length = reg_payload_length;
	assign o_payload_read_data = reg_payload_read_data;
	assign o_payload_read_valid = flag_payload_read_valid;
	assign o_error_valid = error_valid_o;
	assign o_error_code = reg_error_code;
	assign o_error_command = reg_error_command;
	assign o_error_sequence = reg_error_sequence;
	assign o_error_context = reg_error_context;

	crc16_ccitt_byte crc16_ccitt_byte_Inst
	(
		.i_clk(i_clk),
		.i_reset(i_reset),
		.i_start(flag_crc_start),
		.i_clear(flag_crc_clear),
		.i_data(reg_crc_data),
		.o_busy(crc_busy),
		.o_done(crc_done),
		.o_crc(crc_value)
	);

	always@(*)begin
		state_next = state_current;
		if(flag_timeout_hit == 1'b1)begin
			state_next = ST_ERROR_HOLD;
		end else begin
			case(state_current)
				ST_SEARCH_FIRST:begin
					if((flag_byte_accept == 1'b1) && (i_data == 8'hA5))begin
						state_next = ST_SEARCH_SECOND;
					end
				end
				ST_SEARCH_SECOND:begin
					if(flag_byte_accept == 1'b1)begin
						if(i_data == 8'h5A)begin
							state_next = ST_VERSION;
						end else if(i_data == 8'hA5)begin
							state_next = ST_SEARCH_SECOND;
						end else begin
							state_next = ST_SEARCH_FIRST;
						end
					end
				end
				ST_VERSION:begin
					if(flag_byte_accept == 1'b1)begin
						if(i_data == 8'h01)begin
							state_next = ST_COMMAND;
						end else begin
							state_next = ST_ERROR_HOLD;
						end
					end
				end
				ST_COMMAND:begin
					if(flag_byte_accept == 1'b1)begin
						if(flag_command_supported == 1'b1)begin
							state_next = ST_SEQUENCE_LOW;
						end else begin
							state_next = ST_ERROR_HOLD;
						end
					end
				end
				ST_SEQUENCE_LOW:begin
					if(flag_byte_accept == 1'b1)begin
						state_next = ST_SEQUENCE_HIGH;
					end
				end
				ST_SEQUENCE_HIGH:begin
					if(flag_byte_accept == 1'b1)begin
						state_next = ST_LENGTH_LOW;
					end
				end
				ST_LENGTH_LOW:begin
					if(flag_byte_accept == 1'b1)begin
						state_next = ST_LENGTH_HIGH;
					end
				end
				ST_LENGTH_HIGH:begin
					if(flag_byte_accept == 1'b1)begin
						if((i_data != 8'd0) || (reg_payload_length > C_MAX_PAYLOAD_LENGTH))begin
							state_next = ST_ERROR_HOLD;
						end else if(reg_payload_length == 8'd0)begin
							state_next = ST_CRC_LOW;
						end else begin
							state_next = ST_PAYLOAD;
						end
					end
				end
				ST_PAYLOAD:begin
					if((flag_byte_accept == 1'b1) && (reg_payload_index == reg_payload_length - 1'b1))begin
						state_next = ST_CRC_LOW;
					end
				end
				ST_CRC_LOW:begin
					if(flag_byte_accept == 1'b1)begin
						state_next = ST_CRC_HIGH;
					end
				end
				ST_CRC_HIGH:begin
					if(flag_byte_accept == 1'b1)begin
						if(crc_value == {i_data, reg_crc_low})begin
							state_next = ST_FRAME_HOLD;
						end else begin
							state_next = ST_ERROR_HOLD;
						end
					end
				end
				ST_FRAME_HOLD:begin
					if(i_frame_ready == 1'b1)begin
						state_next = ST_SEARCH_FIRST;
					end
				end
				ST_ERROR_HOLD:begin
					if(i_error_ready == 1'b1)begin
						state_next = ST_SEARCH_FIRST;
					end
				end
				default:begin
					state_next = ST_SEARCH_FIRST;
				end
			endcase
		end
	end

	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			state_current <= ST_SEARCH_FIRST;
		end else begin
			state_current <= state_next;
		end
	end

	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_command <= 8'd0;
			reg_sequence <= 16'd0;
			reg_payload_length <= 8'd0;
			reg_payload_index <= 8'd0;
			reg_crc_low <= 8'd0;
			reg_error_code <= 8'd0;
			reg_error_command <= 8'd0;
			reg_error_sequence <= 16'd0;
			reg_error_context <= 32'd0;
			cnt_timeout <= 24'd0;
			flag_crc_wait <= 1'b0;
			flag_crc_start <= 1'b0;
			flag_crc_clear <= 1'b0;
			reg_crc_data <= 8'd0;
		end else begin
			flag_crc_start <= 1'b0;
			flag_crc_clear <= 1'b0;
			if(crc_done == 1'b1)begin
				flag_crc_wait <= 1'b0;
			end
			if(flag_timeout_active == 1'b0)begin
				cnt_timeout <= 24'd0;
			end else if(flag_byte_accept == 1'b1)begin
				cnt_timeout <= 24'd0;
			end else if(flag_timeout_hit == 1'b0)begin
				cnt_timeout <= cnt_timeout + 1'b1;
			end
			if(flag_timeout_hit == 1'b1)begin
				reg_error_code <= C_ERROR_TIMEOUT;
				reg_error_command <= reg_command;
				reg_error_sequence <= reg_sequence;
				reg_error_context <= {8'd0, cnt_timeout};
				flag_crc_wait <= 1'b0;
			end else if(flag_byte_accept == 1'b1)begin
				case(state_current)
					ST_VERSION:begin
						flag_crc_start <= 1'b1;
						flag_crc_clear <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
						if(i_data != 8'h01)begin
							reg_error_code <= C_ERROR_VERSION;
							reg_error_command <= 8'd0;
							reg_error_sequence <= 16'd0;
							reg_error_context <= {24'd0, i_data};
							flag_crc_wait <= 1'b0;
						end
					end
					ST_COMMAND:begin
						reg_command <= i_data;
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
						if(flag_command_supported == 1'b0)begin
							reg_error_code <= C_ERROR_COMMAND;
							reg_error_command <= i_data;
							reg_error_sequence <= 16'd0;
							reg_error_context <= {24'd0, i_data};
							flag_crc_wait <= 1'b0;
						end
					end
					ST_SEQUENCE_LOW:begin
						reg_sequence[7:0] <= i_data;
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
					end
					ST_SEQUENCE_HIGH:begin
						reg_sequence[15:8] <= i_data;
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
					end
					ST_LENGTH_LOW:begin
						reg_payload_length <= i_data;
						reg_payload_index <= 8'd0;
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
					end
					ST_LENGTH_HIGH:begin
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
						if((i_data != 8'd0) || (reg_payload_length > C_MAX_PAYLOAD_LENGTH))begin
							reg_error_code <= C_ERROR_LENGTH;
							reg_error_command <= reg_command;
							reg_error_sequence <= reg_sequence;
							reg_error_context <= {16'd0, i_data, reg_payload_length};
							flag_crc_wait <= 1'b0;
						end
					end
					ST_PAYLOAD:begin
						mem_payload[reg_payload_index] <= i_data;
						reg_payload_index <= reg_payload_index + 1'b1;
						flag_crc_start <= 1'b1;
						reg_crc_data <= i_data;
						flag_crc_wait <= 1'b1;
					end
					ST_CRC_LOW:begin
						reg_crc_low <= i_data;
					end
					ST_CRC_HIGH:begin
						if(crc_value != {i_data, reg_crc_low})begin
							reg_error_code <= C_ERROR_CRC;
							reg_error_command <= reg_command;
							reg_error_sequence <= reg_sequence;
							reg_error_context <= {crc_value, i_data, reg_crc_low};
						end
					end
					default:begin
					end
				endcase
			end
		end
	end

	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_payload_read_data <= 8'd0;
			flag_payload_read_valid <= 1'b0;
		end else begin
			flag_payload_read_valid <= 1'b0;
			if((i_payload_read_enable == 1'b1) && (frame_valid_o == 1'b1) &&
				(i_payload_read_address < reg_payload_length))begin
				reg_payload_read_data <= mem_payload[i_payload_read_address];
				flag_payload_read_valid <= 1'b1;
			end
		end
	end

endmodule
