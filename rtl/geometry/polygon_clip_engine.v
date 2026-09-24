`timescale 1ns / 1ps

// 顺序扫描双缓冲顶点RAM并执行一次Sutherland-Hodgman半平面裁剪
module polygon_clip_engine
#(
	parameter [10:0] C_MAXIMUM_VERTEX_COUNT = 11'd1024
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire input_buffer_i,
	input wire [10:0] input_vertex_count_i,
	input wire signed [31:0] coefficient_a_i,
	input wire signed [31:0] coefficient_b_i,
	input wire signed [65:0] constant_c_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire output_buffer_o,
	output wire [10:0] output_vertex_count_o,
	output wire empty_o,
	output wire result_trusted_o,
	output wire parallel_edge_o,
	output wire arithmetic_saturated_o,
	output wire capacity_overflow_o,
	output wire quantization_margin_used_o,
	output wire residual_violation_o,
	output wire ram_read_enable_o,
	output wire ram_read_buffer_o,
	output wire [9:0] ram_read_address_o,
	input wire [63:0] ram_read_data_i,
	input wire ram_read_valid_i,
	output wire ram_write_enable_o,
	output wire ram_write_buffer_o,
	output wire [9:0] ram_write_address_o,
	output wire [63:0] ram_write_data_o
);

	localparam [4:0] STATE_IDLE = 5'd0;
	localparam [4:0] STATE_READ_START_REQUEST = 5'd1;
	localparam [4:0] STATE_READ_START_WAIT = 5'd2;
	localparam [4:0] STATE_CLASSIFY_START_BEGIN = 5'd3;
	localparam [4:0] STATE_CLASSIFY_START_WAIT = 5'd4;
	localparam [4:0] STATE_READ_END_REQUEST = 5'd5;
	localparam [4:0] STATE_READ_END_WAIT = 5'd6;
	localparam [4:0] STATE_CLASSIFY_END_BEGIN = 5'd7;
	localparam [4:0] STATE_CLASSIFY_END_WAIT = 5'd8;
	localparam [4:0] STATE_DECIDE = 5'd9;
	localparam [4:0] STATE_INTERSECTION_BEGIN = 5'd10;
	localparam [4:0] STATE_INTERSECTION_WAIT = 5'd11;
	localparam [4:0] STATE_RECHECK_BEGIN = 5'd12;
	localparam [4:0] STATE_RECHECK_WAIT = 5'd13;
	localparam [4:0] STATE_EMIT_FIRST = 5'd14;
	localparam [4:0] STATE_EMIT_SECOND = 5'd15;
	localparam [4:0] STATE_ADVANCE = 5'd16;
	localparam [4:0] STATE_FINISH = 5'd17;

	reg [4:0] state_current;
	reg [4:0] state_next;
	reg input_buffer_saved;
	reg [10:0] input_vertex_count_saved;
	reg signed [31:0] coefficient_a_saved;
	reg signed [31:0] coefficient_b_saved;
	reg signed [65:0] constant_c_saved;
	reg [10:0] edge_index_saved;
	reg signed [31:0] start_x_saved;
	reg signed [31:0] start_y_saved;
	reg signed [31:0] end_x_saved;
	reg signed [31:0] end_y_saved;
	reg signed [65:0] start_value_saved;
	reg signed [65:0] end_value_saved;
	reg start_inside_saved;
	reg end_inside_saved;
	reg signed [31:0] first_candidate_x_saved;
	reg signed [31:0] first_candidate_y_saved;
	reg signed [31:0] second_candidate_x_saved;
	reg signed [31:0] second_candidate_y_saved;
	reg second_candidate_valid_saved;
	reg signed [31:0] first_written_x_saved;
	reg signed [31:0] first_written_y_saved;
	reg signed [31:0] last_written_x_saved;
	reg signed [31:0] last_written_y_saved;
	reg [10:0] output_count_saved;
	reg done_result;
	reg protocol_error_result;
	reg output_buffer_result;
	reg [10:0] output_vertex_count_result;
	reg empty_result;
	reg parallel_edge_result;
	reg arithmetic_saturated_result;
	reg capacity_overflow_result;
	reg quantization_margin_result;
	reg residual_violation_result;

	wire classifier_start;
	wire classifier_busy;
	wire signed [31:0] classifier_point_x;
	wire signed [31:0] classifier_point_y;
	wire classifier_done;
	wire classifier_protocol_error;
	wire signed [65:0] classifier_function_value;
	wire classifier_inside;
	wire classifier_margin_used;
	wire classifier_saturated;
	wire intersection_start;
	wire intersection_busy;
	wire intersection_done;
	wire intersection_protocol_error;
	wire intersection_valid;
	wire intersection_parallel;
	wire intersection_saturated;
	wire [30:0] intersection_ratio;
	wire signed [31:0] intersection_x;
	wire signed [31:0] intersection_y;
	wire first_candidate_duplicate;
	wire second_candidate_duplicate;
	wire closing_duplicate;
	wire first_candidate_writable;
	wire second_candidate_writable;

	assign classifier_start = (state_current == STATE_CLASSIFY_START_BEGIN) ||
		(state_current == STATE_CLASSIFY_END_BEGIN) ||
		(state_current == STATE_RECHECK_BEGIN);
	assign classifier_point_x = (state_current == STATE_CLASSIFY_START_BEGIN) ?
		start_x_saved : ((state_current == STATE_CLASSIFY_END_BEGIN) ?
		end_x_saved : first_candidate_x_saved);
	assign classifier_point_y = (state_current == STATE_CLASSIFY_START_BEGIN) ?
		start_y_saved : ((state_current == STATE_CLASSIFY_END_BEGIN) ?
		end_y_saved : first_candidate_y_saved);
	assign intersection_start = (state_current == STATE_INTERSECTION_BEGIN);

	assign first_candidate_duplicate = (output_count_saved != 11'd0) &&
		(first_candidate_x_saved == last_written_x_saved) &&
		(first_candidate_y_saved == last_written_y_saved);
	assign second_candidate_duplicate = (output_count_saved != 11'd0) &&
		(second_candidate_x_saved == last_written_x_saved) &&
		(second_candidate_y_saved == last_written_y_saved);
	assign closing_duplicate = (output_count_saved > 11'd1) &&
		(first_written_x_saved == last_written_x_saved) &&
		(first_written_y_saved == last_written_y_saved);
	assign first_candidate_writable = (state_current == STATE_EMIT_FIRST) &&
		(first_candidate_duplicate == 1'b0) &&
		(output_count_saved < C_MAXIMUM_VERTEX_COUNT);
	assign second_candidate_writable = (state_current == STATE_EMIT_SECOND) &&
		(second_candidate_duplicate == 1'b0) &&
		(output_count_saved < C_MAXIMUM_VERTEX_COUNT);

	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign output_buffer_o = output_buffer_result;
	assign output_vertex_count_o = output_vertex_count_result;
	assign empty_o = empty_result;
	assign parallel_edge_o = parallel_edge_result;
	assign arithmetic_saturated_o = arithmetic_saturated_result;
	assign capacity_overflow_o = capacity_overflow_result;
	assign quantization_margin_used_o = quantization_margin_result;
	assign residual_violation_o = residual_violation_result;
	assign result_trusted_o = ~(parallel_edge_result || arithmetic_saturated_result ||
		capacity_overflow_result || residual_violation_result);
	assign ram_read_enable_o = (state_current == STATE_READ_START_REQUEST) ||
		(state_current == STATE_READ_END_REQUEST);
	assign ram_read_buffer_o = input_buffer_saved;
	assign ram_read_address_o = (state_current == STATE_READ_START_REQUEST) ?
		(input_vertex_count_saved[9:0] - 1'b1) : edge_index_saved[9:0];
	assign ram_write_enable_o = first_candidate_writable || second_candidate_writable;
	assign ram_write_buffer_o = ~input_buffer_saved;
	assign ram_write_address_o = output_count_saved[9:0];
	assign ram_write_data_o = first_candidate_writable ?
		{first_candidate_x_saved, first_candidate_y_saved} :
		{second_candidate_x_saved, second_candidate_y_saved};

	halfplane_classifier classifier_instance
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(classifier_start),
		.point_x_i(classifier_point_x),
		.point_y_i(classifier_point_y),
		.coefficient_a_i(coefficient_a_saved),
		.coefficient_b_i(coefficient_b_saved),
		.constant_c_i(constant_c_saved),
		.busy_o(classifier_busy),
		.done_o(classifier_done),
		.protocol_error_o(classifier_protocol_error),
		.function_value_o(classifier_function_value),
		.inside_o(classifier_inside),
		.margin_used_o(classifier_margin_used),
		.arithmetic_saturated_o(classifier_saturated)
	);

	segment_intersection intersection_instance
	(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.start_i(intersection_start),
		.start_x_i(start_x_saved),
		.start_y_i(start_y_saved),
		.end_x_i(end_x_saved),
		.end_y_i(end_y_saved),
		.start_value_i(start_value_saved),
		.end_value_i(end_value_saved),
		.busy_o(intersection_busy),
		.done_o(intersection_done),
		.protocol_error_o(intersection_protocol_error),
		.intersection_valid_o(intersection_valid),
		.parallel_o(intersection_parallel),
		.arithmetic_saturated_o(intersection_saturated),
		.ratio_q2_30_o(intersection_ratio),
		.intersection_x_o(intersection_x),
		.intersection_y_o(intersection_y)
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
					if((input_vertex_count_i == 11'd0) ||
						(input_vertex_count_i > C_MAXIMUM_VERTEX_COUNT)) begin
						state_next = STATE_FINISH;
					end else begin
						state_next = STATE_READ_START_REQUEST;
					end
				end
			end
			STATE_READ_START_REQUEST: state_next = STATE_READ_START_WAIT;
			STATE_READ_START_WAIT: begin
				if(ram_read_valid_i == 1'b1) begin
					state_next = STATE_CLASSIFY_START_BEGIN;
				end
			end
			STATE_CLASSIFY_START_BEGIN: state_next = STATE_CLASSIFY_START_WAIT;
			STATE_CLASSIFY_START_WAIT: begin
				if(classifier_done == 1'b1) begin
					if(classifier_saturated == 1'b1) begin
						state_next = STATE_FINISH;
					end else begin
						state_next = STATE_READ_END_REQUEST;
					end
				end
			end
			STATE_READ_END_REQUEST: state_next = STATE_READ_END_WAIT;
			STATE_READ_END_WAIT: begin
				if(ram_read_valid_i == 1'b1) begin
					state_next = STATE_CLASSIFY_END_BEGIN;
				end
			end
			STATE_CLASSIFY_END_BEGIN: state_next = STATE_CLASSIFY_END_WAIT;
			STATE_CLASSIFY_END_WAIT: begin
				if(classifier_done == 1'b1) begin
					if(classifier_saturated == 1'b1) begin
						state_next = STATE_FINISH;
					end else begin
						state_next = STATE_DECIDE;
					end
				end
			end
			STATE_DECIDE: begin
				if(start_inside_saved == end_inside_saved) begin
					if(end_inside_saved == 1'b1) begin
						state_next = STATE_EMIT_FIRST;
					end else begin
						state_next = STATE_ADVANCE;
					end
				end else begin
					state_next = STATE_INTERSECTION_BEGIN;
				end
			end
			STATE_INTERSECTION_BEGIN: state_next = STATE_INTERSECTION_WAIT;
			STATE_INTERSECTION_WAIT: begin
				if(intersection_done == 1'b1) begin
					if(intersection_parallel == 1'b1) begin
						state_next = STATE_EMIT_FIRST;
					end else if(intersection_valid == 1'b1) begin
						state_next = STATE_RECHECK_BEGIN;
					end else begin
						state_next = STATE_FINISH;
					end
				end
			end
			STATE_RECHECK_BEGIN: state_next = STATE_RECHECK_WAIT;
			STATE_RECHECK_WAIT: begin
				if(classifier_done == 1'b1) begin
					if(classifier_saturated == 1'b1) begin
						state_next = STATE_FINISH;
					end else begin
						state_next = STATE_EMIT_FIRST;
					end
				end
			end
			STATE_EMIT_FIRST: begin
				if((first_candidate_duplicate == 1'b0) &&
					(output_count_saved >= C_MAXIMUM_VERTEX_COUNT)) begin
					state_next = STATE_FINISH;
				end else if(second_candidate_valid_saved == 1'b1) begin
					state_next = STATE_EMIT_SECOND;
				end else begin
					state_next = STATE_ADVANCE;
				end
			end
			STATE_EMIT_SECOND: begin
				if((second_candidate_duplicate == 1'b0) &&
					(output_count_saved >= C_MAXIMUM_VERTEX_COUNT)) begin
					state_next = STATE_FINISH;
				end else begin
					state_next = STATE_ADVANCE;
				end
			end
			STATE_ADVANCE: begin
				if((edge_index_saved + 1'b1) >= input_vertex_count_saved) begin
					state_next = STATE_FINISH;
				end else begin
					state_next = STATE_READ_END_REQUEST;
				end
			end
			STATE_FINISH: state_next = STATE_IDLE;
			default: state_next = STATE_IDLE;
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			input_buffer_saved <= 1'b0;
			input_vertex_count_saved <= 11'd0;
			coefficient_a_saved <= 32'sd0;
			coefficient_b_saved <= 32'sd0;
			constant_c_saved <= 66'sd0;
			edge_index_saved <= 11'd0;
			start_x_saved <= 32'sd0;
			start_y_saved <= 32'sd0;
			end_x_saved <= 32'sd0;
			end_y_saved <= 32'sd0;
			start_value_saved <= 66'sd0;
			end_value_saved <= 66'sd0;
			start_inside_saved <= 1'b0;
			end_inside_saved <= 1'b0;
			first_candidate_x_saved <= 32'sd0;
			first_candidate_y_saved <= 32'sd0;
			second_candidate_x_saved <= 32'sd0;
			second_candidate_y_saved <= 32'sd0;
			second_candidate_valid_saved <= 1'b0;
			first_written_x_saved <= 32'sd0;
			first_written_y_saved <= 32'sd0;
			last_written_x_saved <= 32'sd0;
			last_written_y_saved <= 32'sd0;
			output_count_saved <= 11'd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			output_buffer_result <= 1'b0;
			output_vertex_count_result <= 11'd0;
			empty_result <= 1'b1;
			parallel_edge_result <= 1'b0;
			arithmetic_saturated_result <= 1'b0;
			capacity_overflow_result <= 1'b0;
			quantization_margin_result <= 1'b0;
			residual_violation_result <= 1'b0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					if(start_i == 1'b1) begin
						input_buffer_saved <= input_buffer_i;
						input_vertex_count_saved <= input_vertex_count_i;
						coefficient_a_saved <= coefficient_a_i;
						coefficient_b_saved <= coefficient_b_i;
						constant_c_saved <= constant_c_i;
						edge_index_saved <= 11'd0;
						output_count_saved <= 11'd0;
						output_buffer_result <= ~input_buffer_i;
						output_vertex_count_result <= 11'd0;
						empty_result <= 1'b1;
						parallel_edge_result <= 1'b0;
						arithmetic_saturated_result <= 1'b0;
						capacity_overflow_result <=
							(input_vertex_count_i > C_MAXIMUM_VERTEX_COUNT);
						quantization_margin_result <= 1'b0;
						residual_violation_result <= 1'b0;
					end
				end
				STATE_READ_START_WAIT: begin
					if(ram_read_valid_i == 1'b1) begin
						start_x_saved <= ram_read_data_i[63:32];
						start_y_saved <= ram_read_data_i[31:0];
					end
				end
				STATE_CLASSIFY_START_WAIT: begin
					if(classifier_done == 1'b1) begin
						start_value_saved <= classifier_function_value;
						start_inside_saved <= classifier_inside;
						quantization_margin_result <= quantization_margin_result ||
							classifier_margin_used;
						arithmetic_saturated_result <= arithmetic_saturated_result ||
							classifier_saturated || classifier_protocol_error;
					end
				end
				STATE_READ_END_WAIT: begin
					if(ram_read_valid_i == 1'b1) begin
						end_x_saved <= ram_read_data_i[63:32];
						end_y_saved <= ram_read_data_i[31:0];
					end
				end
				STATE_CLASSIFY_END_WAIT: begin
					if(classifier_done == 1'b1) begin
						end_value_saved <= classifier_function_value;
						end_inside_saved <= classifier_inside;
						quantization_margin_result <= quantization_margin_result ||
							classifier_margin_used;
						arithmetic_saturated_result <= arithmetic_saturated_result ||
							classifier_saturated || classifier_protocol_error;
					end
				end
				STATE_DECIDE: begin
					second_candidate_valid_saved <= 1'b0;
					if((start_inside_saved == 1'b1) && (end_inside_saved == 1'b1)) begin
						first_candidate_x_saved <= end_x_saved;
						first_candidate_y_saved <= end_y_saved;
					end
				end
				STATE_INTERSECTION_WAIT: begin
					if(intersection_done == 1'b1) begin
						parallel_edge_result <= parallel_edge_result || intersection_parallel;
						arithmetic_saturated_result <= arithmetic_saturated_result ||
							intersection_saturated || intersection_protocol_error;
						if(intersection_parallel == 1'b1) begin
							if(start_inside_saved == 1'b1) begin
								first_candidate_x_saved <= start_x_saved;
								first_candidate_y_saved <= start_y_saved;
							end else begin
								first_candidate_x_saved <= end_x_saved;
								first_candidate_y_saved <= end_y_saved;
							end
							second_candidate_valid_saved <= 1'b0;
						end else if(intersection_valid == 1'b1) begin
							first_candidate_x_saved <= intersection_x;
							first_candidate_y_saved <= intersection_y;
							second_candidate_x_saved <= end_x_saved;
							second_candidate_y_saved <= end_y_saved;
							second_candidate_valid_saved <= ~start_inside_saved;
						end else begin
							residual_violation_result <= 1'b1;
						end
					end
				end
				STATE_RECHECK_WAIT: begin
					if(classifier_done == 1'b1) begin
						quantization_margin_result <= quantization_margin_result ||
							classifier_margin_used;
						arithmetic_saturated_result <= arithmetic_saturated_result ||
							classifier_saturated || classifier_protocol_error;
						if(classifier_inside == 1'b0) begin
							residual_violation_result <= 1'b1;
						end
					end
				end
				STATE_EMIT_FIRST: begin
					if(first_candidate_writable == 1'b1) begin
						if(output_count_saved == 11'd0) begin
							first_written_x_saved <= first_candidate_x_saved;
							first_written_y_saved <= first_candidate_y_saved;
						end
						last_written_x_saved <= first_candidate_x_saved;
						last_written_y_saved <= first_candidate_y_saved;
						output_count_saved <= output_count_saved + 1'b1;
					end else if((first_candidate_duplicate == 1'b0) &&
						(output_count_saved >= C_MAXIMUM_VERTEX_COUNT)) begin
						capacity_overflow_result <= 1'b1;
					end
				end
				STATE_EMIT_SECOND: begin
					if(second_candidate_writable == 1'b1) begin
						if(output_count_saved == 11'd0) begin
							first_written_x_saved <= second_candidate_x_saved;
							first_written_y_saved <= second_candidate_y_saved;
						end
						last_written_x_saved <= second_candidate_x_saved;
						last_written_y_saved <= second_candidate_y_saved;
						output_count_saved <= output_count_saved + 1'b1;
					end else if((second_candidate_duplicate == 1'b0) &&
						(output_count_saved >= C_MAXIMUM_VERTEX_COUNT)) begin
						capacity_overflow_result <= 1'b1;
					end
				end
				STATE_ADVANCE: begin
					start_x_saved <= end_x_saved;
					start_y_saved <= end_y_saved;
					start_value_saved <= end_value_saved;
					start_inside_saved <= end_inside_saved;
					if((edge_index_saved + 1'b1) < input_vertex_count_saved) begin
						edge_index_saved <= edge_index_saved + 1'b1;
					end
				end
				STATE_FINISH: begin
					if(closing_duplicate == 1'b1) begin
						output_vertex_count_result <= output_count_saved - 1'b1;
						empty_result <= ((output_count_saved - 1'b1) == 11'd0);
					end else begin
						output_vertex_count_result <= output_count_saved;
						empty_result <= (output_count_saved == 11'd0);
					end
					done_result <= 1'b1;
				end
				default: begin
					residual_violation_result <= residual_violation_result;
				end
			endcase
		end
	end

endmodule
