// -----------------------------------------------------------------------------
// sync_fifo 的自检测试平台。
//
// 选择 DEPTH=3 以验证非二次幂指针回绕。独立 scoreboard 用固定数组、
// 指针和计数器保存预期队列，不使用动态队列，也不访问 DUT 内部状态。
// -----------------------------------------------------------------------------
module tb;
    // 小数据宽度使队列顺序在日志和波形中易于辨认。
    localparam int unsigned TB_DATA_WIDTH = 8;
    // 非二次幂深度是本题关键参数覆盖项。
    localparam int unsigned TB_DEPTH = 3;

    // DUT 的时钟、复位、读写请求和写数据输入。
    logic                     clk;
    logic                     rst_n;
    logic                     wr_en;
    logic [TB_DATA_WIDTH-1:0] wr_data;
    logic                     rd_en;
    // DUT 的冻结输出端口连接。
    logic                     full;
    logic [TB_DATA_WIDTH-1:0] rd_data;
    logic                     empty;

    // 参考模型存储和控制状态。它们只在下方 monitor 进程中更新。
    logic [TB_DATA_WIDTH-1:0] exp_mem [0:TB_DEPTH-1];
    integer exp_rd_ptr;
    integer exp_wr_ptr;
    integer exp_count;
    integer errors;

    // 被测实例固定命名为 dut；参数仅用于本测试平台的覆盖配置。
    sync_fifo #(
        .DATA_WIDTH(TB_DATA_WIDTH),
        .DEPTH     (TB_DEPTH)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .empty   (empty)
    );

    // 10ns 周期时钟；请求和数据在下降沿更新，使 DUT 在下个上升沿采样。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 输出完整 tb 层次，其中同时包含 DUT 外部端口和 scoreboard 可见状态。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 独立周期级 scoreboard。它先检查本拍开始时的满空和队头，再按照
    // 自己的预期占用数决定操作是否成功，最后检查 DUT 更新后的新状态。
    initial begin : fifo_scoreboard
        logic expected_write_fire;
        logic expected_read_fire;
        logic expected_full;
        logic expected_empty;

        exp_rd_ptr = 0;
        exp_wr_ptr = 0;
        exp_count  = 0;
        errors     = 0;

        forever begin
            @(posedge clk);
            if (!rst_n) begin
                exp_rd_ptr = 0;
                exp_wr_ptr = 0;
                exp_count  = 0;
                #1;
                if ((full !== 1'b0) || (empty !== 1'b1)) begin
                    $display("ERROR[fifo] reset full=%0b empty=%0b", full, empty);
                    errors = errors + 1;
                end
            end else begin
                expected_full  = (exp_count == TB_DEPTH);
                expected_empty = (exp_count == 0);

                // 前态检查确保 DUT 没有把同拍相反方向操作提前用于解锁边界。
                if (full !== expected_full) begin
                    $display("ERROR[fifo] pre-edge full expected=%0b got=%0b", expected_full, full);
                    errors = errors + 1;
                end
                if (empty !== expected_empty) begin
                    $display("ERROR[fifo] pre-edge empty expected=%0b got=%0b", expected_empty, empty);
                    errors = errors + 1;
                end
                if (!expected_empty && (rd_data !== exp_mem[exp_rd_ptr])) begin
                    $display("ERROR[fifo] front data expected=%0h got=%0h", exp_mem[exp_rd_ptr], rd_data);
                    errors = errors + 1;
                end

                expected_write_fire = wr_en && !expected_full;
                expected_read_fire  = rd_en && !expected_empty;

                // 更新参考存储和独立指针；显式回绕与规格的任意深度要求对应。
                if (expected_write_fire) begin
                    exp_mem[exp_wr_ptr] = wr_data;
                    if (exp_wr_ptr == TB_DEPTH - 1) begin
                        exp_wr_ptr = 0;
                    end else begin
                        exp_wr_ptr = exp_wr_ptr + 1;
                    end
                end
                if (expected_read_fire) begin
                    if (exp_rd_ptr == TB_DEPTH - 1) begin
                        exp_rd_ptr = 0;
                    end else begin
                        exp_rd_ptr = exp_rd_ptr + 1;
                    end
                end
                case ({expected_write_fire, expected_read_fire})
                    2'b10: exp_count = exp_count + 1;
                    2'b01: exp_count = exp_count - 1;
                    default: exp_count = exp_count;
                endcase

                // 在 DUT 非阻塞更新完成后检查新满空状态和下一队头。
                #1;
                expected_full  = (exp_count == TB_DEPTH);
                expected_empty = (exp_count == 0);
                if (full !== expected_full) begin
                    $display("ERROR[fifo] post-edge full expected=%0b got=%0b", expected_full, full);
                    errors = errors + 1;
                end
                if (empty !== expected_empty) begin
                    $display("ERROR[fifo] post-edge empty expected=%0b got=%0b", expected_empty, empty);
                    errors = errors + 1;
                end
                if (!expected_empty && (rd_data !== exp_mem[exp_rd_ptr])) begin
                    $display("ERROR[fifo] next front expected=%0h got=%0h", exp_mem[exp_rd_ptr], rd_data);
                    errors = errors + 1;
                end
            end
        end
    end

    // 定向事务序列。每个段落均针对规格中的一个边界条件，scoreboard 对
    // 所有时钟周期进行数据顺序与控制状态检查。
    initial begin : fifo_stimulus
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = '0;
        rd_en   = 1'b0;

        // 异步复位后，空标志必须立即有效；队头数据在空时不参与检查。
        #1;
        if ((full !== 1'b0) || (empty !== 1'b1)) begin
            $fatal(1, "FAIL[fifo] asynchronous reset full=%0b empty=%0b", full, empty);
        end

        @(negedge clk);
        rst_n = 1'b1;

        // 依次写入三笔数据，填满深度为三的 FIFO，并让写指针完成一次回绕。
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'hA1;
        @(negedge clk);
        wr_data = 8'hB2;
        @(negedge clk);
        wr_data = 8'hC3;

        // 满时同拍请求读写：读取队头 A1，但写入 D4 必须被拒绝。
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'hD4;
        rd_en   = 1'b1;

        // 非边界同拍读写：消费 B2，并接收 E5，验证占用数保持不变。
        @(negedge clk);
        wr_data = 8'hE5;

        // 仅写入 F6 重新填满，覆盖已回绕写指针的后续使用。
        @(negedge clk);
        wr_data = 8'hF6;
        rd_en   = 1'b0;

        // 再次在满状态同拍读写：消费 C3，拒绝写入 77。
        @(negedge clk);
        wr_data = 8'h77;
        rd_en   = 1'b1;

        // 连续读取剩余 E5、F6，达到空状态并覆盖读指针回绕。
        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b1;
        @(negedge clk);

        // 空时同拍读写：读必须被拒绝，88 写入后成为新的唯一队头。
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'h88;
        rd_en   = 1'b1;

        // 读取 H8 并在随后空闲两个周期，使 monitor 完成最终后态检查。
        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b1;
        @(negedge clk);
        rd_en = 1'b0;
        repeat (2) @(posedge clk);
        #2;

        if (errors == 0) begin
            $display("PASS[fifo] all checks passed");
        end else begin
            $fatal(1, "FAIL[fifo] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
