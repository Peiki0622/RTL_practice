module parameterized_counter 
#(
    parameter int unsigned WIDTH = 8,
    parameter logic [WIDTH-1:0] MAX_COUNT = {WIDTH{1'b1}} 
)
(
    input logic                 clk         ,
    input logic                 rst_n       ,

    input logic                 enable      ,
    output logic [WIDTH-1:0]    count       ,
    output logic                wrap
);



always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count <= 'd0;
        wrap <= 'd0;
    end else if (enable) begin
        if(count == MAX_COUNT) begin
            count <= 'd0;
            wrap <= 'd1;
        end else begin
            count <= count + 1'b1;
            wrap <= 'd0;
        end
    end else begin
        count <= count;
        wrap <= 'd0;
    end
end



endmodule