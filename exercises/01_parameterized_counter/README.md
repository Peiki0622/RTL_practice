# 01 参数化计数器 — 规格说明

## 目标
实现一个可综合的参数化模计数器。练习参数、计数回绕和单周期脉冲产生。

## 冻结端口
```systemverilog
module parameterized_counter #(
    parameter int unsigned WIDTH = 8,
    parameter logic [WIDTH-1:0] MAX_COUNT = {WIDTH{1'b1}}
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             enable,
    output logic [WIDTH-1:0] count,
    output logic             wrap
);
```

## 功能要求
- `rst_n` 为低有效异步复位。复位时 `count=0`、`wrap=0`。
- `enable=0` 时保持 `count`，并令 `wrap=0`。
- `enable=1` 且 `count<MAX_COUNT` 时，下一拍 `count` 加 1，`wrap=0`。
- `enable=1` 且 `count==MAX_COUNT` 时，下一拍 `count` 回到 0，并让 `wrap` 仅拉高 1 个时钟周期。
- `MAX_COUNT` 必须能由 `WIDTH` 位表示，测试不会使用非法参数。

## 边界条件
- 连续多个周期 `enable=0` 时不得误产生 `wrap`。
- `MAX_COUNT` 不要求是 2 的整数次幂。
- 不要求支持运行时装载初值或运行时修改上限。

## 验收重点
复位、保持、普通加 1、回绕脉冲、非 2 次幂上限。