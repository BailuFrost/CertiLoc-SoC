# localization_command_ctrl 模块规格

> RTL：`rtl/control/localization_command_ctrl.v`

该模块接收 T05 在整帧 CRC、版本、长度和载荷检查完成后形成的语义命令，不在本层重复解析 UART 字节。观测先经索引端口写入暂存 RAM；合法 `LOAD_OBSERVATIONS` 命令仅原子提交 2 至 20 的有效数量，因此未通过协议校验的数据不会成为活动任务。

合法 `START_LOCALIZATION` 依次启动 720 点初始多边形加载、每条观测的上下边界生成与两次 Sutherland-Hodgman 裁剪、最终直径穷举。控制器独占仲裁双缓冲顶点 RAM，持续维护当前缓冲区、顶点数和活动观测索引。任务完成后，结果摘要和最终 RAM 选择保持有效，空闲态同步只读窗口供后续 `READ_RESULT` 分块编码器访问。

响应描述符采用保持型 `valid/ready` 接口。运行期间只允许 `GET_INFO`、`GET_STATUS`、`READ_RESULT` 和 `ABORT` 进入控制器，其余修改命令返回 `BUSY`。`ABORT` 对所有子引擎产生内部软复位、清除结果有效位并置 `aborted` 标志；之后无需重新配置即可提交新观测并启动新任务。

错误标志沿用 T03：bit0 量化容差、bit1 近并行、bit2 算术/残差、bit3 容量、bit4 子模块超时、bit5 非法内部状态、bit6 未执行全局共线检查、bit7 中止。bit1 至 bit5 任一置位会使结果不可信；致命错误的区域类型为 `INVALID`。时序源见 [localization_command_ctrl_job.json5](waveforms/localization_command_ctrl_job.json5)。
