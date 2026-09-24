# T07半平面约束生成验证记录

## 1. 结论

T07功能、模块级动态仿真和100 MHz全工程实现时序修复已完成。原RTL中四处signed 32×32乘法与异步复位寄存器形成了两级DSP48和长进位链路径，布线后WNS为-1.335 ns。修复后四次运算时分复用一条显式乘法通路，T07寄存器改为同步复位，Vivado将AREG/BREG/PREG吸收到DSP48中。重新布线后WNS为+0.511 ns、TNS为0，无setup/hold失败端点。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| 约束生成RTL | `rtl/geometry/bearing_constraint_gen.v` |
| CORDIC依赖 | `rtl/geometry/cordic_sincos.v` |
| 自检testbench | `tb/unit/tb_bearing_constraint_gen.v` |
| 位精确向量 | `tb/vectors/bearing_constraint_vectors.csv` |
| 结构化规格 | `spec/t07_constraint_spec.json` |
| 同名规格 | `spec/t07_constraint/bearing_constraint_gen_spec.md` |
| WaveJSON | `spec/t07_constraint/waveforms/bearing_constraint_gen_constraint_pair.json5` |
| Vivado日志 | `reports/t07_xsim/bearing_constraint_gen/` |
| 时序修复证据 | `reports/timing_repair_t07/` |

## 3. 实现契约

- 输入坐标为signed Q16.16，输入角度为18位无符号整周相位；
- 误差半角冻结为732相位LSB，18位加减自然处理跨零；
- 下边界使用`a=-sin(theta-delta)`、`b=cos(theta-delta)`；
- 上边界使用`a=sin(theta+delta)`、`b=-cos(theta+delta)`；
- 两条边界均计算`c=a*sensor_x+b*sensor_y`；
- `a`、`b`为signed Q2.30，`c`为66位有符号并具有46个小数位；
- 两次调用T06 CORDIC，下边界乘加与第二次CORDIC部分重叠；
- 四次坐标乘法时分复用一条signed 32×32 DSP通路，数据通路寄存器使用高有效同步复位；
- 下边界在接受请求后25周期有效，上边界在45周期有效并同时产生`done_o`；
- 忙时重复启动不覆盖当前事务，并产生单周期协议错误。

## 4. 动态仿真证据

工具：Vivado Simulator 2024.2，SW Build 5239630。

| testbench | 编译 | 展开 | 执行 | 结束时间 |
|---|---|---|---|---:|
| `tb_bearing_constraint_gen` | 通过 | 通过 | `PASS: bearing_constraint_gen matched 10 bit-exact observations` | 4840 ns |
| `tb_radio_localization_fpga_top` | 通过 | 通过 | `PASS: radio_localization_fpga_top completed UART protocol, geometry and paging integration` | 516286 ns |

10组向量全部来自T02位精确模型，覆盖0°、90°、180°、270°，359.6°与0.4°两侧跨零，正负Q16.16坐标，以及T02两测点和四测点集成场景中的四条观测。testbench逐位检查两组`a/b/c`、输出顺序、25/45周期固定延迟、单周期有效脉冲和忙时拒绝。

规格与RTL接口交叉校验通过。Python工程回归共23项，全部通过。

## 5. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 外部通过、内部门禁误报 | Vivado `xvlog`联合编译两个设计模块和testbench；内置formatter未识别合法的`cordic_sincos`实例 |
| `ast` | 未通过 | formatter在子模块实例处报告`unsupported_construct`，Vivado展开已确认实例与端口连接有效 |
| `readability` | 未通过 | Erie严格组合预算、版式和初始化规则仍有阻断项 |
| `comment` | 未通过 | 严格规则要求端口、声明、赋值和过程采用同线语义注释 |
| `naming` | 未通过 | 设计文档冻结的接口后缀命名与门禁要求的方向前缀冲突 |
| `profile` | 未通过 | ANSI端口形式、头部模板及严格版式仍有阻断项 |
| `testbench` | 通过 | Vivado XSim自检覆盖10组位精确观测且最终日志无`FAIL` |
| `toolchain` | 通过 | 模块与T13全链路XSim均PASS；全工程`synth_1`和`impl_1` route_design实际完成，正式布线时序报告通过 |

完整静态报告为`reports/t07_rtl_deliverable_gate.json`和`.md`。Vivado功能证据不能替代尚未通过的严格可读性门禁。

## 6. 已知限制与后续接口

- 全工程已完成到`route_design`并通过100 MHz时序；本次未生成bitstream，未执行板级测试；
- 输出采用设计文档规定的单周期有效脉冲，不带ready反压；T12命令控制器必须在对应周期采样；
- 本次验证的是约束生成，不包含T09的半平面分类、容差判断或交点运算；
- WaveDrom运行时仍不可用，因此只交付WaveJSON源，未宣称SVG渲染通过；
- 下一项可按任务顺序进入T08顶点双缓冲RAM与初始多边形加载器。
