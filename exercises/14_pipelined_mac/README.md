# 14 两级流水乘加器 — 规格说明

## 目标
实现一个有符号两级流水 MAC（乘加）单元，支持每拍接受一笔输入。

## 冻结端口
```systemverilog
module pipelined_mac #(
    parameter int unsigned A_WIDTH   = 8,
    parameter int unsigned B_WIDTH   = 8,
    parameter int unsigned ACC_WIDTH = 32
) (
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          in_valid,
    input  logic signed [A_WIDTH-1:0]     a,
    input  logic signed [B_WIDTH-1:0]     b,
    input  logic signed [ACC_WIDTH-1:0]   acc_in,
    output logic                          out_valid,
    output logic signed [ACC_WIDTH-1:0]   result
);
```

## 功能要求
- `rst_n` 为低有效异步复位，流水有效位清零。
- 功能为有符号乘加：当前输入事务的 `a` 与 `b` 相乘，再与同一事务的 `acc_in` 相加。
- 固定两级流水：第 1 级完成并寄存乘法相关结果和对应累加输入，第 2 级完成加法并产生结果。
- 从输入握手意义上的 `in_valid` 到对应 `out_valid` 固定延迟 2 个时钟周期。
- 填满后支持每拍 1 笔输入和每拍 1 笔输出。
- 乘积必须正确符号扩展到累加宽度。
- 不要求饱和运算；若最终结果超出 `ACC_WIDTH`，按二进制补码低位截断语义处理。

## 验收重点
正负数、边界值、连续输入、气泡、有效信号对齐。