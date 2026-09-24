`timescale 1ns / 1ps

////////////////////////////////////English///////////////////////////////////////
// Company:         FPGA Stage 1 Project
// Engineer:        Codex
//
// Create Date:     2026/09/20
// Design Name:     UART Receiver
// Module Name:     uart_rx
// Description:     115200 bit/s, 8N1 receiver with synchronized input.
// Simulations:     fpga_stage1/tb/unit/tb_uart_rx.v
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
// 设计名称:        UART接收器
// 模块名称:        uart_rx
// 模块说明:        带双触发同步和有效就绪输出的115200 bit/s、8N1接收器
// 仿真工程:        fpga_stage1/tb/unit/tb_uart_rx.v
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

//UART接收模块
module uart_rx
#(
	parameter C_CLKS_PER_BIT = 868,             // 每个串行位占用的系统时钟数
	parameter C_HALF_BIT_CLKS = 434             // 起始位中心确认等待周期数
)
(
	//---------------全局信号---------------//
	input i_clk,                                // 100 MHz系统时钟
	input i_reset,                              // 同步高有效内部复位

	//---------------串行接口---------------//
	input i_uart_rx,                            // 异步8N1串行接收线

	//---------------字节接口---------------//
	input i_data_ready,                         // 下游已准备接收当前字节
	output [7:0] o_data,                        // 已接收的并行字节
	output o_data_valid,                        // 输出字节有效并保持至握手
	output o_frame_error,                       // 停止位为低时产生单周期脉冲
	output o_busy                               // 正在采样一个串行字符
);

	//-------------状态参数区域-------------//
	localparam ST_IDLE = 2'd0;                  // 等待串行线下降沿
	localparam ST_START = 2'd1;                 // 在起始位中心确认低电平
	localparam ST_DATA = 2'd2;                  // 依次采样八个数据位
	localparam ST_STOP = 2'd3;                  // 采样并校验停止位

	//---------------计数信号---------------//
	reg [9:0] cnt_baud = 0;                     // 当前采样位的周期位置
	reg [2:0] cnt_data_bit = 0;                 // 当前待采样数据位索引

	//--------------状态机信号--------------//
	reg [1:0] state_current = 0;                // 接收流程当前状态
	reg [1:0] state_next = 0;                   // 接收流程下一状态

	//--------------寄存器信号--------------//
	reg reg_uart_meta = 0;                      // 异步输入第一级亚稳态隔离寄存器
	reg reg_uart_sync = 0;                      // 异步输入第二级同步寄存器
	reg [7:0] reg_data_shift = 0;               // 按最低位优先装入的接收字节

	//---------------标志信号---------------//
	reg flag_data_valid = 0;                    // 等待下游握手的字节有效状态
	reg flag_frame_error = 0;                   // 停止位错误单周期状态
	wire flag_output_available;                 // 输出缓存可接受新字节条件
	wire flag_start_tick;                       // 起始位中心采样时刻
	wire flag_data_tick;                        // 数据位或停止位采样时刻
	wire rstn_internal;                         // 由高有效接口复位转换的低有效内部复位

	//---------------输出信号---------------//
	wire [7:0] data_o;                          // 输出缓存中的完整字节
	wire data_valid_o;                          // 字节有效状态镜像
	wire frame_error_o;                         // 帧错误脉冲镜像
	wire busy_o;                                // 接收状态机忙指示

	//-------------其他信号连线-------------//
	assign flag_output_available = (~flag_data_valid) | i_data_ready; // 允许空缓存或同周期释放后启动
	assign flag_start_tick = (cnt_baud == C_HALF_BIT_CLKS - 1);       // 定位起始位中心
	assign flag_data_tick = (cnt_baud == C_CLKS_PER_BIT - 1);        // 定位后续各位中心
	assign rstn_internal = ~i_reset;                                 // 保持项目高有效复位接口

	//-------------输出信号连线-------------//
	assign data_o = reg_data_shift;              // 暴露已完成接收的字节缓存
	assign data_valid_o = flag_data_valid;        // 暴露字节等待消费状态
	assign frame_error_o = flag_frame_error;      // 暴露停止位异常脉冲
	assign busy_o = (state_current != ST_IDLE);   // 非空闲状态表示正在接收
	assign o_data = data_o;                       // 连接并行字节输出端口
	assign o_data_valid = data_valid_o;           // 连接字节有效输出端口
	assign o_frame_error = frame_error_o;         // 连接帧错误输出端口
	assign o_busy = busy_o;                       // 连接接收忙输出端口

	//-----------主要任务处理区域-----------//
	//第一级触发器隔离异步UART输入的亚稳态传播
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_uart_meta <= 1'b1;
		end else begin
			reg_uart_meta <= i_uart_rx;
		end
	end

	//第二级触发器向接收状态机提供同步线路电平
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_uart_sync <= 1'b1;
		end else begin
			reg_uart_sync <= reg_uart_meta;
		end
	end

	//--------------状态机区域--------------//
	//根据线路采样进度决定接收阶段
	always@(*)begin
		state_next = state_current;
		case(state_current)
			ST_IDLE:begin
				if((reg_uart_sync == 1'b0) && (flag_output_available == 1'b1))begin
					state_next = ST_START;
				end
			end
			ST_START:begin
				if(flag_start_tick == 1'b1)begin
					if(reg_uart_sync == 1'b0)begin
						state_next = ST_DATA;
					end else begin
						state_next = ST_IDLE;
					end
				end
			end
			ST_DATA:begin
				if((flag_data_tick == 1'b1) && (cnt_data_bit == 3'd7))begin
					state_next = ST_STOP;
				end
			end
			ST_STOP:begin
				if(flag_data_tick == 1'b1)begin
					state_next = ST_IDLE;
				end
			end
			default:begin
				state_next = ST_IDLE;
			end
		endcase
	end

	//时序保存接收流程状态
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			state_current <= ST_IDLE;
		end else begin
			state_current <= state_next;
		end
	end

	//-----------状态任务处理区域-----------//
	//按当前接收阶段维护位周期计数
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			cnt_baud <= 10'd0;
		end else begin
			case(state_current)
				ST_IDLE:begin
					cnt_baud <= 10'd0;
				end
				ST_START:begin
					if(flag_start_tick == 1'b1)begin
						cnt_baud <= 10'd0;
					end else begin
						cnt_baud <= cnt_baud + 1'b1;
					end
				end
				default:begin
					if(flag_data_tick == 1'b1)begin
						cnt_baud <= 10'd0;
					end else begin
						cnt_baud <= cnt_baud + 1'b1;
					end
				end
			endcase
		end
	end

	//数据采样完成后推进最低位优先索引
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			cnt_data_bit <= 3'd0;
		end else if(state_current != ST_DATA)begin
			cnt_data_bit <= 3'd0;
		end else if(flag_data_tick == 1'b1)begin
			if(cnt_data_bit == 3'd7)begin
				cnt_data_bit <= 3'd0;
			end else begin
				cnt_data_bit <= cnt_data_bit + 1'b1;
			end
		end
	end

	//在每个数据位中心写入对应字节位置
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			reg_data_shift <= 8'd0;
		end else if((state_current == ST_DATA) && (flag_data_tick == 1'b1))begin
			reg_data_shift[cnt_data_bit] <= reg_uart_sync;
		end
	end

	//正确停止位将完整字节提交给下游并保持至握手
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			flag_data_valid <= 1'b0;
		end else if((state_current == ST_STOP) && (flag_data_tick == 1'b1) && (reg_uart_sync == 1'b1))begin
			flag_data_valid <= 1'b1;
		end else if((flag_data_valid == 1'b1) && (i_data_ready == 1'b1))begin
			flag_data_valid <= 1'b0;
		end
	end

	//错误停止位只报告一个系统时钟周期
	always@(posedge i_clk or negedge rstn_internal)begin
		if(rstn_internal == 1'b0)begin
			flag_frame_error <= 1'b0;
		end else if((state_current == ST_STOP) && (flag_data_tick == 1'b1) && (reg_uart_sync == 1'b0))begin
			flag_frame_error <= 1'b1;
		end else begin
			flag_frame_error <= 1'b0;
		end
	end

endmodule
