# initial_polygon_loader 模块规格

> RTL：`rtl/memory/initial_polygon_loader.v`

模块在空闲时接受目标缓冲区选择，随后连续请求ROM地址0至719，并将同步ROM响应逐拍写入顶点RAM。目标缓冲区在整个事务中保持不变；第720次写入完成时`loaded_vertex_count_o=720`且`done_o`脉冲。

从接受`start_i`到`done_o`相隔固定721个时钟周期。忙期间重复启动只产生单周期协议错误，不改变当前目标。时序源见 [initial_polygon_loader_load.json5](waveforms/initial_polygon_loader_load.json5)。
