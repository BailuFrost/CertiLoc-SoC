`timescale 1ns / 1ps

module tb_packet_encoder;
	reg i_clk;
	reg i_reset;
	reg i_frame_valid;
	wire o_frame_ready;
	reg [7:0] i_frame_command;
	reg [15:0] i_frame_sequence;
	reg [7:0] i_frame_payload_length;
	reg [7:0] i_payload_data;
	reg i_payload_valid;
	wire o_payload_ready;
	wire [7:0] o_data;
	wire o_data_valid;
	reg i_data_ready;
	wire o_busy;
	wire o_frame_done;
	wire o_length_error;
	reg [7:0] reg_payload [0:3];
	reg [7:0] reg_observed [0:31];
	reg [7:0] reg_expected [0:13];
	integer int_payload_index;
	integer int_output_count;
	integer int_index;
	integer int_error_count;

	packet_encoder dut
	(
		.i_clk(i_clk), .i_reset(i_reset), .i_frame_valid(i_frame_valid),
		.o_frame_ready(o_frame_ready), .i_frame_command(i_frame_command),
		.i_frame_sequence(i_frame_sequence), .i_frame_payload_length(i_frame_payload_length),
		.i_payload_data(i_payload_data), .i_payload_valid(i_payload_valid),
		.o_payload_ready(o_payload_ready), .o_data(o_data), .o_data_valid(o_data_valid),
		.i_data_ready(i_data_ready), .o_busy(o_busy), .o_frame_done(o_frame_done),
		.o_length_error(o_length_error)
	);

	always #5 i_clk=~i_clk;

	always@(posedge i_clk)begin
		if((o_data_valid==1'b1)&&(i_data_ready==1'b1))begin
			reg_observed[int_output_count]=o_data;
			int_output_count=int_output_count+1;
		end
		if((i_payload_valid==1'b1)&&(o_payload_ready==1'b1))begin
			int_payload_index=int_payload_index+1;
			if(int_payload_index<4) i_payload_data=reg_payload[int_payload_index];
			else i_payload_valid=1'b0;
		end
	end

	initial begin
		i_clk=0; i_reset=1; i_frame_valid=0; i_frame_command=0; i_frame_sequence=0;
		i_frame_payload_length=0; i_payload_data=0; i_payload_valid=0; i_data_ready=1;
		int_payload_index=0; int_output_count=0; int_error_count=0;
		reg_payload[0]=8'h11; reg_payload[1]=8'h00; reg_payload[2]=8'h00; reg_payload[3]=8'h00;
		reg_expected[0]=8'hA5; reg_expected[1]=8'h5A; reg_expected[2]=8'h01; reg_expected[3]=8'h80;
		reg_expected[4]=8'h03; reg_expected[5]=8'h00; reg_expected[6]=8'h04; reg_expected[7]=8'h00;
		reg_expected[8]=8'h11; reg_expected[9]=8'h00; reg_expected[10]=8'h00; reg_expected[11]=8'h00;
		reg_expected[12]=8'h09; reg_expected[13]=8'h92;
		repeat(4) @(posedge i_clk); @(negedge i_clk); i_reset=0;
		wait(o_frame_ready==1'b1); @(negedge i_clk);
		i_frame_command=8'h80; i_frame_sequence=16'h0003; i_frame_payload_length=8'd4;
		i_frame_valid=1'b1; i_payload_data=reg_payload[0]; i_payload_valid=1'b1;
		@(negedge i_clk); i_frame_valid=1'b0;
		wait(o_frame_done==1'b1);
		@(posedge i_clk);
		if(int_output_count!=14)begin
			$display("FAIL: encoder byte count %0d",int_output_count); int_error_count=int_error_count+1;
		end
		for(int_index=0; int_index<14; int_index=int_index+1)begin
			if(reg_observed[int_index]!==reg_expected[int_index])begin
				$display("FAIL: encoder byte %0d expected %02x observed %02x",int_index,reg_expected[int_index],reg_observed[int_index]);
				int_error_count=int_error_count+1;
			end
		end

		wait(o_frame_ready==1'b1); @(negedge i_clk);
		i_frame_payload_length=8'd250; i_frame_valid=1'b1;
		@(posedge i_clk); #1;
		if(o_length_error!==1'b1)begin
			$display("FAIL: encoder length rejection missing"); int_error_count=int_error_count+1;
		end
		@(negedge i_clk); i_frame_valid=1'b0;

		if(int_error_count==0) $display("PASS: packet_encoder directed checks completed");
		else $display("FAIL: packet_encoder reported %0d mismatches",int_error_count);
		$finish;
	end

	initial begin
		repeat(10000) @(posedge i_clk);
		$display("FAIL: packet_encoder watchdog timeout");
		$finish;
	end
endmodule
