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


logic src_pulse_toggle_q;

logic dst_pulse_sync_q0;
logic dst_pulse_sync_q1;

logic dst_pulse_delay_q;

assign dst_pulse = dst_pulse_delay_q ^ dst_pulse_sync_q1;


always_ff @(posedge src_clk or negedge src_rst_n) begin
    if(!src_rst_n) begin
        src_pulse_toggle_q <= 'd0;
    end else if(src_pulse) begin
        src_pulse_toggle_q <= ~src_pulse_toggle_q;
    end
end

always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if(!dst_rst_n) begin
        dst_pulse_sync_q0 <= 'd0;
        dst_pulse_sync_q1 <= 'd0;
        dst_pulse_delay_q <= 'd0;
    end else begin
        dst_pulse_sync_q0 <= src_pulse_toggle_q;
        dst_pulse_sync_q1 <= dst_pulse_sync_q0;
        dst_pulse_delay_q <= dst_pulse_sync_q1;
    end
end




endmodule