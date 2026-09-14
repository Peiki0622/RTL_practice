# 16 多存储体请求分发器 — 规格说明

## 目标
把多个并行读请求按地址映射到多个 bank（存储体），并正确处理同 bank 冲突。

## 冻结端口
```systemverilog
module multi_bank_dispatcher #(
    parameter int unsigned NUM_REQ   = 2,
    parameter int unsigned NUM_BANKS = 4,
    parameter int unsigned ADDR_WIDTH = 12
) (
    input  logic [NUM_REQ-1:0] req_valid,
    output logic [NUM_REQ-1:0] req_ready,
    input  logic [NUM_REQ-1:0][ADDR_WIDTH-1:0] req_addr,

    output logic [NUM_BANKS-1:0] bank_valid,
    input  logic [NUM_BANKS-1:0] bank_ready,
    output logic [NUM_BANKS-1:0][ADDR_WIDTH-$clog2(NUM_BANKS)-1:0] bank_addr
);
```

## 地址映射
- `NUM_BANKS` 必须是 2 的整数次幂。
- 地址低 `$clog2(NUM_BANKS)` 位选择 bank。
- 剩余高位作为 bank 内部地址并送到 `bank_addr`。

## 功能要求
- 本模块为纯组合分发器，不使用时钟和复位。
- 落到不同 bank 的请求可以在同一周期并行前进。
- 多个请求落到同一个 bank 时，每周期只允许其中一个请求被转发；请求编号较小者优先。
- 只有目标 bank 的 `bank_ready=1` 且该请求赢得本 bank 仲裁时，对应 `req_ready` 才能为 1。
- `bank_valid` 和 `bank_addr` 必须与被选中的请求一致。
- 未被服务的冲突请求保持 `req_ready=0`，由上游自行保持请求。

## 参数约束
- `NUM_REQ >= 1`，`NUM_BANKS >= 2`，并且 `ADDR_WIDTH > $clog2(NUM_BANKS)`。

## 验收重点
无冲突并行、同 bank 冲突、下游反压、地址拆分。