# 13 流水线加法树 — 规格说明

## 目标
把多路无符号输入用平衡加法树求和，并在每一级树后插入寄存器。

## 冻结端口
```systemverilog
module pipelined_adder_tree #(
    parameter int unsigned N_INPUTS   = 8,
    parameter int unsigned DATA_WIDTH = 16
) (
    input  logic                                              clk,
    input  logic                                              rst_n,
    input  logic                                              in_valid,
    input  logic [N_INPUTS-1:0][DATA_WIDTH-1:0]              in_data,
    output logic                                              out_valid,
    output logic [DATA_WIDTH+$clog2(N_INPUTS)-1:0]           out_sum
);
```

## 功能要求
- `rst_n` 为低有效异步复位，所有有效流水标志清零。
- `N_INPUTS` 路输入按无符号数求和。
- `N_INPUTS` 必须是 2 的整数次幂。
- 每一级加法树后都必须有流水寄存器，因此总有效延迟固定为 `$clog2(N_INPUTS)` 个时钟周期。
- `in_valid=0` 表示插入一个气泡；该气泡必须随流水线传到 `out_valid`。
- 流水线填满后应支持每拍接收一组新输入，并每拍输出一组结果。
- 输出位宽已经为最坏情况求和预留增长位，不得静默缩窄。

## 验收重点
数值正确、有效信号延迟严格匹配、连续满速输入、气泡传播。