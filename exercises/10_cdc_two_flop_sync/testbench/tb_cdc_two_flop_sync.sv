// -----------------------------------------------------------------------------
// cdc_two_flop_sync 的自检测试平台。
//
// async_in 刻意不在目标时钟边沿改变。检查要求输出不直接跟随输入、至少经过
// 两个目标时钟边沿，并在稳定输入窗口内最终到达正确电平。
// -----------------------------------------------------------------------------
module tb;
    // DUT 目标时钟域的冻结输入输出。
    logic dst_clk;
    logic dst_rst_n;
    logic async_in;
    logic sync_out;
    integer errors;

    // 被测实例固定为 dut。
    cdc_two_flop_sync dut (
        .dst_clk   (dst_clk),
        .dst_rst_n (dst_rst_n),
        .async_in  (async_in),
        .sync_out  (sync_out)
    );

    // 10ns 目标时钟。
    initial begin
        dst_clk = 1'b0;
        forever #5 dst_clk = ~dst_clk;
    end

    // 转储时钟、异步输入和同步输出的完整层次。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 等待稳定输入被同步到目标电平。第一拍后仍必须保持旧输出；后续给出
    // 有限观察窗口，以允许多于两级的合规同步实现而不固定精确延迟。
    task wait_for_synced_level(
        input logic expected_level,
        input string label_text
    );
        logic observed;
        begin
            observed = 1'b0;

            @(posedge dst_clk);
            #1;
            if (sync_out === expected_level) begin
                $display("ERROR[cdc_two_flop] %s changed before two-stage latency", label_text);
                errors = errors + 1;
            end

            for (int unsigned cycle_count = 0; cycle_count < 7; cycle_count++) begin
                @(posedge dst_clk);
                #1;
                if (sync_out === expected_level) begin
                    observed = 1'b1;
                    break;
                end
            end

            if (!observed) begin
                $display("ERROR[cdc_two_flop] %s did not settle within observation window", label_text);
                errors = errors + 1;
            end
        end
    endtask

    // 异步复位、高低电平转换与“不能直通”的时序检查。
    initial begin : synchronizer_stimulus
        dst_rst_n = 1'b0;
        async_in  = 1'b0;
        errors    = 0;

        #1;
        if (sync_out !== 1'b0) begin
            $fatal(1, "FAIL[cdc_two_flop] asynchronous reset sync_out=%b", sync_out);
        end

        @(negedge dst_clk);
        dst_rst_n = 1'b1;

        // 在时钟边沿之外将输入拉高，立刻检查输出没有组合直通。
        #2;
        async_in = 1'b1;
        #1;
        if (sync_out !== 1'b0) begin
            $display("ERROR[cdc_two_flop] rising async input directly changed output");
            errors = errors + 1;
        end
        wait_for_synced_level(1'b1, "rising transition");

        // 同样检查从高到低的传播路径和至少两级隔离。
        @(negedge dst_clk);
        #2;
        async_in = 1'b0;
        #1;
        if (sync_out !== 1'b1) begin
            $display("ERROR[cdc_two_flop] falling async input directly changed output");
            errors = errors + 1;
        end
        wait_for_synced_level(1'b0, "falling transition");

        if (errors == 0) begin
            $display("PASS[cdc_two_flop] all checks passed");
        end else begin
            $fatal(1, "FAIL[cdc_two_flop] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
