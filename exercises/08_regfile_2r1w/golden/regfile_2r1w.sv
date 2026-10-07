// -----------------------------------------------------------------------------
// 双读单写寄存器文件。
//
// 存储阵列只有一个同步写端口；两个读端口均为独立组合读，因此可以在同一
// 周期读取相同或不同地址。题目不要求初始化或复位阵列内容。
// -----------------------------------------------------------------------------
module regfile_2r1w #(
    // 每个寄存器字的位宽。
    parameter int unsigned DATA_WIDTH = 32,
    // 寄存器字数；规格保证为不小于二的二次幂深度。
    parameter int unsigned DEPTH      = 32
) (
    // 时钟：写使能有效时，于上升沿提交写入。
    input  logic                         clk,
    // 写端口使能；为零时存储内容保持不变。
    input  logic                         we,
    // 写端口地址。
    input  logic [$clog2(DEPTH)-1:0]     waddr,
    // 写端口数据。
    input  logic [DATA_WIDTH-1:0]        wdata,
    // 第一个独立组合读端口的地址。
    input  logic [$clog2(DEPTH)-1:0]     raddr0,
    // 第一个组合读端口的数据输出。
    output logic [DATA_WIDTH-1:0]        rdata0,
    // 第二个独立组合读端口的地址。
    input  logic [$clog2(DEPTH)-1:0]     raddr1,
    // 第二个组合读端口的数据输出。
    output logic [DATA_WIDTH-1:0]        rdata1
);

    // 行为级寄存器阵列。阵列不复位，符合题目对存储内容的约束。
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // 唯一的同步写驱动。使用非阻塞赋值建模时钟沿后的新存储内容。
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    // 两个读端口互不共享控制状态，也不引入规格之外的同周期旁路。写沿前读到
    // 的仍是原存储内容，写沿之后组合读自然看到已更新的阵列项。
    always_comb begin
        rdata0 = mem[raddr0];
        rdata1 = mem[raddr1];
    end

endmodule
