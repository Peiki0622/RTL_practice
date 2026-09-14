# 02 边沿检测器 — 规格说明

## 目标
对已经同步到本时钟域的单比特信号进行上升沿和下降沿检测。

## 冻结端口
```systemverilog
module edge_detector (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic rise_pulse,
    output logic fall_pulse
);
```

## 功能要求
- `rst_n` 为低有效异步复位，内部历史采样值复位为 0，两个脉冲输出均为 0。
- 当本拍采样到 `sig_in=1`、上一拍采样值为 0 时，`rise_pulse` 拉高 1 拍。
- 当本拍采样到 `sig_in=0`、上一拍采样值为 1 时，`fall_pulse` 拉高 1 拍。
- 其他情况两个输出均为 0。
- 同一拍不允许两个脉冲同时为 1。

## 假设与边界
- `sig_in` 已经位于 `clk` 时钟域，本题不处理 CDC（跨时钟域）问题。
- 信号长时间保持高或低时，只能在真正发生边沿的那一拍产生一次脉冲。

## 验收重点
复位后的第一次采样、连续稳定输入、相邻周期快速翻转。