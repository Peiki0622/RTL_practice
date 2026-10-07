// N 路轮询仲裁器：从保存的起点按编号循环寻找第一个有效请求。
// 只有授权被接受时才推进起点；若 req 变化，组合授权 gnt 仍可能变化。
module round_robin_arbiter #(
    parameter int unsigned N = 4
) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] req,
    input  logic         grant_accept,
    output logic [N-1:0] gnt
);

    localparam int unsigned PTR_WIDTH = $clog2(N);

    // 跨周期保存的搜索起点，以及本周期组合搜索的结果。
    logic [PTR_WIDTH-1:0] search_start_q;
    logic                 grant_found;
    logic [PTR_WIDTH-1:0] granted_index;
    int unsigned          candidate_index;

    // 从当前起点循环扫描。最大候选值为 2*N-2，至多减一次 N 即可回绕，
    // 因而也支持非二次幂的 N。固定次数循环在综合时展开为组合逻辑。
    always_comb begin
        gnt             = '0;
        grant_found     = 1'b0;
        granted_index   = '0;
        candidate_index = '0;

        for (int unsigned offset = 0; offset < N; offset++) begin
            candidate_index = search_start_q + offset;
            if (candidate_index >= N) begin
                candidate_index = candidate_index - N;
            end

            // 只授权给搜索顺序中遇到的第一个有效请求。
            if (req[candidate_index] && !grant_found) begin
                gnt[candidate_index] = 1'b1;
                grant_found          = 1'b1;
                granted_index        = candidate_index[PTR_WIDTH-1:0];
            end
        end
    end

    // 只有成功服务才更新起点：从获胜者的下一路开始，最后一路之后回到 0。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_start_q <= '0;
        end else if (grant_accept && grant_found) begin
            if (granted_index == N - 1) begin
                search_start_q <= '0;
            end else begin
                search_start_q <= granted_index + 1'b1;
            end
        end
    end

endmodule
