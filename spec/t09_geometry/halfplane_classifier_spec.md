# halfplane_classifier 模块规格

> RTL：`rtl/geometry/halfplane_classifier.v`

模块接收Q16.16坐标、Q2.30系数和具有46个小数位的66位常数，计算 `f=a*x+b*y-c`。内部使用67位求和结果判断溢出，输出端饱和至66位有符号范围。

分类规则固定为 `f >= -2^30`。其中 `-2^30 <= f < 0` 时同时置位 `margin_used_o`，`f=0` 不使用容差。接受启动至 `done_o` 固定4周期；忙期间启动被拒绝并产生协议错误脉冲。时序源见 [halfplane_classifier_fixed_latency.json5](waveforms/halfplane_classifier_fixed_latency.json5)。
