// -----------------------------------------------------------------------------
// 可重叠的串行 1011 序列检测器。
//
// 状态记录当前输入流末尾已匹配的最长目标前缀。检测到 1011 后保留
// 末尾的 1 作为下一次匹配的可能起点，因此输入 1011011 可得到两次匹配。
// -----------------------------------------------------------------------------
module sequence_detector (
    // 时钟：每个上升沿均采样一个有效的 bit_in。
    input  logic clk,
    // 低有效异步复位：清除已匹配前缀和 match 脉冲。
    input  logic rst_n,
    // 串行输入比特。
    input  logic bit_in,
    // 当本次采样完成 1011 匹配时拉高一个时钟周期。
    output logic match
);

    // 四个状态分别表示：无前缀、已匹配 1、已匹配 10、已匹配 101。
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        HAVE_1  = 2'b01,
        HAVE_10 = 2'b10,
        HAVE_101 = 2'b11
    } state_t;

    state_t state_q;
    state_t state_d;

    // 状态转移保留当前输入流中仍可能构成 1011 的最长后缀。
    // HAVE_1 和 HAVE_101 遇到相同输入时具有相同的后继状态。
    always_comb begin
        state_d = IDLE;
        case (state_q)
            IDLE: begin
                if (bit_in) begin
                    state_d = HAVE_1;
                end
            end
            HAVE_1, HAVE_101: begin
                if (bit_in) begin
                    state_d = HAVE_1;
                end else begin
                    state_d = HAVE_10;
                end
            end
            HAVE_10: begin
                if (bit_in) begin
                    state_d = HAVE_101;
                end
            end
            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // 同一时钟沿更新状态和输出。match 使用更新前的 state_q 判断本次
    // 采样是否完成匹配；检测到 1011 后，后继状态保留末尾的 1。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            match <= 1'b0;
        end else begin
            state_q <= state_d;
            match <= (state_q == HAVE_101) && bit_in;
        end
    end

endmodule
