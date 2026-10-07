module round_robin_arbiter #(
    parameter int unsigned N = 4
) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] req,
    input  logic         grant_accept,
    output logic [N-1:0] gnt
);

localparam int unsigned PTR_WIDTH = $clog2(N);

logic [PTR_WIDTH-1:0] start_index_q;
logic [PTR_WIDTH-1:0] grant_index_q;
logic                 found_q;
int unsigned candidate_index;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_index_q <= 'd0;
    end else if(grant_accept && found_q) begin
        if(grant_index_q == N-1) begin
            start_index_q <= 'd0;
        end else begin
            start_index_q <= grant_index_q + 1'b1;
        end
    end
end

always_comb begin
    grant_index_q = 'd0;
    found_q = 'd0;
    gnt = 'd0;
    candidate_index = 'd0;

    for(int unsigned idx = 0; idx < N; idx = idx + 1) begin
        candidate_index = start_index_q + idx;
        if(candidate_index >= N) begin
            candidate_index = candidate_index - N;
        end
        if(req[candidate_index] & !found_q) begin
            found_q = 1'b1;
            gnt[candidate_index] = 1'b1;
            grant_index_q = candidate_index[PTR_WIDTH-1:0];
        end
    end
end

endmodule