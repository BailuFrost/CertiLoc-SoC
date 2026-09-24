# T07 DSP时序修复报告

## 结论

T07宽乘法时序违例已修复。针对`xc7a35tcpg236-1`重新执行全工程综合和实现至`route_design`后，100 MHz时钟的正式布线时序为：

| 指标 | 修复前 | 修复后 |
|---|---:|---:|
| WNS | -1.335 ns | +0.511 ns |
| TNS | -47.390 ns | 0.000 ns |
| setup失败端点 | 113 | 0 |
| WHS | +0.026 ns | +0.018 ns |
| hold失败端点 | 0 | 0 |

Vivado结论为`All user specified timing constraints are met.`

## 根因与修复

修复前的最差路径从T07的`lower_b_saved`/`upper_b_saved`经过两级DSP48E1与最长12级CARRY4到`product_y_saved`，数据路径延迟11.287 ns。T07操作数寄存器为带异步清零的`FDCE`，Vivado `DPIR-1`明确指出该复位形式阻止寄存器合并到DSP Block。

修复内容：

- T07状态和数据通路寄存器改为高有效同步复位；
- 四处条件分支的32×32乘法改为一个显式signed共享乘法器；
- 利用现有`START_UPPER`、`MUL_X`和`MUL_Y`状态完成输入及乘积流水，不改变第25/45周期可见延迟；
- 综合日志确认操作数寄存器和乘积寄存器被吸收到DSP，T07最终使用4个DSP48E1，AREG/BREG/PREG启用。

T07相关`DPIR-1`告警已全部消失；全工程`DPIR-1`数量由766降为636，`SYNTH-10`宽乘法告警由28降为24。余下告警来自T09/T11等其他模块，不再出现于T07层级。

## 验证证据

- T07模块XSim：10组位精确观测PASS，结束于4840 ns；
- T13全链路XSim：UART、几何计算与分页响应PASS，结束于516286 ns；
- 全工程`synth_1`：0 errors，0 critical warnings；
- 全工程`impl_1`：`route_design Complete!`，0未布线网络；
- 原始证据：`reports/timing_repair_t07/xsim/`、`t13_xsim/`和`implementation/`。

严格可读性交付门禁本次重跑时在长时间源锥分析中未返回结果，已手动终止，因此不宣称新门禁通过；Vivado编译、仿真、综合和实现证据均为实际执行结果。

## 范围

本次已执行到布线完成，未生成bitstream，未执行板级回环。
