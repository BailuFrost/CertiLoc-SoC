# T04 UART RX/TX实现与验证记录

## 1. 结论

T04 的功能实现与模块级动态仿真已经完成：UART发送器、UART接收器、周期语义模型、同名模块规格和定向自检 testbench 均已建立。Vivado 2024.2的 `xvlog`、`xelab` 和 `xsim` 已分别完成TX与RX编译、展开和执行，两组自检均输出唯一 `PASS` 且无 `FAIL`。当前仍不宣称综合、实现或板级验证已经通过。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| 发送RTL | `rtl/comm/uart_tx.v` |
| 接收RTL | `rtl/comm/uart_rx.v` |
| 发送规格 | `spec/t04_uart/uart_tx_spec.md` |
| 接收规格 | `spec/t04_uart/uart_rx_spec.md` |
| 规格源合同 | `spec/t04_uart_spec.json` |
| 周期语义模型 | `model/uart_reference.py` |
| TX testbench | `tb/unit/tb_uart_tx.v` |
| RX testbench | `tb/unit/tb_uart_rx.v` |
| 模型单元测试 | `tb/unit/test_t04_uart_model.py` |
| XSim原始日志 | `reports/t04_xsim/uart_tx/*.log`、`reports/t04_xsim/uart_rx/*.log` |

## 3. 冻结行为

- 系统时钟100 MHz，整数位周期868个时钟，8N1，最低位优先。
- TX输入采用 `valid/ready`；忙期间不接受或覆盖新字节。
- RX输入采用两级同步；起始位中心确认后，以868时钟间隔采样8个数据位和停止位。
- RX输出有效信号和数据在下游反压期间保持稳定。
- 错误停止位不提交字节，并产生一个系统时钟的帧错误脉冲。
- 模块对外保持阶段1冻结的同步高有效 `i_reset` 接口；内部转换为低有效复位网络。上游复位控制器保证 `i_reset` 只在系统时钟边沿变化。

## 4. 已执行验证

### 4.1 Python周期语义模型

命令：

```powershell
python -m unittest discover -s .\fpga_stage1\tb\unit -p 'test_*.py' -v
```

结果：23项工程单元测试全部通过，其中T04为4项：

- 256个字节值全覆盖往返；
- `0xA5`最低位优先线路顺序；
- 错误停止位报告；
- 发送端位周期相对接收端为-2%和+2%时正确恢复字节。

### 4.2 RTL静态门禁

报告：`reports/t04_rtl_deliverable_gate.json` 和 `reports/t04_rtl_deliverable_gate.md`。

| 公共门禁 | 状态 | 说明 |
|---|---|---|
| `compile` | 通过 | 2个RTL文件、2个模块、0个解析错误 |
| `ast` | 通过 | formatter-preserve AST成功建立 |
| `readability` | 未通过 | 通用Erie规则对注释列、区域分组、组合操作预算和内部复位生成方式仍有阻断项 |
| `comment` | 通过 | 2个RTL文件无注释覆盖错误 |
| `naming` | 未通过 | 剩余10项主要来自内部高转低复位网络及规则分组要求 |
| `profile` | 通过 | 规则配置成功加载 |
| `testbench` | 通过外部动态验证 | TX与RX自检均由Vivado XSim执行并输出 `PASS` |
| `toolchain` | 通过模块级执行 | Vivado/XSim 2024.2，完成编译、展开和运行 |

技能内置formatter对testbench的结构检查存在“only single module sources are currently supported”误报；本次Vivado工具链已经直接编译并执行真实testbench，因此动态工具证据优先于该误报。

### 4.3 Vivado XSim动态仿真

工具：Vivado Simulator 2024.2，SW Build 5239630。

| 模块 | `xvlog` | `xelab` | `xsim -runall` | 仿真结束时间 |
|---|---|---|---|---:|
| `uart_tx` | 通过 | 通过 | `PASS: uart_tx directed checks completed` | 347285 ns |
| `uart_rx` | 通过 | 通过 | `PASS: uart_rx directed checks completed` | 443975 ns |

TX覆盖复位空闲状态、`00`、`FF`、`A5`、`3C`完整8N1位序和位周期。RX覆盖标准帧、发送位周期851/885时钟的正负约2%偏差、下游反压、错误停止位和假起始脉冲。为兼容XSim，testbench中的Icarus专用 `$finish_and_return` 已替换为标准 `$finish`；失败路径仍输出 `FAIL`，批处理判据为唯一 `PASS` 且日志中无 `FAIL`。

## 5. 规格图状态

两份同名规格和WaveJSON源文件已经生成。受控规格生成器检查到当前环境缺少 `npm` 和 `wavedrom@3.6.1` 后按规则停止，因此没有伪造SVG渲染成功证据。待安装规定工具链后，应重新执行 `write-spec`，生成并核对两张SVG时序图。

## 6. 后续闭环

1. 修复或经项目评审豁免剩余Erie可读性门禁，重点核对项目复位契约与通用低有效复位规则的冲突；
2. 安装受控WaveDrom运行时并重新发布规格SVG；
3. 在Basys 3上执行USB-UART回环，并测量连续帧与允许时钟偏差下的稳定性；
4. 板级回环完成后把T04状态升级为“板级验证关闭”。
