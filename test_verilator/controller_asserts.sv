module controller_asserts (
    input logic       clk,
    input logic       rst,
    input logic       alu_enable,
    input logic       done,
    input logic [1:0] current_state // Direct access to the controller's internal register!
);
    always @(posedge clk) begin
        if (!rst) begin
            // Check Rule 1 (IDLE = 2'b00)
            IdleNoEnable: assert (!(current_state == 2'b00 && alu_enable == 1'b1))
                else $error("Error! alu_enable is asserted while in IDLE state!");

            // Check Rule 2
            NoSimultaneousEnDone: assert (!(alu_enable && done))
                else $fatal("Critical error! alu_enable and done are both asserted simultaneously!");
        end
    end
endmodule
