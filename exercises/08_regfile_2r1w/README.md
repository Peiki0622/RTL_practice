# 08 双读单写寄存器文件 — 规格说明

## 目标
实现 2 个独立读端口、1 个同步写端口的寄存器文件。

## 冻结端口
```systemverilog
module regfile_2r1w #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH      = 32
) (
    input  logic                         clk,
    input  logic                         we,
    input  logic [$clog2(DEPTH)-1:0]     waddr,
    input  logic [DATA_WIDTH-1:0]         wdata,
    input  logic [$clog2(DEPTH)-1:0]     raddr0,
    output logic [DATA_WIDTH-1:0]         rdata0,
    input  logic [$clog2(DEPTH)-1:0]     raddr1,
    output logic [DATA_WIDTH-1:0]         rdata1
);
```

## 功能要求
- 写入在 `clk` 上升沿发生；`we=1` 时将 `wdata` 写入 `waddr`。
- 两个读端口均为组合读，可同时读取相同或不同地址。
- 读端口之间互不阻塞。
- 本题不要求复位寄存器文件内容。
- 本题不额外实现显式写后读旁路；写时钟沿之后，组合读自然看到已经更新的存储内容。

## 参数约束
- `DEPTH >= 2`，测试使用 2 的整数次幂深度。

## 验收重点
双读并行、同步写、同地址双读、写后读取。