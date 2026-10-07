// -----------------------------------------------------------------------------
// 单时钟域、前视读的同步 FIFO。
//
// 使用读写指针及各自的环回位区分满、空。指针达到 DEPTH-1 时显式
// 回到零并翻转环回位，因此 DEPTH 不需要是二的整数次幂。
// -----------------------------------------------------------------------------
module sync_fifo #(
    // 每一笔 FIFO 数据的位宽。
    parameter int unsigned DATA_WIDTH = 32,
    // FIFO 可容纳的最大条目数，规格保证其不小于二。
    parameter int unsigned DEPTH      = 16
) (
    // 时钟：存储写入和指针均在上升沿更新。
    input  logic                  clk,
    // 低有效异步复位：清空控制状态；存储阵列内容无需复位。
    input  logic                  rst_n,
    // 写请求；仅在 wr_en 且 full 为零时接收。
    input  logic                  wr_en,
    // 待写入的数据。
    input  logic [DATA_WIDTH-1:0] wr_data,
    // 已占用 DEPTH 个位置时为高，表示本拍开始时不能接受写入。
    output logic                  full,
    // 读请求；仅在 rd_en 且 empty 为零时接收。
    input  logic                  rd_en,
    // 前视读数据：非空时始终表示当前读指针指向的队头。
    output logic [DATA_WIDTH-1:0] rd_data,
    // 没有有效条目时为高，表示本拍开始时不能接受读取。
    output logic                  empty
);

    // 地址指针只需编码 0 到 DEPTH-1；环回位在地址回零时翻转。
    localparam int unsigned PTR_WIDTH = $clog2(DEPTH);
    localparam logic [PTR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

    // 存储阵列仅由写成功时的时序写端口驱动。
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    // 读、写指针分别定位当前队头和下一个可写位置。
    logic [PTR_WIDTH-1:0] rd_ptr_q;
    logic [PTR_WIDTH-1:0] wr_ptr_q;
    // 地址相同且环回位相同为空；地址相同且环回位不同时为满。
    logic rd_wrap_q;
    logic wr_wrap_q;
    // 当前周期真正被 FIFO 接收的读写操作。
    logic write_fire;
    logic read_fire;

    // 组合输出与握手判定。write_fire/read_fire 使用周期开始时的占用状态，
    // 因而满时同拍读写仍拒绝写、空时同拍读写仍拒绝读，符合冻结语义。
    always_comb begin
        full       = (wr_ptr_q == rd_ptr_q) && (wr_wrap_q != rd_wrap_q);
        empty      = (wr_ptr_q == rd_ptr_q) && (wr_wrap_q == rd_wrap_q);
        write_fire = wr_en && !full;
        read_fire  = rd_en && !empty;

        if (empty) begin
            // 空 FIFO 的读数据不具有事务含义，输出零值以保持波形确定。
            rd_data = '0;
        end else begin
            rd_data = mem[rd_ptr_q];
        end
    end

    // 时序控制与存储写入。复位只改变控制状态，不对大容量存储阵列实施
    // 无必要的复位写入。两个指针只在各自操作成功时前进。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_q <= '0;
            wr_ptr_q <= '0;
            rd_wrap_q <= 1'b0;
            wr_wrap_q <= 1'b0;
        end else begin
            if (write_fire) begin
                mem[wr_ptr_q] <= wr_data;
                if (wr_ptr_q == LAST_ADDR) begin
                    wr_ptr_q <= '0;
                    wr_wrap_q <= ~wr_wrap_q;
                end else begin
                    wr_ptr_q <= wr_ptr_q + 1'b1;
                end
            end

            if (read_fire) begin
                if (rd_ptr_q == LAST_ADDR) begin
                    rd_ptr_q <= '0;
                    rd_wrap_q <= ~rd_wrap_q;
                end else begin
                    rd_ptr_q <= rd_ptr_q + 1'b1;
                end
            end
        end
    end

endmodule
