// -----------------------------------------------------------------------------
// 单比特、两级目标时钟域同步器。
//
// async_in 仅适用于相对稳定的单比特电平。第一级用于承受潜在亚稳态，模块
// 外部只使用第二级寄存器，避免让后级逻辑直接依赖第一级采样结果。
// -----------------------------------------------------------------------------
module cdc_two_flop_sync (
    // 目标时钟域时钟；两个同步寄存器均在其上升沿采样。
    input  logic dst_clk,
    // 低有效异步复位；两个同步级均复位为零。
    input  logic dst_rst_n,
    // 来自其他时钟域的单比特稳定电平。
    input  logic async_in,
    // 经过两级目标域触发器后的安全使用信号。
    output logic sync_out
);

    // 第一级不得被模块外的后级逻辑使用。
    logic sync_stage1_q;
    // 第二级是同步器对外可见的唯一状态。
    logic sync_stage2_q;

    // 两个触发器串联采样同一异步电平。非阻塞赋值使第二级取得前一周期的
    // 第一级值，从结构上保证至少两级寄存器隔离。
    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_stage1_q <= 1'b0;
            sync_stage2_q <= 1'b0;
        end else begin
            sync_stage1_q <= async_in;
            sync_stage2_q <= sync_stage1_q;
        end
    end

    // 输出只由第二级寄存器驱动，没有第一级的组合旁路。
    assign sync_out = sync_stage2_q;

endmodule
