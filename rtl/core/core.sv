module Core (
    input clk, rst,
    input [7:0] window [2:0][2:0],
    input G_reg_en,
    input xy_ctrl, // ctrl0: X, ctrl1: Y
    output [7:0] 
);
    
    wire [7:0] ordered_window[5:0];
    wire [10:0] acc, abs_acc;
    
    assign ordered_window[0] = ~window[0][0];
    assign ordered_window[1] = xy_ctrl ? ~{window[1][0][7:1], 1'b0} : ~{window[0][1][7:1], 1'b0};
    assign ordered_window[2] = xy_ctrl ? ~window[2][0] : ~window[0][2];
    
    assign ordered_window[3] = xy_ctrl ? window[2][2] : window[0][2];
    assign ordered_window[4] = xy_ctrl ? {window[2][2][7:1], 1'b0} : {window[0][2][7:1], 1'b0};
    assign ordered_window[5] = window[2][2];
    
    MIA7 #( .WIDTH(11) ) adder_tree (
    .in0(ordered_window[0]),
    .in1(ordered_window[1]),
    .in2(ordered_window[2]),
    .in3(ordered_window[3]),
    .in4(ordered_window[4]),
    .in5(ordered_window[5]),
    .in6(G),
    .csa_cin(3'b111),   
    .adder_cin(1'b0), 
    .sum(acc)
    );

endmodule
