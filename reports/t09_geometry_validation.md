# T09分类器与交点模块验证记录

## 1. 结论

T09首版RTL、规格和模块级动态仿真已经完成。Vivado XSim 2024.2实际编译、展开并执行两组自检testbench，最终日志各输出唯一`PASS`且无`FAIL`。`EPS_HP=2^30`与`EPS_DEN=2^30`在负容差边界、分母等于阈值及阈值加一的定向测试中与T02模型契约一致，因此本阶段保留该基线。

按当前开发范围，本任务不执行综合、实现或板级测试。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| 半平面分类器 | `rtl/geometry/halfplane_classifier.v` |
| 线段交点模块 | `rtl/geometry/segment_intersection.v` |
| 自检testbench | `tb/unit/tb_halfplane_classifier.v`、`tb/unit/tb_segment_intersection.v` |
| 结构化规格 | `spec/t09_geometry_spec.json` |
| 同名规格与时序源 | `spec/t09_geometry/` |
| Vivado日志 | `reports/t09_xsim/` |

## 3. 实现契约

### 3.1 半平面分类器

- 计算具有46个小数位的 `f=a*x+b*y-c`；
- 输入坐标为Q16.16，系数为Q2.30，常数和结果为66位有符号数；
- `f >= -2^30`判定为内部点，且仅在`-2^30 <= f < 0`置位量化余量标志；
- 67位内部求和溢出时对66位输出饱和并显式报告；
- 接受启动至完成固定4周期，忙时重复启动被拒绝。

### 3.2 线段交点

- 按 `t=f(A)/(f(A)-f(B))` 计算Q2.30比例并限制在`[0,1]`；
- 使用30轮恢复除法，比例和坐标均采用最近值舍入；
- `|f(A)-f(B)| <= 2^30`报告近并行，不输出有效交点；
- 一般除法路径37周期，端点或比例钳位路径6周期，近并行路径2周期；
- 坐标输出采用32位有符号饱和，忙时重复启动被拒绝。

## 4. 动态仿真证据

工具：Vivado Simulator 2024.2，SW Build 5239630。

| testbench | 编译 | 展开 | 执行 | 覆盖 |
|---|---|---|---|---|
| `tb_halfplane_classifier` | 通过 | 通过 | `PASS: halfplane_classifier matched 6 directed vectors` | 正值、零、负容差边界、越界、混合乘加、正饱和、4周期延迟、忙时启动 |
| `tb_segment_intersection` | 通过 | 通过 | `PASS: segment_intersection matched 6 directed vectors` | 中点、1/3、2/3、端点、阈值加一、阈值近并行、三类延迟、忙时启动 |

结构化规格与两个RTL模块的接口交叉校验通过。Python工程回归共23项，全部通过。

## 5. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 通过 | Vivado `xvlog`实际编译两个RTL模块及两组testbench |
| `ast` | 未通过严格门禁 | Vivado展开通过；可读Verilog严格规则仍报告结构/格式项 |
| `readability` | 未通过 | 严格组合预算、版式及人工复核规则仍有阻断项 |
| `comment` | 未通过 | 严格规则要求双语头及逐声明、赋值、过程语义注释 |
| `naming` | 未通过 | 工程既有`*_i/*_o`后缀约定与门禁要求的`i_*/o_*`前缀冲突 |
| `profile` | 未通过 | 头部模板、显式分支及严格版式仍有阻断项 |
| `testbench` | 通过 | 两组Vivado XSim自检均PASS且最终日志无`FAIL` |
| `toolchain` | 通过模块级执行 | `xvlog`、`xelab`、`xsim -runall`均实际执行 |

严格报告分别为`reports/t09_halfplane_deliverable_gate.*`和`reports/t09_intersection_deliverable_gate.*`，当前分别记录234项和378项错误。功能仿真通过不能替代严格可读性门禁或综合证据。

## 6. 已知限制与后续接口

- 尚未综合，未确认乘法器/除法器资源映射、100 MHz时序及功耗；
- 30轮除法器一次只能处理一条边，上层T10必须在`busy_o`期间停顿；
- `parallel_o`和`arithmetic_saturated_o`必须由T10提升为结果不可信状态，不能静默忽略；
- 当前EPS复核是阈值邻域定向验证与T02软件回归，不等同于后续T14的大规模随机扫描；
- WaveDrom运行时仍不可用，只交付WaveJSON源，未宣称SVG渲染通过；
- 下一项可进入T10多边形裁剪引擎。
