// =============================================================================
// core module_name (
//     .clk      (clk),
//     .rst      (rst),
//     .shift_en (shift_en),
//     .window   (window),
//     .G_sat_reg    (G_sat_reg)
// );
// =============================================================================

module core (
    input  logic       clk,
    input  logic       rst,
    input  logic       shift_en,
    input  logic [7:0] window [2:0][2:0],

    output logic [7:0] G_sat_reg
);

    // Gx computation
    // 
    // 
    /////////////////
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

    // stage 2 pipeline
    logic [10:0] reg_c2, reg_c1, reg_c0;
    Register #(
        .WIDTH (11)
    ) u_reg_c2 (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (c2),
        .q      (reg_c2)
    );
    Register #(
        .WIDTH (11)
    ) u_reg_c1 (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (reg_c2),
        .q      (reg_c1)
    );
    Register #(
        .WIDTH (11)
    ) u_reg_c0 (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (reg_c1),
        .q      (reg_c0)
    );

    // Gy computation
    // 
    // 
    /////////////////
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

    // stage 2 pipeline
    logic [10:0] reg_s_gy, reg_c_gy;
    Register #(
        .WIDTH (11)
    ) u_reg_s_gy (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (s_csa4),
        .q      (reg_s_gy)
    );
    Register #(
        .WIDTH (11)
    ) u_reg_c_gy (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (c_csa4),
        .q      (reg_c_gy)
    );

    wire [10:0] Gx = reg_c2 + (~reg_c0) + 1'b1;
    wire [10:0] Gy = reg_s_gy + reg_c_gy;

    // stage 3 pipeline
    logic [10:0] reg_Gx, reg_Gy;
    Register #(
        .WIDTH (11)
    ) u_reg_gx (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (Gx),
        .q      (reg_Gx)
    );
    Register #(
        .WIDTH (11)
    ) u_reg_gy (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (Gy),
        .q      (reg_Gy)
    );

    wire [10:0] xor_Gx = reg_Gx ^ {11{reg_Gx[10]}};
    wire [10:0] xor_Gy = reg_Gy ^ {11{reg_Gy[10]}};

    wire cin = reg_Gx[10] | reg_Gy[10];

    // i have a -1 at most error 
    wire [10:0] G = xor_Gx + xor_Gy + cin;

    wire [7:0] G_sat = |(G[10:8]) ? 8'd255 : G[7:0];

    // final stage / output register
    Register #(
        .WIDTH (8)
    ) u_reg_gsat (
        .clk    (clk),
        .reset  (rst),
        .enable (shift_en),
        .d      (G_sat),
        .q      (G_sat_reg)
    );

endmodule
