// -----------------------------------------------------------------------------
// round_robin_arbiter 的自检测试平台。
//
// 默认 N=3 覆盖非二次幂路数，可覆盖参数验证其他路数。参考模型独立保存轮询起点，并按规格从该起点
// 循环扫描请求；它不会读取或修改 DUT 的内部状态。
// -----------------------------------------------------------------------------
module tb #(
    parameter int unsigned TB_N = 3
);
    localparam int unsigned TB_PTR_WIDTH = $clog2(TB_N);

    // DUT 时钟、复位、请求和服务确认输入。
    logic             clk;
    logic             rst_n;
    logic [TB_N-1:0]  req;
    logic             grant_accept;
    // DUT 的冻结授权输出。
    logic [TB_N-1:0]  gnt;

    // 独立参考模型的轮询起点与组合期望授权。
    logic [TB_PTR_WIDTH-1:0] expected_start;
    logic [TB_N-1:0]         expected_gnt;
    logic                    expected_found;
    logic [TB_PTR_WIDTH-1:0] expected_granted_index;
    int unsigned             expected_candidate_index;
    integer                  errors;

    // 被测实例固定为 dut，端口与题目冻结定义逐项相连。
    round_robin_arbiter #(
        .N(TB_N)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .req          (req),
        .grant_accept (grant_accept),
        .gnt          (gnt)
    );

    // 10ns 周期时钟。所有激励在下降沿改变，使上升沿的采样不存在竞争。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 固定文件名保证 Makefile 能在当前 .sim/golden 工作目录找到 FSDB。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 参考仲裁选择：与规格相同地从 expected_start 起按编号循环寻找首个请求。
    always_comb begin
        expected_gnt             = '0;
        expected_found           = 1'b0;
        expected_granted_index   = '0;
        expected_candidate_index = '0;

        for (int unsigned offset = 0; offset < TB_N; offset++) begin
            expected_candidate_index = expected_start + offset;
            if (expected_candidate_index >= TB_N) begin
                expected_candidate_index = expected_candidate_index - TB_N;
            end

            if (req[expected_candidate_index] && !expected_found) begin
                expected_gnt[expected_candidate_index] = 1'b1;
                expected_found                          = 1'b1;
                expected_granted_index = expected_candidate_index[TB_PTR_WIDTH-1:0];
            end
        end
    end

    // 每个上升沿先检查本周期的组合授权，再在服务真正完成时推进独立参考
    // 起点。随后等待 DUT 的非阻塞状态更新并检查新起点产生的授权。
    initial begin : arbiter_scoreboard
        expected_start = '0;
        errors         = 0;

        forever begin
            @(posedge clk);
            if (!rst_n) begin
                expected_start = '0;
                #1;
                if (gnt !== '0) begin
                    $display("ERROR[rr_arbiter] reset gnt expected=%b got=%b", {TB_N{1'b0}}, gnt);
                    errors = errors + 1;
                end
            end else begin
                if (gnt !== expected_gnt) begin
                    $display("ERROR[rr_arbiter] pre-edge req=%b start=%0d expected=%b got=%b",
                             req, expected_start, expected_gnt, gnt);
                    errors = errors + 1;
                end

                if (grant_accept && expected_found) begin
                    if (expected_granted_index == TB_N - 1) begin
                        expected_start = '0;
                    end else begin
                        expected_start = expected_granted_index + 1'b1;
                    end
                end

                #1;
                if (gnt !== expected_gnt) begin
                    $display("ERROR[rr_arbiter] post-edge req=%b start=%0d expected=%b got=%b",
                             req, expected_start, expected_gnt, gnt);
                    errors = errors + 1;
                end
            end
        end
    end

    // 定向用例覆盖：复位起点、未接受授权保持、公平轮转、请求变化、无请求
    // 保持，以及 grant_accept 在无授权时不得推进状态。
    initial begin : arbiter_stimulus
        rst_n        = 1'b0;
        req          = '0;
        grant_accept = 1'b0;

        #1;
        if (gnt !== '0) begin
            $fatal(1, "FAIL[rr_arbiter] asynchronous reset gnt=%b", gnt);
        end

        @(negedge clk);
        rst_n = 1'b1;

        // 全部持续请求但不接受授权：gnt 必须持续指向请求 0。
        @(negedge clk);
        req          = '1;
        grant_accept = 1'b0;
        repeat (2) @(negedge clk);

        // 连续接受服务，必须按编号公平轮转，并跨越最后一路回到 0。
        grant_accept = 1'b1;
        repeat (TB_N + 1) @(negedge clk);

        // 中途撤销部分请求，当前起点后的首个有效路仍应得到授权。
        req = TB_N'(3'b101);
        repeat (2) @(negedge clk);

        // 无请求时即使 grant_accept 为高也必须保持状态。
        req = '0;
        repeat (2) @(negedge clk);

        // 恢复单个请求，验证无请求周期没有篡改保存的轮询起点。
        req          = TB_N'(3'b010);
        grant_accept = 1'b0;
        repeat (2) @(negedge clk);
        grant_accept = 1'b1;
        @(negedge clk);

        // 遍历每个合法起点与全部请求组合，覆盖分组边界、两组都有请求、
        // 仅一组有请求及全空。参考模型仍使用独立的循环搜索方法。
        for (int unsigned start = 0; start < TB_N; start++) begin
            for (int unsigned pattern = 0; pattern < (1 << TB_N); pattern++) begin
                // 通过服务起点的前一路建立目标起点，不读取 DUT 内部状态。
                @(negedge clk);
                req = TB_N'(1) << ((start + TB_N - 1) % TB_N);
                grant_accept = 1'b1;

                @(negedge clk);
                req = TB_N'(pattern);
                grant_accept = 1'b0;

                // 未接受期间改变请求，检查起点保持而授权重新计算。
                @(negedge clk);
                req = ~TB_N'(pattern);

                @(negedge clk);
                req = TB_N'(pattern);
                grant_accept = 1'b1;
            end
        end

        @(negedge clk);
        req          = '0;
        grant_accept = 1'b0;
        repeat (2) @(posedge clk);
        #2;

        if (errors == 0) begin
            $display("PASS[rr_arbiter] N=%0d all checks passed, including %0d start/request combinations",
                     TB_N, TB_N * (1 << TB_N));
        end else begin
            $fatal(1, "FAIL[rr_arbiter] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
