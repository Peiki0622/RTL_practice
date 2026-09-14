# 09 存储器同地址读写旁路 — 规格说明

## 目标
在一个同步写、组合读的存储器外增加 forwarding/bypass（前递/旁路），保证同周期同地址读写时读端看到新数据。

## 冻结端口
```systemverilog
module sram_read_write_bypass #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH      = 64
) (
    input  logic                         clk,
    input  logic                         we,
    input  logic [$clog2(DEPTH)-1:0]     waddr,
    input  logic [DATA_WIDTH-1:0]         wdata,
    input  logic [$clog2(DEPTH)-1:0]     raddr,
    output logic [DATA_WIDTH-1:0]         rdata
);
```

## 功能要求
- `we=1` 时在 `clk` 上升沿写入 `waddr`。
- 正常情况下 `rdata` 为 `raddr` 对应的存储内容。
- 当 `we=1` 且 `waddr==raddr` 时，`rdata` 必须直接反映 `wdata`，不得依赖底层存储器的读写冲突模式。
- 存储内容不要求复位。

## 参数约束
- 测试使用 2 的整数次幂深度。

## 验收重点
普通读、普通写、同地址读写、不同地址并行读写。