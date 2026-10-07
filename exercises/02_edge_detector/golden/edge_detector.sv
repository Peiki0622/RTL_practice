// -----------------------------------------------------------------------------
// 单比特同步信号边沿检测器。
//
// sig_in 已经属于 clk 时钟域。本模块保存上一拍样本，并将当前样本与
// 历史样本比较，分别产生一个时钟周期宽度的上升沿和下降沿脉冲。
// -----------------------------------------------------------------------------
module edge_detector (
    // 时钟：输入采样、历史值和输出脉冲均在上升沿更新。
    input  logic clk,
    // 低有效异步复位：历史样本和两个输出脉冲均复位为零。
    input  logic rst_n,
    // 已同步到 clk 域的待检测单比特信号。
    input  logic sig_in,
    // 当前采样由低变高时拉高一拍。
    output logic rise_pulse,
    // 当前采样由高变低时拉高一拍。
    output logic fall_pulse
);

    // 保存前一拍的输入样本，是边沿比较所需的唯一内部状态。
    logic sig_in_d;

    // 唯一的时序状态块。脉冲由同一拍的 sig_in 和更新前的 sig_in_d
    // 直接计算；随后再写入新历史样本，因此不会产生两个脉冲同时为高。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sig_in_d   <= 1'b0;
            rise_pulse <= 1'b0;
            fall_pulse <= 1'b0;
        end else begin
            rise_pulse <=  sig_in && !sig_in_d;
            fall_pulse <= !sig_in &&  sig_in_d;
            sig_in_d   <= sig_in;
        end
    end

endmodule
