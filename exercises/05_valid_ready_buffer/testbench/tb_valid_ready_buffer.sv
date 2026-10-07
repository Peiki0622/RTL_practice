// -----------------------------------------------------------------------------
// valid_ready_buffer 的自检测试平台。
//
// 独立的一项参考模型只根据握手定义更新预期状态，检查反压数据稳定性、
// 同拍收发替换、连续满速传输和空缓冲不直通等冻结行为。
// -----------------------------------------------------------------------------
module tb;
    // 使用较小数据宽度便于在日志和 FSDB 中识别传输顺序。
    localparam int unsigned TB_DATA_WIDTH = 8;

    // DUT 时钟、复位、上游和下游接口信号。
    logic                     clk;
    logic                     rst_n;
    logic                     s_valid;
    logic                     s_ready;
    logic [TB_DATA_WIDTH-1:0] s_data;
    logic                     m_valid;
    logic                     m_ready;
    logic [TB_DATA_WIDTH-1:0] m_data;

    // 一项参考模型状态，仅由下方 monitor 进程写入。
    logic                     exp_valid;
    logic [TB_DATA_WIDTH-1:0] exp_data;
    integer errors;

    // 被测实例固定为 dut，不增加任何调试端口。
    valid_ready_buffer #(
        .DATA_WIDTH(TB_DATA_WIDTH)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_valid (s_valid),
        .s_ready (s_ready),
        .s_data  (s_data),
        .m_valid (m_valid),
        .m_ready (m_ready),
        .m_data  (m_data)
    );

    // 10ns 周期时钟；接口激励在下降沿修改，下一上升沿完成握手。
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 转储 tb 和 dut 层次，保证 Makefile 在 .sim/<variant> 下找到 wave.fsdb。
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // 周期级独立参考模型。先比较当前可见接口，再依照预期握手更新模型，
    // 最后在非阻塞更新后比较下一周期对外可见的数据和有效标志。
    initial begin : buffer_scoreboard
        logic expected_s_ready;
        logic expected_push_fire;
        logic expected_pop_fire;

        exp_valid = 1'b0;
        exp_data  = '0;
        errors    = 0;

        forever begin
            @(posedge clk);
            if (!rst_n) begin
                exp_valid = 1'b0;
                exp_data  = '0;
                #1;
                if (m_valid !== 1'b0) begin
                    $display("ERROR[buffer] reset m_valid=%0b", m_valid);
                    errors = errors + 1;
                end
            end else begin
                expected_s_ready = !exp_valid || m_ready;
                if (s_ready !== expected_s_ready) begin
                    $display("ERROR[buffer] s_ready expected=%0b got=%0b", expected_s_ready, s_ready);
                    errors = errors + 1;
                end
                if (m_valid !== exp_valid) begin
                    $display("ERROR[buffer] m_valid expected=%0b got=%0b", exp_valid, m_valid);
                    errors = errors + 1;
                end
                if (exp_valid && (m_data !== exp_data)) begin
                    $display("ERROR[buffer] output data expected=%0h got=%0h", exp_data, m_data);
                    errors = errors + 1;
                end

                expected_push_fire = s_valid && expected_s_ready;
                expected_pop_fire  = exp_valid && m_ready;
                case ({expected_push_fire, expected_pop_fire})
                    2'b10: begin
                        exp_valid = 1'b1;
                        exp_data  = s_data;
                    end
                    2'b01: begin
                        exp_valid = 1'b0;
                    end
                    2'b11: begin
                        exp_valid = 1'b1;
                        exp_data  = s_data;
                    end
                    default: begin
                        exp_valid = exp_valid;
                        exp_data  = exp_data;
                    end
                endcase

                #1;
                expected_s_ready = !exp_valid || m_ready;
                if (s_ready !== expected_s_ready) begin
                    $display("ERROR[buffer] post-edge s_ready expected=%0b got=%0b", expected_s_ready, s_ready);
                    errors = errors + 1;
                end
                if (m_valid !== exp_valid) begin
                    $display("ERROR[buffer] post-edge m_valid expected=%0b got=%0b", exp_valid, m_valid);
                    errors = errors + 1;
                end
                if (exp_valid && (m_data !== exp_data)) begin
                    $display("ERROR[buffer] post-edge data expected=%0h got=%0h", exp_data, m_data);
                    errors = errors + 1;
                end
            end
        end
    end

    // 定向激励。下游停顿期间故意改变上游数据，以证明满缓冲的数据不会
    // 被未完成的输入请求覆盖；随后验证无气泡替换和连续每拍传输。
    initial begin : buffer_stimulus
        rst_n   = 1'b0;
        s_valid = 1'b0;
        s_data  = '0;
        m_ready = 1'b0;

        #1;
        if (m_valid !== 1'b0) begin
            $fatal(1, "FAIL[buffer] asynchronous reset m_valid=%0b", m_valid);
        end

        @(negedge clk);
        rst_n = 1'b1;

        // 首笔数据进入空缓冲；下游尚未准备好，缓冲应在下一拍变满。
        @(negedge clk);
        s_valid = 1'b1;
        s_data  = 8'h11;
        m_ready = 1'b0;

        // 两个反压周期中更改未握手输入，输出仍必须持续稳定为 11。
        @(negedge clk);
        s_data = 8'h22;
        @(negedge clk);
        s_data = 8'h23;

        // 下游恢复就绪且上游有效：旧 11 被消费，新 33 同拍替换进入缓冲。
        @(negedge clk);
        s_data  = 8'h33;
        m_ready = 1'b1;

        // 连续两拍替换，验证填充后每拍完成一笔输出与一笔输入。
        @(negedge clk);
        s_data = 8'h44;
        @(negedge clk);
        s_data = 8'h55;

        // 停止输入并保持下游就绪，消费最后一笔 55，缓冲应变空。
        @(negedge clk);
        s_valid = 1'b0;
        m_ready = 1'b1;

        // 空缓冲下同时给出输入和下游就绪：本拍不能直通，下一拍才有效。
        @(negedge clk);
        s_valid = 1'b1;
        s_data  = 8'h66;
        m_ready = 1'b1;

        // 消费该笔数据并留出空闲周期给 scoreboard 完成最终检查。
        @(negedge clk);
        s_valid = 1'b0;
        m_ready = 1'b1;
        @(negedge clk);
        m_ready = 1'b0;
        repeat (2) @(posedge clk);
        #2;

        if (errors == 0) begin
            $display("PASS[buffer] all checks passed");
        end else begin
            $fatal(1, "FAIL[buffer] %0d check(s) failed", errors);
        end
        $finish;
    end
endmodule
