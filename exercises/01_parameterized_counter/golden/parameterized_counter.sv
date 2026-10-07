// -----------------------------------------------------------------------------
// 参数化模计数器。
//
// 计数器仅在 enable 有效的时钟上升沿更新。达到 MAX_COUNT 后回到零，
// 并在该次回绕对应的完整时钟周期内给出一个 wrap 脉冲。
// -----------------------------------------------------------------------------
module parameterized_counter #(
    // 计数值的位宽，同时约束 MAX_COUNT 和 count 的位宽。
    parameter int unsigned WIDTH = 8,
    // 可计到的最大值；该参数由调用者在 elaboration 时固定。
    parameter logic [WIDTH-1:0] MAX_COUNT = {WIDTH{1'b1}}
) (
    // 时钟：所有正常状态更新均在上升沿发生。
    input  logic             clk,
    // 低有效异步复位：拉低时立即清零 count 和 wrap。
    input  logic             rst_n,
    // 计数使能：低电平保持 count，且不产生 wrap。
    input  logic             enable,
    // 当前计数值。
    output logic [WIDTH-1:0] count,
    // 回绕指示：仅在使能条件下从 MAX_COUNT 回到零时拉高一拍。
    output logic             wrap
);

    // 唯一的时序状态块。每个非回绕周期先默认清除 wrap，确保它不会
    // 因 enable 关闭或普通加一而被保持为高电平。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            wrap  <= 1'b0;
        end else begin
            wrap <= 1'b0;
            if (enable) begin
                if (count == MAX_COUNT) begin
                    count <= '0;
                    wrap  <= 1'b1;
                end else begin
                    count <= count + {{(WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
