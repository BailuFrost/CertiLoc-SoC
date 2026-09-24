# Basys 3板级接口基线

## 1. 适用范围

本文档冻结阶段1顶层模块 `radio_localization_fpga_top` 的板级接口。目标器件为 XC7A35T-1CPG236C，Vivado 器件名为 `xc7a35tcpg236-1`。

管脚来自 Digilent 官方 `Basys-3-Master.xdc`。USB-UART方向按 FPGA 顶层端口定义：`uart_rx_i` 是 PC 向 FPGA 发送的数据，`uart_tx_o` 是 FPGA 向 PC 发送的数据。

## 2. 顶层端口与管脚

| 顶层端口 | 方向 | 宽度 | Basys 3资源 | FPGA管脚 | 电平标准 | 功能 |
|---|---|---:|---|---|---|---|
| `clk_100mhz_i` | 输入 | 1 | 板载100 MHz振荡器 | W5 | LVCMOS33 | 唯一系统时钟 |
| `reset_btn_i` | 输入 | 1 | 中心按键BtnC | U18 | LVCMOS33 | 高有效异步复位请求 |
| `uart_rx_i` | 输入 | 1 | USB-UART的PC发送通道 | B18 | LVCMOS33 | 115200 bit/s、8N1接收 |
| `uart_tx_o` | 输出 | 1 | USB-UART的PC接收通道 | A18 | LVCMOS33 | 115200 bit/s、8N1发送 |
| `status_led_o[0]` | 输出 | 1 | LED0 | U16 | LVCMOS33 | 空闲状态 |
| `status_led_o[1]` | 输出 | 1 | LED1 | E19 | LVCMOS33 | 接收状态 |
| `status_led_o[2]` | 输出 | 1 | LED2 | U19 | LVCMOS33 | 计算状态 |
| `status_led_o[3]` | 输出 | 1 | LED3 | V19 | LVCMOS33 | 错误状态 |
| `debug_trigger_o` | 输出 | 1 | Pmod JA1 | J1 | LVCMOS33 | 可选示波器/逻辑分析仪触发 |

## 3. 时钟与复位契约

- `clk_100mhz_i` 的周期约束为10 ns，占空比约50%。
- 首版不使用 PLL、MMCM、门控时钟或派生时钟。
- `reset_btn_i` 相对系统时钟异步。
- 复位控制器必须采用高有效异步置位、同步释放，并向其余逻辑输出统一的同步高有效内部复位。
- 按键抖动在复位语义下允许延长复位时间，但不得造成同步释放链失效。

## 4. UART契约

- 格式固定为115200 bit/s、8数据位、无校验、1停止位。
- 在100 MHz系统时钟下，首版采用 `CLKS_PER_BIT=868`。
- `uart_rx_i` 必须先经过双触发器同步，再进入起始位检测逻辑。
- XDC不对异步UART输入设置虚假的同步输入延迟；CDC安全性由RTL同步器结构和后续时序报告证明。

## 5. XDC使用规则

约束文件 `constraints/basys3_radio_localization.xdc` 只包含本阶段实际使用的资源，不包含未使用的开关、数码管、VGA、PS/2和Flash管脚。

加入Vivado工程后必须检查：

1. 顶层模块端口名与XDC完全一致；
2. `report_clocks` 中存在周期10 ns的 `clk_100mhz`；
3. `report_io` 中所有九个板级端口均被正确约束；
4. 实现阶段无 `NSTD-1`、`UCIO-1` 或管脚冲突；
5. UART方向不得互换；
6. 若取消 `debug_trigger_o` 顶层端口，必须同时移除对应XDC约束。

## 6. 来源与验证状态

- 管脚来源：Digilent官方 `digilent-xdc/Basys-3-Master.xdc`，2026-09-19核对。
- UART方向交叉核对：Digilent《Basys 3 FPGA Board Reference Manual》的USB-UART章节。
- 当前已使用本机Vivado Simulator 2024.2完成T04至T13动态仿真，T13顶层端口与本XDC约束对象已逐名静态核对。按照当前开发范围，尚未执行综合、实现、实现后XDC检查或下板验证。
