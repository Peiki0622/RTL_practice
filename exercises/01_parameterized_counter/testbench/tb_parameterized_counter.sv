// -----------------------------------------------------------------------------
// parameterized_counter 的自检测试平台。
//
// 使用非二次幂上限 MAX_COUNT=5，直接覆盖保持、正常加一和回绕脉冲。
// 本文件不依赖 golden 内部信号，因此可原样验证 practice 实现。
// -----------------------------------------------------------------------------
module tb;
    // 选择较小且便于观察的参数，同时验证非二次幂模数。
    localparam int unsigned TB_WIDTH = 4;
    localparam logic [TB_WIDTH-1:0] TB_MAX_COUNT = 4'd5;

    // 测试平台产生的时钟、复位和输入驱动信号。
    logic clk;
    logic rst_n;
    logic enable;
    // DUT 的冻结输出端口连接。
    logic [TB_WIDTH-1:0] count;
    logic wrap;
    integer errors;

    // 被测实例名固定为 dut，参数仅在本测试平台 elaboration 时指定。
    parameterized_counter #(
        .WIDTH(TB_WIDTH),
        .MAX_COUNT(TB_MAX_COUNT)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .count  (count),
        .wrap   (wrap)
    );

    // 10ns 周期时钟；所有激励均在下降沿更新以避开上升沿采样竞争。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 覆盖 tb 及 dut 的全部外部端口，生成 Makefile 所要求的工作目录波形。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 主测试流程。每次时钟检查均在上升沿后的一个时间步执行，确保
    // 已观察到非阻塞赋值更新后的稳定结果。
    initial begin
        rst_n  = 1'b0;
        enable = 1'b0;
        errors = 0;

        // 异步复位无需等待时钟，应立即将所有可见状态清零。
        #1;
        if ((count !== '0) || (wrap !== 1'b0)) begin
            $display("ERROR[counter] asynchronous reset: count=%0h wrap=%0b", count, wrap);
            errors = errors + 1;
        end

        // 释放复位后保持使能关闭，验证多周期保持和 wrap 清零。
        @(negedge clk);
        rst_n  = 1'b1;
        enable = 1'b0;
        repeat (2) begin
            @(posedge clk);
            #1;
            if ((count !== '0) || (wrap !== 1'b0)) begin
                $display("ERROR[counter] hold: count=%0h wrap=%0b", count, wrap);
                errors = errors + 1;
            end
        end

        // 连续使能，检查 0 至 MAX_COUNT 的每一个普通递增结果。
        @(negedge clk);
        enable = 1'b1;
        for (int expected_count = 1; expected_count <= TB_MAX_COUNT; expected_count++) begin
            @(posedge clk);
            #1;
            if ((count != expected_count) || (wrap !== 1'b0)) begin
                $display("ERROR[counter] increment: expected=%0d got=%0d wrap=%0b",
                         expected_count, count, wrap);
                errors = errors + 1;
            end
        end

        // 下一拍必须从五回到零，并且 wrap 只在该拍拉高。
        @(posedge clk);
        #1;
        if ((count !== '0) || (wrap !== 1'b1)) begin
            $display("ERROR[counter] wrap: count=%0h wrap=%0b", count, wrap);
            errors = errors + 1;
        end

        // 再关闭使能，确认刚产生的脉冲不会被错误保持。
        @(negedge clk);
        enable = 1'b0;
        @(posedge clk);
        #1;
        if ((count !== '0) || (wrap !== 1'b0)) begin
            $display("ERROR[counter] post-wrap hold: count=%0h wrap=%0b", count, wrap);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS[counter] all checks passed");
        end else begin
            $fatal(1, "FAIL[counter] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
