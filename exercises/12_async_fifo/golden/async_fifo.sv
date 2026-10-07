// -----------------------------------------------------------------------------
// 双时钟域异步 FIFO。
//
// 写、读位置在各自时钟域以二进制指针维护；仅将对应 Gray 指针跨域并经过
// 两级同步。满空标志完全由本地 next-pointer 与同步后的远端 Gray 指针比较
// 得到，因此同步延迟只会造成保守反压，不会错误允许溢出或下溢。
// -----------------------------------------------------------------------------
module async_fifo #(
    // 每笔 FIFO 数据的位宽。
    parameter int unsigned DATA_WIDTH = 32,
    // FIFO 深度；规格保证其为至少四的二次幂。
    parameter int unsigned DEPTH      = 16
) (
    // 写时钟域时钟；写数据、写指针和满标志在该域更新。
    input  logic                  wr_clk,
    // 写时钟域低有效异步复位。
    input  logic                  wr_rst_n,
    // 写端 valid；与 wr_ready 同时为高时接收一笔数据。
    input  logic                  wr_valid,
    // 写端 ready；FIFO 在写域看来未满时为高。
    output logic                  wr_ready,
    // 写端数据，仅在写握手成功时写入阵列。
    input  logic [DATA_WIDTH-1:0] wr_data,

    // 读时钟域时钟；读指针和空标志在该域更新。
    input  logic                  rd_clk,
    // 读时钟域低有效异步复位。
    input  logic                  rd_rst_n,
    // 读端 valid；FIFO 在读域看来非空时为高。
    output logic                  rd_valid,
    // 读端 ready；与 rd_valid 同时为高时弹出当前队头。
    input  logic                  rd_ready,
    // 前视读数据；非空时表示当前读指针指向的队头。
    output logic [DATA_WIDTH-1:0] rd_data
);

    // 地址部分编码阵列索引；额外的一位二进制/Gray 指针位用于区分回绕后
    // 的满、空状态。DEPTH 至少为四，保证满判断中“翻转最高两位”合法。
    localparam int unsigned ADDR_WIDTH = $clog2(DEPTH);
    localparam int unsigned PTR_WIDTH  = ADDR_WIDTH + 1;

    // 行为级双端口存储体：仅写域更新阵列，读域以当前读指针前视读取。
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // 写域本地二进制/Gray 指针、满标志及其组合下一状态。
    logic [PTR_WIDTH-1:0] wr_bin_q;
    logic [PTR_WIDTH-1:0] wr_gray_q;
    logic [PTR_WIDTH-1:0] wr_bin_next;
    logic [PTR_WIDTH-1:0] wr_gray_next;
    logic                 wr_full_q;
    logic                 wr_full_next;
    logic                 wr_fire;

    // 读域本地二进制/Gray 指针、空标志及其组合下一状态。
    logic [PTR_WIDTH-1:0] rd_bin_q;
    logic [PTR_WIDTH-1:0] rd_gray_q;
    logic [PTR_WIDTH-1:0] rd_bin_next;
    logic [PTR_WIDTH-1:0] rd_gray_next;
    logic                 rd_empty_q;
    logic                 rd_empty_next;
    logic                 rd_fire;

    // 远端 Gray 指针在本地域中的两级同步副本。只有第二级参与满空判断。
    logic [PTR_WIDTH-1:0] rd_gray_sync1_q;
    logic [PTR_WIDTH-1:0] rd_gray_sync2_q;
    logic [PTR_WIDTH-1:0] wr_gray_sync1_q;
    logic [PTR_WIDTH-1:0] wr_gray_sync2_q;

    // 接口握手使用当前本地域的满空状态。同步延迟可能让 ready/valid 晚一些
    // 改变，但不会以未经同步的远端二进制指针作出决定。
    assign wr_ready = !wr_full_q;
    assign rd_valid = !rd_empty_q;
    assign wr_fire  = wr_valid && wr_ready;
    assign rd_fire  = rd_valid && rd_ready;

    // 写域下一状态：成功写入时才前进二进制指针，再直接以 Gray 编码表达式
    // 生成跨域值。满状态检测比较 next Gray 指针与同步读指针，其中远端指针
    // 的最高两位取反是环形 FIFO 的标准满条件。
    always_comb begin
        wr_bin_next = wr_bin_q;
        if (wr_fire) begin
            wr_bin_next = wr_bin_q + 1'b1;
        end

        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
        wr_full_next = (wr_gray_next ==
                        {~rd_gray_sync2_q[PTR_WIDTH-1:PTR_WIDTH-2],
                          rd_gray_sync2_q[PTR_WIDTH-3:0]});
    end

    // 读域下一状态：成功读取时才前进。next Gray 指针追上同步写 Gray 指针
    // 时，下一拍读域将报告为空。
    always_comb begin
        rd_bin_next = rd_bin_q;
        if (rd_fire) begin
            rd_bin_next = rd_bin_q + 1'b1;
        end

        rd_gray_next  = (rd_bin_next >> 1) ^ rd_bin_next;
        rd_empty_next = (rd_gray_next == wr_gray_sync2_q);
    end

    // 写域控制状态。复位只清空指针与满标志，不复位大容量存储阵列。
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin_q   <= '0;
            wr_gray_q  <= '0;
            wr_full_q  <= 1'b0;
        end else begin
            wr_bin_q   <= wr_bin_next;
            wr_gray_q  <= wr_gray_next;
            wr_full_q  <= wr_full_next;
        end
    end

    // 写阵列是独立的单一写驱动源，只在真实握手发生时保存输入数据。
    always_ff @(posedge wr_clk) begin
        if (wr_fire) begin
            mem[wr_bin_q[ADDR_WIDTH-1:0]] <= wr_data;
        end
    end

    // 读域控制状态与写域完全独立，避免把读写二进制指针直接跨域使用。
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin_q    <= '0;
            rd_gray_q   <= '0;
            rd_empty_q  <= 1'b1;
        end else begin
            rd_bin_q    <= rd_bin_next;
            rd_gray_q   <= rd_gray_next;
            rd_empty_q  <= rd_empty_next;
        end
    end

    // 读端前视数据路径。读指针在 rd_valid && !rd_ready 时保持不变；同时 FIFO
    // 不会覆盖未读队头，因此该条件下 rd_data 也保持稳定。
    always_comb begin
        if (rd_empty_q) begin
            rd_data = '0;
        end else begin
            rd_data = mem[rd_bin_q[ADDR_WIDTH-1:0]];
        end
    end

    // 将读域 Gray 写指针同步到写域。第一级只用于同步，不参与满判断。
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1_q <= '0;
            rd_gray_sync2_q <= '0;
        end else begin
            rd_gray_sync1_q <= rd_gray_q;
            rd_gray_sync2_q <= rd_gray_sync1_q;
        end
    end

    // 将写域 Gray 读指针同步到读域。第一级只用于同步，不参与空判断。
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1_q <= '0;
            wr_gray_sync2_q <= '0;
        end else begin
            wr_gray_sync1_q <= wr_gray_q;
            wr_gray_sync2_q <= wr_gray_sync1_q;
        end
    end

endmodule
