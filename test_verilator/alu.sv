module alu (
    input  logic       clk,
    input  logic       en,
    input  logic [1:0] op,      // 00: ADD, 01: SUB, 10: DIV (11 is invalid!)
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] result
);
    // An internal wire to detect addition overflow
    
    logic [8:0] temp_add;

    assign temp_add = a + b;


    always_ff @(posedge clk) begin
        if (en) begin
            case (op)
                2'b00: result <= a + b;
                2'b01: result <= a - b;
                2'b10: result <= a / b;
                default: result <= 8'h00;
            endcase
        end
    end
endmodule

