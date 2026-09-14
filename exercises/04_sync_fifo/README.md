# 04 同步 FIFO — 规格说明

## 目标
实现单时钟域 FIFO（先进先出队列），练习读写指针、满空判断和边界行为。

## 冻结端口
```systemverilog
module sync_fifo #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH      = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);
```

## 功能要求
- `rst_n` 为低有效异步复位。复位后 FIFO 为空。
- 写入成功条件为 `wr_en && !full`。
- 读取成功条件为 `rd_en && !empty`。
- 数据严格保持先进先出顺序，不丢失、不重复。
- `rd_data` 采用前视读语义：只要 `empty=0`，`rd_data` 就表示当前队头数据；成功读取后，下一个队头在指针更新后可见。
- FIFO 满时写请求被忽略；FIFO 空时读请求被忽略。
- 若周期开始时 `full=1`，即使同拍 `rd_en=1`，该拍写请求仍按“满时拒绝”处理；若周期开始时 `empty=1`，即使同拍 `wr_en=1`，该拍读请求仍按“空时拒绝”处理。

## 参数约束
- `DEPTH >= 2`。
- 本题允许任意深度，不得只对 2 的整数次幂深度正确。
- 存储阵列内容不要求复位。

## 验收重点
写满、读空、同时读写、指针回绕、非 2 次幂深度。