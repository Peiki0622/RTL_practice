module async_fifo #(
    // 每笔 FIFO 数据的位宽。
    parameter int unsigned DATA_WIDTH = 32,
    // FIFO 深度；规格保证其为至少四的二次幂。
    parameter int unsigned DEPTH      = 16
) 
(
    input   logic                   wr_clk,
    input   logic                   wr_rst_n,
    input   logic                   wr_valid,
    output  logic                   wr_ready,
    input   logic [DATA_WIDTH-1:0]  wr_data,

    input   logic                   rd_clk,
    input   logic                   rd_rst_n,
    output   logic                  rd_valid,
    input  logic                    rd_ready,
    output  logic [DATA_WIDTH-1:0]  rd_data 
);

localparam int unsigned ADDR_WIDTH = $clog2(DEPTH);
localparam int unsigned PTR_WIDTH = ADDR_WIDTH + 1;

logic [PTR_WIDTH-1:0] wr_ptr_bin_q;
logic [PTR_WIDTH-1:0] wr_ptr_bin_d;
logic [PTR_WIDTH-1:0] wr_ptr_gray_q;
logic [PTR_WIDTH-1:0] wr_ptr_gray_d;
logic                 wr_full_d;
logic                 wr_full_q;
logic                 wr_fire;

logic [PTR_WIDTH-1:0] wr_gray_sync_q0;
logic [PTR_WIDTH-1:0] wr_gray_sync_q1;


logic [PTR_WIDTH-1:0] rd_ptr_bin_q;
logic [PTR_WIDTH-1:0] rd_ptr_bin_d;
logic [PTR_WIDTH-1:0] rd_ptr_gray_q;
logic [PTR_WIDTH-1:0] rd_ptr_gray_d;
logic                 rd_empty_d;
logic                 rd_empty_q;
logic                 rd_fire;

logic [PTR_WIDTH-1:0] rd_gray_sync_q0;
logic [PTR_WIDTH-1:0] rd_gray_sync_q1;

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

assign rd_valid = ~rd_empty_q;
assign wr_ready = ~wr_full_q;
assign wr_fire = wr_ready & wr_valid;
assign rd_fire = rd_ready & rd_valid;

always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        rd_gray_sync_q0 <= 'd0;
        rd_gray_sync_q1 <= 'd0;
    end else begin
        rd_gray_sync_q0 <= rd_ptr_gray_q;
        rd_gray_sync_q1 <= rd_gray_sync_q0;
    end
end

always_comb begin
    wr_ptr_bin_d = wr_ptr_bin_q;
    if(wr_fire) begin
        wr_ptr_bin_d = wr_ptr_bin_q + 1'b1;
    end
    wr_ptr_gray_d = (wr_ptr_bin_d >> 1) ^ wr_ptr_bin_d;
    wr_full_d = (wr_ptr_gray_d == {~rd_gray_sync_q1[PTR_WIDTH-1:PTR_WIDTH-2], 
                                    rd_gray_sync_q1[PTR_WIDTH-3:0]});
end

always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        wr_ptr_bin_q <= 'd0;
        wr_ptr_gray_q <= 'd0;
        wr_full_q <= 'd0;
    end else begin
        wr_ptr_bin_q <= wr_ptr_bin_d;
        wr_ptr_gray_q <= wr_ptr_gray_d;
        wr_full_q <= wr_full_d;
    end
end

always_ff @(posedge wr_clk) begin
    if(wr_fire) begin
        mem[wr_ptr_bin_q[ADDR_WIDTH-1:0]] <= wr_data;
    end
end

always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        wr_gray_sync_q0 <= 'd0;
        wr_gray_sync_q1 <= 'd0;
    end else begin
        wr_gray_sync_q0 <= wr_ptr_gray_q;
        wr_gray_sync_q1 <= wr_gray_sync_q0;
    end
end

always_comb begin
    rd_ptr_bin_d = rd_ptr_bin_q;
    if(rd_fire) begin
        rd_ptr_bin_d = rd_ptr_bin_q + 1'b1;
    end
    rd_ptr_gray_d = (rd_ptr_bin_d >> 1) ^ rd_ptr_bin_d;
    rd_empty_d = (rd_ptr_gray_d == wr_gray_sync_q1);
end

always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        rd_ptr_bin_q <= 'd0;
        rd_ptr_gray_q <= 'd0;
        rd_empty_q <= 'd1;
    end else begin
        rd_ptr_bin_q <= rd_ptr_bin_d;
        rd_ptr_gray_q <= rd_ptr_gray_d;
        rd_empty_q <= rd_empty_d;
    end
end

always_comb begin
    if(rd_empty_q) begin
        rd_data = 'd0;
    end else begin
        rd_data = mem[rd_ptr_bin_q[ADDR_WIDTH-1:0]];
    end
end

endmodule