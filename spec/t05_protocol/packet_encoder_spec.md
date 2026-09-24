# packet_encoder 模块规格

> RTL：`rtl/comm/packet_encoder.v`

编码器接收响应命令、序号和载荷长度，依次输出`A5 5A`、版本`01`、命令、小端序号、小端长度、流式载荷以及小端CRC。每个输出字节在UART TX反压期间保持稳定，只有实际输出握手的版本至载荷字节才推进CRC。

载荷长度范围为0至244；超长请求产生`o_length_error`且不开始帧。最后一个CRC字节被接受后产生`o_frame_done`单周期脉冲。动态验证使用T03的ACK黄金帧`A55A018003000400110000000992`。

时序源见 [packet_encoder_ack_frame.json5](waveforms/packet_encoder_ack_frame.json5)。

