module alu_asserts (
    input logic       clk,
    input logic       en,
    input logic [1:0] op,
    input logic [7:0] b,
    input logic [8:0] temp_add // Direct access to ALU's internal wire!
);
    always @(posedge clk) begin
        if (en) begin
            // Rule 1: Check for a valid operation code
            ValidOpCode: assert (op != 2'b11)
                else $error("Invalid operation code (2'b11) sent to ALU!");

            // Rule 2: Prevent division by zero
            if (op == 2'b10) begin
                DivByZero: assert (b != 8'd0)
                        else $error("Division by zero error in ALU!");
            
            end

            // Rule 3: Warn on addition overflow
            if (op == 2'b00) begin
                AddOverflow: assert (temp_add[8] == 1'b0)
                    else $warning("Warning! Addition operation has overflowed.");
            end
        end
    end
endmodule
