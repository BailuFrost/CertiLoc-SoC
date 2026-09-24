`timescale 1ns / 1ps

// ============================================================================
// 模块名称: bearing_constraint_gen
// Module Name: bearing_constraint_gen
// 功能说明: 将一条示向观测转换为上下两条定点半平面约束
// Description: Convert one bearing observation into two fixed-point half-planes
// ============================================================================
module bearing_constraint_gen
#(
	parameter [17:0] C_BEARING_DELTA_PHASE = 18'd732
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire signed [31:0] sensor_x_i,
	input wire signed [31:0] sensor_y_i,
	input wire [17:0] bearing_phase_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire constraint_valid_o,
	output wire constraint_upper_o,
	output wire signed [31:0] coefficient_a_o,
	output wire signed [31:0] coefficient_b_o,
	output wire signed [65:0] constant_c_o
);

	localparam [3:0] STATE_IDLE = 4'd0;
	localparam [3:0] STATE_START_LOWER = 4'd1;
	localparam [3:0] STATE_WAIT_LOWER = 4'd2;
	localparam [3:0] STATE_START_UPPER = 4'd3;
	localparam [3:0] STATE_LOWER_MUL_X = 4'd4;
	localparam [3:0] STATE_LOWER_MUL_Y = 4'd5;
	localparam [3:0] STATE_LOWER_OUTPUT = 4'd6;
	localparam [3:0] STATE_WAIT_UPPER = 4'd7;
	localparam [3:0] STATE_UPPER_MUL_X = 4'd8;
	localparam [3:0] STATE_UPPER_MUL_Y = 4'd9;
	localparam [3:0] STATE_UPPER_OUTPUT = 4'd10;

	reg [3:0] state_current;
	reg [3:0] state_next;
	reg signed [31:0] sensor_x_saved;
	reg signed [31:0] sensor_y_saved;
	reg [17:0] lower_phase_saved;
	reg [17:0] upper_phase_saved;
	reg signed [31:0] lower_a_saved;
	reg signed [31:0] lower_b_saved;
	reg signed [31:0] upper_a_saved;
	reg signed [31:0] upper_b_saved;
	reg signed [31:0] multiplier_factor_a_saved;
	reg signed [31:0] multiplier_factor_b_saved;
	reg signed [63:0] multiplier_product_saved;
	reg signed [63:0] product_x_saved;
	reg done_result;
	reg protocol_error_result;
	reg constraint_valid_result;
	reg constraint_upper_result;
	reg signed [31:0] coefficient_a_result;
	reg signed [31:0] coefficient_b_result;
	reg signed [65:0] constant_c_result;

	wire cordic_start;
	wire [17:0] cordic_phase;
	wire cordic_busy;
	wire cordic_done;
	wire cordic_protocol_error;
	wire signed [31:0] cordic_sine;
	wire signed [31:0] cordic_cosine;
	(* use_dsp = "yes" *) wire signed [63:0] multiplier_product;
	wire signed [64:0] product_sum;

	assign cordic_start = (state_current == STATE_START_LOWER) ||
		(state_current == STATE_START_UPPER);
	assign cordic_phase = (state_current == STATE_START_UPPER) ?
		upper_phase_saved : lower_phase_saved;
	assign multiplier_product = multiplier_factor_a_saved * multiplier_factor_b_saved;
	assign product_sum = {product_x_saved[63], product_x_saved} +
		{multiplier_product_saved[63], multiplier_product_saved};

	assign busy_o = (state_current != STATE_IDLE) || cordic_busy;
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign constraint_valid_o = constraint_valid_result;
	assign constraint_upper_o = constraint_upper_result;
	assign coefficient_a_o = coefficient_a_result;
	assign coefficient_b_o = coefficient_b_result;
	assign constant_c_o = constant_c_result;

	cordic_sincos cordic_sincos_instance
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(cordic_start),
		.phase_i(cordic_phase),
		.busy_o(cordic_busy),
		.done_o(cordic_done),
		.protocol_error_o(cordic_protocol_error),
		.sine_o(cordic_sine),
		.cosine_o(cordic_cosine)
	);

	// State register.
	always @(posedge clk_i) begin
		if(reset_i == 1'b1) begin
			state_current <= STATE_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	// The upper CORDIC launch overlaps lower-boundary multiplication.
	always @(*) begin
		state_next = state_current;
		case(state_current)
			STATE_IDLE: begin
				if(start_i == 1'b1) begin
					state_next = STATE_START_LOWER;
				end
			end
			STATE_START_LOWER: state_next = STATE_WAIT_LOWER;
			STATE_WAIT_LOWER: begin
				if(cordic_done == 1'b1) begin
					state_next = STATE_START_UPPER;
				end
			end
			STATE_START_UPPER: state_next = STATE_LOWER_MUL_X;
			STATE_LOWER_MUL_X: state_next = STATE_LOWER_MUL_Y;
			STATE_LOWER_MUL_Y: state_next = STATE_LOWER_OUTPUT;
			STATE_LOWER_OUTPUT: state_next = STATE_WAIT_UPPER;
			STATE_WAIT_UPPER: begin
				if(cordic_done == 1'b1) begin
					state_next = STATE_UPPER_MUL_X;
				end
			end
			STATE_UPPER_MUL_X: state_next = STATE_UPPER_MUL_Y;
			STATE_UPPER_MUL_Y: state_next = STATE_UPPER_OUTPUT;
			STATE_UPPER_OUTPUT: state_next = STATE_IDLE;
			default: state_next = STATE_IDLE;
		endcase
	end

	// Datapath emits the lower constraint first and the upper constraint second.
	always @(posedge clk_i) begin
		if(reset_i == 1'b1) begin
			sensor_x_saved <= 32'sd0;
			sensor_y_saved <= 32'sd0;
			lower_phase_saved <= 18'd0;
			upper_phase_saved <= 18'd0;
			lower_a_saved <= 32'sd0;
			lower_b_saved <= 32'sd0;
			upper_a_saved <= 32'sd0;
			upper_b_saved <= 32'sd0;
			multiplier_factor_a_saved <= 32'sd0;
			multiplier_factor_b_saved <= 32'sd0;
			multiplier_product_saved <= 64'sd0;
			product_x_saved <= 64'sd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			constraint_valid_result <= 1'b0;
			constraint_upper_result <= 1'b0;
			coefficient_a_result <= 32'sd0;
			coefficient_b_result <= 32'sd0;
			constant_c_result <= 66'sd0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			constraint_valid_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			if(cordic_protocol_error == 1'b1) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					if(start_i == 1'b1) begin
						sensor_x_saved <= sensor_x_i;
						sensor_y_saved <= sensor_y_i;
						lower_phase_saved <= bearing_phase_i - C_BEARING_DELTA_PHASE;
						upper_phase_saved <= bearing_phase_i + C_BEARING_DELTA_PHASE;
					end
				end
				STATE_WAIT_LOWER: begin
					if(cordic_done == 1'b1) begin
						lower_a_saved <= -cordic_sine;
						lower_b_saved <= cordic_cosine;
					end
				end
				STATE_START_UPPER: begin
					multiplier_factor_a_saved <= lower_a_saved;
					multiplier_factor_b_saved <= sensor_x_saved;
				end
				STATE_LOWER_MUL_X: begin
					multiplier_product_saved <= multiplier_product;
					multiplier_factor_a_saved <= lower_b_saved;
					multiplier_factor_b_saved <= sensor_y_saved;
				end
				STATE_LOWER_MUL_Y: begin
					product_x_saved <= multiplier_product_saved;
					multiplier_product_saved <= multiplier_product;
				end
				STATE_LOWER_OUTPUT: begin
					constraint_upper_result <= 1'b0;
					coefficient_a_result <= lower_a_saved;
					coefficient_b_result <= lower_b_saved;
					constant_c_result <= {product_sum[64], product_sum};
					constraint_valid_result <= 1'b1;
				end
				STATE_WAIT_UPPER: begin
					if(cordic_done == 1'b1) begin
						upper_a_saved <= cordic_sine;
						upper_b_saved <= -cordic_cosine;
						multiplier_factor_a_saved <= cordic_sine;
						multiplier_factor_b_saved <= sensor_x_saved;
					end
				end
				STATE_UPPER_MUL_X: begin
					multiplier_product_saved <= multiplier_product;
					multiplier_factor_a_saved <= upper_b_saved;
					multiplier_factor_b_saved <= sensor_y_saved;
				end
				STATE_UPPER_MUL_Y: begin
					product_x_saved <= multiplier_product_saved;
					multiplier_product_saved <= multiplier_product;
				end
				STATE_UPPER_OUTPUT: begin
					constraint_upper_result <= 1'b1;
					coefficient_a_result <= upper_a_saved;
					coefficient_b_result <= upper_b_saved;
					constant_c_result <= {product_sum[64], product_sum};
					constraint_valid_result <= 1'b1;
					done_result <= 1'b1;
				end
				default: product_x_saved <= product_x_saved;
			endcase
		end
	end

endmodule
