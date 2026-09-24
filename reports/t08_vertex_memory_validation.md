# T08顶点双缓冲RAM与初始多边形加载验证记录

## 1. 结论

T08功能实现、模块级动态仿真和顶点RAM定向综合验证已经完成。交付包含720×64位初始多边形ROM、两个逻辑1024×64位顶点缓冲区以及流水加载器。Vivado XSim 2024.2两组testbench均输出唯一`PASS`且无`FAIL`；Vivado OOC综合将RAM识别为2048×64位真双口Block RAM，最终使用4个`RAMB36E1`，无综合错误。

本次只对T08顶点RAM执行了定向OOC综合，未执行全工程综合、实现或板级测试。

## 2. 交付资产

| 类型 | 文件 |
|---|---|
| 初始多边形ROM | `rtl/memory/initial_polygon_rom.v` |
| 顶点双缓冲RAM | `rtl/memory/vertex_ram_dual_buffer.v` |
| 初始多边形加载器 | `rtl/memory/initial_polygon_loader.v` |
| RAM testbench | `tb/unit/tb_vertex_ram_dual_buffer.v` |
| 加载器testbench | `tb/unit/tb_initial_polygon_loader.v` |
| ROM初始化文件 | `tb/vectors/initial_polygon_720_q16_16.mem` |
| 结构化规格 | `spec/t08_vertex_memory_spec.json` |
| 同名规格 | `spec/t08_vertex_memory/*_spec.md` |
| Vivado日志 | `reports/t08_xsim/` |
| RAM模板修复证据 | `reports/t08_ram_template_repair/` |

## 3. 实现契约

### 3.1 初始多边形ROM

- 固定保存720个半径1800 m的外接正多边形顶点；
- 顶点顺序为逆时针；
- 每个64位字打包`{x_q16_16, y_q16_16}`；
- 同步读延迟一个时钟，越界地址返回零。

### 3.2 顶点双缓冲RAM

- A、B两个逻辑缓冲区，各1024×64位；缓冲区位和10位地址合并为11位物理地址；
- 两个逻辑端口均可独立选择缓冲区、读写方向和地址；
- 同步读返回单周期有效脉冲；
- 支持不同缓冲区并发访问，以及同一缓冲区不同地址的并发访问；
- 禁止两端口同周期访问同一物理地址且至少一端口写入。

### 3.3 初始多边形加载器

- 空闲时锁存目标缓冲区；
- 连续发出ROM地址0至719，并将响应逐拍写入RAM；
- 接受启动至最后一次写入及`done_o`相隔固定721周期；
- 完成时顶点计数为720；
- 忙时重复启动不会改变目标缓冲区，并产生单周期协议错误。

## 4. 动态仿真证据

工具：Vivado Simulator 2024.2，SW Build 5239630。

| testbench | 编译 | 展开 | 执行 | 结束时间 |
|---|---|---|---|---:|
| `tb_vertex_ram_dual_buffer` | 通过 | 通过 | `PASS: vertex_ram_dual_buffer concurrent access checks completed` | 80 ns |
| `tb_initial_polygon_loader` | 通过 | 通过 | `PASS: initial_polygon_loader copied both 720-vertex buffers bit-exactly` | 43380 ns |

RAM testbench覆盖不同缓冲区并发读写、同一缓冲区不同地址并发写入和交叉读回。加载器testbench依次将全部720个顶点装入A、B缓冲区并逐字比较1440次，同时复核A缓冲区未被B加载覆盖、721周期延迟、720计数和忙时启动拒绝。

规格与三个RTL模块的接口交叉校验通过。Python工程回归共23项，全部通过。

## 5. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 通过 | 内部静态编译通过；Vivado `xvlog`实际编译三个设计模块和两组testbench |
| `ast` | 未通过 | formatter报告3项格式化错误，Vivado展开未报告结构错误 |
| `readability` | 未通过 | Erie严格组合预算、版式、RAM多写端口分析和初始化规则仍有阻断项 |
| `comment` | 未通过 | 严格规则要求端口、声明、赋值和过程采用同线语义注释 |
| `naming` | 未通过 | 设计接口后缀形式及端口编号与门禁命名规则冲突 |
| `profile` | 未通过 | ANSI端口、复位形式、头部模板和严格版式仍有阻断项 |
| `testbench` | 通过 | 两组Vivado XSim自检均PASS且最终日志无`FAIL` |
| `toolchain` | 通过模块级执行 | `xvlog`、`xelab`和`xsim -runall`均实际执行 |

完整静态报告为`reports/t08_rtl_deliverable_gate.json`和`.md`。功能仿真与RAM定向综合证据不能替代严格可读性门禁、全工程综合或实现证据。

## 6. 已知限制与后续接口

- 顶点RAM已在`xc7a35tcpg236-1`上定向推断为4个`RAMB36E1`；ROM、全工程资源和100 MHz时序仍未验证；
- `initial_polygon_720_q16_16.mem`必须作为Vivado memory initialization file加入工程；
- RAM不在复位时清空，顶点有效范围由上层维护的顶点数决定；
- 同址读写和同址双写行为未定义，上层仲裁必须禁止；
- WaveDrom运行时仍不可用，因此只交付WaveJSON源，未宣称SVG渲染通过；
- 下一项可进入T09半平面分类器与线段交点模块。
