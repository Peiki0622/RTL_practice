// -----------------------------------------------------------------------------
// sequence_detector 的自检测试平台。
//
// 每个向量从最高位至最低位串行送入。期望 match 向量采用相同的送入次序，
// 便于明确检查普通匹配、无匹配和重叠匹配的每一个采样周期。
// -----------------------------------------------------------------------------
module tb;
    // 时钟、异步复位和串行输入。
    logic clk;
    logic rst_n;
    logic bit_in;
    // DUT 的单拍匹配输出。
    logic match;
    integer errors;

    // 被测实例名固定为 dut，并且不暴露或访问内部状态。
    sequence_detector dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .bit_in (bit_in),
        .match  (match)
    );

    // 10ns 周期时钟；串行位在下降沿提供给下一次上升沿采样。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 转储测试平台及 DUT 外部端口，供 Verdi 回放脚本直接使用。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 主测试流程。每个循环中显式比较本次采样后的 match，避免只统计
    // 总次数而遗漏错误的脉冲位置或脉冲宽度。
    initial begin
        logic [6:0] overlap_bits;
        logic [6:0] overlap_expected;
        logic [5:0] candidate_bits;
        logic [5:0] candidate_expected;
        logic [5:0] miss_bits;
        logic [5:0] miss_expected;

        rst_n  = 1'b0;
        bit_in = 1'b0;
        errors = 0;

        #1;
        if (match !== 1'b0) begin
            $display("ERROR[sequence] reset match=%0b", match);
            errors = errors + 1;
        end

        // 第一段为最短的普通 1011 匹配，最后一个输入位后必须脉冲一次。
        @(negedge clk);
        rst_n = 1'b1;
        for (int index = 3; index >= 0; index--) begin
            case (index)
                3: bit_in = 1'b1;
                2: bit_in = 1'b0;
                1: bit_in = 1'b1;
                default: bit_in = 1'b1;
            endcase
            @(posedge clk);
            #1;
            if (match !== (index == 0)) begin
                $display("ERROR[sequence] basic index=%0d match=%0b", index, match);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        // 单独复位后送入 1011011，应在第四和第七个输入位各检测一次。
        rst_n = 1'b0;
        bit_in = 1'b0;
        #1;
        @(negedge clk);
        rst_n = 1'b1;
        overlap_bits     = 7'b1011011;
        overlap_expected = 7'b0001001;
        for (int index = 6; index >= 0; index--) begin
            bit_in = overlap_bits[index];
            @(posedge clk);
            #1;
            if (match !== overlap_expected[index]) begin
                $display("ERROR[sequence] overlap index=%0d expected=%0b got=%0b",
                         index, overlap_expected[index], match);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        // 连续候选前缀 111011 只在最终输入位完成一次 1011 匹配。
        rst_n = 1'b0;
        bit_in = 1'b0;
        #1;
        @(negedge clk);
        rst_n = 1'b1;
        candidate_bits     = 6'b111011;
        candidate_expected = 6'b000001;
        for (int index = 5; index >= 0; index--) begin
            bit_in = candidate_bits[index];
            @(posedge clk);
            #1;
            if (match !== candidate_expected[index]) begin
                $display("ERROR[sequence] candidate index=%0d expected=%0b got=%0b",
                         index, candidate_expected[index], match);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        // 全零输入不包含任何目标序列，验证无匹配路径一直保持低电平。
        rst_n = 1'b0;
        bit_in = 1'b0;
        #1;
        @(negedge clk);
        rst_n = 1'b1;
        miss_bits     = 6'b000000;
        miss_expected = 6'b000000;
        for (int index = 5; index >= 0; index--) begin
            bit_in = miss_bits[index];
            @(posedge clk);
            #1;
            if (match !== miss_expected[index]) begin
                $display("ERROR[sequence] miss index=%0d expected=%0b got=%0b",
                         index, miss_expected[index], match);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        if (errors == 0) begin
            $display("PASS[sequence] all checks passed");
        end else begin
            $fatal(1, "FAIL[sequence] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
