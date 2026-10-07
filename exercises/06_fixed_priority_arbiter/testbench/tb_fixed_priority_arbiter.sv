// -----------------------------------------------------------------------------
// fixed_priority_arbiter 的自检测试平台。
//
// 对 N=4 的所有请求位图进行穷举。期望授权由测试平台中的显式低到高扫描
// 得到，逐向量检查无请求、单请求、多请求和独热优先级选择。
// -----------------------------------------------------------------------------
module tb;
    // 默认四路仲裁器正好可在短仿真内穷举全部十六种请求组合。
    localparam int unsigned TB_N = 4;

    // DUT 请求输入、授权输出及独立期望授权。
    logic [TB_N-1:0] req;
    logic [TB_N-1:0] gnt;
    logic [TB_N-1:0] expected_gnt;
    integer errors;

    // 被测实例不含时钟和复位，保持冻结的纯组合端口定义。
    fixed_priority_arbiter #(
        .N(TB_N)
    ) dut (
        .req(req),
        .gnt(gnt)
    );

    // 即使无时钟，也转储所有请求和授权变化，便于检查组合响应。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 穷举测试主流程。每个向量的期望值独立生成，低编号首个有效请求
    // 是唯一可授权项；相等比较同时验证零授权和独热性质。
    initial begin
        req          = '0;
        expected_gnt = '0;
        errors       = 0;

        for (int request_value = 0; request_value < (1 << TB_N); request_value++) begin
            req = request_value;
            expected_gnt = '0;
            for (int unsigned index = 0; index < TB_N; index++) begin
                if (req[index] && (expected_gnt == '0)) begin
                    expected_gnt[index] = 1'b1;
                end
            end

            #1;
            if (gnt !== expected_gnt) begin
                $display("ERROR[arbiter] req=%b expected=%b got=%b", req, expected_gnt, gnt);
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("PASS[arbiter] all checks passed");
        end else begin
            $fatal(1, "FAIL[arbiter] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
