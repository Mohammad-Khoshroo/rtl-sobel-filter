module top_system (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] data_a,
    input  logic [7:0] data_b,
    output logic [7:0] final_res,
    output logic       system_done
);
    // Internal connecting wires between the controller and ALU
    logic       w_alu_en;
    logic [1:0] w_alu_op;

    // Instantiate the controller (instance name: u_ctrl)
    controller u_ctrl (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .alu_enable (w_alu_en),
        .alu_op     (w_alu_op),
        .done       (system_done)
    );

    // Instantiate the ALU (instance name: u_alu)
    alu u_alu (
        .clk    (clk),
        .en     (w_alu_en),
        .op     (w_alu_op),
        .a      (data_a),
        .b      (data_b),
        .result (final_res)
    );
endmodule
