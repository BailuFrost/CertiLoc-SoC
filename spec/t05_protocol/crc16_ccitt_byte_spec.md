# crc16_ccitt_byte 模块规格

> RTL：`rtl/comm/crc16_ccitt_byte.v`

模块以8个时钟逐位处理一个输入字节，算法固定为CRC-16/CCITT-FALSE：初值`FFFF`、多项式`1021`、输入不反射、无最终异或。`i_start`仅在空闲时接受；与`i_clear`同时置位时从初值开始新帧。`o_done`在第8次更新完成后脉冲一个时钟。

验收案例为ASCII字符串`123456789`，最终余数必须为`29B1`。时序源见 [crc16_ccitt_byte_byte.json5](waveforms/crc16_ccitt_byte_byte.json5)。

