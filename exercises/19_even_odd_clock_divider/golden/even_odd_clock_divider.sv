// -----------------------------------------------------------------------------
// 奇偶分频器参考实现。
//
// 偶数分频：在输入时钟上升沿计数，每经过半个分频周期翻转一次输出。
// 奇数分频：先在上升沿产生一个宽度为整数个输入周期的相位，再在下降沿
// 延迟该相位半个输入周期，最后将两路相位组合，从而得到严格 50% 占空比。
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

    localparam int unsigned EVEN_HALF  = EVEN_DIV / 2;
    localparam int unsigned EVEN_CNT_W = (EVEN_HALF <= 1) ? 1 : $clog2(EVEN_HALF);
    localparam int unsigned ODD_CNT_W  = (ODD_DIV <= 2) ? 1 : $clog2(ODD_DIV);

    logic [EVEN_CNT_W-1:0] even_count;
    logic [ODD_CNT_W-1:0]  odd_count;
    logic odd_pos_phase;
    logic odd_neg_phase;

    // 偶数分频：每计满半个分频周期翻转一次输出。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            even_count   <= '0;
            clk_div_even <= 1'b0;
        end else begin
            if (even_count == EVEN_HALF - 1) begin
                even_count   <= '0;
                clk_div_even <= ~clk_div_even;
            end else begin
                even_count <= even_count + {{(EVEN_CNT_W-1){1'b0}}, 1'b1};
            end
        end
    end

    // 奇数分频的上升沿相位。odd_pos_phase 在每个 ODD_DIV 周期窗口中
    // 保持 floor(ODD_DIV/2) 个完整输入周期的高电平。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            odd_count     <= '0;
            odd_pos_phase <= 1'b0;
        end else begin
            if (odd_count == ODD_DIV - 1) begin
                odd_count <= '0;
            end else begin
                odd_count <= odd_count + {{(ODD_CNT_W-1){1'b0}}, 1'b1};
            end

            if (odd_count < (ODD_DIV / 2)) begin
                odd_pos_phase <= 1'b1;
            end else begin
                odd_pos_phase <= 1'b0;
            end
        end
    end

    // 在下降沿把上升沿相位延迟半个输入周期。
    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            odd_neg_phase <= 1'b0;
        end else begin
            odd_neg_phase <= odd_pos_phase;
        end
    end

    // 两个相位分别只有一个时序驱动源，最终输出由单一组合逻辑驱动。
    always_comb begin
        clk_div_odd = odd_pos_phase | odd_neg_phase;
    end

endmodule
