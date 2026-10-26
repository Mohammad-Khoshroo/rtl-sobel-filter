// =============================================================================
// core module_name (
//     .clk     (clk),
//     .rst     (rst),
//     .window  (window),
//     .xy_ctrl (xy_ctrl),
//     .gx_en   (gx_en),
//     .gy_en   (gy_en),
//     .xm_ctrl (xm_ctrl),
//     .ym_ctrl (ym_ctrl),
//     .G       (G)
// );
// =============================================================================

module core (
    input clk, rst,
    input [7:0] window [2:0][2:0],

    input xy_ctrl,
    input gx_en,
    input gy_en,
    input xm_ctrl,
    input ym_ctrl,

    output logic [7:0] G
);

    wire [10:0] ordered_window [5:0];

    assign ordered_window[0] = ~{3'b000, window[0][0]};
    assign ordered_window[1] = xy_ctrl ? ~{2'b00, window[1][0], 1'b0} : ~{2'b00, window[0][1], 1'b0};
    assign ordered_window[2] = xy_ctrl ? ~{3'b000, window[2][0]}      : ~{3'b000, window[0][2]};
    assign ordered_window[3] = xy_ctrl ? {3'b000, window[0][2]}       : {3'b000, window[2][0]};
    assign ordered_window[4] = xy_ctrl ? {2'b00, window[1][2], 1'b0}  : {2'b00, window[2][1], 1'b0};
    assign ordered_window[5] = {3'b000, window[2][2]};

    logic [10:0] s_pos, c_pos;
    CSA #(.WIDTH(11)) u_csa_pos (
        .a     (ordered_window[3]),
        .b     (ordered_window[4]),
        .c     (ordered_window[5]),
        .cin   (1'b0),
        .sum   (s_pos),
        .carry (c_pos)
    );

    logic [10:0] s_neg, c_neg;
    CSA #(.WIDTH(11)) u_csa_neg (
        .a     (ordered_window[0]),
        .b     (ordered_window[1]),
        .c     (ordered_window[2]),
        .cin   (1'b1),
        .sum   (s_neg),
        .carry (c_neg)
    );

    logic [10:0] s_mid, c_mid;
    CSA #(.WIDTH(11)) u_csa_mid (
        .a     (c_pos),
        .b     (s_neg),
        .c     (c_neg),
        .cin   (1'b1),
        .sum   (s_mid),
        .carry (c_mid)
    );

    logic [10:0] s_csa4, c_csa4;
    CSA #(.WIDTH(11)) u_csa_bot (
        .a     (s_pos),
        .b     (s_mid),
        .c     (c_mid),
        .cin   (1'b1),
        .sum   (s_csa4),
        .carry (c_csa4)
    );

    logic [10:0] adder_out;
    logic [10:0] reg_Gx, reg_Gy;

    Register #(
        .WIDTH (11),
        .INIT  (11'b0)
    ) u_reg_gx (
        .clk       (clk),
        .reset     (rst),
        .enable    (gx_en),
        .pl_enable (1'b0),
        .d         (adder_out),
        .pl        (11'b0),
        .q         (reg_Gx)
    );

    Register #(
        .WIDTH (11),
        .INIT  (11'b0)
    ) u_reg_gy (
        .clk       (clk),
        .reset     (rst),
        .enable    (gy_en),
        .pl_enable (1'b0),
        .d         (adder_out),
        .pl        (11'b0),
        .q         (reg_Gy)
    );

    logic [10:0] xm_out, ym_out;
    assign xm_out = xm_ctrl ? ~reg_Gx : s_csa4;
    assign ym_out = ym_ctrl ? ~reg_Gy : c_csa4;

    wire adder_cin = reg_Gx[10] | reg_Gy[10];

    assign adder_out = xm_out + ym_out + {10'b0, adder_cin};
    assign G = (adder_out > 11'd255) ? 8'd255 : adder_out[7:0];

endmodule
