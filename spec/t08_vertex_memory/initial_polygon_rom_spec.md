# initial_polygon_rom 模块规格

> RTL：`rtl/memory/initial_polygon_rom.v`

模块保存T02生成的720个外接正多边形顶点，顶点按逆时针顺序排列。每个64位字的高32位为signed Q16.16 X坐标，低32位为signed Q16.16 Y坐标。读接口为单周期同步响应，地址720至1023返回零。

初始化文件固定为`tb/vectors/initial_polygon_720_q16_16.mem`，必须作为Vivado memory initialization file加入工程。时序源见 [initial_polygon_rom_read.json5](waveforms/initial_polygon_rom_read.json5)。
