# T13顶层集成与约束资产验证记录

## 1. 结论

T13首版顶层RTL、命令与响应适配器、模块规格和串行端到端动态仿真已经完成。Vivado XSim 2024.2从真实UART输入位流开始，贯通接收器、CRC帧解析、Payload语义校验、T12定位控制器、结果分页、帧编码器和UART发送器；testbench再从发送串行线恢复字节并独立核对帧头、Payload和CRC。最终日志输出唯一`PASS`且无`FAIL`。

既有 `basys3_radio_localization.xdc` 的时钟、复位、UART、四个LED和调试端口均与新顶层逐名一致。本轮没有执行综合、实现或板级回环，因此不作资源、时序收敛或硬件功能声明。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| Basys 3顶层 | `rtl/top/radio_localization_fpga_top.v` |
| 命令Payload适配 | `rtl/control/protocol_command_adapter.v` |
| 响应Payload与分页适配 | `rtl/control/protocol_response_adapter.v` |
| T12状态接口补充 | `rtl/control/localization_command_ctrl.v` 的活动观测索引输出 |
| 顶层自检testbench | `tb/integration/tb_radio_localization_fpga_top.v` |
| 结构化规格 | `spec/t13_top_integration_spec.json` |
| 同名规格与时序源 | `spec/t13_top_integration/` |
| 板级约束 | `constraints/basys3_radio_localization.xdc` |
| Vivado日志 | `reports/t13_xsim/radio_localization_fpga_top/` |
| 严格静态报告 | `reports/t13_command_adapter_gate.*`、`t13_response_adapter_gate.*`、`t13_top_gate.*` |

## 3. 顶层数据路径

`UART RX -> packet_decoder -> protocol_command_adapter -> localization_command_ctrl -> protocol_response_adapter -> packet_encoder -> UART TX`

- 命令适配器只读取CRC通过后由T05保持的帧；
- 冻结配置逐字节精确比较；
- 观测全部缓存在适配器内部，字段完整合法后才写入T12暂存区并提交数量；
- `READ_RESULT`支持结果头和1至16个顶点的分页请求；
- 响应适配器在握手时快照状态，避免UART发送期间状态变化造成字段撕裂；
- 顶点页通过T12最终RAM同步只读窗口逐点预取；
- 响应仲裁优先级为帧解析错误、Payload语义错误、控制器响应；
- 外部复位异步置位、两级同步释放；LED表示空闲、接收、计算和锁存错误，调试口输出任务完成脉冲。

## 4. 动态仿真覆盖

工具：Vivado Simulator 2024.2，SW Build 5239630。

为缩短仿真，testbench把UART参数覆盖为每位8时钟；产品默认参数仍为100 MHz下的868时钟/位，即115200 bit/s。覆盖场景如下：

1. `GET_INFO`返回24字节设备与能力信息；
2. 单字节不匹配的`SET_CONFIG`返回`PARAMETER_RANGE`并锁存错误LED；
3. 精确28字节冻结配置返回ACK；
4. 通过串行Payload提交两条朝向中心的观测；
5. `START_LOCALIZATION`贯通真实T07至T11几何计算，计算LED曾置位并产生完成脉冲；
6. `GET_STATUS`返回`RESULT_READY`、可信四边形、2条观测、4个顶点、12607核心周期和`0x41`标志；
7. 27字节结果头逐位匹配距离平方`17179868135424016`及最远点索引`(0,2)`；
8. 40字节结果顶点页返回4个Q16.16顶点并通过独立CRC核对；
9. 起始索引等于结果顶点数时返回`RESULT_UNAVAILABLE`；
10. 输入帧CRC被破坏时返回`CRC_MISMATCH`，随后合法`GET_INFO`证明协议重新同步。

RTL顶点序列与Python列表相比采用不同循环起点，但四个坐标逐位一致且构成同一有序凸多边形；协议未规定首顶点规范化。最终消息为：

`PASS: radio_localization_fpga_top completed UART protocol, geometry and paging integration`

仿真结束于516286 ns。Python协议与数值模型回归23项全部通过。

## 5. 板级约束核对

| 顶层对象 | XDC对象 | 状态 |
|---|---|---|
| `clk_100mhz_i` | W5、10.000 ns主时钟 | 名称一致 |
| `reset_btn_i` | U18 | 名称一致 |
| `uart_rx_i` | B18 | 名称和方向一致 |
| `uart_tx_o` | A18 | 名称和方向一致 |
| `status_led_o[3:0]` | V19/U19/E19/U16 | 位号一致 |
| `debug_trigger_o` | J1 | 名称一致 |

该表是RTL/XDC静态交叉核对，不是综合或实现后的`report_io`证据。

## 6. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 通过 | Vivado `xvlog`编译全部T04至T13 RTL与顶层testbench |
| `ast` | 未通过严格门禁 | Vivado展开成功；技能严格解析器对当前实例版式仍报不支持结构 |
| `readability` | 未通过 | 严格组合源锥、声明布局和过程规模规则仍有阻断项 |
| `comment` | 未通过 | 新文件未满足技能完整双语头和逐声明语义注释要求 |
| `naming` | 未通过 | 工程同时存在T04/T05的`i_*/o_*`和后续模块的`*_i/*_o`约定 |
| `profile` | 未通过 | 显式分支、三过程FSM和严格版式规则仍有阻断项 |
| `testbench` | 通过 | 十类真实串行端到端场景PASS，最终日志无`FAIL` |
| `toolchain` | 通过动态仿真 | `xvlog`、`xelab`、`xsim -runall`实际执行；未执行综合/实现 |

严格门禁记录：命令适配器626项、响应适配器718项、顶层215项错误，均为当前技能严格风格/结构门禁结果。功能仿真通过不能替代这些可读性门禁或综合证据。

## 7. 已知限制与后续工作

- 顶层响应通道为单项保持队列，协议主机仍应遵守“一请求一响应”顺序；
- 错误LED在下一次被接受的START命令时清除，不提供单独清错命令；
- 最终多边形未规范化首顶点，也未执行全局共线检测；
- UART仿真使用加速位周期，115200 bit/s默认参数由既有T04独立动态仿真覆盖；
- 尚未运行综合、时序分析、`report_io`、实现或板级回环；
- 下一项T14应增加随机帧、随机观测、最大20条观测、分页边界和连续任务压力回归。
