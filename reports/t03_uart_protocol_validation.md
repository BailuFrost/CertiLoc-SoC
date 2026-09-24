# T03 UART协议验证报告

## 固定参数

| 项目 | 数值 |
|---|---:|
| SOF | A5 5A |
| VERSION | 01 |
| CRC | CRC-16/CCITT-FALSE |
| CRC参数 | poly=1021, init=FFFF, refin=false, refout=false, xorout=0000 |
| CRC线路字节序 | 小端，低字节先发送 |
| 最大Payload | 244字节 |
| 最大整帧 | 254字节 |
| 顶点分页上限 | 16个/帧 |
| 帧间字节超时 | 10,000,000个100 MHz周期，即100 ms |

## 生成结果

- 合法黄金帧：15组；
- CRC标准检查串 `123456789`：0x29B1；
- 最大黄金帧：`load_twenty_observations`，Payload 244字节；
- 所有PC到FPGA黄金帧均通过CRC、长度和命令载荷语义校验；
- 距离平方按unsigned 66位编码为9字节，高6位保留为0；
- 结果顶点采用按需分页，不在定位完成后自动发送全部顶点。

## RTL使用边界

`packet_decoder`必须先完成整帧CRC验证，再一次性提交配置或观测。CRC错误、长度错误、超时和未知命令不得修改有效任务状态。该报告是Python协议模型证据，不是UART物理层、RTL仿真或Vivado综合证据。
