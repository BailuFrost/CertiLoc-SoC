`timescale 1ns / 1ps

////////////////////////////////////English///////////////////////////////////////
// Company:         FPGA Stage 1 Project
// Engineer:        Codex
//
// Create Date:     2026/09/20
// Design Name:     UART Transmitter
// Module Name:     uart_tx
// Description:     115200 bit/s, 8N1 byte transmitter with valid-ready input.
// Simulations:     fpga_stage1/tb/unit/tb_uart_tx.v
//
// Referrences:     fpga_stage1/docs/t03_uart_protocol.md
//
// Dependencies:    None
//
// Version:         V1.0
// Revision Date:   2026/09/20
// History:
// Time             Version     Revised by        Contents
// 2026/09/20       V1.0        Codex             Create file.
///////////////////////////////////Chinese////////////////////////////////////////
// 版权归属:        FPGA阶段1项目
// 开发人员:        Codex
//
// 创建日期:        2026年09月20日
// 设计名称:        UART发送器
// 模块名称:        uart_tx
// 模块说明:        具备有效就绪握手的115200 bit/s、8N1字节发送器
// 仿真工程:        fpga_stage1/tb/unit/tb_uart_tx.v
//
// 参考资料:        fpga_stage1/docs/t03_uart_protocol.md
//
// 依赖文件:        无
//
// 当前版本:        V1.0
// 修订日期:        2026年09月20日
// 修订历史:
// 时间             版本        修订人            修订内容
// 2026年09月20日   V1.0        Codex             创建文件

//UART发送模块
module uart_tx
#(
	parameter C_CLKS_PER_BIT = 868              // 每个串行位占用的系统时钟数
)
(
	//---------------全局信号---------------//
	input i_clk,                                // 100 MHz系统时钟
	input i_reset,                              // 同步高有效内部复位

	//---------------字节接口---------------//
	input [7:0] i_data,                         // 待发送的并行字节
	input i_data_valid,                         // 输入字节有效指示
	output o_data_ready,                        // 当前周期能够接收新字节

	//---------------串行接口---------------//
	output o_uart_tx,                           // 8N1串行发送线
	output o_busy                               // 正在发送完整字符
);

	//---------------计数信号---------------//
	reg [9:0] cnt_baud = 0;                     // 当前串行位的周期位置
	reg [3:0] cnt_frame_bit = 0;                // 当前发送帧的位序号

	//--------------寄存器信号--------------//
	reg [9:0] reg_frame = 0;                    // 停止位、数据位和起始位移位帧

	//---------------标志信号---------------//
	reg flag_busy = 0;                          // 帧发送期间保持置位

	//---------------其他信号---------------//
	wire flag_accept;                           // 上游字节握手完成条件
	wire flag_bit_tick;                         // 当前串行位周期结束条件
	wire rstn_internal;                         // 由高有效接口复位转换的低有效内部复位

	//---------------输出信号---------------//
	wire data_ready_o;                          // 字节入口就绪状态
	wire uart_tx_o;                             // 当前待驱动的串行位
	wire busy_o;                                // 发送忙状态镜像

	//-------------其他信号连线-------------//
	assign flag_accept = i_data_valid & data_ready_o;       // 只在空闲且有效时装载字节
	assign flag_bit_tick = (cnt_baud == C_CLKS_PER_BIT - 1);// 满足整位周期时推进帧
	assign rstn_internal = ~i_reset;                         // 保持项目高有效复位接口

	//-------------输出信号连线-------------//
	assign data_ready_o = ~flag_busy;            // 空闲状态允许接收下一字节
	assign uart_tx_o = reg_frame[0];             // 移位帧最低位直接驱动串行线
	assign busy_o = flag_busy;                    // 输出当前帧占用状态
	assign o_data_ready = data_ready_o;           // 连接字节入口就绪端口
	assign o_uart_tx = uart_tx_o;                 // 连接物理串行发送端口
	assign o_busy = busy_o;                       // 连接发送忙指示端口

	//-----------主要任务处理区域-----------//
	//发送事务占用状态
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			flag_busy <= 1'b0;
		end else if(flag_accept == 1'b1)begin
			flag_busy <= 1'b1;
		end else if((flag_busy == 1'b1) && (flag_bit_tick == 1'b1) && (cnt_frame_bit == 4'd9))begin
			flag_busy <= 1'b0;
		end
	end

	//串行位内周期计数
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			cnt_baud <= 10'd0;
		end else if(flag_busy == 1'b0)begin
			cnt_baud <= 10'd0;
		end else if(flag_bit_tick == 1'b1)begin
			cnt_baud <= 10'd0;
		end else begin
			cnt_baud <= cnt_baud + 1'b1;
		end
	end

	//完整字符位序号计数
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			cnt_frame_bit <= 4'd0;
		end else if(flag_busy == 1'b0)begin
			cnt_frame_bit <= 4'd0;
		end else if(flag_bit_tick == 1'b1)begin
			if(cnt_frame_bit == 4'd9)begin
				cnt_frame_bit <= 4'd0;
			end else begin
				cnt_frame_bit <= cnt_frame_bit + 1'b1;
			end
		end
	end

	//握手时装载8N1帧，随后每个整位周期右移一次
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_frame <= 10'h3FF;
		end else if(flag_accept == 1'b1)begin
			reg_frame <= {1'b1, i_data, 1'b0};
		end else if((flag_busy == 1'b1) && (flag_bit_tick == 1'b1))begin
			reg_frame <= {1'b1, reg_frame[9:1]};
		end
	end

endmodule
