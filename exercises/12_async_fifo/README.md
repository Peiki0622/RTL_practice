# 12 异步 FIFO — 规格说明

## 目标
实现双时钟域 FIFO（先进先出队列），练习格雷码指针、跨域同步和满空判断。

## 冻结端口
```systemverilog
module async_fifo #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH      = 16
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_valid,
    output logic                  wr_ready,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    output logic                  rd_valid,
    input  logic                  rd_ready,
    output logic [DATA_WIDTH-1:0] rd_data
);
```

## 功能要求
- 两个复位均为低有效异步复位。
- 写入发生在 `wr_valid && wr_ready` 的 `wr_clk` 上升沿。
- 读取发生在 `rd_valid && rd_ready` 的 `rd_clk` 上升沿。
- 数据必须严格先进先出，不丢失、不重复。
- `rd_valid=1 && rd_ready=0` 时，`rd_data` 必须保持稳定。
- 由于跨域同步存在延迟，`wr_ready` 和 `rd_valid` 允许保守地晚若干本地域时钟变化，但绝不能错误允许溢出或下溢。

## 结构要求
- `DEPTH` 必须是 2 的整数次幂，且至少为 4。
- 读写位置在本地域使用二进制指针维护；跨时钟域传递的指针必须转换为 Gray Code（格雷码）并经过至少两级同步。
- 不允许把多比特二进制指针直接逐位同步后用于满空判断。
- 存储体可使用行为级双端口数组描述，不依赖厂商专用 IP。

## 复位假设
- 测试开始前两个时钟域都会进入复位；不测试一侧在有未读数据时单独复位的恢复语义。

## 验收重点
异步频率比、指针回绕、写满、读空、长随机流、反压稳定性。