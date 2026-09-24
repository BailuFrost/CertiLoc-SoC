`timescale 1ns / 1ps

// 计算66位半平面函数并使用负容差完成内外分类
module halfplane_classifier
#(
	parameter signed [65:0] C_EPS_HALFPLANE = 66'sd1073741824
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire signed [31:0] point_x_i,
	input wire signed [31:0] point_y_i,
	input wire signed [31:0] coefficient_a_i,
	input wire signed [31:0] coefficient_b_i,
	input wire signed [65:0] constant_c_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire signed [65:0] function_value_o,
	output wire inside_o,
	output wire margin_used_o,
	output wire arithmetic_saturated_o
);

	localparam [2:0] STATE_IDLE = 3'd0;
	localparam [2:0] STATE_MUL_X = 3'd1;
	localparam [2:0] STATE_MUL_Y = 3'd2;
	localparam [2:0] STATE_SUM = 3'd3;
	localparam [2:0] STATE_OUTPUT = 3'd4;

	reg [2:0] state_current;
	reg [2:0] state_next;
	reg signed [31:0] point_x_saved;
	reg signed [31:0] point_y_saved;
	reg signed [31:0] coefficient_a_saved;
	reg signed [31:0] coefficient_b_saved;
	reg signed [65:0] constant_c_saved;
	reg signed [63:0] product_x_saved;
	reg signed [63:0] product_y_saved;
	reg signed [66:0] evaluation_saved;
	reg done_result;
	reg protocol_error_result;
	reg signed [65:0] function_value_result;
	reg inside_result;
	reg margin_used_result;
	reg arithmetic_saturated_result;

	wire signed [66:0] evaluation_combined;
	wire evaluation_overflow;

	assign evaluation_combined = {{3{product_x_saved[63]}}, product_x_saved} +
		{{3{product_y_saved[63]}}, product_y_saved} -
		{constant_c_saved[65], constant_c_saved};
	assign evaluation_overflow = evaluation_saved[66] ^ evaluation_saved[65];

	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign function_value_o = function_value_result;
	assign inside_o = inside_result;
	assign margin_used_o = margin_used_result;
	assign arithmetic_saturated_o = arithmetic_saturated_result;

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
					state_next = STATE_MUL_X;
				end
			end
			STATE_MUL_X: state_next = STATE_MUL_Y;
			STATE_MUL_Y: state_next = STATE_SUM;
			STATE_SUM: state_next = STATE_OUTPUT;
			STATE_OUTPUT: state_next = STATE_IDLE;
			default: state_next = STATE_IDLE;
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			point_x_saved <= 32'sd0;
			point_y_saved <= 32'sd0;
			coefficient_a_saved <= 32'sd0;
			coefficient_b_saved <= 32'sd0;
			constant_c_saved <= 66'sd0;
			product_x_saved <= 64'sd0;
			product_y_saved <= 64'sd0;
			evaluation_saved <= 67'sd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			function_value_result <= 66'sd0;
			inside_result <= 1'b0;
			margin_used_result <= 1'b0;
			arithmetic_saturated_result <= 1'b0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					if(start_i == 1'b1) begin
						point_x_saved <= point_x_i;
						point_y_saved <= point_y_i;
						coefficient_a_saved <= coefficient_a_i;
						coefficient_b_saved <= coefficient_b_i;
						constant_c_saved <= constant_c_i;
					end
				end
				STATE_MUL_X: product_x_saved <= coefficient_a_saved * point_x_saved;
				STATE_MUL_Y: product_y_saved <= coefficient_b_saved * point_y_saved;
				STATE_SUM: evaluation_saved <= evaluation_combined;
				STATE_OUTPUT: begin
					arithmetic_saturated_result <= evaluation_overflow;
					if(evaluation_overflow == 1'b1) begin
						if(evaluation_saved[66] == 1'b0) begin
							function_value_result <= {1'b0, {65{1'b1}}};
						end else begin
							function_value_result <= {1'b1, {65{1'b0}}};
						end
					end else begin
						function_value_result <= evaluation_saved[65:0];
					end
					inside_result <= (evaluation_saved >= -$signed({1'b0, C_EPS_HALFPLANE}));
					margin_used_result <=
						(evaluation_saved < 67'sd0) &&
						(evaluation_saved >= -$signed({1'b0, C_EPS_HALFPLANE}));
					done_result <= 1'b1;
				end
				default: evaluation_saved <= 67'sd0;
			endcase
		end
	end

endmodule
