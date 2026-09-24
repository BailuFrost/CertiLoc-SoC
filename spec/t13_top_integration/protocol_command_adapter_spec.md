# protocol_command_adapter 模块规格

> RTL：`rtl/control/protocol_command_adapter.v`

模块位于 T05 `packet_decoder` 与 T12 `localization_command_ctrl` 之间。它只处理 CRC 已通过且由解析器保持的完整帧，逐字节同步读取 Payload，并验证命令长度、冻结配置、观测数量、保留位、相位高位及结果分页参数。

`LOAD_OBSERVATIONS` 的坐标和相位先保存在模块内部20项暂存区。只有全部字段合法后，模块才依次写入控制器观测暂存端口，最后发出语义命令，从而保证部分或非法 Payload 不会提交活动任务。错误通过保持型描述符返回，原始帧在语义命令或错误被下游接受后才释放。时序源见 [protocol_command_adapter_load.json5](waveforms/protocol_command_adapter_load.json5)。
