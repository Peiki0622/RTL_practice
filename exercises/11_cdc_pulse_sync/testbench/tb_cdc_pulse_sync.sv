// -----------------------------------------------------------------------------
// cdc_pulse_sync 的自检测试平台。
//
// 测试先以源快于目标的频率发送事件，再把源时钟改为慢于目标，覆盖快到慢与
// 慢到快。事件间隔始终至少跨过四个目标时钟上升沿，符合题目无握手方案假设。
// -----------------------------------------------------------------------------
module tb;
    // 两个独立时钟域的冻结端口信号。
    logic src_clk;
    logic src_rst_n;
    logic src_pulse;
    logic dst_clk;
    logic dst_rst_n;
    logic dst_pulse;

    // 可在空闲阶段调整源时钟半周期，以测试两种相对频率关系。
    time src_half_period = 3;
    time dst_half_period = 5;
    integer expected_events;
    integer observed_events;
    integer errors;
    logic   previous_dst_pulse;

    // 被测实例固定为 dut。
    cdc_pulse_sync dut (
        .src_clk   (src_clk),
        .src_rst_n (src_rst_n),
        .src_pulse (src_pulse),
        .dst_clk   (dst_clk),
        .dst_rst_n (dst_rst_n),
        .dst_pulse (dst_pulse)
    );

    // 源与目标时钟由不同进程生成，初始周期分别为 6ns 与 10ns。
    initial begin
        src_clk = 1'b0;
        forever #src_half_period src_clk = ~src_clk;
    end

    initial begin
        dst_clk = 1'b0;
        forever #dst_half_period dst_clk = ~dst_clk;
    end

    // 转储完整顶层，便于观察源事件、翻转传播和目标脉冲。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 仅在源域下降沿驱动单周期脉冲，确保 src_pulse 覆盖恰好一个 src_clk
    // 上升沿。任务仅复用激励时序，不实现 DUT 的 CDC 参考逻辑。
    task send_source_event;
        begin
            @(negedge src_clk);
            src_pulse = 1'b1;
            @(negedge src_clk);
            src_pulse = 1'b0;
            expected_events = expected_events + 1;
        end
    endtask

    // 目标域监视器统计每个脉冲，并验证其不会连续两个目标时钟周期为高。
    initial begin : destination_monitor
        previous_dst_pulse = 1'b0;
        observed_events    = 0;

        forever begin
            @(posedge dst_clk);
            #1;
            if (!dst_rst_n) begin
                previous_dst_pulse = 1'b0;
                if (dst_pulse !== 1'b0) begin
                    $display("ERROR[cdc_pulse] reset dst_pulse=%b", dst_pulse);
                    errors = errors + 1;
                end
            end else begin
                if (dst_pulse && previous_dst_pulse) begin
                    $display("ERROR[cdc_pulse] dst_pulse lasted more than one dst_clk cycle");
                    errors = errors + 1;
                end
                if (dst_pulse) begin
                    observed_events = observed_events + 1;
                end
                previous_dst_pulse = dst_pulse;
            end
        end
    end

    // 驱动复位、两种时钟速率下的独立事件，并在每次事件后留出足够的目标域
    // 同步时间，检查恰有一个新目标脉冲到达。
    initial begin : pulse_stimulus
        src_half_period = 3;
        dst_half_period = 5;
        src_rst_n       = 1'b0;
        dst_rst_n       = 1'b0;
        src_pulse       = 1'b0;
        expected_events = 0;
        errors          = 0;

        #1;
        if (dst_pulse !== 1'b0) begin
            $fatal(1, "FAIL[cdc_pulse] reset dst_pulse=%b", dst_pulse);
        end

        @(negedge src_clk);
        src_rst_n = 1'b1;
        @(negedge dst_clk);
        dst_rst_n = 1'b1;

        // 源快、目标慢：两个事件之间留出六个目标域边沿。
        send_source_event();
        repeat (6) @(posedge dst_clk);
        #1;
        if (observed_events != expected_events) begin
            $display("ERROR[cdc_pulse] fast-to-slow event expected=%0d observed=%0d",
                     expected_events, observed_events);
            errors = errors + 1;
        end

        send_source_event();
        repeat (6) @(posedge dst_clk);
        #1;
        if (observed_events != expected_events) begin
            $display("ERROR[cdc_pulse] second fast-to-slow event expected=%0d observed=%0d",
                     expected_events, observed_events);
            errors = errors + 1;
        end

        // 在空闲期切换源半周期。随后源周期为 16ns，慢于 10ns 目标周期。
        @(negedge src_clk);
        #1;
        src_half_period = 8;
        repeat (2) @(posedge dst_clk);

        send_source_event();
        repeat (6) @(posedge dst_clk);
        #1;
        if (observed_events != expected_events) begin
            $display("ERROR[cdc_pulse] slow-to-fast event expected=%0d observed=%0d",
                     expected_events, observed_events);
            errors = errors + 1;
        end

        repeat (2) @(posedge dst_clk);
        if (observed_events != expected_events) begin
            $display("ERROR[cdc_pulse] duplicate or missing pulse expected=%0d observed=%0d",
                     expected_events, observed_events);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS[cdc_pulse] all checks passed");
        end else begin
            $fatal(1, "FAIL[cdc_pulse] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
