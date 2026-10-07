// -----------------------------------------------------------------------------
// 练习区：请根据上级 README.md 的冻结规格完成奇偶分频器。
// 不要修改模块名、参数名、端口方向或位宽。
// -----------------------------------------------------------------------------
module even_odd_clock_divider #(
    parameter int unsigned EVEN_DIV = 6,
    parameter int unsigned ODD_DIV  = 5
) (
    input  logic clk,
    input  logic rst_n,
    output logic clk_div_even,
    output logic clk_div_odd
);

    // TODO: 在这里完成你的实现。
    //
    // 提示：
    // 1. 偶数分频可以在输入时钟上升沿计数，每半个分频周期翻转一次输出。
    // 2. 奇数分频若要求严格 50% 占空比，需要利用输入时钟的上升沿与下降沿。
    // 3. 不要把分频后的输出再作为内部时钟使用。

endmodule
