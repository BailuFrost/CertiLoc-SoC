# T15 ILA实现与板级测量准备报告

## 1. 结论

T15的ILA工程、可下载镜像、布线后时序/资源/功耗报告和自动板测工具已经完成。带ILA设计在XC7A35T-1CPG236C上完成综合、布局布线和bitstream生成，100 MHz约束通过。

当前主机未枚举到Digilent/Basys 3 JTAG设备或串口，因此本报告不宣称已经取得本次ILA波形或UART实测日志。物理板测仍需连接板卡后执行第5节命令；该边界不能由仿真或用户口述的既往上板成功替代。

## 2. ILA镜像与探针

| 项目 | 结果 |
|---|---|
| Vivado | 2024.2，SW Build 5239630 |
| 器件 | `xc7a35tcpg236-1` |
| ILA采样时钟 | 100 MHz |
| 采样深度 | 4096 |
| Probe宽度 | 91位 |
| 触发 | 普通数据触发，2个匹配单元，支持存储限定 |
| Bitstream | `reports/t15_ila/radio_localization_t15_ila.bit` |
| Probe定义 | `reports/t15_ila/radio_localization_t15_ila.ltx` |

91位探针覆盖控制器忙状态、8位工程状态、活动观测索引、任务完成、当前RAM缓冲与顶点数、约束/裁剪/直径启动和完成握手、结果有效/可信、结果顶点数、32位核心周期和8位错误标志。建议以`controller_job_done`上升沿触发并设置约50%预触发。

## 3. 实现结果

| 指标 | ILA版本结果 |
|---|---:|
| WNS | +0.441 ns |
| TNS | 0.000 ns |
| WHS | +0.008 ns |
| THS | 0.000 ns |
| Slice LUT | 8015 / 20800（38.53%） |
| Slice Register | 12298 / 41600（29.56%） |
| Block RAM Tile | 16.5 / 50（33.00%） |
| DSP | 24 / 90（26.67%） |
| I/O | 9 / 106（8.49%） |
| 向量无关总功耗估算 | 0.202 W，置信度Medium |
| 估算结温 | 26.0 °C |

`report_drc`无Error，但保留306条Warning，主要是DSP输入/输出未完全流水、异步复位检查、BRAM异步控制和布局等价警告；它们未阻断bitstream生成，且100 MHz建立/保持时序均已收敛。方法学报告还提示顶层I/O未设置输入输出延迟，这与板级异步UART/按钮接口的当前约束策略一致，但仍应作为后续约束精化项保留。

## 4. 板测工具

`tools/t15_board_validation.py`通过真实115200 bit/s UART执行：

1. `GET_INFO`与能力核对；
2. 冻结配置与两条演示观测加载；
3. 启动定位并轮询状态；
4. 读取结果头和全部顶点页；
5. 顶点集合、距离平方与位精确模型逐位核对；
6. 分开记录命令往返、结果等待、分页、端到端与FPGA核心周期；
7. 默认追加1000次连续任务压力测试；
8. 输出`reports/t15_board/t15_board_measurements.json`和`t15_board_validation.md`。

## 5. 连接板卡后的关闭步骤

1. 在Vivado Hardware Manager中同时加载`.bit`与`.ltx`；
2. ILA触发设为`controller_job_done == 1`，采集一次完整事务并导出CSV到`reports/t15_board/`；
3. 在带`pyserial`的Python环境执行：

```powershell
python fpga_stage1/tools/t15_board_validation.py --port COM5 --stress 1000
```

将`COM5`替换为实际串口。脚本只有全部协议、位精确结果和压力检查通过后才写PASS报告。

## 6. 工程证据

| 报告 | 路径 |
|---|---|
| 布线时序 | `reports/t15_ila/timing_summary_routed.rpt` |
| 资源 | `reports/t15_ila/utilization_routed.rpt` |
| 功耗 | `reports/t15_ila/power_routed.rpt` |
| DRC | `reports/t15_ila/drc_routed.rpt` |
| 方法学 | `reports/t15_ila/methodology_routed.rpt` |
| I/O | `reports/t15_ila/io_routed.rpt` |
| ILA核/探针 | `reports/t15_ila/debug_cores.rpt` |
| 可复现构建 | `scripts/build_t15_ila.tcl` |

## 7. T15关闭状态

- ILA插入、实现、时序、资源、功耗、bitstream和板测自动化：完成；
- 本次物理板UART实测日志、ILA捕获CSV：因板卡未连接当前主机，待执行；
- 因此T15处于“工程资产完成、物理证据待采集”，尚不能标记为完全验收。
