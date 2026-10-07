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


logic sid_in_d;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sid_in_d <= 'd0;
        rise_pulse <= 'd0;
        fall_pulse <= 'd0;
    end else begin
        sid_in_d <= sig_in;
        rise_pulse <= (~sid_in_d) & sig_in;
        fall_pulse <= sid_in_d & (~sig_in);  
    end
end


endmodule