# 07 轮询仲裁器 — 规格说明

## 目标
实现 N 路 Round-Robin（轮询）仲裁，保证持续请求之间的公平性。

## 冻结端口
```systemverilog
module round_robin_arbiter #(
    parameter int unsigned N = 4
) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] req,
    input  logic         grant_accept,
    output logic [N-1:0] gnt
);
```

## 功能要求
- `rst_n` 为低有效异步复位。复位后下一次搜索从请求 0 开始。
- `gnt` 为 one-hot（独热）或全 0。
- 当前搜索起点开始，按编号循环寻找第一个有效请求。
- 只有当 `grant_accept=1` 且当前确实存在授权时，轮询起点才更新到“刚被服务请求的下一路”。
- 未完成服务时不得因为仅仅发出 `gnt` 就推进优先级。
- 无请求时保持轮询状态不变。
- 若某个请求持续保持有效，且所有已发出的授权最终都会被接受，则该请求不得永久饥饿。

## 参数约束
- `N >= 2`，不要求 `N` 是 2 的整数次幂。

## 验收重点
公平轮转、请求中途变化、授权未接受时状态保持、非 2 次幂路数。