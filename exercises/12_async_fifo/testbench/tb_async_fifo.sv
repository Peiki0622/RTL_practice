// -----------------------------------------------------------------------------
// async_fifo 的自检测试平台。
//
// 写、读时钟周期不同且相位错开。固定大小的独立参考阵列由观测到的写握手
// 填充，读握手逐项比较；不读取 DUT 内部状态，不使用动态队列或自定义函数。
// -----------------------------------------------------------------------------
module tb;
    // 深度四可在短仿真中覆盖满、空和地址回绕；数据宽度八便于观察顺序。
    localparam int unsigned TB_DATA_WIDTH = 8;
    localparam int unsigned TB_DEPTH      = 4;

    // 写时钟域的冻结接口信号。
    logic                     wr_clk;
    logic                     wr_rst_n;
    logic                     wr_valid;
    logic                     wr_ready;
    logic [TB_DATA_WIDTH-1:0] wr_data;
    // 读时钟域的冻结接口信号。
    logic                     rd_clk;
    logic                     rd_rst_n;
    logic                     rd_valid;
    logic                     rd_ready;
    logic [TB_DATA_WIDTH-1:0] rd_data;

    // 8ns 写周期和 14ns 读周期构成非整数频率比；读时钟额外延后 4ns 启动，
    // 使两个上升沿永不重合，参考模型的读写事件没有调度竞争。
    time wr_half_period = 4;
    time rd_half_period = 7;

    // 固定数组参考队列。写序号只由写域监视器更新，读序号只由读域监视器
    // 更新；数组项只由写监视器写入，避免 scoreboard 的多驱动。
    logic [TB_DATA_WIDTH-1:0] expected_mem [0:TB_DEPTH-1];
    integer                   expected_write_sequence;
    integer                   expected_read_sequence;
    integer                   write_monitor_errors;
    integer                   read_monitor_errors;
    integer                   stimulus_errors;

    // 读端反压稳定性检查的本地历史值，只由读域监视器维护。
    logic                     stall_active;
    logic [TB_DATA_WIDTH-1:0] stalled_data;
    // 两个确定性 LFSR 为长随机流提供可重复的 valid/ready 与数据模式。
    logic [15:0]              write_lfsr;
    logic [15:0]              read_lfsr;

    // 被测实例固定名为 dut，完全使用冻结端口。
    async_fifo #(
        .DATA_WIDTH(TB_DATA_WIDTH),
        .DEPTH     (TB_DEPTH)
    ) dut (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_valid (wr_valid),
        .wr_ready (wr_ready),
        .wr_data  (wr_data),
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_valid (rd_valid),
        .rd_ready (rd_ready),
        .rd_data  (rd_data)
    );

    // 写时钟从 t=0 开始；写端输入只会在其下降沿改变。
    initial begin
        wr_clk = 1'b0;
        forever #wr_half_period wr_clk = ~wr_clk;
    end

    // 读时钟相位错开，读端输入只会在其下降沿改变。
    initial begin
        rd_clk = 1'b0;
        #4;
        forever #rd_half_period rd_clk = ~rd_clk;
    end

    // 全层次 FSDB 转储同时包含接口和参考检查信号。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 写域 scoreboard：只有真实 wr_valid && wr_ready 握手才写入参考阵列并
    // 推进序号。复位只清空模型控制状态，不需要初始化数据数组。
    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            expected_write_sequence = 0;
            write_monitor_errors    = 0;
        end else if (wr_valid && wr_ready) begin
            expected_mem[expected_write_sequence % TB_DEPTH] = wr_data;
            expected_write_sequence = expected_write_sequence + 1;
        end
    end

    // 读域 scoreboard：在读握手的采样时刻比较前视 rd_data 与参考队头。它还
    // 在每个停顿周期保存数据，并验证持续 rd_valid && !rd_ready 时数据不变。
    always @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            expected_read_sequence = 0;
            read_monitor_errors    = 0;
            stall_active           = 1'b0;
            stalled_data           = '0;
        end else begin
            if (rd_valid && !rd_ready) begin
                if (stall_active && (rd_data !== stalled_data)) begin
                    $display("ERROR[async_fifo] stalled rd_data changed expected=%0h got=%0h",
                             stalled_data, rd_data);
                    read_monitor_errors = read_monitor_errors + 1;
                end
                stalled_data = rd_data;
                stall_active = 1'b1;
            end else begin
                stall_active = 1'b0;
            end

            if (rd_valid && rd_ready) begin
                if (expected_read_sequence >= expected_write_sequence) begin
                    $display("ERROR[async_fifo] read handshake occurred without model data");
                    read_monitor_errors = read_monitor_errors + 1;
                end else if (rd_data !== expected_mem[expected_read_sequence % TB_DEPTH]) begin
                    $display("ERROR[async_fifo] data order mismatch sequence=%0d expected=%0h got=%0h",
                             expected_read_sequence,
                             expected_mem[expected_read_sequence % TB_DEPTH], rd_data);
                    read_monitor_errors = read_monitor_errors + 1;
                end
                expected_read_sequence = expected_read_sequence + 1;
            end
        end
    end

    // 主激励进程是 wr_valid/wr_data/rd_ready 的唯一驱动源。前半段采用定向
    // 场景，后半段以 LFSR 产生可复现的长随机流，并最终把所有已接受数据排空。
    initial begin : fifo_stimulus
        wr_rst_n       = 1'b0;
        rd_rst_n       = 1'b0;
        wr_valid       = 1'b0;
        wr_data        = '0;
        rd_ready       = 1'b0;
        stimulus_errors = 0;
        write_lfsr     = 16'h1ace;
        read_lfsr      = 16'h2bad;

        #1;
        if (rd_valid !== 1'b0) begin
            $fatal(1, "FAIL[async_fifo] reset rd_valid=%b", rd_valid);
        end

        // 两个域均在开始阶段经历异步复位，再分别于各自下降沿释放。
        @(negedge wr_clk);
        wr_rst_n = 1'b1;
        @(negedge rd_clk);
        rd_rst_n = 1'b1;

        // 读端保持反压，连续写入四笔数据直到写域观察到满；每笔数据由写域
        // 监视器按实际握手记录，因而不会假设跨域标志无延迟。
        @(negedge wr_clk);
        wr_valid = 1'b1;
        wr_data  = 8'ha1;
        @(negedge wr_clk);
        wr_data  = 8'hb2;
        @(negedge wr_clk);
        wr_data  = 8'hc3;
        @(negedge wr_clk);
        wr_data  = 8'hd4;
        @(negedge wr_clk);
        #1;
        if (wr_ready !== 1'b0) begin
            $display("ERROR[async_fifo] wr_ready did not deassert after filling FIFO");
            stimulus_errors = stimulus_errors + 1;
        end

        // 满状态下继续请求写，必须保持 wr_ready 为低且不能覆盖已排队数据。
        wr_data = 8'he5;
        repeat (2) @(negedge wr_clk);
        #1;
        if (wr_ready !== 1'b0) begin
            $display("ERROR[async_fifo] full FIFO accepted an extra write request");
            stimulus_errors = stimulus_errors + 1;
        end
        wr_valid = 1'b0;

        // 等待读域经两级同步观察到非空，然后故意反压三个读时钟周期；读域
        // monitor 会检查 rd_data 在整个停顿期间稳定。
        repeat (8) @(posedge rd_clk);
        if (rd_valid !== 1'b1) begin
            $display("ERROR[async_fifo] rd_valid did not assert for queued data");
            stimulus_errors = stimulus_errors + 1;
        end
        repeat (3) @(posedge rd_clk);

        // 释放读端并排空四笔数据，覆盖读指针回绕与严格 FIFO 顺序。
        @(negedge rd_clk);
        rd_ready = 1'b1;
        repeat (7) @(posedge rd_clk);
        #1;
        if (rd_valid !== 1'b0) begin
            $display("ERROR[async_fifo] rd_valid did not deassert after draining FIFO");
            stimulus_errors = stimulus_errors + 1;
        end
        @(negedge rd_clk);
        rd_ready = 1'b0;

        // 长随机流：每轮均在对应输入时钟下降沿产生下一组 valid/ready/data，
        // 先前驱动值会跨越实际采样上升沿。LFSR 使失败可重现且不依赖随机种子。
        for (int unsigned transaction_index = 0; transaction_index < 128;
             transaction_index++) begin
            @(negedge wr_clk);
            write_lfsr = {write_lfsr[14:0],
                          write_lfsr[15] ^ write_lfsr[13] ^
                          write_lfsr[12] ^ write_lfsr[10]};
            wr_valid = write_lfsr[0];
            wr_data  = write_lfsr[7:0] ^ transaction_index[7:0];

            @(negedge rd_clk);
            read_lfsr = {read_lfsr[14:0],
                         read_lfsr[15] ^ read_lfsr[13] ^
                         read_lfsr[12] ^ read_lfsr[10]};
            rd_ready = read_lfsr[0];
        end

        // 停止发起新写，并持续接收读数据，直到 scoreboard 的两个序号相等。
        @(negedge wr_clk);
        wr_valid = 1'b0;
        @(negedge rd_clk);
        rd_ready = 1'b1;

        for (int unsigned drain_cycles = 0; drain_cycles < 160; drain_cycles++) begin
            @(posedge rd_clk);
            if (expected_read_sequence == expected_write_sequence) begin
                break;
            end
        end
        #2;

        if (expected_read_sequence != expected_write_sequence) begin
            $display("ERROR[async_fifo] timeout while draining expected_write=%0d expected_read=%0d",
                     expected_write_sequence, expected_read_sequence);
            stimulus_errors = stimulus_errors + 1;
        end
        if (rd_valid !== 1'b0) begin
            $display("ERROR[async_fifo] rd_valid remained high after final drain");
            stimulus_errors = stimulus_errors + 1;
        end

        if ((write_monitor_errors == 0) && (read_monitor_errors == 0) &&
            (stimulus_errors == 0)) begin
            $display("PASS[async_fifo] all checks passed");
        end else begin
            $fatal(1, "FAIL[async_fifo] write_errors=%0d read_errors=%0d stimulus_errors=%0d",
                   write_monitor_errors, read_monitor_errors, stimulus_errors);
        end
        $finish;
    end
endmodule
