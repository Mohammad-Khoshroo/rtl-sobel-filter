`ifndef CSA_SV
`include "../MIA/CSA.sv"
`endif

`ifndef REGISTER_MODULE
`include "../Register/Register.sv"
`endif

module Core #(
    parameter PIXEL_WIDTH = 8,
    parameter WIDTH       = PIXEL_WIDTH + 3
)(
    input clk, rst,
    input [PIXEL_WIDTH-1:0] window [2:0][2:0],

    input xy_ctrl,
    input gx_en,
    input gy_en,
    input xm_ctrl,
    input ym_ctrl,

    output logic [PIXEL_WIDTH-1:0] G,
    output logic signed [WIDTH-1:0] Gx_out,
    output logic signed [WIDTH-1:0] Gy_out
);

    wire [WIDTH-1:0] ordered_window [5:0];

    assign ordered_window[0] = ~{{(WIDTH-PIXEL_WIDTH){1'b0}}, window[0][0]};
    assign ordered_window[1] = xy_ctrl ? ~{{(WIDTH-(PIXEL_WIDTH+1)){1'b0}}, window[1][0], 1'b0}
                                       : ~{{(WIDTH-(PIXEL_WIDTH+1)){1'b0}}, window[0][1], 1'b0};
    assign ordered_window[2] = xy_ctrl ? ~{{(WIDTH-PIXEL_WIDTH){1'b0}}, window[2][0]}
                                       : ~{{(WIDTH-PIXEL_WIDTH){1'b0}}, window[0][2]};
    assign ordered_window[3] = xy_ctrl ? {{(WIDTH-PIXEL_WIDTH){1'b0}}, window[0][2]}
                                       : {{(WIDTH-PIXEL_WIDTH){1'b0}}, window[2][0]};
    assign ordered_window[4] = xy_ctrl ? {{(WIDTH-(PIXEL_WIDTH+1)){1'b0}}, window[1][2], 1'b0}
                                       : {{(WIDTH-(PIXEL_WIDTH+1)){1'b0}}, window[2][1], 1'b0};
    assign ordered_window[5] = {{(WIDTH-PIXEL_WIDTH){1'b0}}, window[2][2]};

    logic [WIDTH-1:0] s_pos, c_pos;
    CSA #(.WIDTH(WIDTH)) u_csa_pos (
        .a     (ordered_window[3]),
        .b     (ordered_window[4]),
        .c     (ordered_window[5]),
        .cin   (1'b0),
        .sum   (s_pos),
        .carry (c_pos)
    );

    logic [WIDTH-1:0] s_neg, c_neg;
    CSA #(.WIDTH(WIDTH)) u_csa_neg (
        .a     (ordered_window[0]),
        .b     (ordered_window[1]),
        .c     (ordered_window[2]),
        .cin   (1'b1),
        .sum   (s_neg),
        .carry (c_neg)
    );

    logic [WIDTH-1:0] s_mid, c_mid;
    CSA #(.WIDTH(WIDTH)) u_csa_mid (
        .a     (c_pos),
        .b     (s_neg),
        .c     (c_neg),
        .cin   (1'b1),
        .sum   (s_mid),
        .carry (c_mid)
    );

    logic [WIDTH-1:0] s_csa4, c_csa4;
    CSA #(.WIDTH(WIDTH)) u_csa_bot (
        .a     (s_pos),
        .b     (s_mid),
        .c     (c_mid),
        .cin   (1'b1),
        .sum   (s_csa4),
        .carry (c_csa4)
    );

    logic [WIDTH-1:0] adder_out;
    logic [WIDTH-1:0] reg_Gx, reg_Gy;

    Register #(
        .WIDTH (WIDTH),
        .INIT  ({WIDTH{1'b0}})
    ) u_reg_gx (
        .clk       (clk),
        .reset     (rst),
        .enable    (gx_en),
        .pl_enable (1'b0),
        .d         (adder_out),
        .pl        ({WIDTH{1'b0}}),
        .q         (reg_Gx)
    );

    Register #(
        .WIDTH (WIDTH),
        .INIT  ({WIDTH{1'b0}})
    ) u_reg_gy (
        .clk       (clk),
        .reset     (rst),
        .enable    (gy_en),
        .pl_enable (1'b0),
        .d         (adder_out),
        .pl        ({WIDTH{1'b0}}),
        .q         (reg_Gy)
    );

    assign Gx_out = reg_Gx;
    assign Gy_out = reg_Gy;

    wire [WIDTH-1:0] inv_Gx = ~reg_Gx;
    wire [WIDTH-1:0] inv_Gy = ~reg_Gy;

    logic [WIDTH-1:0] xm_out, ym_out;
    assign xm_out = xm_ctrl ? inv_Gx : s_csa4;
    assign ym_out = ym_ctrl ? inv_Gy : c_csa4;

    wire cin_sel   = reg_Gx[WIDTH-1] | reg_Gy[WIDTH-1];
    wire adder_cin = (xm_ctrl || ym_ctrl) ? cin_sel : 1'b0;

    assign adder_out = xm_out + ym_out + {{(WIDTH-1){1'b0}}, adder_cin};
    assign G         = (adder_out > {{(WIDTH-8){1'b0}}, 8'hFF}) ? 8'hFF : adder_out[7:0];

endmodule
