# 05 有效-就绪单级缓冲 — 规格说明

## 目标
实现一个容量为 1 的弹性缓冲，正确处理 valid-ready（有效-就绪）握手与反压。

## 冻结端口
```systemverilog
module valid_ready_buffer #(
    parameter int unsigned DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  s_valid,
    output logic                  s_ready,
    input  logic [DATA_WIDTH-1:0] s_data,
    output logic                  m_valid,
    input  logic                  m_ready,
    output logic [DATA_WIDTH-1:0] m_data
);
```

## 功能要求
- `rst_n` 为低有效异步复位，复位后缓冲为空，`m_valid=0`。
- 输入握手发生在 `s_valid && s_ready`。
- 输出握手发生在 `m_valid && m_ready`。
- 缓冲已满且下游不接收时，必须保持 `m_valid=1` 且 `m_data` 不变。
- 当同一拍既完成输出握手又完成输入握手时，应允许旧数据被消费并由新数据无气泡替换。
- 只完成输入握手时，缓冲变满；只完成输出握手时，缓冲变空；两者都不发生时保持状态。

## 性能要求
- 在上下游持续就绪的情况下，填充后应支持每拍传输 1 笔数据。
- 不要求零延迟直通；允许数据先进入 1 级寄存器再输出。

## 验收重点
反压稳定性、同拍收发、连续满速传输、复位清空。