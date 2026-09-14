# 18 脉动阵列处理单元 — 规格说明

## 目标
实现一个可平铺到 Systolic Array（脉动阵列）中的基础 PE（处理单元）：接收两个操作数和部分和，完成一次乘加，并把操作数向相邻单元继续转发。

## 冻结端口
```systemverilog
module systolic_array_pe #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned ACC_WIDTH  = 32
) (
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic                           in_valid,
    input  logic signed [DATA_WIDTH-1:0]   a_in,
    input  logic signed [DATA_WIDTH-1:0]   b_in,
    input  logic signed [ACC_WIDTH-1:0]    psum_in,
    output logic                           out_valid,
    output logic signed [DATA_WIDTH-1:0]   a_out,
    output logic signed [DATA_WIDTH-1:0]   b_out,
    output logic signed [ACC_WIDTH-1:0]    psum_out
);
```

## 功能要求
- `rst_n` 为低有效异步复位，`out_valid=0`；数据寄存器复位值不作为功能判定重点。
- 当 `in_valid=1` 时，在一个时钟周期后：
  - `a_out` 等于该事务的 `a_in`；
  - `b_out` 等于该事务的 `b_in`；
  - `psum_out` 等于该事务的 `psum_in` 加上 `a_in * b_in`；
  - `out_valid=1`。
- 当 `in_valid=0` 时，一个周期后 `out_valid=0`；数据输出可保持旧值。
- 全部算术按有符号二进制补码处理，乘积必须正确符号扩展到 `ACC_WIDTH`。
- 不要求饱和运算；超出 `ACC_WIDTH` 时按低位截断。
- 流水线填满后应支持每拍处理一笔事务。

## 验收重点
单周期事务延迟、操作数转发、部分和乘加、正负数、连续有效流和气泡。