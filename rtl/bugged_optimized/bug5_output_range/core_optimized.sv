`ifndef CSA_SV
`include "CSA.sv"
`endif

`ifndef REGISTER_MODULE
`include "Register.sv"
`endif

module core_optimized (
    input  logic       clk,
    input  logic       rst,
    input  logic       shift_en,
    input  logic [7:0] window [2:0][2:0],

    output logic [7:0] G_sat
);

    // Gx computation
    wire [10:0] p02    = {3'b000, window[2][0]};
    wire [10:0] p12_2x = {2'b00,  window[2][1], 1'b0};
    wire [10:0] p22    = {3'b000, window[2][2]};

    logic [10:0] s_c2, c_c2;
    CSA #(.WIDTH(11)) u_csa_c2 (
        .a     (p02),
        .b     (p12_2x),
        .c     (p22),
        .cin   (1'b0),
        .sum   (s_c2),
        .carry (c_c2)
    );

    wire [10:0] c2 = s_c2 + c_c2;

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

    wire [10:0] Gx = c2 + (~reg_c0) + 1'b1;

    // Gy computation
    wire [10:0] p20    = {3'b000, window[0][2]};
    wire [10:0] p21_x2 = {2'b00,  window[1][2], 1'b0};
    
    wire [10:0] p00_not    = ~{3'b000, window[0][0]};
    wire [10:0] p01_x2_not = ~{2'b00,  window[1][0], 1'b0};
    wire [10:0] p02_not    = ~{3'b000, window[2][0]};

    logic [10:0] s_pos, c_pos;
    CSA #(.WIDTH(11)) u_csa_pos (
        .a     (p20),
        .b     (p21_x2),
        .c     (p22),
        .cin   (1'b1),
        .sum   (s_pos),
        .carry (c_pos)
    );

    logic [10:0] s_neg, c_neg;
    CSA #(.WIDTH(11)) u_csa_neg (
        .a     (p00_not),
        .b     (p01_x2_not),
        .c     (p02_not),
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
        .cin   (1'b0),
        .sum   (s_csa4),
        .carry (c_csa4)
    );

    wire [10:0] Gy = s_csa4 + c_csa4;

    wire gy_sign, gx_sign;

    assign gx_sign = Gx[10];
    assign gy_sign = Gy[10];

    wire [10:0] xor_Gx = Gx ^ {11{gx_sign}};
    wire [10:0] xor_Gy = Gy ^ {11{gy_sign}};

    wire cin = gx_sign | gy_sign;

    wire [10:0] G = xor_Gx + xor_Gy + cin;

    // =========================================================================
    // INJECTED BUG 5: Output Range / Missing Saturation!
    // Expected: assign G_sat = |(G[10:8]) ? 8'd255 : G[7:0];
    // Injected: missing saturation clamp, wraps around on values > 255
    // =========================================================================
    assign G_sat = G[7:0];

endmodule
