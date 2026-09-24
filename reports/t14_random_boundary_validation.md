# T14随机回归与边界测试报告

## 1. 结论

T14通过。固定种子软件回归、RTL位精确随机/边界回归、协议模糊测试和连续1000任务压力测试均已执行，最终日志只有`PASS`、没有`FAIL`。

## 2. 软件随机与数值边界

执行工具：`model/run_t14_regression.py`，随机种子`0x1415b301`。

| 项目 | 结果 |
|---|---:|
| 总用例数 | 1006 |
| 随机真源用例 | 1000 |
| 观测数量范围 | 2至20 |
| 固定边界用例 | 跨0°、空域、负坐标、圆边界、20观测、近平行 |
| 最大定点顶点数 | 10 |
| 半平面/容量不变量失败 | 0 |
| 真源包含性失败 | 0 |
| 浮点/定点空域分类差异 | 0 |
| 顶点Hausdorff误差最大值 | 1.180691113 m |
| 顶点Hausdorff误差P95 | 0.062728494 m |
| 直径平方误差最大值 | 3764.653616717 m² |
| 直径平方误差P95 | 5.040271523 m² |

交点回写采用2个坐标LSB的连续裁剪包含性容差；结果`error_flags[0]`继续明确报告量化裕量使用，未把容差内偏差静默当作精确值。完整机器可读统计见`t14_software_regression.json`。

## 3. RTL位精确联合回归

工具：Vivado XSim 2024.2。`tb_localization_command_ctrl.v`读取固定生成的24组RTL向量，逐事务检查：

- 观测提交数量与2至20条边界；
- `trusted`、区域类型、顶点数量、距离平方和错误标志；
- RTL顶点集合与位精确Python模型逐点相等，允许循环首顶点不同；
- RTL最远点索引实际指向距离平方最大值；
- 最大20条观测、跨0°、空域、负坐标、圆边界和近平行场景；
- 在同一配置与观测下连续执行1000次完整任务，检查序号、有效性、可信度、区域、顶点数和距离无残留污染。

仿真时间为126189026 ns，宿主执行约18秒。日志结尾：

```text
INFO: T14 continuous stress completed 1000 jobs
PASS: localization_command_ctrl command, restart, RAM and geometry integration
```

## 4. 协议随机与恢复

`tb_packet_decoder.v`在既有定向测试之后增加固定种子模糊回归：256个随机合法零载荷帧、其中每隔一轮先注入一个坏CRC帧，并在帧前插入1至8个噪声字节。每个合法帧还保持三周期背压，检查元数据稳定。

覆盖结果：256个合法帧、128个坏CRC帧、噪声重同步、重叠SOF、接收超时和Payload只读窗口全部通过。日志结尾：

```text
PASS: packet_decoder directed and 256-frame randomized checks completed
```

## 5. 证据文件

| 证据 | 路径 |
|---|---|
| 软件统计 | `reports/t14_software_regression.json`、`.md` |
| RTL向量清单 | `tb/vectors/t14_regression_manifest.json` |
| RTL向量 | `tb/vectors/t14_case_meta.mem`、`t14_observations.mem`、`t14_expected_vertices.mem` |
| 控制器XSim | `reports/t14_xsim/localization_command_ctrl/` |
| 协议XSim | `reports/t14_xsim/packet_decoder/` |

## 6. 公共质量矩阵

| 门禁 | 状态 | 证据或限制 |
|---|---|---|
| `compile` | 通过外部编译 | 两条XSim链均由`xvlog`成功编译；后续T15全工程综合0 error |
| `ast` | 未通过技能严格门禁 | 既有T12/T13报告仍记录格式化AST解析阻断；本轮全目录复跑长时间无输出后停止 |
| `readability` | 未通过既有严格门禁 | T12/T13的过程规模、组合源锥和版式问题未在T14范围内重构 |
| `comment` | 未通过既有严格门禁 | 既有逐声明语义注释覆盖不足 |
| `naming` | 未通过既有严格门禁 | 工程仍混用`i_*/o_*`与`*_i/*_o` |
| `profile` | 未通过既有严格门禁 | 既有严格三过程FSM与版式规则阻断仍在 |
| `testbench` | 通过 | 1006软件用例、24组RTL向量、256随机协议帧、1000连续任务 |
| `toolchain` | 通过动态仿真 | Vivado XSim 2024.2实际编译、展开与执行 |

功能与工具链通过不替代尚未关闭的严格可读性门禁。
