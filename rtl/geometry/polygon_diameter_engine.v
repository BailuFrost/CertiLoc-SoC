`timescale 1ns / 1ps

// 使用双端口顶点RAM流水穷举所有i<j顶点对并保存最大距离平方
module polygon_diameter_engine
#(
	parameter [10:0] C_MAXIMUM_VERTEX_COUNT = 11'd1024
)
(
	input wire clk_i,
	input wire reset_i,
	input wire start_i,
	input wire vertex_buffer_i,
	input wire [10:0] vertex_count_i,
	output wire busy_o,
	output wire done_o,
	output wire protocol_error_o,
	output wire empty_o,
	output wire result_trusted_o,
	output wire arithmetic_saturated_o,
	output wire input_count_error_o,
	output wire [65:0] maximum_distance_squared_o,
	output wire [9:0] farthest_first_index_o,
	output wire [9:0] farthest_second_index_o,
	output wire [19:0] evaluated_pair_count_o,
	output wire ram_first_read_enable_o,
	output wire ram_first_read_buffer_o,
	output wire [9:0] ram_first_read_address_o,
	input wire [63:0] ram_first_read_data_i,
	input wire ram_first_read_valid_i,
	output wire ram_second_read_enable_o,
	output wire ram_second_read_buffer_o,
	output wire [9:0] ram_second_read_address_o,
	input wire [63:0] ram_second_read_data_i,
	input wire ram_second_read_valid_i
);

	localparam [1:0] STATE_IDLE = 2'd0;
	localparam [1:0] STATE_RUN = 2'd1;
	localparam [1:0] STATE_FINISH = 2'd2;

	reg [1:0] state_current;
	reg [1:0] state_next;
	reg vertex_buffer_saved;
	reg [10:0] vertex_count_saved;
	reg [9:0] issue_first_index_saved;
	reg [9:0] issue_second_index_saved;
	reg issue_active_saved;
	reg pending_valid_saved;
	reg pending_last_saved;
	reg [9:0] pending_first_index_saved;
	reg [9:0] pending_second_index_saved;
	reg difference_valid_saved;
	reg difference_last_saved;
	reg [9:0] difference_first_index_saved;
	reg [9:0] difference_second_index_saved;
	reg signed [32:0] difference_x_saved;
	reg signed [32:0] difference_y_saved;
	reg square_valid_saved;
	reg square_last_saved;
	reg [9:0] square_first_index_saved;
	reg [9:0] square_second_index_saved;
	reg [65:0] square_x_saved;
	reg [65:0] square_y_saved;
	reg done_result;
	reg protocol_error_result;
	reg empty_result;
	reg arithmetic_saturated_result;
	reg input_count_error_result;
	reg [65:0] maximum_distance_result;
	reg [9:0] farthest_first_index_result;
	reg [9:0] farthest_second_index_result;
	reg [19:0] evaluated_pair_count_result;

	wire [66:0] distance_sum_wide;
	wire distance_sum_overflow;
	wire issue_has_more_second_indices;
	wire issue_has_more_first_indices;
	wire issue_is_last_pair;

	assign distance_sum_wide = {1'b0, square_x_saved} + {1'b0, square_y_saved};
	assign distance_sum_overflow = distance_sum_wide[66];
	assign issue_has_more_second_indices =
		({1'b0, issue_second_index_saved} + 1'b1) < vertex_count_saved;
	assign issue_has_more_first_indices =
		({1'b0, issue_first_index_saved} + 2'd2) < vertex_count_saved;
	assign issue_is_last_pair = (issue_has_more_second_indices == 1'b0) &&
		(issue_has_more_first_indices == 1'b0);

	assign busy_o = (state_current != STATE_IDLE);
	assign done_o = done_result;
	assign protocol_error_o = protocol_error_result;
	assign empty_o = empty_result;
	assign arithmetic_saturated_o = arithmetic_saturated_result;
	assign input_count_error_o = input_count_error_result;
	assign result_trusted_o = ~(arithmetic_saturated_result || input_count_error_result);
	assign maximum_distance_squared_o = maximum_distance_result;
	assign farthest_first_index_o = farthest_first_index_result;
	assign farthest_second_index_o = farthest_second_index_result;
	assign evaluated_pair_count_o = evaluated_pair_count_result;
	assign ram_first_read_enable_o = (state_current == STATE_RUN) && issue_active_saved;
	assign ram_first_read_buffer_o = vertex_buffer_saved;
	assign ram_first_read_address_o = issue_first_index_saved;
	assign ram_second_read_enable_o = (state_current == STATE_RUN) && issue_active_saved;
	assign ram_second_read_buffer_o = vertex_buffer_saved;
	assign ram_second_read_address_o = issue_second_index_saved;

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
					if((vertex_count_i < 11'd2) ||
						(vertex_count_i > C_MAXIMUM_VERTEX_COUNT)) begin
						state_next = STATE_FINISH;
					end else begin
						state_next = STATE_RUN;
					end
				end
			end
			STATE_RUN: begin
				if((square_valid_saved == 1'b1) &&
					(square_last_saved == 1'b1)) begin
					state_next = STATE_FINISH;
				end
			end
			STATE_FINISH: state_next = STATE_IDLE;
			default: state_next = STATE_IDLE;
		endcase
	end

	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i == 1'b1) begin
			vertex_buffer_saved <= 1'b0;
			vertex_count_saved <= 11'd0;
			issue_first_index_saved <= 10'd0;
			issue_second_index_saved <= 10'd1;
			issue_active_saved <= 1'b0;
			pending_valid_saved <= 1'b0;
			pending_last_saved <= 1'b0;
			pending_first_index_saved <= 10'd0;
			pending_second_index_saved <= 10'd1;
			difference_valid_saved <= 1'b0;
			difference_last_saved <= 1'b0;
			difference_first_index_saved <= 10'd0;
			difference_second_index_saved <= 10'd1;
			difference_x_saved <= 33'sd0;
			difference_y_saved <= 33'sd0;
			square_valid_saved <= 1'b0;
			square_last_saved <= 1'b0;
			square_first_index_saved <= 10'd0;
			square_second_index_saved <= 10'd1;
			square_x_saved <= 66'd0;
			square_y_saved <= 66'd0;
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			empty_result <= 1'b1;
			arithmetic_saturated_result <= 1'b0;
			input_count_error_result <= 1'b0;
			maximum_distance_result <= 66'd0;
			farthest_first_index_result <= 10'd0;
			farthest_second_index_result <= 10'd0;
			evaluated_pair_count_result <= 20'd0;
		end else begin
			done_result <= 1'b0;
			protocol_error_result <= 1'b0;
			if((start_i == 1'b1) && (state_current != STATE_IDLE)) begin
				protocol_error_result <= 1'b1;
			end
			case(state_current)
				STATE_IDLE: begin
					pending_valid_saved <= 1'b0;
					difference_valid_saved <= 1'b0;
					square_valid_saved <= 1'b0;
					issue_active_saved <= 1'b0;
					if(start_i == 1'b1) begin
						vertex_buffer_saved <= vertex_buffer_i;
						vertex_count_saved <= vertex_count_i;
						issue_first_index_saved <= 10'd0;
						issue_second_index_saved <= 10'd1;
						issue_active_saved <= (vertex_count_i >= 11'd2) &&
							(vertex_count_i <= C_MAXIMUM_VERTEX_COUNT);
						empty_result <= (vertex_count_i == 11'd0);
						arithmetic_saturated_result <= 1'b0;
						input_count_error_result <=
							(vertex_count_i > C_MAXIMUM_VERTEX_COUNT);
						maximum_distance_result <= 66'd0;
						if(vertex_count_i >= 11'd2) begin
							farthest_first_index_result <= 10'd0;
							farthest_second_index_result <= 10'd1;
						end else begin
							farthest_first_index_result <= 10'd0;
							farthest_second_index_result <= 10'd0;
						end
						evaluated_pair_count_result <= 20'd0;
					end
				end
				STATE_RUN: begin
					pending_valid_saved <= issue_active_saved;
					if(issue_active_saved == 1'b1) begin
						pending_first_index_saved <= issue_first_index_saved;
						pending_second_index_saved <= issue_second_index_saved;
						pending_last_saved <= issue_is_last_pair;
						if(issue_has_more_second_indices == 1'b1) begin
							issue_second_index_saved <= issue_second_index_saved + 1'b1;
						end else if(issue_has_more_first_indices == 1'b1) begin
							issue_first_index_saved <= issue_first_index_saved + 1'b1;
							issue_second_index_saved <= issue_first_index_saved + 2'd2;
						end else begin
							issue_active_saved <= 1'b0;
						end
					end

					difference_valid_saved <= ram_first_read_valid_i &&
						ram_second_read_valid_i && pending_valid_saved;
					if((ram_first_read_valid_i == 1'b1) &&
						(ram_second_read_valid_i == 1'b1) &&
						(pending_valid_saved == 1'b1)) begin
						difference_x_saved <=
							{ram_first_read_data_i[63], ram_first_read_data_i[63:32]} -
							{ram_second_read_data_i[63], ram_second_read_data_i[63:32]};
						difference_y_saved <=
							{ram_first_read_data_i[31], ram_first_read_data_i[31:0]} -
							{ram_second_read_data_i[31], ram_second_read_data_i[31:0]};
						difference_first_index_saved <= pending_first_index_saved;
						difference_second_index_saved <= pending_second_index_saved;
						difference_last_saved <= pending_last_saved;
					end

					square_valid_saved <= difference_valid_saved;
					if(difference_valid_saved == 1'b1) begin
						square_x_saved <= difference_x_saved * difference_x_saved;
						square_y_saved <= difference_y_saved * difference_y_saved;
						square_first_index_saved <= difference_first_index_saved;
						square_second_index_saved <= difference_second_index_saved;
						square_last_saved <= difference_last_saved;
					end

					if(square_valid_saved == 1'b1) begin
						if(distance_sum_overflow == 1'b1) begin
							maximum_distance_result <= {66{1'b1}};
							farthest_first_index_result <= square_first_index_saved;
							farthest_second_index_result <= square_second_index_saved;
							arithmetic_saturated_result <= 1'b1;
						end else if(distance_sum_wide[65:0] > maximum_distance_result) begin
							maximum_distance_result <= distance_sum_wide[65:0];
							farthest_first_index_result <= square_first_index_saved;
							farthest_second_index_result <= square_second_index_saved;
						end
						evaluated_pair_count_result <= evaluated_pair_count_result + 1'b1;
					end
				end
				STATE_FINISH: begin
					done_result <= 1'b1;
				end
				default: begin
					maximum_distance_result <= maximum_distance_result;
				end
			endcase
		end
	end

endmodule
