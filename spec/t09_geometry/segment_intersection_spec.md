# segment_intersection 模块规格

> RTL：`rtl/geometry/segment_intersection.v`

模块按 `t=f(A)/(f(A)-f(B))` 求线段与边界的交点。若分母绝对值不大于 `2^30`，模块在2周期后报告 `parallel_o`，不产生有效坐标。常规路径执行30轮恢复除法，将比例舍入为Q2.30并限制在 `[0,1]`，随后对两维坐标执行最近值舍入。

常规除法路径固定37周期；零端点或比例钳位路径为6周期。所有完成、有效、近并行和协议错误状态均为单周期脉冲。时序源见 [segment_intersection_iterative.json5](waveforms/segment_intersection_iterative.json5)。
