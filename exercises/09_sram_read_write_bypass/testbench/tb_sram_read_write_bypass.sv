// -----------------------------------------------------------------------------
// sram_read_write_bypass 的自检测试平台。
//
// 先写入确定内容，再分别验证普通读、不同地址并行读写和同地址写读旁路；
// 关键旁路检查发生在写时钟沿之前，因而不会被阵列自然更新掩盖。
// -----------------------------------------------------------------------------
module tb;
    // 小规模配置便于在波形中观察读写冲突。
    localparam int unsigned TB_DATA_WIDTH = 8;
    localparam int unsigned TB_DEPTH      = 4;
    localparam int unsigned TB_ADDR_WIDTH = $clog2(TB_DEPTH);

    // DUT 时钟及读写端口输入。
    logic                     clk;
    logic                     we;
    logic [TB_ADDR_WIDTH-1:0] waddr;
    logic [TB_DATA_WIDTH-1:0] wdata;
    logic [TB_ADDR_WIDTH-1:0] raddr;
    // DUT 的冻结组合读输出。
    logic [TB_DATA_WIDTH-1:0] rdata;
    integer                   errors;

    // 被测实例固定为 dut。
    sram_read_write_bypass #(
        .DATA_WIDTH(TB_DATA_WIDTH),
        .DEPTH     (TB_DEPTH)
    ) dut (
        .clk   (clk),
        .we    (we),
        .waddr (waddr),
        .wdata (wdata),
        .raddr (raddr),
        .rdata (rdata)
    );

    // 10ns 时钟，输入在下降沿设置，写入在随后的上升沿发生。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 输出完整验证层次并生成标准固定名的 FSDB 文件。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 单一读数据检查任务只复用日志格式，不实现或隐藏任何参考功能。
    task check_rdata(
        input logic [TB_DATA_WIDTH-1:0] expected_rdata,
        input string                    label_text
    );
        begin
            #1;
            if (rdata !== expected_rdata) begin
                $display("ERROR[sram_bypass] %s expected=%0h got=%0h",
                         label_text, expected_rdata, rdata);
                errors = errors + 1;
            end
        end
    endtask

    // 定向场景覆盖普通存储读写、地址不同的并行访问，以及同地址旁路。
    initial begin : bypass_stimulus
        we     = 1'b0;
        waddr  = '0;
        wdata  = '0;
        raddr  = '0;
        errors = 0;

        // 写入两个已知初值，避免检查未定义的非复位阵列内容。
        @(negedge clk);
        we    = 1'b1;
        waddr = 2'd0;
        wdata = 8'h10;
        raddr = 2'd0;
        @(posedge clk);
        check_rdata(8'h10, "ordinary read after write to address 0");

        @(negedge clk);
        waddr = 2'd1;
        wdata = 8'h20;
        raddr = 2'd0;
        // 地址不同的写入不能影响当前读地址 0 的旧存储内容。
        check_rdata(8'h10, "different-address read while write is pending");
        @(posedge clk);
        check_rdata(8'h10, "different-address read after write commits");

        // 同址写读发生在下一个写沿之前时，旁路必须立即输出 aa，而不是旧值 10。
        @(negedge clk);
        waddr = 2'd0;
        wdata = 8'haa;
        raddr = 2'd0;
        check_rdata(8'haa, "same-address bypass before write edge");
        @(posedge clk);
        check_rdata(8'haa, "same-address value after write edge");

        // 再次执行地址不同读写，验证旁路选择器不会错误覆盖其他地址的读数据。
        @(negedge clk);
        waddr = 2'd1;
        wdata = 8'hbb;
        raddr = 2'd0;
        check_rdata(8'haa, "bypass not selected for different addresses");
        @(posedge clk);
        check_rdata(8'haa, "address 0 remains unchanged");

        @(negedge clk);
        we    = 1'b0;
        raddr = 2'd1;
        check_rdata(8'hbb, "ordinary read of updated address 1");

        repeat (2) @(posedge clk);
        if (errors == 0) begin
            $display("PASS[sram_bypass] all checks passed");
        end else begin
            $fatal(1, "FAIL[sram_bypass] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
