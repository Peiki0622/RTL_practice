module valid_ready_buffer #(
    // 单笔传输数据的位宽。
    parameter int unsigned DATA_WIDTH = 32
) (
    // 时钟：占用标志和保存的数据均在上升沿更新。
    input  logic                  clk,
    // 低有效异步复位：将缓冲置为空。
    input  logic                  rst_n,
    // 上游有效标志；与 s_ready 同时为高时输入传输完成。
    input  logic                  s_valid,
    // 上游就绪标志；空缓冲或本拍可消费旧数据时为高。
    output logic                  s_ready,
    // 上游提供的数据，仅在输入传输完成时被保存。
    input  logic [DATA_WIDTH-1:0] s_data,
    // 下游有效标志；缓冲中保存有效数据时为高。
    output logic                  m_valid,
    // 下游就绪标志；与 m_valid 同时为高时输出传输完成。
    input  logic                  m_ready,
    // 下游数据，始终由缓冲的数据寄存器驱动。
    output logic [DATA_WIDTH-1:0] m_data
);

logic push_fire;
logic pop_fire;
logic occupied_q;
logic [DATA_WIDTH-1:0] data_q;


always_comb begin
    s_ready = !occupied_q || m_ready;
    m_valid = occupied_q;
    push_fire = s_ready & s_valid;
    pop_fire = m_ready & m_valid;
    m_data = data_q;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        occupied_q <= 'd0;
        data_q <= 'd0;
    end else begin
        case({push_fire, pop_fire})
            2'b01: begin
                data_q <= 'd0;
                occupied_q <= 'd0;
            end
            2'b10: begin
                data_q <= s_data;
                occupied_q <= 'd1;
            end
            2'b11: begin
                data_q <= s_data;
                occupied_q <= 'd1;
            end
            default: begin
                data_q <= data_q;
                occupied_q <= occupied_q;
            end
        endcase
    end
end




endmodule