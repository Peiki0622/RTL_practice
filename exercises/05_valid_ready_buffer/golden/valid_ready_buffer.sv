// -----------------------------------------------------------------------------
// 容量为一笔数据的 valid-ready 弹性缓冲。
//
// 缓冲为空时可接收输入；缓冲已满但下游本拍接收时，也可接收新输入以实现
// 无气泡替换。该结构不提供空缓冲直通路径，所有输出数据均来自寄存器。
// -----------------------------------------------------------------------------
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

    // occupied_q 是缓冲中是否保存有效数据的唯一状态标志。
    logic occupied_q;
    // data_q 仅在成功接收上游数据时更新。
    logic [DATA_WIDTH-1:0] data_q;
    // 组合握手结果，供时序状态更新统一使用。
    logic push_fire;
    logic pop_fire;

    // 组合接口逻辑。满且 m_ready 为零时反压上游；满且 m_ready 为一时，
    // 旧数据会在本拍被消费，因此允许上游在同拍装入替代数据。
    always_comb begin
        m_valid  = occupied_q;
        m_data   = data_q;
        s_ready  = !occupied_q || m_ready;
        push_fire = s_valid && s_ready;
        pop_fire  = m_valid && m_ready;
    end

    // 时序状态逻辑。两次握手同时发生时优先保存新输入并保持占用，
    // 从而使下一拍立即提供新数据，不引入额外气泡。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            occupied_q <= 1'b0;
            data_q     <= '0;
        end else begin
            case ({push_fire, pop_fire})
                2'b10: begin
                    occupied_q <= 1'b1;
                    data_q     <= s_data;
                end
                2'b01: begin
                    occupied_q <= 1'b0;
                end
                2'b11: begin
                    occupied_q <= 1'b1;
                    data_q     <= s_data;
                end
                default: begin
                    occupied_q <= occupied_q;
                    data_q     <= data_q;
                end
            endcase
        end
    end

endmodule
