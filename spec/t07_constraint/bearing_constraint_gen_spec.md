# bearing_constraint_gen 模块规格

> RTL：`rtl/geometry/bearing_constraint_gen.v`

## 接口与数值格式

模块接收一个Q16.16测点坐标和一个18位无符号整周示向相位。误差半角固定为T02冻结值732相位LSB，对应约1.005249°。每次事务依次输出下边界和上边界两组半平面参数：`a`、`b`为signed Q2.30，`c`为66位有符号整数并具有46个小数位。

## 约束方向

统一半平面形式为`a*x+b*y-c >= 0`：

- 下边界：`a=-sin(theta-delta)`，`b=cos(theta-delta)`；
- 上边界：`a=sin(theta+delta)`，`b=-cos(theta+delta)`；
- 两条边界均使用`c=a*sensor_x+b*sensor_y`。

18位相位加减采用自然模运算，因此能够处理359°附近的跨零边界。模块先调用T06 CORDIC计算下边界，再启动上边界计算；下边界乘加与第二次CORDIC执行部分重叠。

四次signed 32×32乘法在时间上复用一个显式DSP乘法通路，利用现有`MUL_X`和`MUL_Y`状态分别锁存X、Y乘积。乘法输入、乘积及控制寄存器使用高有效同步复位，以允许Vivado将流水寄存器吸收到DSP48中。

## 时序与异常

`reset_i`为高有效同步复位，至少在一个`clk_i`上升沿保持为高。`start_i`仅在空闲时接受。下边界在接受后的第25个周期通过`constraint_valid_o`输出；上边界在第45个周期输出，同时`done_o`脉冲。忙期间重复启动产生单周期`protocol_error_o`，不会覆盖当前测点。

验收向量包含主轴角、跨零角、负坐标和T02集成场景观测。时序源见 [bearing_constraint_gen_constraint_pair.json5](waveforms/bearing_constraint_gen_constraint_pair.json5)。
