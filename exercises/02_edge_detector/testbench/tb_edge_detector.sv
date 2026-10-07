// -----------------------------------------------------------------------------
// edge_detector 的自检测试平台。
//
// 激励覆盖复位后的首次采样、稳定输入和连续翻转；测试平台只观察模块
// 冻结端口，因此同一文件可验证 golden 与 practice 两种实现。
// -----------------------------------------------------------------------------
module tb;
    // 时钟、复位与输入驱动。
    logic clk;
    logic rst_n;
    logic sig_in;
    // DUT 的两个单拍输出。
    logic rise_pulse;
    logic fall_pulse;
    integer errors;

    // 被测实例名遵循仓库统一约定。
    edge_detector dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .sig_in     (sig_in),
        .rise_pulse (rise_pulse),
        .fall_pulse (fall_pulse)
    );

    // 10ns 周期时钟；输入在下降沿切换以避免与 DUT 采样竞争。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 转储完整测试层次，波形文件名由各题 Makefile 约束为 wave.fsdb。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 主测试流程。脉冲输出在每个上升沿后检查，确保不会遗漏单拍行为。
    initial begin
        rst_n  = 1'b0;
        sig_in = 1'b0;
        errors = 0;

        #1;
        if ((rise_pulse !== 1'b0) || (fall_pulse !== 1'b0)) begin
            $display("ERROR[edge] reset pulse rise=%0b fall=%0b", rise_pulse, fall_pulse);
            errors = errors + 1;
        end

        // 复位后将输入置高再释放复位，验证历史值为零时的首次上升沿。
        @(negedge clk);
        sig_in = 1'b1;
        rst_n  = 1'b1;
        @(posedge clk);
        #1;
        if ((rise_pulse !== 1'b1) || (fall_pulse !== 1'b0)) begin
            $display("ERROR[edge] first rising sample rise=%0b fall=%0b", rise_pulse, fall_pulse);
            errors = errors + 1;
        end

        // 高电平保持不应重复产生上升沿或下降沿。
        repeat (2) begin
            @(posedge clk);
            #1;
            if ((rise_pulse !== 1'b0) || (fall_pulse !== 1'b0)) begin
                $display("ERROR[edge] stable high rise=%0b fall=%0b", rise_pulse, fall_pulse);
                errors = errors + 1;
            end
        end

        // 切换到低电平，验证恰好一个下降沿脉冲。
        @(negedge clk);
        sig_in = 1'b0;
        @(posedge clk);
        #1;
        if ((rise_pulse !== 1'b0) || (fall_pulse !== 1'b1)) begin
            $display("ERROR[edge] falling edge rise=%0b fall=%0b", rise_pulse, fall_pulse);
            errors = errors + 1;
        end

        // 相邻周期快速翻转，分别确认上升沿、下降沿和两个脉冲的互斥性。
        @(negedge clk);
        sig_in = 1'b1;
        @(posedge clk);
        #1;
        if ((rise_pulse !== 1'b1) || (fall_pulse !== 1'b0)) begin
            $display("ERROR[edge] rapid rising edge rise=%0b fall=%0b", rise_pulse, fall_pulse);
            errors = errors + 1;
        end

        @(negedge clk);
        sig_in = 1'b0;
        @(posedge clk);
        #1;
        if ((rise_pulse !== 1'b0) || (fall_pulse !== 1'b1)) begin
            $display("ERROR[edge] rapid falling edge rise=%0b fall=%0b", rise_pulse, fall_pulse);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS[edge] all checks passed");
        end else begin
            $fatal(1, "FAIL[edge] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
