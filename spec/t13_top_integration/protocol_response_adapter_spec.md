# protocol_response_adapter 模块规格

> RTL：`rtl/control/protocol_response_adapter.v`

模块把接收错误、语义错误或控制器响应统一转换为 T03 Payload，支持 `ACK`、`INFO`、`STATUS`、`RESULT_HEADER`、`RESULT_VERTICES` 和 `ERROR`。响应入口握手时锁存全部状态和结果字段，避免 UART 长帧发送期间的数据撕裂。

顶点请求合法时，模块计算1至16的实际页长，并通过 T12 空闲只读窗口逐点预取64位坐标；靠近尾部时只返回剩余顶点。起始索引不小于结果顶点数时转换为 `RESULT_UNAVAILABLE`。时序源见 [protocol_response_adapter_page.json5](waveforms/protocol_response_adapter_page.json5)。
