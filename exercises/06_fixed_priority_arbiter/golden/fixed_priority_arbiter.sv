// -----------------------------------------------------------------------------
// N 路固定优先级仲裁器。
//
// req[0] 的优先级最高。组合扫描从低编号到高编号进行，首次发现有效请求
// 后锁定结果，因此 gnt 始终为零或恰好一个高位。
// -----------------------------------------------------------------------------
module fixed_priority_arbiter #(
    // 请求和授权向量的路数；规格保证其不小于一。
    parameter int unsigned N = 4
) (
    // 请求位图，编号越小优先级越高。
    input  logic [N-1:0] req,
    // 独热授权位图；无请求时所有位均为零。
    output logic [N-1:0] gnt
);

    // found_q 仅为组合扫描中的已授权标记，不保存跨周期状态。
    logic found_q;

    // 纯组合优先级选择。默认值覆盖无请求路径；扫描完成后不再改变已选中
    // 的最低编号请求，因此不会产生多个授权位。
    always_comb begin
        gnt     = '0;
        found_q = 1'b0;

        for (int unsigned index = 0; index < N; index++) begin
            if (req[index] && !found_q) begin
                gnt[index] = 1'b1;
                found_q    = 1'b1;
            end
        end
    end

endmodule
