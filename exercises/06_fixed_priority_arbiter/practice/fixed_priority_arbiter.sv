module fixed_priority_arbiter #(
    // 请求和授权向量的路数；规格保证其不小于一。
    parameter int unsigned N = 4
) 
(
    input   logic  [N-1:0]      req,
    output  logic  [N-1:0]      gnt
);

logic found_q;


always_comb begin
    gnt = 'd0;
    found_q = 'd0;
    for(int unsigned idx = 0; idx < N; idx = idx + 1) begin
        if(req[idx] && !found_q) begin
            gnt[idx] = 1'b1;
            found_q = 1'b1;
        end
    end
end

endmodule