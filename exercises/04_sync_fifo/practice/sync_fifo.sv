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

localparam int unsigned ADDR_WIDTH = $clog2(DEPTH);
localparam int unsigned PTR_WIDTH = ADDR_WIDTH + 1;

logic [PTR_WIDTH-1:0] wr_ptr_q;
logic [PTR_WIDTH-1:0] rd_ptr_q;

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

logic wr_fire;
logic rd_fire;

assign full = (wr_ptr_q == {~rd_ptr_q[PTR_WIDTH-1], rd_ptr_q[PTR_WIDTH-2:0]});
assign empty = (wr_ptr_q == rd_ptr_q);
assign wr_fire = !full & wr_en;
assign rd_fire = !empty & rd_en;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_ptr_q <= 'd0;
    end else if(wr_fire) begin
        if(wr_ptr_q[ADDR_WIDTH-1:0] == DEPTH-1) begin
            wr_ptr_q <= {~wr_ptr_q[PTR_WIDTH-1], {ADDR_WIDTH{1'b0}}};
        end else begin
            wr_ptr_q <= wr_ptr_q + 1'b1;
        end
    end
end

always_ff @(posedge clk) begin
    if(wr_fire) begin
        mem[wr_ptr_q[ADDR_WIDTH-1:0]] <= wr_data;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_ptr_q <= 'd0;
    end else if(rd_fire) begin
        if(rd_ptr_q[ADDR_WIDTH-1:0] == DEPTH-1) begin
            rd_ptr_q <= {~rd_ptr_q[PTR_WIDTH-1], {ADDR_WIDTH{1'b0}}};
        end else begin
            rd_ptr_q <= rd_ptr_q + 1'b1;
        end
    end
end

always_comb begin
    if(empty) begin
        rd_data = 'd0;
    end else begin
        rd_data = mem[rd_ptr_q[ADDR_WIDTH-1:0]];
    end
end

endmodule