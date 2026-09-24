`timescale 1ns / 1ps

module tb_packet_decoder;
	reg i_clk;
	reg i_reset;
	reg [7:0] i_data;
	reg i_data_valid;
	wire o_data_ready;
	wire o_frame_valid;
	reg i_frame_ready;
	wire [7:0] o_frame_command;
	wire [15:0] o_frame_sequence;
	wire [7:0] o_frame_payload_length;
	reg i_payload_read_enable;
	reg [7:0] i_payload_read_address;
	wire [7:0] o_payload_read_data;
	wire o_payload_read_valid;
	wire o_error_valid;
	reg i_error_ready;
	wire [7:0] o_error_code;
	wire [7:0] o_error_command;
	wire [15:0] o_error_sequence;
	wire [31:0] o_error_context;
	integer int_error_count;
	integer int_index;
	integer int_random_index;
	integer int_noise_index;
	reg [31:0] reg_random_state;
	reg [7:0] reg_random_command;
	reg [7:0] reg_get_info [0:9];
	reg [7:0] reg_read_result [0:17];
	reg [7:0] reg_bad_crc [0:9];
	reg [7:0] reg_expected_payload [0:7];

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

	packet_decoder #(.C_TIMEOUT_CLKS(32)) dut
	(
		.i_clk(i_clk), .i_reset(i_reset), .i_data(i_data), .i_data_valid(i_data_valid),
		.o_data_ready(o_data_ready), .o_frame_valid(o_frame_valid), .i_frame_ready(i_frame_ready),
		.o_frame_command(o_frame_command), .o_frame_sequence(o_frame_sequence),
		.o_frame_payload_length(o_frame_payload_length), .i_payload_read_enable(i_payload_read_enable),
		.i_payload_read_address(i_payload_read_address), .o_payload_read_data(o_payload_read_data),
		.o_payload_read_valid(o_payload_read_valid), .o_error_valid(o_error_valid),
		.i_error_ready(i_error_ready), .o_error_code(o_error_code),
		.o_error_command(o_error_command), .o_error_sequence(o_error_sequence),
		.o_error_context(o_error_context)
	);

	always #5 i_clk = ~i_clk;

	task send_byte;
		input [7:0] data_value;
	begin
		wait(o_data_ready == 1'b1);
		@(negedge i_clk);
		i_data = data_value;
		i_data_valid = 1'b1;
		@(negedge i_clk);
		i_data_valid = 1'b0;
	end
	endtask

	task release_frame;
	begin
		@(negedge i_clk); i_frame_ready = 1'b1;
		@(negedge i_clk); i_frame_ready = 1'b0;
	end
	endtask

	task release_error;
	begin
		@(negedge i_clk); i_error_ready = 1'b1;
		@(negedge i_clk); i_error_ready = 1'b0;
	end
	endtask

	task send_zero_payload_frame;
		input [7:0] command_value;
		input [15:0] sequence_value;
		input corrupt_crc;
		reg [15:0] crc_value;
		begin
			crc_value = 16'hffff;
			crc_value = crc_next_byte(crc_value, 8'h01);
			crc_value = crc_next_byte(crc_value, command_value);
			crc_value = crc_next_byte(crc_value, sequence_value[7:0]);
			crc_value = crc_next_byte(crc_value, sequence_value[15:8]);
			crc_value = crc_next_byte(crc_value, 8'h00);
			crc_value = crc_next_byte(crc_value, 8'h00);
			send_byte(8'ha5);
			send_byte(8'h5a);
			send_byte(8'h01);
			send_byte(command_value);
			send_byte(sequence_value[7:0]);
			send_byte(sequence_value[15:8]);
			send_byte(8'h00);
			send_byte(8'h00);
			send_byte(crc_value[7:0] ^ {7'd0, corrupt_crc});
			send_byte(crc_value[15:8]);
		end
	endtask

	initial begin
		i_clk = 1'b0; i_reset = 1'b1; i_data = 0; i_data_valid = 0;
		i_frame_ready = 0; i_payload_read_enable = 0; i_payload_read_address = 0;
		i_error_ready = 0; int_error_count = 0; int_random_index = 0;
		int_noise_index = 0; reg_random_state = 32'h1415b301;
		reg_get_info[0]=8'hA5; reg_get_info[1]=8'h5A; reg_get_info[2]=8'h01; reg_get_info[3]=8'h01;
		reg_get_info[4]=8'h01; reg_get_info[5]=8'h00; reg_get_info[6]=8'h00; reg_get_info[7]=8'h00;
		reg_get_info[8]=8'h55; reg_get_info[9]=8'h97;
		reg_read_result[0]=8'hA5; reg_read_result[1]=8'h5A; reg_read_result[2]=8'h01; reg_read_result[3]=8'h14;
		reg_read_result[4]=8'h07; reg_read_result[5]=8'h00; reg_read_result[6]=8'h08; reg_read_result[7]=8'h00;
		reg_read_result[8]=8'h00; reg_read_result[9]=8'h00; reg_read_result[10]=8'h00; reg_read_result[11]=8'h00;
		reg_read_result[12]=8'h00; reg_read_result[13]=8'h00; reg_read_result[14]=8'h00; reg_read_result[15]=8'h00;
		reg_read_result[16]=8'h12; reg_read_result[17]=8'h83;
		for(int_index=0; int_index<8; int_index=int_index+1) reg_expected_payload[int_index]=8'h00;
		for(int_index=0; int_index<10; int_index=int_index+1) reg_bad_crc[int_index]=reg_get_info[int_index];
		reg_bad_crc[9]=8'h17;
		repeat(4) @(posedge i_clk); @(negedge i_clk); i_reset=1'b0;

		for(int_index=0; int_index<10; int_index=int_index+1) send_byte(reg_get_info[int_index]);
		wait(o_frame_valid==1'b1);
		if((o_frame_command!==8'h01)||(o_frame_sequence!==16'h0001)||(o_frame_payload_length!==8'd0))begin
			$display("FAIL: decoder GET_INFO metadata mismatch"); int_error_count=int_error_count+1;
		end
		release_frame;

		send_byte(8'hA5);
		for(int_index=0; int_index<10; int_index=int_index+1) send_byte(reg_get_info[int_index]);
		wait(o_frame_valid==1'b1);
		if(o_frame_sequence!==16'h0001)begin
			$display("FAIL: decoder overlapping SOF recovery"); int_error_count=int_error_count+1;
		end
		release_frame;

		for(int_index=0; int_index<18; int_index=int_index+1) send_byte(reg_read_result[int_index]);
		wait(o_frame_valid==1'b1);
		if((o_frame_command!==8'h14)||(o_frame_payload_length!==8'd8))begin
			$display("FAIL: decoder payload frame metadata"); int_error_count=int_error_count+1;
		end
		for(int_index=0; int_index<8; int_index=int_index+1)begin
			@(negedge i_clk); i_payload_read_address=int_index; i_payload_read_enable=1'b1;
			@(posedge i_clk); #1;
			if((o_payload_read_valid!==1'b1)||(o_payload_read_data!==reg_expected_payload[int_index]))begin
				$display("FAIL: decoder payload byte %0d",int_index); int_error_count=int_error_count+1;
			end
			@(negedge i_clk); i_payload_read_enable=1'b0;
		end
		release_frame;

		for(int_index=0; int_index<10; int_index=int_index+1) send_byte(reg_bad_crc[int_index]);
		wait(o_error_valid==1'b1);
		if(o_error_code!==8'h04)begin
			$display("FAIL: decoder CRC error code %02x",o_error_code); int_error_count=int_error_count+1;
		end
		release_error;

		send_byte(8'hA5); send_byte(8'h5A);
		repeat(40) @(posedge i_clk);
		if((o_error_valid!==1'b1)||(o_error_code!==8'h05))begin
			$display("FAIL: decoder timeout handling"); int_error_count=int_error_count+1;
		end
		release_error;

		// T14固定种子协议模糊回归：噪声、CRC破坏、重同步与输出背压稳定性。
		for(int_random_index = 0; int_random_index < 256;
			int_random_index = int_random_index + 1) begin
			reg_random_state = {reg_random_state[30:0],
				reg_random_state[31] ^ reg_random_state[21] ^
				reg_random_state[1] ^ reg_random_state[0]};
			for(int_noise_index = 0; int_noise_index < (reg_random_state[2:0] + 1);
				int_noise_index = int_noise_index + 1) begin
				// 避免噪声自身构成SOF；合法帧负责验证每轮重同步。
				send_byte(reg_random_state[7:0] == 8'ha5 ? 8'ha4 : reg_random_state[7:0]);
				reg_random_state = {reg_random_state[30:0],
					reg_random_state[31] ^ reg_random_state[21] ^
					reg_random_state[1] ^ reg_random_state[0]};
			end
			case(reg_random_state[2:0])
				3'd0: reg_random_command = 8'h01;
				3'd1: reg_random_command = 8'h10;
				3'd2: reg_random_command = 8'h11;
				3'd3: reg_random_command = 8'h12;
				3'd4: reg_random_command = 8'h13;
				3'd5: reg_random_command = 8'h14;
				default: reg_random_command = 8'h1f;
			endcase
			if(int_random_index[0]) begin
				send_zero_payload_frame(reg_random_command, int_random_index[15:0], 1'b1);
				wait(o_error_valid == 1'b1);
				if(o_error_code !== 8'h04) begin
					$display("FAIL: randomized CRC error code %02x", o_error_code);
					int_error_count = int_error_count + 1;
				end
				release_error;
			end
			send_zero_payload_frame(reg_random_command, int_random_index[15:0], 1'b0);
			wait((o_frame_valid == 1'b1) || (o_error_valid == 1'b1));
			if(o_error_valid == 1'b1) begin
				$display("FAIL: randomized valid frame raised error=%02x index=%0d",
					o_error_code, int_random_index);
				int_error_count = int_error_count + 1;
				release_error;
			end else begin
				if((o_frame_command !== reg_random_command) ||
					(o_frame_sequence !== int_random_index[15:0]) ||
					(o_frame_payload_length !== 8'd0)) begin
					$display("FAIL: randomized valid frame metadata mismatch");
					int_error_count = int_error_count + 1;
				end
				repeat(3) begin
					@(posedge i_clk);
					#1;
					if((o_frame_valid !== 1'b1) ||
						(o_frame_command !== reg_random_command) ||
						(o_frame_sequence !== int_random_index[15:0])) begin
						$display("FAIL: randomized frame changed under backpressure");
						int_error_count = int_error_count + 1;
					end
				end
				release_frame;
			end
		end

		if(int_error_count==0) $display("PASS: packet_decoder directed and 256-frame randomized checks completed");
		else $display("FAIL: packet_decoder reported %0d mismatches",int_error_count);
		$finish;
	end

	initial begin
		repeat(1000000) @(posedge i_clk);
		$display("FAIL: packet_decoder watchdog timeout");
		$finish;
	end
endmodule
