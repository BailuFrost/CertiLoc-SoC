# T05帧解析与结果编码实现验证记录

## 1. 结论

T05首版功能实现和模块级动态仿真已经完成。交付包含逐字节CRC-16/CCITT-FALSE引擎、命令帧解析器和通用响应帧编码器。Vivado XSim 2024.2已对三组RTL与testbench完成编译、展开和执行，全部输出唯一`PASS`且无`FAIL`。

按用户当前范围，本任务不执行综合、实现或板级回环。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| CRC RTL | `rtl/comm/crc16_ccitt_byte.v` |
| 帧解析RTL | `rtl/comm/packet_decoder.v` |
| 帧编码RTL | `rtl/comm/packet_encoder.v` |
| CRC testbench | `tb/unit/tb_crc16_ccitt_byte.v` |
| 解析器testbench | `tb/unit/tb_packet_decoder.v` |
| 编码器testbench | `tb/unit/tb_packet_encoder.v` |
| 结构化规格源 | `spec/t05_protocol_spec.json` |
| 同名规格 | `spec/t05_protocol/*_spec.md` |
| Vivado原始日志 | `reports/t05_xsim/` |

## 3. 已实现行为

### 3.1 CRC引擎

- `poly=0x1021`、`init=0xFFFF`、非反射、无最终异或；
- 每字节MSB优先，8个系统时钟完成；
- `i_clear`与`i_start`同时置位时开始新帧；
- 标准检查串`123456789`输出`0x29B1`。

### 3.2 packet_decoder

- 搜索`A5 5A`并支持`A5 A5 5A`重叠重同步；
- 解析版本、命令、小端序号、小端长度、0至244字节载荷和小端CRC；
- CRC只覆盖VERSION至PAYLOAD；
- CRC通过后才提交帧，提交前载荷只写入内部暂存；
- 提供244字节同步载荷读取端口；
- 识别版本、命令、长度、CRC和帧内字节超时错误；
- 帧和错误输出均使用`valid/ready`保持协议。

### 3.3 packet_encoder

- 输出SOF、版本、命令、小端序号、小端长度、流式载荷和小端CRC；
- UART TX反压期间保持输出字节稳定；
- 只对实际完成输出握手的VERSION至PAYLOAD字节更新CRC；
- 支持0至244字节载荷，拒绝超长请求；
- 最后一个CRC字节被接受后产生完成脉冲。

## 4. 动态仿真证据

工具：Vivado Simulator 2024.2，SW Build 5239630。

| testbench | 编译 | 展开 | 执行 | 结束时间 |
|---|---|---|---|---:|
| `tb_crc16_ccitt_byte` | 通过 | 通过 | `PASS: crc16_ccitt_byte standard vector completed` | 855 ns |
| `tb_packet_decoder` | 通过 | 通过 | `PASS: packet_decoder directed checks completed` | 4590 ns |
| `tb_packet_encoder` | 通过 | 通过 | `PASS: packet_encoder directed checks completed` | 1220 ns |

解析器动态用例覆盖：GET_INFO、重叠SOF、READ_RESULT的8字节载荷读取、CRC错误和缩短参数后的超时。编码器按T03黄金向量逐字节核对ACK帧`A55A018003000400110000000992`，并检查250字节超长请求拒绝。

Python工程回归共23项，全部通过；其中T03协议模型继续提供CRC、最大244字节载荷、重同步和命令载荷语义的黄金参考。

## 5. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 外部通过、内部门禁误报 | Vivado `xvlog`真实编译3个设计模块及3个testbench；内置formatter不能识别两处合法CRC实例 |
| `ast` | 部分通过 | CRC模块可解析；解析器和编码器在CRC实例处被formatter报告unsupported_construct |
| `readability` | 未通过 | 当前Erie严格版式、注释覆盖和组合预算仍有阻断项 |
| `comment` | 未通过 | 首版RTL尚未补齐Erie逐实体同线注释 |
| `naming` | 未通过 | 严格规则仍报告区域和声明命名问题 |
| `profile` | 未通过 | 受上述formatter实例识别失败连带阻断 |
| `testbench` | 通过 | 三组Vivado XSim自检全部PASS且日志无FAIL |
| `toolchain` | 通过模块级执行 | `xvlog`、`xelab`、`xsim -runall`均实际执行 |

完整静态报告为`reports/t05_rtl_deliverable_gate.json`和`.md`。外部Vivado编译证据优先用于判断语法与实例连接是否有效，但不会替代尚未通过的可读性门禁。

## 6. 已知限制与后续接口

- T05验证命令帧的结构、版本、命令集合、长度和CRC；SET_CONFIG、LOAD_OBSERVATIONS及READ_RESULT的字段级语义检查由后续命令控制器执行。
- 载荷缓存当前为244×8位寄存器数组；综合阶段需确认推断资源，必要时改为同步RAM结构。
- 受控WaveDrom运行时仍缺少`npm`与`wavedrom@3.6.1`，因此只交付WaveJSON源，未宣称SVG渲染通过。
- 按当前计划，下一任务可进入T06 18次迭代CORDIC；T05的综合、实现和板级联调暂缓。

