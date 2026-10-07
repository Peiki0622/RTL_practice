module sequence_detector
(
    input   logic       clk     ,
    input   logic       rst_n   ,
    input   logic       bit_in  ,
    output  logic       match
);


typedef enum logic [1:0] { 
    IDLE = 2'd0,
    HAVE_1 = 2'd1,
    HAVE_10 = 2'd2,
    HAVE_101 = 2'd3
} state_t;

state_t fsm_d;
state_t fsm_q;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fsm_q <= IDLE;
        match <= 1'b0;
    end else begin
        fsm_q <= fsm_d;
        match <= (fsm_q == HAVE_101) & bit_in;
    end
end

always_comb begin
    fsm_d = fsm_q;
    case(fsm_q)
        IDLE: begin
            if(bit_in) begin
                fsm_d = HAVE_1;
            end else begin
                fsm_d = IDLE;
            end
        end
        HAVE_1: begin
            if(bit_in) begin
                fsm_d = HAVE_1;
            end else begin
                fsm_d = HAVE_10;
            end
        end
        HAVE_10: begin
            if(bit_in) begin
                fsm_d = HAVE_101;
            end else begin
                fsm_d = IDLE;
            end
        end
        HAVE_101: begin
            if(bit_in) begin
                fsm_d = HAVE_1;
            end else begin
                fsm_d = IDLE;
            end
        end
        default: begin
            fsm_d = IDLE;
        end
    endcase
end



endmodule