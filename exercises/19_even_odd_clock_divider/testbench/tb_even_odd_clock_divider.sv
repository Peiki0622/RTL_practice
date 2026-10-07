// -----------------------------------------------------------------------------
// even_odd_clock_divider 的自检测试平台。
// 默认用 6 分频与 5 分频，同时检查周期、半周期和复位后的启动相位。
// -----------------------------------------------------------------------------
module tb;
    localparam int unsigned TB_EVEN_DIV = 6;
    localparam int unsigned TB_ODD_DIV  = 5;
    localparam time CLK_HALF = 5ns;
    localparam time CLK_PERIOD = 10ns;
    localparam time EVEN_HALF_PERIOD = (TB_EVEN_DIV / 2) * CLK_PERIOD;
    localparam time ODD_HALF_PERIOD  = TB_ODD_DIV * CLK_HALF;

    logic clk;
    logic rst_n;
    logic clk_div_even;
    logic clk_div_odd;

    integer even_errors;
    integer odd_errors;
    integer even_edges;
    integer odd_edges;
    time last_even_edge;
    time last_odd_edge;

    even_odd_clock_divider #(
        .EVEN_DIV(TB_EVEN_DIV),
        .ODD_DIV (TB_ODD_DIV)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .clk_div_even (clk_div_even),
        .clk_div_odd  (clk_div_odd)
    );

    initial begin
        clk = 1'b0;
        forever #CLK_HALF clk = ~clk;
    end

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 统计偶数分频输出的相邻边沿间隔。严格 50% 占空比意味着每个半周期
    // 都应等于 EVEN_DIV/2 个输入时钟周期。
    always @(posedge clk_div_even or negedge clk_div_even) begin
        if (rst_n) begin
            if (even_edges != 0) begin
                if (($time - last_even_edge) != EVEN_HALF_PERIOD) begin
                    $display("ERROR[divider] even half-period expected=%0t got=%0t",
                             EVEN_HALF_PERIOD, $time - last_even_edge);
                    even_errors = even_errors + 1;
                end
            end
            last_even_edge = $time;
            even_edges = even_edges + 1;
        end
    end

    // 奇数分频要达到严格 50% 占空比，相邻边沿间隔应为 ODD_DIV/2 个
    // 输入周期；因为 ODD_DIV 为奇数，该值落在半个输入周期的时间网格上。
    always @(posedge clk_div_odd or negedge clk_div_odd) begin
        if (rst_n) begin
            if (odd_edges != 0) begin
                if (($time - last_odd_edge) != ODD_HALF_PERIOD) begin
                    $display("ERROR[divider] odd half-period expected=%0t got=%0t",
                             ODD_HALF_PERIOD, $time - last_odd_edge);
                    odd_errors = odd_errors + 1;
                end
            end
            last_odd_edge = $time;
            odd_edges = odd_edges + 1;
        end
    end

    initial begin
        rst_n = 1'b1;
        even_errors = 0;
        odd_errors = 0;
        even_edges = 0;
        odd_edges = 0;
        last_even_edge = 0;
        last_odd_edge = 0;

        // 主动制造一次异步复位边沿，确认两个输出无需等待时钟即可清零。
        #2;
        rst_n = 1'b0;
        #1;
        if ((clk_div_even !== 1'b0) || (clk_div_odd !== 1'b0)) begin
            $display("ERROR[divider] asynchronous reset: even=%0b odd=%0b",
                     clk_div_even, clk_div_odd);
            even_errors = even_errors + 1;
            odd_errors = odd_errors + 1;
        end

        // 在下降沿释放复位，避免与 DUT 上升沿状态更新竞争。
        @(negedge clk);
        rst_n = 1'b1;

        // 第一个上升沿后，奇数分频应立即进入第一个高电平半周期；
        // 偶数分频尚未数满 EVEN_DIV/2 个上升沿，应保持为低。
        @(posedge clk);
        #1;
        if (clk_div_odd !== 1'b1) begin
            $display("ERROR[divider] odd startup phase: expected high at first posedge");
            odd_errors = odd_errors + 1;
        end
        if (clk_div_even !== 1'b0) begin
            $display("ERROR[divider] even startup phase: expected low before half-period");
            even_errors = even_errors + 1;
        end

        // 运行足够长时间，覆盖多个完整输出周期与共同边沿位置。
        repeat (36) @(posedge clk);
        #1;

        if (even_edges < 10) begin
            $display("ERROR[divider] too few even output edges: %0d", even_edges);
            even_errors = even_errors + 1;
        end
        if (odd_edges < 10) begin
            $display("ERROR[divider] too few odd output edges: %0d", odd_edges);
            odd_errors = odd_errors + 1;
        end

        // 再次在非输入时钟边沿时刻拉低复位，检查异步清零。
        #2;
        rst_n = 1'b0;
        #1;
        if ((clk_div_even !== 1'b0) || (clk_div_odd !== 1'b0)) begin
            $display("ERROR[divider] second asynchronous reset: even=%0b odd=%0b",
                     clk_div_even, clk_div_odd);
            even_errors = even_errors + 1;
            odd_errors = odd_errors + 1;
        end

        if ((even_errors == 0) && (odd_errors == 0)) begin
            $display("PASS[divider] all checks passed");
        end else begin
            $fatal(1, "FAIL[divider] even_errors=%0d odd_errors=%0d",
                   even_errors, odd_errors);
        end
        $finish;
    end
endmodule
