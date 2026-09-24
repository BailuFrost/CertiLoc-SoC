`timescale 1ns / 1ps

// 使用30轮分数恢复除法计算Q16.16线段与半平面边界交点
module segment_intersection
#(
	parameter [66:0] C_EPS_DENOMINATOR = 67'd1073741824
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire signed [31:0] start_x_i,
	input wire signed [31:0] start_y_i,
	input wire signed [31:0] end_x_i,
	input wire signed [31:0] end_y_i,
	input wire signed [65:0] start_value_i,
	input wire signed [65:0] end_value_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire intersection_valid_o,
	output wire parallel_o,
	output wire arithmetic_saturated_o,
	output wire [30:0] ratio_q2_30_o,
	output wire signed [31:0] intersection_x_o,
	output wire signed [31:0] intersection_y_o
);

	localparam [3:0] STATE_IDLE = 4'd0;
	localparam [3:0] STATE_CHECK = 4'd1;
	localparam [3:0] STATE_DIVIDE = 4'd2;
	localparam [3:0] STATE_ROUND_RATIO = 4'd3;
	localparam [3:0] STATE_MUL_X = 4'd4;
	localparam [3:0] STATE_ROUND_X = 4'd5;
	localparam [3:0] STATE_MUL_Y = 4'd6;
	localparam [3:0] STATE_ROUND_Y = 4'd7;
	localparam [3:0] STATE_OUTPUT = 4'd8;
	localparam [3:0] STATE_PARALLEL = 4'd9;

	reg [3:0] state_current;
	reg [3:0] state_next;
	reg signed [31:0] start_x_saved;
	reg signed [31:0] start_y_saved;
	reg signed [32:0] delta_x_saved;
	reg signed [32:0] delta_y_saved;
	reg signed [65:0] start_value_saved;
	reg signed [66:0] denominator_saved;
	reg [66:0] denominator_magnitude_saved;
	reg [67:0] remainder_saved;
	reg [29:0] quotient_saved;
	reg [4:0] division_count;
	reg [30:0] ratio_result;
	reg signed [64:0] product_saved;
	reg signed [33:0] x_candidate_saved;
	reg signed [33:0] y_candidate_saved;
	reg done_result;
	reg protocol_error_result;
	reg intersection_valid_result;
	reg parallel_result;
	reg arithmetic_saturated_result;
	reg signed [31:0] intersection_x_result;
	reg signed [31:0] intersection_y_result;

	wire [66:0] denominator_magnitude;
	wire [66:0] start_magnitude;
	wire ratio_sign_negative;
	wire [67:0] remainder_shifted;
	wire remainder_subtract;
	wire signed [64:0] rounded_product;
	wire x_overflow_high;
	wire x_overflow_low;
	wire y_overflow_high;
	wire y_overflow_low;

	assign denominator_magnitude = denominator_saved[66] ?
		(~denominator_saved[66:0] + 1'b1) : denominator_saved[66:0];
	assign start_magnitude = start_value_saved[65] ?
		(~{start_value_saved[65], start_value_saved} + 1'b1) :
		{start_value_saved[65], start_value_saved};
	assign ratio_sign_negative = start_value_saved[65] ^ denominator_saved[66];
	assign remainder_shifted = remainder_saved << 1;
	assign remainder_subtract =
		(remainder_shifted >= {1'b0, denominator_magnitude_saved});
	assign rounded_product = product_saved[64] ?
		-(((-product_saved) + 65'sd536870912) >>> 30) :
		((product_saved + 65'sd536870912) >>> 30);
	assign x_overflow_high = (x_candidate_saved > 34'sd2147483647);
	assign x_overflow_low = (x_candidate_saved < -34'sd2147483648);
	assign y_overflow_high = (y_candidate_saved > 34'sd2147483647);
	assign y_overflow_low = (y_candidate_saved < -34'sd2147483648);

	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign intersection_valid_o = intersection_valid_result;
	assign parallel_o = parallel_result;
	assign arithmetic_saturated_o = arithmetic_saturated_result;
	assign ratio_q2_30_o = ratio_result;
	assign intersection_x_o = intersection_x_result;
	assign intersection_y_o = intersection_y_result;

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
					state_next = STATE_CHECK;
				end
			end
			STATE_CHECK: begin
				if(denominator_magnitude <= C_EPS_DENOMINATOR) begin
					state_next = STATE_PARALLEL;
				end else if((start_value_saved == 66'sd0) ||
					(ratio_sign_negative == 1'b1) ||
					(start_magnitude >= denominator_magnitude)) begin
					state_next = STATE_MUL_X;
				end else begin
					state_next = STATE_DIVIDE;
				end
			end
			STATE_DIVIDE: begin
				if(division_count == 5'd29) begin
					state_next = STATE_ROUND_RATIO;
				end
			end
			STATE_ROUND_RATIO: state_next = STATE_MUL_X;
			STATE_MUL_X: state_next = STATE_ROUND_X;
			STATE_ROUND_X: state_next = STATE_MUL_Y;
			STATE_MUL_Y: state_next = STATE_ROUND_Y;
			STATE_ROUND_Y: state_next = STATE_OUTPUT;
			STATE_OUTPUT: state_next = STATE_IDLE;
			STATE_PARALLEL: state_next = STATE_IDLE;
			default: state_next = STATE_IDLE;
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			start_x_saved <= 32'sd0;
			start_y_saved <= 32'sd0;
			delta_x_saved <= 33'sd0;
			delta_y_saved <= 33'sd0;
			start_value_saved <= 66'sd0;
			denominator_saved <= 67'sd0;
			denominator_magnitude_saved <= 67'd0;
			remainder_saved <= 68'd0;
			quotient_saved <= 30'd0;
			division_count <= 5'd0;
			ratio_result <= 31'd0;
			product_saved <= 65'sd0;
			x_candidate_saved <= 34'sd0;
			y_candidate_saved <= 34'sd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			intersection_valid_result <= 1'b0;
			parallel_result <= 1'b0;
			arithmetic_saturated_result <= 1'b0;
			intersection_x_result <= 32'sd0;
			intersection_y_result <= 32'sd0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			intersection_valid_result <= 1'b0;
			parallel_result <= 1'b0;
			arithmetic_saturated_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					if(start_i == 1'b1) begin
						start_x_saved <= start_x_i;
						start_y_saved <= start_y_i;
						delta_x_saved <= {end_x_i[31], end_x_i} - {start_x_i[31], start_x_i};
						delta_y_saved <= {end_y_i[31], end_y_i} - {start_y_i[31], start_y_i};
						start_value_saved <= start_value_i;
						denominator_saved <=
							{start_value_i[65], start_value_i} -
							{end_value_i[65], end_value_i};
					end
				end
				STATE_CHECK: begin
					denominator_magnitude_saved <= denominator_magnitude;
					remainder_saved <= {1'b0, start_magnitude};
					quotient_saved <= 30'd0;
					division_count <= 5'd0;
					if((start_value_saved == 66'sd0) || (ratio_sign_negative == 1'b1)) begin
						ratio_result <= 31'd0;
					end else if(start_magnitude >= denominator_magnitude) begin
						ratio_result <= 31'h40000000;
					end
				end
				STATE_DIVIDE: begin
					if(remainder_subtract == 1'b1) begin
						remainder_saved <= remainder_shifted -
							{1'b0, denominator_magnitude_saved};
						quotient_saved <= {quotient_saved[28:0], 1'b1};
					end else begin
						remainder_saved <= remainder_shifted;
						quotient_saved <= {quotient_saved[28:0], 1'b0};
					end
					if(division_count != 5'd29) begin
						division_count <= division_count + 1'b1;
					end
				end
				STATE_ROUND_RATIO: begin
					if((remainder_saved << 1) >=
						{1'b0, denominator_magnitude_saved}) begin
						ratio_result <= {1'b0, quotient_saved} + 1'b1;
					end else begin
						ratio_result <= {1'b0, quotient_saved};
					end
				end
				STATE_MUL_X: begin
					product_saved <= $signed({1'b0, ratio_result}) * delta_x_saved;
				end
				STATE_ROUND_X: begin
					x_candidate_saved <=
						{{2{start_x_saved[31]}}, start_x_saved} +
						{{1{rounded_product[32]}}, rounded_product[32:0]};
				end
				STATE_MUL_Y: begin
					product_saved <= $signed({1'b0, ratio_result}) * delta_y_saved;
				end
				STATE_ROUND_Y: begin
					y_candidate_saved <=
						{{2{start_y_saved[31]}}, start_y_saved} +
						{{1{rounded_product[32]}}, rounded_product[32:0]};
				end
				STATE_OUTPUT: begin
					if(x_overflow_high == 1'b1) begin
						intersection_x_result <= 32'sh7FFFFFFF;
					end else if(x_overflow_low == 1'b1) begin
						intersection_x_result <= 32'sh80000000;
					end else begin
						intersection_x_result <= x_candidate_saved[31:0];
					end
					if(y_overflow_high == 1'b1) begin
						intersection_y_result <= 32'sh7FFFFFFF;
					end else if(y_overflow_low == 1'b1) begin
						intersection_y_result <= 32'sh80000000;
					end else begin
						intersection_y_result <= y_candidate_saved[31:0];
					end
					arithmetic_saturated_result <= x_overflow_high || x_overflow_low ||
						y_overflow_high || y_overflow_low;
					intersection_valid_result <= 1'b1;
					done_result <= 1'b1;
				end
				STATE_PARALLEL: begin
					parallel_result <= 1'b1;
					done_result <= 1'b1;
				end
				default: ratio_result <= 31'd0;
			endcase
		end
	end

endmodule
