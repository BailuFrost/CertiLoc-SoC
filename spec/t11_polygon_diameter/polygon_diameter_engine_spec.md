# polygon_diameter_engine 模块规格

> RTL：`rtl/geometry/polygon_diameter_engine.v`

模块使用顶点RAM的两个读端口并行获取一对Q16.16坐标，按字典序穷举全部`i<j`组合。坐标差扩展为33位有符号数，两个平方各保留66位，求和再增加一位保护位，最终输出具有32个小数位的66位无符号距离平方。

最大值仅在候选严格大于当前值时更新，因此并列最远点对保留字典序最早者，与T02模型一致。流水线每周期发起一个顶点对；对于两个及以上顶点，完成延迟为`N_pair+4`周期，其中`N_pair=N*(N-1)/2`；0点和1点均在1周期完成。超过1024点的输入在发出RAM请求前报告错误。时序源见 [polygon_diameter_engine_pair.json5](waveforms/polygon_diameter_engine_pair.json5)。
