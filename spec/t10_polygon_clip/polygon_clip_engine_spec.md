# polygon_clip_engine 模块规格

> RTL：`rtl/geometry/polygon_clip_engine.v`

模块对当前双缓冲RAM中的一个闭合多边形执行一次Sutherland-Hodgman半平面裁剪。引擎先读取末顶点作为边起点，再依次读取地址0至`count-1`作为边终点，因此显式覆盖首尾闭环。输出写入输入缓冲区的另一侧。

每个端点复用T09分类器；跨界边复用T09多周期交点模块，并对生成交点再次执行残差分类。四种状态分别输出B、交点、交点与B、或不输出。相邻重复点会被过滤，首尾重复点从最终有效计数中剔除。

若检测到近并行边，保守保留内侧端点并将结果标为不可信。算术饱和、交点残差失败或超过1024顶点容量同样拉低`result_trusted_o`。忙时启动被拒绝并产生单周期协议错误。时序源见 [polygon_clip_engine_edge.json5](waveforms/polygon_clip_engine_edge.json5)。
