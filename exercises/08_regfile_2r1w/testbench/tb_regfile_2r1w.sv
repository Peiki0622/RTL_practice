// -----------------------------------------------------------------------------
// regfile_2r1w 的自检测试平台。
//
// 不读取未初始化存储项；先建立已知内容，再检查同步写、双读并行、同址双读
// 以及“无显式旁路”的写沿前旧值和写沿后新值语义。
// -----------------------------------------------------------------------------
module tb;
    // 较小配置便于在波形中辨认每一项内容。
    localparam int unsigned TB_DATA_WIDTH = 8;
    localparam int unsigned TB_DEPTH      = 4;
    localparam int unsigned TB_ADDR_WIDTH = $clog2(TB_DEPTH);

    // DUT 时钟、写端口和两个读端口输入。
    logic                     clk;
    logic                     we;
    logic [TB_ADDR_WIDTH-1:0] waddr;
    logic [TB_DATA_WIDTH-1:0] wdata;
    logic [TB_ADDR_WIDTH-1:0] raddr0;
    logic [TB_ADDR_WIDTH-1:0] raddr1;
    // DUT 的两个冻结组合读输出。
    logic [TB_DATA_WIDTH-1:0] rdata0;
    logic [TB_DATA_WIDTH-1:0] rdata1;
    integer                   errors;

    // 被测实例固定为 dut。
    regfile_2r1w #(
        .DATA_WIDTH(TB_DATA_WIDTH),
        .DEPTH     (TB_DEPTH)
    ) dut (
        .clk    (clk),
        .we     (we),
        .waddr  (waddr),
        .wdata  (wdata),
        .raddr0 (raddr0),
        .rdata0 (rdata0),
        .raddr1 (raddr1),
        .rdata1 (rdata1)
    );

    // 10ns 时钟；刺激在下降沿稳定，以便下个上升沿进行同步写。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 转储完整 tb 层次，包含外部端口及 DUT 的可见数组状态。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 对两个组合读端口作独立明确检查，错误日志保留当前测试语义。
    task check_reads(
        input logic [TB_DATA_WIDTH-1:0] expected_rdata0,
        input logic [TB_DATA_WIDTH-1:0] expected_rdata1,
        input string                    label_text
    );
        begin
            #1;
            if (rdata0 !== expected_rdata0) begin
                $display("ERROR[regfile] %s rdata0 expected=%0h got=%0h",
                         label_text, expected_rdata0, rdata0);
                errors = errors + 1;
            end
            if (rdata1 !== expected_rdata1) begin
                $display("ERROR[regfile] %s rdata1 expected=%0h got=%0h",
                         label_text, expected_rdata1, rdata1);
                errors = errors + 1;
            end
        end
    endtask

    // 定向写入和读回。每次写都在时钟沿后检查阵列更新，最后单独验证写同址
    // 读在写沿前不会旁路、写沿后自然看到新值。
    initial begin : regfile_stimulus
        we     = 1'b0;
        waddr  = '0;
        wdata  = '0;
        raddr0 = '0;
        raddr1 = '0;
        errors = 0;

        // 建立地址 0 的已知值，并让两个读端口读取同一地址。
        @(negedge clk);
        we     = 1'b1;
        waddr  = 2'd0;
        wdata  = 8'h11;
        raddr0 = 2'd0;
        raddr1 = 2'd0;
        @(posedge clk);
        check_reads(8'h11, 8'h11, "same-address dual read after first write");

        // 写地址 1，同时读回地址 0 与地址 1，验证两路组合读相互独立。
        @(negedge clk);
        waddr  = 2'd1;
        wdata  = 8'h22;
        raddr0 = 2'd0;
        raddr1 = 2'd1;
        @(posedge clk);
        check_reads(8'h11, 8'h22, "independent reads after second write");

        // 继续填充地址 2，覆盖不同地址并行读取的常用情形。
        @(negedge clk);
        waddr  = 2'd2;
        wdata  = 8'h33;
        raddr0 = 2'd1;
        raddr1 = 2'd2;
        @(posedge clk);
        check_reads(8'h22, 8'h33, "different-address dual read");

        // 对已知地址 0 发起同址写读。规格明确不要求显式旁路，因此写沿前仍
        // 必须读到旧值 11，写沿后才读到新值 aa。
        @(negedge clk);
        waddr  = 2'd0;
        wdata  = 8'haa;
        raddr0 = 2'd0;
        raddr1 = 2'd1;
        check_reads(8'h11, 8'h22, "pre-edge read without explicit bypass");
        @(posedge clk);
        check_reads(8'haa, 8'h22, "post-edge natural updated read");

        // 关闭写端口后重复双读，确认组合读不会彼此阻塞且数据能稳定保留。
        @(negedge clk);
        we     = 1'b0;
        raddr0 = 2'd2;
        raddr1 = 2'd0;
        check_reads(8'h33, 8'haa, "read-only parallel access");

        repeat (2) @(posedge clk);
        if (errors == 0) begin
            $display("PASS[regfile] all checks passed");
        end else begin
            $fatal(1, "FAIL[regfile] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
