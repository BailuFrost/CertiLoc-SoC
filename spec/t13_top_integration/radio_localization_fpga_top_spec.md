# radio_localization_fpga_top 模块规格

> RTL：`rtl/top/radio_localization_fpga_top.v`

该模块是 Basys 3 阶段1板级顶层，端口与 `constraints/basys3_radio_localization.xdc` 完全一致。外部按键复位异步置位，两级移位链同步释放；系统只有100 MHz板载时钟，不生成派生时钟。

数据链路依次为 UART RX、T05帧解析、命令适配、T12定位控制器、响应适配、T05帧编码和 UART TX。响应仲裁优先级为帧解析错误、Payload语义错误、控制器响应。LED0至LED3分别表示空闲、接收、计算和锁存错误；Pmod调试脉冲在定位任务完成时保持一个周期。时序源见 [radio_localization_fpga_top_uart_job.json5](waveforms/radio_localization_fpga_top_uart_job.json5)。
