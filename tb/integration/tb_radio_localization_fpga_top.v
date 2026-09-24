`timescale 1ns / 1ps

module tb_radio_localization_fpga_top;

	reg clk_100mhz_i;
	reg reset_btn_i;
	reg uart_rx_i;
	wire uart_tx_o;
	wire [3:0] status_led_o;
	wire debug_trigger_o;

	wire [7:0] monitor_uart_data;
	wire monitor_uart_valid;
	wire monitor_uart_ready;
	wire monitor_uart_frame_error;
	wire monitor_uart_busy;

	reg [7:0] request_payload [0:243];
	reg [7:0] response_payload [0:243];
	reg [7:0] serial_response_bytes [0:253];
	reg [7:0] captured_response_command;
	reg [15:0] captured_response_sequence;
	reg [7:0] captured_response_length;
	integer monitor_byte_count;
	integer failure_count;
	integer wait_count;
	integer index;
	reg saw_compute_led;

	radio_localization_fpga_top
	#(
		.C_UART_CLKS_PER_BIT(8),
		.C_UART_HALF_BIT_CLKS(4),
		.C_DECODER_TIMEOUT_CLKS(10000)
	)
	dut
	(
		.clk_100mhz_i(clk_100mhz_i),
		.reset_btn_i(reset_btn_i),
		.uart_rx_i(uart_rx_i),
		.uart_tx_o(uart_tx_o),
		.status_led_o(status_led_o),
		.debug_trigger_o(debug_trigger_o)
	);

	// The monitor independently decodes the DUT serial response and therefore checks CRC.
	uart_rx
	#(
		.C_CLKS_PER_BIT(8),
		.C_HALF_BIT_CLKS(4)
	)
	monitor_uart_rx
	(
		.i_clk(clk_100mhz_i),
		.i_reset(reset_btn_i),
		.i_uart_rx(uart_tx_o),
		.i_data_ready(1'b1),
		.o_data(monitor_uart_data),
		.o_data_valid(monitor_uart_valid),
		.o_frame_error(monitor_uart_frame_error),
		.o_busy(monitor_uart_busy)
	);
	assign monitor_uart_ready = 1'b1;

	always #5 clk_100mhz_i = ~clk_100mhz_i;

	always @(posedge clk_100mhz_i) begin
		if(status_led_o[2]) begin
			saw_compute_led <= 1'b1;
		end
		if(monitor_uart_valid) begin
			serial_response_bytes[monitor_byte_count] <= monitor_uart_data;
			monitor_byte_count <= monitor_byte_count + 1;
		end
	end

	function [15:0] crc_next_byte;
		input [15:0] crc_input;
		input [7:0] data_input;
		integer bit_index;
		reg [15:0] crc_work;
		begin
			crc_work = crc_input ^ {data_input, 8'd0};
			for(bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
				if(crc_work[15]) begin
					crc_work = (crc_work << 1) ^ 16'h1021;
				end else begin
					crc_work = crc_work << 1;
				end
			end
			crc_next_byte = crc_work;
		end
	endfunction

	task check_condition;
		input condition;
		input [8*112-1:0] message;
		begin
			if(condition !== 1'b1) begin
				$display("FAIL: %0s", message);
				failure_count = failure_count + 1;
			end
		end
	endtask

	task clear_request_payload;
		integer clear_index;
		begin
			for(clear_index = 0; clear_index < 244; clear_index = clear_index + 1) begin
				request_payload[clear_index] = 8'd0;
			end
		end
	endtask

	task send_uart_byte;
		input [7:0] byte_value;
		integer bit_number;
		begin
			@(negedge clk_100mhz_i);
			uart_rx_i = 1'b0;
			repeat(8) @(posedge clk_100mhz_i);
			for(bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
				@(negedge clk_100mhz_i);
				uart_rx_i = byte_value[bit_number];
				repeat(8) @(posedge clk_100mhz_i);
			end
			@(negedge clk_100mhz_i);
			uart_rx_i = 1'b1;
			repeat(8) @(posedge clk_100mhz_i);
		end
	endtask

	task send_protocol_frame;
		input [7:0] command_value;
		input [15:0] sequence_value;
		input [7:0] payload_length_value;
		input corrupt_crc;
		integer payload_number;
		reg [15:0] crc_value;
		begin
			monitor_byte_count = 0;
			crc_value = 16'hffff;
			crc_value = crc_next_byte(crc_value, 8'h01);
			crc_value = crc_next_byte(crc_value, command_value);
			crc_value = crc_next_byte(crc_value, sequence_value[7:0]);
			crc_value = crc_next_byte(crc_value, sequence_value[15:8]);
			crc_value = crc_next_byte(crc_value, payload_length_value);
			crc_value = crc_next_byte(crc_value, 8'd0);
			for(payload_number = 0; payload_number < payload_length_value;
				payload_number = payload_number + 1) begin
				crc_value = crc_next_byte(crc_value, request_payload[payload_number]);
			end
			send_uart_byte(8'ha5);
			send_uart_byte(8'h5a);
			send_uart_byte(8'h01);
			send_uart_byte(command_value);
			send_uart_byte(sequence_value[7:0]);
			send_uart_byte(sequence_value[15:8]);
			send_uart_byte(payload_length_value);
			send_uart_byte(8'd0);
			for(payload_number = 0; payload_number < payload_length_value;
				payload_number = payload_number + 1) begin
				send_uart_byte(request_payload[payload_number]);
			end
			send_uart_byte(crc_value[7:0] ^ {7'd0, corrupt_crc});
			send_uart_byte(crc_value[15:8]);
		end
	endtask

	task capture_response;
		integer payload_number;
		integer crc_number;
		integer expected_frame_length;
		reg [15:0] calculated_crc;
		reg [15:0] received_crc;
		begin
			wait_count = 0;
			while((monitor_byte_count < 8) && (wait_count < 100000)) begin
				@(posedge clk_100mhz_i);
				#1;
				wait_count = wait_count + 1;
			end
			check_condition(monitor_byte_count >= 8, "response header timeout");
			expected_frame_length = 10 + serial_response_bytes[6];
			while((monitor_byte_count < expected_frame_length) && (wait_count < 100000)) begin
				@(posedge clk_100mhz_i);
				#1;
				wait_count = wait_count + 1;
			end
			check_condition(monitor_byte_count >= expected_frame_length, "response body timeout");
			check_condition(serial_response_bytes[0] == 8'ha5 &&
				serial_response_bytes[1] == 8'h5a, "response SOF mismatch");
			check_condition(serial_response_bytes[2] == 8'h01, "response version mismatch");
			check_condition(serial_response_bytes[7] == 8'd0, "response length high byte is nonzero");
			calculated_crc = 16'hffff;
			for(crc_number = 2; crc_number < 8 + serial_response_bytes[6];
				crc_number = crc_number + 1) begin
				calculated_crc = crc_next_byte(calculated_crc, serial_response_bytes[crc_number]);
			end
			received_crc = {serial_response_bytes[9 + serial_response_bytes[6]],
				serial_response_bytes[8 + serial_response_bytes[6]]};
			check_condition(calculated_crc == received_crc, "response CRC mismatch");
			captured_response_command = serial_response_bytes[3];
			captured_response_sequence = {serial_response_bytes[5], serial_response_bytes[4]};
			captured_response_length = serial_response_bytes[6];
			for(payload_number = 0; payload_number < captured_response_length;
				payload_number = payload_number + 1) begin
				response_payload[payload_number] = serial_response_bytes[8 + payload_number];
			end
		end
	endtask

	task check_response_header;
		input [7:0] expected_command;
		input [15:0] expected_sequence;
		input [7:0] expected_length;
		begin
			check_condition(captured_response_command == expected_command,
				"response command mismatch");
			check_condition(captured_response_sequence == expected_sequence,
				"response sequence mismatch");
			check_condition(captured_response_length == expected_length,
				"response payload length mismatch");
		end
	endtask

	initial begin
		clk_100mhz_i = 1'b0;
		reset_btn_i = 1'b1;
		uart_rx_i = 1'b1;
		monitor_byte_count = 0;
		failure_count = 0;
		wait_count = 0;
		saw_compute_led = 1'b0;
		clear_request_payload;
		repeat(8) @(posedge clk_100mhz_i);
		reset_btn_i = 1'b0;
		repeat(8) @(posedge clk_100mhz_i);
		check_condition(status_led_o[0], "idle LED was not asserted after reset release");

		// GET_INFO proves the complete receive and response path before configuration.
		send_protocol_frame(8'h01, 16'h0001, 8'd0, 1'b0);
		capture_response;
		check_response_header(8'h81, 16'h0001, 8'd24);
		check_condition(response_payload[0] == 8'h01 && response_payload[1] == 8'hb3,
			"INFO device kind mismatch");
		check_condition(response_payload[3] == 8'h3f, "INFO capability flags mismatch");

		// A one-byte configuration mismatch must return PARAMETER_RANGE.
		clear_request_payload;
		request_payload[0] = 8'h01;
		request_payload[2] = 8'h08;
		request_payload[3] = 8'h07;
		request_payload[4] = 8'hdc;
		request_payload[5] = 8'h02;
		request_payload[11] = 8'h40;
		request_payload[19] = 8'h40;
		request_payload[24] = 8'hd0;
		request_payload[25] = 8'h02;
		request_payload[27] = 8'h04;
		send_protocol_frame(8'h10, 16'h0002, 8'd28, 1'b0);
		capture_response;
		check_response_header(8'hff, 16'h0002, 8'd8);
		check_condition(response_payload[0] == 8'h10 && response_payload[1] == 8'h06,
			"invalid SET_CONFIG error mismatch");
		check_condition(status_led_o[3], "error LED did not latch semantic payload error");

		// Submit the exact frozen configuration.
		request_payload[0] = 8'h00;
		send_protocol_frame(8'h10, 16'h0003, 8'd28, 1'b0);
		capture_response;
		check_response_header(8'h80, 16'h0003, 8'd4);
		check_condition(response_payload[0] == 8'h10 && response_payload[1] == 8'h00,
			"valid SET_CONFIG ACK mismatch");

		// Load two inward-facing observations through the serialized payload path.
		clear_request_payload;
		request_payload[0] = 8'd2;
		request_payload[4] = 8'h00;
		request_payload[5] = 8'h00;
		request_payload[6] = 8'h18;
		request_payload[7] = 8'hfc;
		request_payload[16] = 8'h00;
		request_payload[17] = 8'h00;
		request_payload[18] = 8'he8;
		request_payload[19] = 8'h03;
		request_payload[26] = 8'h02;
		send_protocol_frame(8'h11, 16'h0004, 8'd28, 1'b0);
		capture_response;
		check_response_header(8'h80, 16'h0004, 8'd4);
		check_condition(response_payload[0] == 8'h11, "LOAD_OBSERVATIONS ACK mismatch");

		// Start the real geometry pipeline and wait for its top-level completion pulse.
		clear_request_payload;
		send_protocol_frame(8'h12, 16'h1234, 8'd0, 1'b0);
		capture_response;
		check_response_header(8'h80, 16'h1234, 8'd4);
		wait_count = 0;
		while((debug_trigger_o !== 1'b1) && (wait_count < 100000)) begin
			@(posedge clk_100mhz_i);
			#1;
			wait_count = wait_count + 1;
		end
		check_condition(debug_trigger_o, "top-level localization completion timeout");
		check_condition(saw_compute_led, "compute LED never asserted during job");
		check_condition(!status_led_o[3], "successful START did not clear latched error LED");

		// STATUS exposes the completed four-vertex result and measured cycle count.
		send_protocol_frame(8'h13, 16'h0005, 8'd0, 1'b0);
		capture_response;
		check_response_header(8'h82, 16'h0005, 8'd16);
		check_condition(response_payload[0] == 8'h06, "STATUS state is not RESULT_READY");
		check_condition(response_payload[1] == 8'd1 && response_payload[2] == 8'd1,
			"STATUS valid or trusted mismatch");
		check_condition(response_payload[3] == 8'h03, "STATUS region mismatch");
		check_condition(response_payload[4] == 8'd2 && response_payload[5] == 8'd1,
			"STATUS observation fields mismatch");
		check_condition(response_payload[6] == 8'd4 && response_payload[7] == 8'd0,
			"STATUS vertex count mismatch");
		check_condition(response_payload[8] == 8'h41, "STATUS error flags mismatch");

		// Read and verify the complete result header including the 66-bit distance field.
		clear_request_payload;
		send_protocol_frame(8'h14, 16'h0006, 8'd8, 1'b0);
		capture_response;
		check_response_header(8'h90, 16'h0006, 8'd27);
		check_condition(response_payload[0] == 8'h34 && response_payload[1] == 8'h12,
			"RESULT_HEADER job sequence mismatch");
		check_condition(response_payload[2] == 8'd1 && response_payload[3] == 8'h03,
			"RESULT_HEADER trust or region mismatch");
		check_condition(response_payload[4] == 8'd4 && response_payload[5] == 8'd0,
			"RESULT_HEADER vertex count mismatch");
		check_condition(response_payload[6] == 8'h10 && response_payload[7] == 8'h00 &&
			response_payload[8] == 8'h80 && response_payload[9] == 8'hc1 &&
			response_payload[10] == 8'hff && response_payload[11] == 8'h08 &&
			response_payload[12] == 8'h3d && response_payload[13] == 8'h00 &&
			response_payload[14] == 8'h00, "RESULT_HEADER distance mismatch");
		check_condition(response_payload[15] == 8'd0 && response_payload[17] == 8'd2,
			"RESULT_HEADER farthest indices mismatch");
		check_condition(response_payload[23] == 8'h41, "RESULT_HEADER flags mismatch");

		// Request all four vertices and check both paging header and endpoint coordinates.
		clear_request_payload;
		request_payload[0] = 8'd1;
		request_payload[4] = 8'd4;
		send_protocol_frame(8'h14, 16'h0007, 8'd8, 1'b0);
		capture_response;
		check_response_header(8'h91, 16'h0007, 8'd40);
		$display("INFO: vertex bytes x0=%02x%02x%02x%02x x2=%02x%02x%02x%02x",
			response_payload[11], response_payload[10], response_payload[9], response_payload[8],
			response_payload[27], response_payload[26], response_payload[25], response_payload[24]);
		check_condition(response_payload[0] == 8'h34 && response_payload[1] == 8'h12 &&
			response_payload[4] == 8'd4, "RESULT_VERTICES paging header mismatch");
		check_condition(response_payload[8] == 8'hfd && response_payload[9] == 8'hff &&
			response_payload[10] == 8'he7 && response_payload[11] == 8'h03 &&
			response_payload[12] == 8'h00 && response_payload[13] == 8'h00 &&
			response_payload[14] == 8'h00 && response_payload[15] == 8'h00,
			"RESULT_VERTICES first x coordinate mismatch");
		check_condition(response_payload[16] == 8'hfb && response_payload[17] == 8'hff &&
			response_payload[18] == 8'hff && response_payload[19] == 8'hff &&
			response_payload[20] == 8'h70 && response_payload[21] == 8'h8d &&
			response_payload[22] == 8'h11 && response_payload[23] == 8'h00,
			"RESULT_VERTICES second coordinate mismatch");
		check_condition(response_payload[24] == 8'h01 && response_payload[25] == 8'h00 &&
			response_payload[26] == 8'h18 && response_payload[27] == 8'hfc &&
			response_payload[28] == 8'h00 && response_payload[29] == 8'h00 &&
			response_payload[30] == 8'h00 && response_payload[31] == 8'h00,
			"RESULT_VERTICES third x coordinate mismatch");
		check_condition(response_payload[32] == 8'hfb && response_payload[33] == 8'hff &&
			response_payload[34] == 8'hff && response_payload[35] == 8'hff &&
			response_payload[36] == 8'h90 && response_payload[37] == 8'h72 &&
			response_payload[38] == 8'hee && response_payload[39] == 8'hff,
			"RESULT_VERTICES fourth coordinate mismatch");

		// A vertex page beginning at the exact result count is unavailable.
		clear_request_payload;
		request_payload[0] = 8'd1;
		request_payload[2] = 8'd4;
		request_payload[4] = 8'd1;
		send_protocol_frame(8'h14, 16'h0008, 8'd8, 1'b0);
		capture_response;
		check_response_header(8'hff, 16'h0008, 8'd8);
		check_condition(response_payload[0] == 8'h14 && response_payload[1] == 8'h0a,
			"out-of-range vertex request error mismatch");

		// Corrupt one CRC byte, then verify parser ERROR and subsequent resynchronization.
		clear_request_payload;
		send_protocol_frame(8'h13, 16'h0009, 8'd0, 1'b1);
		capture_response;
		check_response_header(8'hff, 16'h0009, 8'd8);
		check_condition(response_payload[0] == 8'h13 && response_payload[1] == 8'h04,
			"CRC error response mismatch");
		send_protocol_frame(8'h01, 16'h000a, 8'd0, 1'b0);
		capture_response;
		check_response_header(8'h81, 16'h000a, 8'd24);

		check_condition(!monitor_uart_frame_error, "response UART monitor saw a frame error");
		if(failure_count == 0) begin
			$display("PASS: radio_localization_fpga_top completed UART protocol, geometry and paging integration");
		end else begin
			$display("FAIL: radio_localization_fpga_top failures=%0d", failure_count);
		end
		$finish;
	end

endmodule
