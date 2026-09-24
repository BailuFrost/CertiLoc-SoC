# Verilog deliverable gate

Root: `E:\B题改进\fpga_stage1\rtl\top\radio_localization_fpga_top.v`
Delivery ready: `False`
Summary: **215 error(s)**, **0 strict warning(s)**

## Actionable VG findings

<a id="vg-finding-1"></a>
### VG000: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `failed`
- Severity: `error`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-2"></a>
### VG007: Standard bilingual header with English/Chinese sections is required.
- Status: `failed`
- Severity: `error`
- Location: `radio_localization_fpga_top.v:1`
- Evidence:
- node_kind: `verilog_rtl`
- detail: header.bilingual
- source_excerpt: `header.bilingual`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `behavioral`; human review required: `True`
- Example 1 kind: `verilog`
- Bad example:
```text
header.bilingual
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-3"></a>
### VG007: English header is missing required field(s): Company, Engineer, Create Date, Design Name, Module Name, Description, Simulations, Referrences, Dependencies, Version, Revision Date, History
- Status: `failed`
- Severity: `error`
- Location: `radio_localization_fpga_top.v:1`
- Evidence:
- node_kind: `verilog_rtl`
- detail: header.english_fields
- source_excerpt: `header.english_fields`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `behavioral`; human review required: `True`
- Example 1 kind: `verilog`
- Bad example:
```text
header.english_fields
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-4"></a>
### VG007: Chinese header is missing required field(s): 版权归属, 开发人员, 创建日期, 设计名称, 模块名称, 模块说明, 仿真工程, 参考资料, 依赖文件, 当前版本, 修订日期, 修订历史
- Status: `failed`
- Severity: `error`
- Location: `radio_localization_fpga_top.v:1`
- Evidence:
- node_kind: `verilog_rtl`
- detail: header.chinese_fields
- source_excerpt: `header.chinese_fields`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `behavioral`; human review required: `True`
- Example 1 kind: `verilog`
- Bad example:
```text
header.chinese_fields
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-5"></a>
### VG068: Header Description/Simulations fields must use the fixed bilingual path contract (`description/testbench` in English and `Description/TestBench` in Chinese).
- Status: `failed`
- Severity: `error`
- Location: `radio_localization_fpga_top.v:1`
- Evidence:
- node_kind: `verilog_rtl`
- detail: header.description_simulations_paths
- source_excerpt: `header.description_simulations_paths`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `behavioral`; human review required: `True`
- Example 1 kind: `verilog`
- Bad example:
```text
header.description_simulations_paths
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-6"></a>
### VG007: Header history must contain at least one dated record with a Vx.y version.
- Status: `failed`
- Severity: `error`
- Location: `radio_localization_fpga_top.v:1`
- Evidence:
- node_kind: `verilog_rtl`
- detail: header.history_records
- source_excerpt: `header.history_records`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `behavioral`; human review required: `True`
- Example 1 kind: `verilog`
- Bad example:
```text
header.history_records
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-7"></a>
### VG042: Comment coverage is too low for generated RTL (0.00%); add semantic comments near declarations, assigns, always blocks, FSM, and instances.
- Status: `failed`
- Severity: `error`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: comments.coverage
- source_excerpt: `comments.coverage`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
comments.coverage
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-8"></a>
### VG072: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-9"></a>
### VG073: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-10"></a>
### VG074: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-11"></a>
### VG075: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-12"></a>
### VG076: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-13"></a>
### VG077: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-14"></a>
### VG078: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-15"></a>
### VG079: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-16"></a>
### VG080: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-17"></a>
### VG081: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-18"></a>
### VG082: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-19"></a>
### VG083: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-20"></a>
### VG084: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-21"></a>
### VG085: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-22"></a>
### VG086: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-23"></a>
### VG087: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-24"></a>
### VG088: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-25"></a>
### VG089: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-26"></a>
### VG090: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-27"></a>
### VG091: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-28"></a>
### VG092: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-29"></a>
### VG093: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-30"></a>
### VG094: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-31"></a>
### VG095: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-32"></a>
### VG096: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-33"></a>
### VG097: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-34"></a>
### VG098: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-35"></a>
### VG099: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-36"></a>
### VG100: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-37"></a>
### VG101: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-38"></a>
### VG102: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-39"></a>
### VG103: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-40"></a>
### VG104: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-41"></a>
### VG105: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-42"></a>
### VG106: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-43"></a>
### VG107: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-44"></a>
### VG108: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-45"></a>
### VG109: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-46"></a>
### VG110: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-47"></a>
### VG111: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-48"></a>
### VG112: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-49"></a>
### VG113: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-50"></a>
### VG114: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-51"></a>
### VG115: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-52"></a>
### VG116: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-53"></a>
### VG117: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-54"></a>
### VG118: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-55"></a>
### VG119: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-56"></a>
### VG120: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-57"></a>
### VG121: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-58"></a>
### VG122: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-59"></a>
### VG123: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-60"></a>
### VG124: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-61"></a>
### VG125: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-62"></a>
### VG126: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-63"></a>
### VG127: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-64"></a>
### VG128: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-65"></a>
### VG129: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-66"></a>
### VG130: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-67"></a>
### VG131: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-68"></a>
### VG132: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-69"></a>
### VG133: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-70"></a>
### VG134: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-71"></a>
### VG135: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-72"></a>
### VG136: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-73"></a>
### VG137: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-74"></a>
### VG138: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-75"></a>
### VG139: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-76"></a>
### VG140: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-77"></a>
### VG141: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-78"></a>
### VG142: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-79"></a>
### VG143: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-80"></a>
### VG144: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-81"></a>
### VG145: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-82"></a>
### VG146: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-83"></a>
### VG147: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-84"></a>
### VG150: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-85"></a>
### VG151: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-86"></a>
### VG152: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-87"></a>
### VG153: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-88"></a>
### VG154: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-89"></a>
### VG155: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-90"></a>
### VG156: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-91"></a>
### VG157: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

<a id="vg-finding-92"></a>
### VG158: > ERR: [Python] Strict mode [unsupported_construct]: protocol_command_adapter protocol_command_adapter_instance. Suggestion: > ERR: [Python] Move this statement into a supported declaration, assign, always block, or instance block.
- Status: `error`
- Severity: `BLOCKER`
- Location: `file:radio_localization_fpga_top.v:unknown`
- Evidence:
- node_kind: `verilog_rtl`
- detail: FORMATTER_AST_PARSE
- source_excerpt: `FORMATTER_AST_PARSE`
- How to fix: 修复 evidence 所代表的违规事实，并在修改后重新运行对应 VG 门禁。
- Steps:
  1. 打开 location 指向的文件或结构范围，核对 evidence 与当前源码是否一致。
  2. 按 instruction 修改问题片段，保留模块接口、复位和时序契约。
  3. 重新运行对应 VG 门禁，并检查示例方向是否适用于当前模块。
- Risk: `mechanical`; human review required: `False`
- Example 1 kind: `verilog`
- Bad example:
```text
FORMATTER_AST_PARSE
```
- Good example:
```text
按当前模块接口、时序和可综合约束重写该片段，并保留可追溯的结构事实。
```
- Example note: 示例表达修改方向，不替代当前模块的接口、时序和综合约束审查。

## Other deliverable findings

| Severity | Code | Path | Line | Message |
|---|---|---|---:|---|
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:6` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:7` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:8` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:9` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:12` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:13` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:14` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:15` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:16` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:17` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:20` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:21` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:22` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:24` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:25` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:26` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:27` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:28` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:29` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:30` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:31` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:32` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:34` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:35` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:36` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:37` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:38` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:39` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:40` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:41` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:42` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:43` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:44` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:45` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:46` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:47` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:48` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:50` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:51` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:52` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:53` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:54` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:55` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:56` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:57` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:58` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:59` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:60` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:61` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:62` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:63` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:64` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:65` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:66` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:67` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:68` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:69` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:70` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:71` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:73` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:74` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:75` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:76` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:77` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:78` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:79` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:80` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:81` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:82` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:83` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:84` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:85` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:86` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:87` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:88` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:89` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:90` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:91` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:92` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:93` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:94` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:95` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:96` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:97` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:98` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:99` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:100` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:101` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:102` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:104` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:105` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:106` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:107` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:108` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:109` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:110` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:112` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:113` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:114` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:115` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:116` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:117` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:118` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:119` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:120` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:121` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:122` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:123` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:124` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:126` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:127` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:128` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:130` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:132` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:136` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:138` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:139` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:140` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:141` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:144` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:152` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
| error | COMMENT_COMMENT_PLACEMENT | `radio_localization_fpga_top.v:166` |  | Verilog code line must use a same-line or adjacent explanatory comment in the requested language. |
