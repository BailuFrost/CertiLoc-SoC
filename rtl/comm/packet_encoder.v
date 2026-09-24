`timescale 1ns / 1ps

// T03二进制协议流式帧编码器
module packet_encoder
#(
	parameter C_MAX_PAYLOAD_LENGTH = 244
)
(
	input i_clk,
	input i_reset,
	input i_frame_valid,
	output o_frame_ready,
	input [7:0] i_frame_command,
	input [15:0] i_frame_sequence,
	input [7:0] i_frame_payload_length,
	input [7:0] i_payload_data,
	input i_payload_valid,
	output o_payload_ready,
	output [7:0] o_data,
	output o_data_valid,
	input i_data_ready,
	output o_busy,
	output o_frame_done,
	output o_length_error
);

	localparam ST_IDLE = 4'd0;
	localparam ST_SOF_FIRST = 4'd1;
	localparam ST_SOF_SECOND = 4'd2;
	localparam ST_VERSION = 4'd3;
	localparam ST_COMMAND = 4'd4;
	localparam ST_SEQUENCE_LOW = 4'd5;
	localparam ST_SEQUENCE_HIGH = 4'd6;
	localparam ST_LENGTH_LOW = 4'd7;
	localparam ST_LENGTH_HIGH = 4'd8;
	localparam ST_PAYLOAD = 4'd9;
	localparam ST_CRC_LOW = 4'd10;
	localparam ST_CRC_HIGH = 4'd11;

	reg [3:0] state_current = ST_IDLE;
	reg [3:0] state_next = ST_IDLE;
	reg [7:0] reg_command = 0;
	reg [15:0] reg_sequence = 0;
	reg [7:0] reg_payload_length = 0;
	reg [7:0] reg_payload_index = 0;
	reg flag_crc_wait = 0;
	reg flag_crc_start = 0;
	reg flag_crc_clear = 0;
	reg [7:0] reg_crc_data = 0;
	reg flag_frame_done = 0;
	reg flag_length_error = 0;
	reg [7:0] reg_data_output = 0;
	reg flag_data_valid = 0;
	reg flag_payload_ready = 0;

	wire flag_frame_accept;
	wire flag_data_accept;
	wire frame_ready_o;
	wire busy_o;
	wire crc_busy;
	wire crc_done;
	wire [15:0] crc_value;
	wire rstn_internal;

	assign frame_ready_o = (state_current == ST_IDLE);
	assign flag_frame_accept = i_frame_valid & frame_ready_o;
	assign flag_data_accept = flag_data_valid & i_data_ready;
	assign busy_o = (state_current != ST_IDLE);
	assign rstn_internal = ~i_reset;

	assign o_frame_ready = frame_ready_o;
	assign o_payload_ready = flag_payload_ready;
	assign o_data = reg_data_output;
	assign o_data_valid = flag_data_valid;
	assign o_busy = busy_o;
	assign o_frame_done = flag_frame_done;
	assign o_length_error = flag_length_error;

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
		reg_data_output = 8'd0;
		flag_data_valid = 1'b0;
		flag_payload_ready = 1'b0;
		if(flag_crc_wait == 1'b0)begin
			case(state_current)
				ST_SOF_FIRST:begin
					reg_data_output = 8'hA5;
					flag_data_valid = 1'b1;
				end
				ST_SOF_SECOND:begin
					reg_data_output = 8'h5A;
					flag_data_valid = 1'b1;
				end
				ST_VERSION:begin
					reg_data_output = 8'h01;
					flag_data_valid = 1'b1;
				end
				ST_COMMAND:begin
					reg_data_output = reg_command;
					flag_data_valid = 1'b1;
				end
				ST_SEQUENCE_LOW:begin
					reg_data_output = reg_sequence[7:0];
					flag_data_valid = 1'b1;
				end
				ST_SEQUENCE_HIGH:begin
					reg_data_output = reg_sequence[15:8];
					flag_data_valid = 1'b1;
				end
				ST_LENGTH_LOW:begin
					reg_data_output = reg_payload_length;
					flag_data_valid = 1'b1;
				end
				ST_LENGTH_HIGH:begin
					reg_data_output = 8'd0;
					flag_data_valid = 1'b1;
				end
				ST_PAYLOAD:begin
					reg_data_output = i_payload_data;
					flag_data_valid = i_payload_valid;
					flag_payload_ready = i_data_ready;
				end
				ST_CRC_LOW:begin
					reg_data_output = crc_value[7:0];
					flag_data_valid = 1'b1;
				end
				ST_CRC_HIGH:begin
					reg_data_output = crc_value[15:8];
					flag_data_valid = 1'b1;
				end
				default:begin
				end
			endcase
		end
	end

	always@(*)begin
		state_next = state_current;
		case(state_current)
			ST_IDLE:begin
				if((flag_frame_accept == 1'b1) && (i_frame_payload_length <= C_MAX_PAYLOAD_LENGTH))begin
					state_next = ST_SOF_FIRST;
				end
			end
			ST_SOF_FIRST:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_SOF_SECOND;
				end
			end
			ST_SOF_SECOND:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_VERSION;
				end
			end
			ST_VERSION:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_COMMAND;
				end
			end
			ST_COMMAND:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_SEQUENCE_LOW;
				end
			end
			ST_SEQUENCE_LOW:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_SEQUENCE_HIGH;
				end
			end
			ST_SEQUENCE_HIGH:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_LENGTH_LOW;
				end
			end
			ST_LENGTH_LOW:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_LENGTH_HIGH;
				end
			end
			ST_LENGTH_HIGH:begin
				if(flag_data_accept == 1'b1)begin
					if(reg_payload_length == 8'd0)begin
						state_next = ST_CRC_LOW;
					end else begin
						state_next = ST_PAYLOAD;
					end
				end
			end
			ST_PAYLOAD:begin
				if((flag_data_accept == 1'b1) && (reg_payload_index == reg_payload_length - 1'b1))begin
					state_next = ST_CRC_LOW;
				end
			end
			ST_CRC_LOW:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_CRC_HIGH;
				end
			end
			ST_CRC_HIGH:begin
				if(flag_data_accept == 1'b1)begin
					state_next = ST_IDLE;
				end
			end
			default:begin
				state_next = ST_IDLE;
			end
		endcase
	end

	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			state_current <= ST_IDLE;
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
			flag_crc_wait <= 1'b0;
			flag_crc_start <= 1'b0;
			flag_crc_clear <= 1'b0;
			reg_crc_data <= 8'd0;
			flag_frame_done <= 1'b0;
			flag_length_error <= 1'b0;
		end else begin
			flag_crc_start <= 1'b0;
			flag_crc_clear <= 1'b0;
			flag_frame_done <= 1'b0;
			flag_length_error <= 1'b0;
			if(crc_done == 1'b1)begin
				flag_crc_wait <= 1'b0;
			end
			if(flag_frame_accept == 1'b1)begin
				if(i_frame_payload_length <= C_MAX_PAYLOAD_LENGTH)begin
					reg_command <= i_frame_command;
					reg_sequence <= i_frame_sequence;
					reg_payload_length <= i_frame_payload_length;
					reg_payload_index <= 8'd0;
				end else begin
					flag_length_error <= 1'b1;
				end
			end
			if(flag_data_accept == 1'b1)begin
				if((state_current >= ST_VERSION) && (state_current <= ST_PAYLOAD))begin
					flag_crc_start <= 1'b1;
					reg_crc_data <= reg_data_output;
					flag_crc_wait <= 1'b1;
					if(state_current == ST_VERSION)begin
						flag_crc_clear <= 1'b1;
					end
				end
				if(state_current == ST_PAYLOAD)begin
					reg_payload_index <= reg_payload_index + 1'b1;
				end
				if(state_current == ST_CRC_HIGH)begin
					flag_frame_done <= 1'b1;
				end
			end
		end
	end

endmodule
