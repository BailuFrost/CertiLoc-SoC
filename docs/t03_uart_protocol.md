# T03 UART二进制协议规格

## 1. 线路参数

- 物理链路：Basys 3板载USB-UART；
- 格式：115200 bit/s、8数据位、无校验、1停止位；
- 多字节整数：小端；
- 主从关系：PC发起命令，FPGA返回一个响应；FPGA不主动推送顶点数据。

## 2. 通用帧

| 偏移 | 字段 | 长度 | 规则 |
|---:|---|---:|---|
| 0 | SOF | 2 | 固定 `A5 5A` |
| 2 | VERSION | 1 | 固定 `01` |
| 3 | CMD | 1 | 命令或响应码 |
| 4 | SEQ | 2 | 小端，请求与响应相同 |
| 6 | LEN | 2 | Payload字节数，小端，最大244 |
| 8 | PAYLOAD | LEN | 按命令定义 |
| 8+LEN | CRC16 | 2 | 小端发送 |

最大整帧长度为254字节。CRC覆盖 `VERSION` 到 `PAYLOAD` 的全部字节，不覆盖SOF和CRC字段。

CRC固定采用CRC-16/CCITT-FALSE：`poly=0x1021`、`init=0xFFFF`、`refin=false`、`refout=false`、`xorout=0x0000`。标准检查串 `123456789` 的结果必须为 `0x29B1`，线路字节为 `B1 29`。

## 3. PC到FPGA命令

| 命令 | 值 | Payload长度 | 成功响应 |
|---|---:|---:|---|
| GET_INFO | 01 | 0 | INFO |
| SET_CONFIG | 10 | 28 | ACK |
| LOAD_OBSERVATIONS | 11 | 28至244 | ACK |
| START_LOCALIZATION | 12 | 0 | ACK |
| GET_STATUS | 13 | 0 | STATUS |
| READ_RESULT | 14 | 8 | RESULT_HEADER或RESULT_VERTICES |
| ABORT | 1F | 0 | ACK |

### 3.1 SET_CONFIG

阶段1配置固定，命令用于显式核对PC与FPGA参数。任一字段不等于冻结值时返回 `PARAMETER_RANGE`，不得部分生效。

| 偏移 | 字段 | 类型 | 冻结值 |
|---:|---|---|---:|
| 0 | radius_q16_16 | u32 | `1800×2^16` |
| 4 | delta_phase_u18 | u32 | 732，高14位为0 |
| 8 | eps_halfplane_raw | u64 | `2^30` |
| 16 | eps_denominator_raw | u64 | `2^30` |
| 24 | polygon_side_count | u16 | 720 |
| 26 | maximum_vertex_count | u16 | 1024 |

### 3.2 LOAD_OBSERVATIONS

| 偏移 | 字段 | 类型 | 规则 |
|---:|---|---|---|
| 0 | observation_count | u8 | 2至20 |
| 1 | reserved | 3字节 | 必须全0 |
| 4+12i | x_i | i32 | signed Q16.16 |
| 8+12i | y_i | i32 | signed Q16.16 |
| 12+12i | bearing_phase_i | u32 | 低18位有效，高14位必须为0 |

只有整帧CRC和全部字段验证通过后，观测才一次性提交。

### 3.3 READ_RESULT

| 偏移 | 字段 | 类型 | 规则 |
|---:|---|---|---|
| 0 | kind | u8 | 0结果头，1顶点块 |
| 1 | reserved | u8 | 0 |
| 2 | start_index | u16 | 结果头请求时必须为0 |
| 4 | maximum_vertices | u8 | 结果头时为0；顶点块时1至16 |
| 5 | reserved | 3字节 | 全0 |

## 4. FPGA到PC响应

| 响应 | 值 | Payload长度 |
|---|---:|---:|
| ACK | 80 | 4 |
| INFO | 81 | 24 |
| STATUS | 82 | 16 |
| RESULT_HEADER | 90 | 27 |
| RESULT_VERTICES | 91 | `8+8n`，1≤n≤16 |
| ERROR | FF | 8 |

### 4.1 ACK

`request_cmd:u8, ack_code:u8, detail:u16`。正常接受时后两项为0。

### 4.2 INFO

| 偏移 | 字段 | 类型 |
|---:|---|---|
| 0 | device_kind=`B301` | u16 |
| 2 | protocol_version | u8 |
| 3 | capability_flags | u8 |
| 4 | system_clock_hz | u32 |
| 8 | uart_baud | u32 |
| 12 | coordinate_fraction_bits | u8 |
| 13 | trigonometric_fraction_bits | u8 |
| 14 | phase_bits | u8 |
| 15 | cordic_iterations | u8 |
| 16 | maximum_observations | u8 |
| 17 | maximum_vertex_chunk | u8 |
| 18 | polygon_side_count | u16 |
| 20 | maximum_vertex_count | u16 |
| 22 | reserved | u16 |

`capability_flags[5:0]`依次表示固定半径、固定误差半角、顶点分页、核心周期计数、自研CORDIC、未实现全局共线检测；高2位保留为0。

### 4.3 STATUS

字段依次为：`state:u8, result_valid:u8, result_trusted:u8, region_type:u8, observation_count:u8, active_observation_index:u8, vertex_count:u16, error_flags:u32, core_cycles:u32`。

状态码为：`00 IDLE`、`01 RECEIVE`、`02 LOAD_INITIAL_POLYGON`、`03 CORDIC`、`04 CLIP`、`05 DIAMETER`、`06 RESULT_READY`、`07 TRANSMIT`、`FE ERROR_REPORT`、`FF ILLEGAL`。

`error_flags[7:0]`分别为：量化裕量已使用、近并行、算术溢出、顶点容量溢出、CORDIC超时、非法状态、未执行全局共线检测、任务被中止；高24位保留为0。仅量化裕量和未执行共线检测属于警告，其余置位时 `result_trusted` 必须为0。

### 4.4 RESULT_HEADER

字段依次为：`job_sequence:u16, trusted:u8, region_type:u8, vertex_count:u16, diameter_squared:u66-in-9-bytes, farthest_first:u16, farthest_second:u16, core_cycles:u32, error_flags:u32`。66位字段高6位必须为0。

### 4.5 RESULT_VERTICES

头部为 `job_sequence:u16, start_index:u16, vertex_count:u8, reserved:3×u8`，之后每个顶点为 `x:i32, y:i32`，均为Q16.16。

### 4.6 ERROR

字段为 `failed_cmd:u8, error_code:u8, engine_state:u8, reserved:u8, context:u32`。

主要错误码：`01`版本、`02`命令、`03`长度、`04`CRC、`05`超时、`06`参数、`07`忙、`08`观测数量、`09`保留位、`0A`结果不可用、`20`顶点容量、`21`算术溢出、`22`近并行、`23`CORDIC超时、`24`非法状态。

区域类型：`00 EMPTY`、`01 POINT`、`02 SEGMENT`、`03 POLYGON`、`FF INVALID`。

## 5. 时序、重试与重同步

- `SEQ`只用于请求—响应关联，不是自动去重令牌；存在未完成请求时PC不得复用相同SEQ。
- `RESULT_HEADER`和`RESULT_VERTICES`中的 `job_sequence` 固定回填产生当前结果的 `START_LOCALIZATION.SEQ`。
- GET_INFO、GET_STATUS、READ_RESULT可安全重试。
- SET_CONFIG、LOAD_OBSERVATIONS、START_LOCALIZATION和ABORT超时后，PC应先查询状态，不得盲目重复。
- 帧内相邻字节超过100 ms未到达时，解析器放弃当前帧并重新搜索SOF。
- 搜索SOF时若收到连续 `A5 A5 5A`，第二个A5作为新帧首字节。
- `LEN>244`时立即放弃该帧；CRC通过前不得改变有效配置、观测或任务状态。
- 顶点请求超出当前结果范围时返回 `RESULT_UNAVAILABLE`；合法请求靠近尾部时返回剩余顶点数，不用空顶点填充。
- ERROR响应尽量回显已接收的SEQ；若SEQ尚未完整接收则使用0。

## 6. 黄金向量

- `tb/vectors/uart_crc_vectors.csv`：标准CRC和每个黄金帧的CRC输入/输出；
- `tb/vectors/uart_protocol_frames.json`：结构化命令与响应帧；
- `tb/vectors/uart_protocol_frames.mem`：每字节一行的RTL testbench输入。

可执行语义由 `model/protocol_reference.py` 定义。
