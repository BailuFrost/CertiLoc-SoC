# vertex_ram_dual_buffer 模块规格

> RTL：`rtl/memory/vertex_ram_dual_buffer.v`

模块向外提供A、B两块1024×64位顶点存储，每个逻辑端口均可独立选择缓冲区、地址以及读写方向。RTL将缓冲区选择作为11位物理地址的最高位，以一个2048×64位单时钟真双口RAM实现，从而符合Vivado的Block RAM推断模板。同步读在请求后一个时钟返回数据并脉冲`read_valid`；写操作在请求上升沿完成。

复位只清零读数据寄存器和有效标志，不清空存储阵列。禁止两个端口同周期访问同一物理地址且至少一个端口执行写操作；该读写或双写冲突的数据结果未定义，必须由上层仲裁避免。同一缓冲区的不同地址仍可并发访问。时序源见 [vertex_ram_dual_buffer_dual_read.json5](waveforms/vertex_ram_dual_buffer_dual_read.json5)。
