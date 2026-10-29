`ifndef CSA_SV
`include "CSA.sv"
`endif

`ifndef REGISTER_MODULE
`include "Register.sv"
`endif

// =============================================================================
// Optimized Parallel Sobel Core Datapath
// Implements:
//   - Gx branch: Column sum (C2) calculation with shift registers (C1, C0)
//                Gx = C2 - C0
//   - Gy branch: 4-CSA Wallace reduction tree + CPA
//                Gy = Row2 - Row0
//   - Absolute Value & Merged Sum:
//                cin = Gx[10] | Gy[10]
//                G = (Gx ^ sign_x) + (Gy ^ sign_y) + cin
//   - Clamping to [0, 255]
// =============================================================================

module core (
    input  logic       clk,
    input  logic       rst,
    input  logic       shift_en,
    input  logic [7:0] window [2:0][2:0],

    output logic       gx_sign,
    output logic       gy_sign,
    output logic [7:0] G
);

    // =========================================================================
    // 1. Gx Branch: Column Sum (C2) and Shift Registers (C1, C0)
    // =========================================================================
    // Window indexing: window[x][y] where x is column (0:left, 1:mid, 2:right), y is row (0:top, 1:mid, 2:bot)
    // Rightmost column elements: P02, P12, P22
    wire [10:0] w_p02    = {3'b000, window[2][0]};
    wire [10:0] w_p12_x2 = {2'b00,  window[2][1], 1'b0};
    wire [10:0] w_p22    = {3'b000, window[2][2]};

    logic [10:0] s_c2, c_c2;
    CSA #(.WIDTH(11)) u_csa_c2 (
        .a     (w_p02),
        .b     (w_p12_x2),
        .c     (w_p22),
        .cin   (1'b0),
        .sum   (s_c2),
        .carry (c_c2)
    );

    wire [10:0] c2 = s_c2 + c_c2;

    // Shift registers for column reuse: C2 -> C1 -> C0
    logic [10:0] reg_c1, reg_c0;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_c1 <= 11'd0;
            reg_c0 <= 11'd0;
        end else if (shift_en) begin
            reg_c1 <= c2;
            reg_c0 <= reg_c1;
        end
    end

    // Gx = C2 - C0 = C2 + (~C0) + 1
    wire [10:0] Gx = c2 + (~reg_c0) + 11'd1;

    // =========================================================================
    // 2. Gy Branch: 4-CSA Reduction Tree + CPA
    // =========================================================================
    // Gy = (P20 + 2*P21 + P22) - (P00 + 2*P01 + P02)
    // Positive terms (Row 2): window[0][2], window[1][2], window[2][2]
    wire [10:0] w_p20    = {3'b000, window[0][2]};
    wire [10:0] w_p21_x2 = {2'b00,  window[1][2], 1'b0};
    wire [10:0] w_p22_y  = {3'b000, window[2][2]};

    // Inverted negative terms (Row 0): window[0][0], window[1][0], window[2][0]
    wire [10:0] w_inv_p00    = ~{3'b000, window[0][0]};
    wire [10:0] w_inv_p01_x2 = ~{2'b00,  window[1][0], 1'b0};
    wire [10:0] w_inv_p02    = ~{3'b000, window[2][0]};

    logic [10:0] s_pos, c_pos;
    CSA #(.WIDTH(11)) u_csa_pos (
        .a     (w_p20),
        .b     (w_p21_x2),
        .c     (w_p22_y),
        .cin   (1'b0),
        .sum   (s_pos),
        .carry (c_pos)
    );

    logic [10:0] s_neg, c_neg;
    CSA #(.WIDTH(11)) u_csa_neg (
        .a     (w_inv_p00),
        .b     (w_inv_p01_x2),
        .c     (w_inv_p02),
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

    wire [10:0] Gy = s_csa4 + c_csa4;

    // =========================================================================
    // 3. Absolute Value & Final Summation
    // =========================================================================
    assign gx_sign = Gx[10];
    assign gy_sign = Gy[10];

    wire [10:0] xor_Gx = Gx ^ {11{gx_sign}};
    wire [10:0] xor_Gy = Gy ^ {11{gy_sign}};

    // cin is OR of sign bits
    wire cin_final = gx_sign | gy_sign;

    wire [10:0] G_raw = xor_Gx + xor_Gy + {10'd0, cin_final};

    // Saturation clamping to [0, 255]
    assign G = (G_raw > 11'd255) ? 8'd255 : G_raw[7:0];

endmodule
