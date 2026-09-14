# 17 NPU 权重驻留处理单元 — 规格说明

## 目标
实现一个简化的 NPU（神经网络处理器）PE（处理单元）：本地保存权重，对连续激活值执行有符号乘加并累积到内部累加器。

## 冻结端口
```systemverilog
module npu_processing_element #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned ACC_WIDTH  = 32
) (
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic                           weight_load,
    input  logic signed [DATA_WIDTH-1:0]   weight_in,
    input  logic                           acc_clear,
    input  logic                           in_valid,
    input  logic signed [DATA_WIDTH-1:0]   activation,
    output logic                           acc_valid,
    output logic signed [ACC_WIDTH-1:0]    acc_out
);
```

## 功能要求
- `rst_n` 为低有效异步复位，权重寄存器、累加器和 `acc_valid` 清零。
- `weight_load=1` 时，在该上升沿把 `weight_in` 写入本地权重寄存器。
- `acc_clear=1` 时，在该上升沿把累加器清零。
- `in_valid=1` 时，使用已经存储的本地权重，将 `activation * weight` 按有符号数计算并累加到内部累加器。
- 每次成功执行乘加后，`acc_valid` 拉高 1 拍；没有乘加时 `acc_valid=0`。
- 乘积必须正确符号扩展到 `ACC_WIDTH` 后再累加。
- 不要求饱和运算，溢出按 `ACC_WIDTH` 二进制补码截断。

## 输入约束
- 测试不会在同一周期同时断言 `in_valid` 与 `weight_load`。
- 测试不会在同一周期同时断言 `in_valid` 与 `acc_clear`。
- `weight_load` 与 `acc_clear` 可以同拍发生，二者分别更新自己的状态。

## 验收重点
权重装载、清零、正负有符号乘加、连续累加、有效脉冲。