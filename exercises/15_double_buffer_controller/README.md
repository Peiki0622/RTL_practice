# 15 双缓冲控制器 — 规格说明

## 目标
实现两块 bank（存储体）的 Ping-Pong Buffer（乒乓双缓冲）控制器，使“装载下一块数据”和“计算当前块数据”尽可能重叠。

## 冻结端口
```systemverilog
module double_buffer_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic enable,

    output logic load_start,
    output logic load_bank,
    input  logic load_done,

    output logic compute_start,
    output logic compute_bank,
    input  logic compute_done
);
```

## 接口语义
- `load_start`：持续 1 拍的启动脉冲，表示外部装载器应开始向 `load_bank` 指定的存储体装载一块数据。
- `load_done`：外部装载器返回的 1 拍完成脉冲；任意时刻最多只有一个装载事务在途。
- `compute_start`：持续 1 拍的启动脉冲，表示计算单元应开始消费 `compute_bank` 指定的存储体。
- `compute_done`：计算单元返回的 1 拍完成脉冲；任意时刻最多只有一个计算事务在途。

## 功能要求
- `rst_n` 为低有效异步复位，复位后两块存储体均视为空闲。
- `enable=1` 且装载器空闲时，应尽快启动对空闲存储体的装载；首次优先选择 bank 0。
- 某 bank 收到 `load_done` 后被视为“已装满、可计算”。
- 计算单元空闲且存在已装满 bank 时，应尽快对其发出 `compute_start`。
- 某 bank 在计算期间不能被装载；某 bank 在装载期间不能被计算。
- 当一块 bank 用于计算时，应尽可能让另一块 bank 同时装载下一块数据。
- 某 bank 收到 `compute_done` 后重新变为空闲，可再次装载。
- `enable=0` 时不启动新的装载或计算事务，但已经在途的事务允许通过 `load_done`/`compute_done` 正常结束并更新状态。

## 验收重点
首次启动、装载与计算重叠、bank 角色交替、禁止同 bank 同时装载和计算、enable 暂停后恢复。