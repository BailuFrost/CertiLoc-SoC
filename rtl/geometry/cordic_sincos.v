`timescale 1ns / 1ps

// ============================================================================
// 模块名称: cordic_sincos
// Module Name: cordic_sincos
// 功能说明: 18次迭代旋转模式CORDIC正余弦计算器
// Description: 18-iteration rotation-mode CORDIC sine/cosine engine
// ============================================================================
module cordic_sincos
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire [17:0] phase_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire signed [31:0] sine_o,
	output wire signed [31:0] cosine_o
);

	// State encoding for load, iteration, and result publication.
	localparam [1:0] STATE_IDLE = 2'd0;
	localparam [1:0] STATE_ITERATE = 2'd1;
	localparam [1:0] STATE_OUTPUT = 2'd2;

	// Datapath constants use Q4.32 magnitude and 32-bit full-turn phase units.
	localparam signed [35:0] C_INVERSE_GAIN = 36'sh09B74EDA8;

	reg [1:0] state_current;
	reg [1:0] state_next;
	reg [4:0] iteration_count;
	reg signed [35:0] x_value;
	reg signed [35:0] y_value;
	reg signed [31:0] z_value;
	reg cosine_negative;
	reg sine_negative;
	reg signed [31:0] sine_result;
	reg signed [31:0] cosine_result;
	reg done_result;
	reg protocol_error_result;

	reg [17:0] reduced_phase;
	reg reduced_cosine_negative;
	reg reduced_sine_negative;
	reg signed [31:0] atan_step;

	wire signed [35:0] x_shifted;
	wire signed [35:0] y_shifted;
	wire signed [35:0] x_rounded;
	wire signed [35:0] y_rounded;

	assign x_shifted = x_value >>> iteration_count;
	assign y_shifted = y_value >>> iteration_count;
	assign x_rounded = (x_value[35] == 1'b0) ?
		((x_value + 36'sd2) >>> 2) : -(((-x_value) + 36'sd2) >>> 2);
	assign y_rounded = (y_value[35] == 1'b0) ?
		((y_value + 36'sd2) >>> 2) : -(((-y_value) + 36'sd2) >>> 2);

	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign sine_o = sine_result;
	assign cosine_o = cosine_result;

	// Map the full turn into the first quadrant and retain output signs.
	always @(*) begin
		reduced_phase = phase_i;
		reduced_cosine_negative = 1'b0;
		reduced_sine_negative = 1'b0;
		case(phase_i[17:16])
			2'b00: begin
				reduced_phase = phase_i;
			end
			2'b01: begin
				reduced_phase = 18'd131072 - phase_i;
				reduced_cosine_negative = 1'b1;
			end
			2'b10: begin
				reduced_phase = phase_i - 18'd131072;
				reduced_cosine_negative = 1'b1;
				reduced_sine_negative = 1'b1;
			end
			default: begin
				reduced_phase = 18'd0 - phase_i;
				reduced_sine_negative = 1'b1;
			end
		endcase
	end

	// The table is atan(2^-i) expressed in unsigned 32-bit full-turn phase units.
	always @(*) begin
		case(iteration_count)
			5'd0: atan_step = 32'sh20000000;
			5'd1: atan_step = 32'sh12E4051E;
			5'd2: atan_step = 32'sh09FB385B;
			5'd3: atan_step = 32'sh051111D4;
			5'd4: atan_step = 32'sh028B0D43;
			5'd5: atan_step = 32'sh0145D7E1;
			5'd6: atan_step = 32'sh00A2F61E;
			5'd7: atan_step = 32'sh00517C55;
			5'd8: atan_step = 32'sh0028BE53;
			5'd9: atan_step = 32'sh00145F2F;
			5'd10: atan_step = 32'sh000A2F98;
			5'd11: atan_step = 32'sh000517CC;
			5'd12: atan_step = 32'sh00028BE6;
			5'd13: atan_step = 32'sh000145F3;
			5'd14: atan_step = 32'sh0000A2FA;
			5'd15: atan_step = 32'sh0000517D;
			5'd16: atan_step = 32'sh000028BE;
			5'd17: atan_step = 32'sh0000145F;
			default: atan_step = 32'sd0;
		endcase
	end

	// State register.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			state_current <= STATE_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	// Next-state logic keeps every accepted operation at a fixed 19-cycle latency.
	always @(*) begin
		state_next = state_current;
		case(state_current)
			STATE_IDLE: begin
				if(start_i == 1'b1) begin
					state_next = STATE_ITERATE;
				end
			end
			STATE_ITERATE: begin
				if(iteration_count == 5'd17) begin
					state_next = STATE_OUTPUT;
				end
			end
			STATE_OUTPUT: begin
				state_next = STATE_IDLE;
			end
			default: begin
				state_next = STATE_IDLE;
			end
		endcase
	end

	// Registered datapath performs exactly one shift-add micro-rotation per cycle.
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			iteration_count <= 5'd0;
			x_value <= 36'sd0;
			y_value <= 36'sd0;
			z_value <= 32'sd0;
			cosine_negative <= 1'b0;
			sine_negative <= 1'b0;
			sine_result <= 32'sd0;
			cosine_result <= 32'sd0;
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
						iteration_count <= 5'd0;
						x_value <= C_INVERSE_GAIN;
						y_value <= 36'sd0;
						z_value <= $signed({reduced_phase, 14'b0});
						cosine_negative <= reduced_cosine_negative;
						sine_negative <= reduced_sine_negative;
					end
				end
				STATE_ITERATE: begin
					if(z_value >= 32'sd0) begin
						x_value <= x_value - y_shifted;
						y_value <= y_value + x_shifted;
						z_value <= z_value - atan_step;
					end else begin
						x_value <= x_value + y_shifted;
						y_value <= y_value - x_shifted;
						z_value <= z_value + atan_step;
					end
					if(iteration_count != 5'd17) begin
						iteration_count <= iteration_count + 1'b1;
					end
				end
				STATE_OUTPUT: begin
					if(sine_negative == 1'b1) begin
						sine_result <= -$signed(y_rounded[31:0]);
					end else begin
						sine_result <= $signed(y_rounded[31:0]);
					end
					if(cosine_negative == 1'b1) begin
						cosine_result <= -$signed(x_rounded[31:0]);
					end else begin
						cosine_result <= $signed(x_rounded[31:0]);
					end
					done_result <= 1'b1;
				end
				default: begin
					iteration_count <= 5'd0;
				end
			endcase
		end
	end

endmodule
