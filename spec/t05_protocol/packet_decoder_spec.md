# packet_decoder 模块规格

> RTL：`rtl/comm/packet_decoder.v`

解析器从字节级`valid/ready`入口搜索`A5 5A`，依次接收版本、命令、序号、长度、0至244字节载荷和小端CRC。CRC仅覆盖版本至载荷。合法帧在CRC通过后通过`o_frame_valid`原子提交；载荷保存在244字节内部存储中，并通过同步读端口访问。

解析器支持`A5 A5 5A`重叠同步，拒绝错误版本、未知命令、超长载荷和错误CRC。帧内100 ms没有接受新字节时报告超时。帧与错误输出均保持到下游握手，不会在CRC通过前修改有效任务状态。

动态验证覆盖GET_INFO、重叠SOF、READ_RESULT载荷读取、CRC错误和缩短参数下的超时。时序源见 [packet_decoder_valid_frame.json5](waveforms/packet_decoder_valid_frame.json5)。

