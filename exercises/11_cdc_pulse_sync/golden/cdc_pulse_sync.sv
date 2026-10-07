// -----------------------------------------------------------------------------
// 基于事件翻转位的单脉冲跨时钟域同步器。
//
// 源域中的窄脉冲先翻转一个状态位。目标域同步该状态位，并检测同步状态的
// 相邻值是否不同，从而在目标域生成恰好一个时钟周期的脉冲。该无握手方案
// 依赖规格给出的相邻源事件间隔假设。
// -----------------------------------------------------------------------------
module cdc_pulse_sync (
    // 源时钟域时钟；源脉冲在此域编码为翻转事件。
    input  logic src_clk,
    // 源域低有效异步复位。
    input  logic src_rst_n,
    // 源域单周期事件脉冲。
    input  logic src_pulse,
    // 目标时钟域时钟；同步与输出脉冲均以此时钟为基准。
    input  logic dst_clk,
    // 目标域低有效异步复位。
    input  logic dst_rst_n,
    // 目标域单周期事件脉冲。
    output logic dst_pulse
);

    // 每个源事件都使该位翻转一次，因此不会因源脉冲窄于目标时钟周期而漏采。
    logic src_toggle_q;
    // 目标域两级同步链；第一级不会被事件检测逻辑直接使用。
    logic dst_sync_stage1_q;
    logic dst_sync_stage2_q;
    // 目标域中保存上一拍第二级同步结果，用于边沿/变化检测。
    logic dst_sync_delay_q;

    // 源域事件编码。没有 src_pulse 时保持翻转位，确保单个事件对应唯一状态
    // 变化，而非将脉冲电平本身跨域传递。
    always_ff @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_toggle_q <= 1'b0;
        end else if (src_pulse) begin
            src_toggle_q <= ~src_toggle_q;
        end
    end

    // 目标域的标准两级单比特同步结构。第二级是唯一送往本地域事件检测的
    // 跨域信号，降低第一级潜在亚稳态传播的概率。
    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_stage1_q <= 1'b0;
            dst_sync_stage2_q <= 1'b0;
        end else begin
            dst_sync_stage1_q <= src_toggle_q;
            dst_sync_stage2_q <= dst_sync_stage1_q;
        end
    end

    // 本地域历史寄存器独立保存第二级的前一拍值。它不参与跨域采样，只服务
    // 于目标域的单周期变化检测。
    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_delay_q <= 1'b0;
        end else begin
            dst_sync_delay_q <= dst_sync_stage2_q;
        end
    end

    // 同步翻转位与其前一拍值不同的整个 dst_clk 周期内，输出为一；下一拍
    // 两值重新相同，故不产生重复脉冲。
    assign dst_pulse = dst_sync_stage2_q ^ dst_sync_delay_q;

endmodule
