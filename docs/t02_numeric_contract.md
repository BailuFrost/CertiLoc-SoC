# T02位精确定点数值契约

## 1. 模型边界

T02提供两个软件参考层：

1. 双精度模型：外接正720边形、示向角锥裁剪、顶点对直径平方；
2. 位精确定点模型：模拟后续RTL的相位、CORDIC、乘加、交点、裁剪、容量与错误标志。

模型不包含接收距离圆、最小包围圆、主动规划、UART协议或时钟周期调度。

## 2. 冻结格式

| 数据 | 格式 | 原始整数语义 |
|---|---|---|
| 坐标 | signed Q16.16，32位 | 米乘以 \(2^{16}\) |
| 输入角度 | unsigned 18位整周相位 | 一周等于 \(2^{18}\) |
| CORDIC角度累加器 | 32位整周相位 | 18位输入左移14位 |
| CORDIC X/Y | signed 36位、32个小数位 | 比输出多2个小数保护位 |
| 正弦、余弦 | signed Q2.30，32位 | 实数乘以 \(2^{30}\) |
| 半平面函数 | signed 66位 | 46个小数位 |
| 交点参数 | Q2.30 | 线段内钳位到0至1 |
| 距离平方 | unsigned 66位 | 平方米乘以 \(2^{32}\) |

## 3. 舍入和异常规则

- 浮点转定点、缩位和除法均采用“最近值，恰好半值时远离零”。
- 初始多边形ROM的每个坐标分量向远离零方向量化，避免圆域近似向内收缩。
- 坐标和正余弦输出执行饱和检查；任何饱和都使结果不可信。
- `EPS_HP = 2^30`，等价于一个Q16.16坐标LSB乘以单位Q2.30系数。
- `EPS_DEN = 2^30`，分母绝对值不大于该值时报告近并行。
- 近并行跨界边保留内侧端点并置 `parallel_edge`，最终 `trusted=false`。
- 顶点超过1024个时截断写入、置 `capacity_overflow`，最终 `trusted=false`。
- 交点残差落在 `[-EPS_HP, 0)` 时保留交点并置 `quantization_margin_used`；该标志本身不使结果不可信。

## 4. CORDIC契约

- 旋转模式，每轮一次移位加减，共18轮。
- 初始X装入18轮CORDIC增益倒数，不在输出端乘法。
- 输入按象限预处理至0°至90°，输出恢复正余弦符号。
- 反正切表和增益常量由 `cordic.py` 生成，并在黄金向量中固化。
- 18位输入相位只限定输入分辨率；内部32位角度累加器用于降低反正切表逐项量化误差。

## 5. 交付和复现

从项目根目录运行：

```powershell
python -m unittest discover -s .\fpga_stage1\tb\unit -p 'test_*.py' -v
python .\fpga_stage1\model\generate_t02_artifacts.py
```

生成物：

- `tb/vectors/cordic_q2_30_vectors.csv`；
- `tb/vectors/cordic_constants.json`；
- `tb/vectors/initial_polygon_720_q16_16.mem`；
- `tb/vectors/geometry_integration_vectors.json`；
- `reports/t02_fixed_point_error_report.md`。

T09确定实际除法器位宽和流水结构后，必须重新运行交点残差扫描，才能把当前EPS基线升级为RTL冻结常量。
