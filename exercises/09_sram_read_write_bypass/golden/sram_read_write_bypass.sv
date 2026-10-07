// -----------------------------------------------------------------------------
// 带同址读写旁路的单读单写存储器。
//
// 阵列仍采用同步写、组合读；额外的组合选择器确保写使能和读写地址相等时，
// 读端不依赖底层阵列在读写冲突时的实现行为。
// -----------------------------------------------------------------------------
module sram_read_write_bypass #(
    // 每个存储字的位宽。
    parameter int unsigned DATA_WIDTH = 32,
    // 存储字数；规格测试二的整数次幂深度。
    parameter int unsigned DEPTH      = 64
) (
    // 时钟：写使能有效时，于上升沿提交数组写入。
    input  logic                         clk,
    // 写端口使能。
    input  logic                         we,
    // 写端口地址。
    input  logic [$clog2(DEPTH)-1:0]     waddr,
    // 写端口数据。
    input  logic [DATA_WIDTH-1:0]        wdata,
    // 组合读端口地址。
    input  logic [$clog2(DEPTH)-1:0]     raddr,
    // 组合读端口数据；同址有效写期间直接反映 wdata。
    output logic [DATA_WIDTH-1:0]        rdata
);

    // 行为级单写端口存储阵列；题目不要求复位其中的内容。
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // 同步写路径只在写使能有效的时钟上升沿更新目标字。
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    // 旁路路径优先级高于阵列读。即使同址读写发生在写沿之前，rdata 也立即
    // 表示新写数据；不同址或未写时则保持普通组合读语义。
    always_comb begin
        if (we && (waddr == raddr)) begin
            rdata = wdata;
        end else begin
            rdata = mem[raddr];
        end
    end

endmodule
