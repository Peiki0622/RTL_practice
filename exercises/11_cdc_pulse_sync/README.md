# 11 脉冲跨时钟域同步 — 规格说明

## 目标
把源时钟域中的单周期脉冲可靠转换为目标时钟域中的单周期脉冲。

## 冻结端口
```systemverilog
module cdc_pulse_sync (
    input  logic src_clk,
    input  logic src_rst_n,
    input  logic src_pulse,
    input  logic dst_clk,
    input  logic dst_rst_n,
    output logic dst_pulse
);
```

## 功能要求
- 两个复位均为低有效异步复位。
- 每个合法 `src_pulse` 最终必须在目标域产生且只产生一个持续 1 个 `dst_clk` 周期的 `dst_pulse`。
- 目标脉冲允许存在跨时钟域同步延迟，不要求固定延迟。
- 不能把 `src_pulse` 直接接入普通两级电平同步器后期望所有窄脉冲都被采到。

## 测试假设
- `src_pulse` 每次只持续 1 个 `src_clk` 周期。
- 相邻两个源脉冲之间会至少跨过 4 个 `dst_clk` 上升沿，避免无握手方案因事件过密而丢失。
- 测试开始前两个复位会同时被拉低；不测试运行中单独复位某一个时钟域。

## 验收重点
快到慢、慢到快、单次事件不重复、输出严格单周期。