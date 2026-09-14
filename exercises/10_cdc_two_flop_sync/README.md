# 10 单比特两级同步器 — 规格说明

## 目标
实现最基本的 CDC（跨时钟域）单比特电平同步器。

## 冻结端口
```systemverilog
module cdc_two_flop_sync (
    input  logic dst_clk,
    input  logic dst_rst_n,
    input  logic async_in,
    output logic sync_out
);
```

## 功能要求
- `dst_rst_n` 为低有效异步复位，两级同步寄存器均复位为 0。
- `async_in` 只允许作为单比特、相对稳定的电平信号使用。
- 必须使用至少两级串联触发器后再输出 `sync_out`；后级逻辑不得直接使用第一级同步寄存器。
- 允许同步延迟为若干个 `dst_clk` 周期，不要求固定到单一周期。

## 不在本题范围
- 不用于窄脉冲同步。
- 不用于多比特总线逐位同步。
- 不宣称彻底消除亚稳态，只要求采用标准概率降低结构。

## 验收重点
复位、0 到 1、1 到 0、输出不得直接跟随异步输入。