# 06 固定优先级仲裁器 — 规格说明

## 目标
实现纯组合的 N 路固定优先级仲裁器。

## 冻结端口
```systemverilog
module fixed_priority_arbiter #(
    parameter int unsigned N = 4
) (
    input  logic [N-1:0] req,
    output logic [N-1:0] gnt
);
```

## 功能要求
- 请求编号越小优先级越高，`req[0]` 为最高优先级。
- 没有请求时 `gnt` 全 0。
- 有一个或多个请求时，`gnt` 必须且只能有 1 位为 1，并对应当前最高优先级的有效请求。
- `gnt` 必须是纯组合结果，不需要时钟和复位。
- 参数 `N >= 1`。

## 验收重点
单请求、多请求、全请求、无请求，以及 one-hot（独热）性质。