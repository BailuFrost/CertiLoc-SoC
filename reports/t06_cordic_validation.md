# T06迭代CORDIC实现验证记录

## 1. 结论

T06首版功能实现和模块级动态仿真已经完成。交付包含18次迭代旋转模式CORDIC、全四象限相位包装、输入端增益补偿以及忙时重复启动保护。Vivado XSim 2024.2已完成RTL与testbench的编译、展开和执行，最终日志输出唯一`PASS`且无`FAIL`。

按当前开发范围，本任务不执行综合、实现或板级测试。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| CORDIC RTL | `rtl/geometry/cordic_sincos.v` |
| 自检testbench | `tb/unit/tb_cordic_sincos.v` |
| 结构化规格 | `spec/t06_cordic_spec.json` |
| 同名规格 | `spec/t06_cordic/cordic_sincos_spec.md` |
| WaveJSON | `spec/t06_cordic/waveforms/cordic_sincos_fixed_latency.json5` |
| Vivado日志 | `reports/t06_xsim/cordic_sincos/` |

## 3. 实现契约

- 输入为18位无符号整周相位；输出正弦、余弦为signed Q2.30；
- X/Y内部寄存器为36位Q4.32，保留2个额外小数保护位和幅值保护位；
- 内部角度采用32位整周相位，输入左移14位；
- 初始X为量化增益倒数`36'h09B74EDA8`，不使用输出乘法；
- 每周期执行一次算术移位加减，共18次微旋转；
- Q4.32至Q2.30采用最近值、半值远离零舍入；
- 接受`start_i`至`done_o`相隔固定19个上升沿，`done_o`脉冲一个周期；
- 忙时重复启动不覆盖当前数据，并产生单周期`protocol_error_o`。

## 4. 动态仿真证据

工具：Vivado Simulator 2024.2，SW Build 5239630。

| testbench | 编译 | 展开 | 执行 | 结束时间 |
|---|---|---|---|---:|
| `tb_cordic_sincos` | 通过 | 通过 | `PASS: cordic_sincos matched 74 bit-exact vectors` | 16320 ns |

自检testbench从T02黄金CSV读取全部74组向量并逐位比较正余弦结果，同时检查固定19周期延迟、单周期`done_o`以及忙时重复启动只产生一次协议错误。向量覆盖四个主轴角、象限边界、359°附近输入和确定性随机角。

T02软件模型已扫描全部262144个输入相位：最大正弦误差`7.625663645369e-06`，最大余弦误差`7.626606159453e-06`，内部36位通路饱和次数为0。本次RTL仿真逐位匹配该模型固化向量。

Python工程回归共23项，全部通过。

## 5. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 通过 | 内部门禁静态编译通过；Vivado `xvlog`实际编译通过 |
| `ast` | 未通过 | formatter对当前结构仍报告1项格式化错误，Vivado语法分析未报错 |
| `readability` | 未通过 | Erie严格组合预算、版式和初始化规则报告阻断项 |
| `comment` | 未通过 | 严格规则要求每个端口、声明、赋值和过程采用同线语义注释 |
| `naming` | 未通过 | 项目接口采用设计文档冻结的`start_i/busy_o/done_o`后缀形式，与门禁要求的`i_/o_`前缀冲突 |
| `profile` | 未通过 | ANSI端口形式、头部模板及严格版式仍有阻断项 |
| `testbench` | 通过 | Vivado XSim自检覆盖74组位精确向量且最终日志无`FAIL` |
| `toolchain` | 通过模块级执行 | `xvlog`、`xelab`和`xsim -runall`均实际执行 |

严格静态报告为`reports/t06_rtl_deliverable_gate.json`和`.md`。当前功能证据不能替代尚未通过的严格可读性门禁。

## 6. 已知限制与后续接口

- 本次未执行综合，因此不宣称DSP使用数、LUT/FF资源、100 MHz时序收敛或功耗结果；
- 本次未进行262144个输入的RTL穷举仿真；全相位误差边界来自T02位精确软件扫描，RTL证据为74组逐位向量；
- WaveDrom运行时仍不可用，因此交付WaveJSON源但未宣称SVG渲染通过；
- T07可直接使用`start_i/busy_o/done_o`请求上下边界角的正余弦结果，并在收到第一次`done_o`后再启动第二次计算。
