# T08顶点RAM综合模板修复记录

## 结论

`vertex_ram_dual_buffer` 的Vivado `[Synth 8-2914]` / `[Synth 8-5743]` 报错已修复。原RTL中A、B两个数组都可被两个独立时序过程动态选中写入，不匹配Vivado支持的RAM推断模板。修复后将缓冲区选择作为物理地址位`[10]`，存储结构为单个2048×64位单时钟真双口RAM，外部接口、同步读延迟和A/B缓冲语义不变。

## 综合证据

- 工具：Vivado 2024.2，目标器件`xc7a35tcpg236-1`；
- 方式：仅对`vertex_ram_dual_buffer`执行out-of-context综合；
- Vivado报告`vertex_memory_reg` was recognized as a true dual port RAM template；
- 最终映射：2048×64，两个端口均可读写，`READ_FIRST`，4个`RAMB36E1`，0个`RAMB18E1`；
- 结果：0 errors，0 critical warnings，1 warning。该warning为未合并可选BRAM输出寄存器的时序提示，不影响RAM推断。

原始证据：`synth/vivado_ascii_path.log`、`synth/ram_utilization.rpt`和`synth/utilization.rpt`。工作区路径含中文时，Vivado综合子进程在模块解析后异常退出；同一RTL在纯ASCII临时路径下完成了上述综合。

## 动态仿真证据

| testbench | 结果 | 结束时间 |
|---|---|---:|
| `tb_vertex_ram_dual_buffer` | `PASS: vertex_ram_dual_buffer concurrent access checks completed` | 80 ns |
| `tb_initial_polygon_loader` | `PASS: initial_polygon_loader copied both 720-vertex buffers bit-exactly` | 43380 ns |

原始日志为`xsim/xsim_ram.log`和`xsim/xsim_loader.log`。

## 边界条件

- 复位不清空RAM，只清零读数据寄存器和`read_valid`；
- 两端口同周期访问同一物理地址且至少一端口写入时，结果未定义，必须由上层仲裁禁止；
- 本次未执行全工程综合、实现或板级回环。
