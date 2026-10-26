`include "CSA.sv"

// =============================================================================
// MIA3 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .csa_cin   (csa_cin),
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA3 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [0:0]       csa_cin   = 1'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    assign sum = s1 + c1 + adder_cin;

endmodule


// =============================================================================
// MIA4 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .csa_cin   (csa_cin),    // [1:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA4 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [1:0]       csa_cin   = 2'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (s1),
        .b     (c1),
        .c     (in3),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    assign sum = s2 + c2 + adder_cin;

endmodule


// =============================================================================
// MIA5 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .in4       (in4),
//     .csa_cin   (csa_cin),    // [2:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA5 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [2:0]       csa_cin   = 3'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (s1),
        .b     (c1),
        .c     (in3),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s2),
        .b     (c2),
        .c     (in4),
        .cin   (csa_cin[2]),
        .sum   (s3),
        .carry (c3)
    );

    assign sum = s3 + c3 + adder_cin;

endmodule


// =============================================================================
// MIA6 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .in4       (in4),
//     .in5       (in5),
//     .csa_cin   (csa_cin),    // [3:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA6 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [WIDTH-1:0] in5,
    input  [3:0]       csa_cin   = 4'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;
    logic [WIDTH-1:0] s4, c4;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (in3),
        .b     (in4),
        .c     (in5),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s1),
        .b     (c1),
        .c     (s2),
        .cin   (csa_cin[2]),
        .sum   (s3),
        .carry (c3)
    );

    CSA #(.WIDTH(WIDTH)) u_csa4 (
        .a     (s3),
        .b     (c3),
        .c     (c2),
        .cin   (csa_cin[3]),
        .sum   (s4),
        .carry (c4)
    );

    assign sum = s4 + c4 + adder_cin;

endmodule


// =============================================================================
// MIA7 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .in4       (in4),
//     .in5       (in5),
//     .in6       (in6),
//     .csa_cin   (csa_cin),    // [4:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA7 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [WIDTH-1:0] in5,
    input  [WIDTH-1:0] in6,
    input  [4:0]       csa_cin   = 5'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;
    logic [WIDTH-1:0] s4, c4;
    logic [WIDTH-1:0] s5, c5;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (in3),
        .b     (in4),
        .c     (in5),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s1),
        .b     (c1),
        .c     (s2),
        .cin   (csa_cin[2]),
        .sum   (s3),
        .carry (c3)
    );

    CSA #(.WIDTH(WIDTH)) u_csa4 (
        .a     (s3),
        .b     (c3),
        .c     (c2),
        .cin   (csa_cin[3]),
        .sum   (s4),
        .carry (c4)
    );

    CSA #(.WIDTH(WIDTH)) u_csa5 (
        .a     (s4),
        .b     (c4),
        .c     (in6),
        .cin   (csa_cin[4]),
        .sum   (s5),
        .carry (c5)
    );

    assign sum = s5 + c5 + adder_cin;

endmodule


// =============================================================================
// MIA8 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .in4       (in4),
//     .in5       (in5),
//     .in6       (in6),
//     .in7       (in7),
//     .csa_cin   (csa_cin),    // [5:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA8 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [WIDTH-1:0] in5,
    input  [WIDTH-1:0] in6,
    input  [WIDTH-1:0] in7,
    input  [5:0]       csa_cin   = 6'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;
    logic [WIDTH-1:0] s4, c4;
    logic [WIDTH-1:0] s5, c5;
    logic [WIDTH-1:0] s6, c6;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (in3),
        .b     (in4),
        .c     (in5),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s1),
        .b     (c1),
        .c     (s2),
        .cin   (csa_cin[2]),
        .sum   (s3),
        .carry (c3)
    );

    CSA #(.WIDTH(WIDTH)) u_csa4 (
        .a     (c2),
        .b     (in6),
        .c     (in7),
        .cin   (csa_cin[3]),
        .sum   (s4),
        .carry (c4)
    );

    CSA #(.WIDTH(WIDTH)) u_csa5 (
        .a     (s3),
        .b     (c3),
        .c     (s4),
        .cin   (csa_cin[4]),
        .sum   (s5),
        .carry (c5)
    );

    CSA #(.WIDTH(WIDTH)) u_csa6 (
        .a     (s5),
        .b     (c5),
        .c     (c4),
        .cin   (csa_cin[5]),
        .sum   (s6),
        .carry (c6)
    );

    assign sum = s6 + c6 + adder_cin;

endmodule


// =============================================================================
// MIA9 #(
//     .WIDTH     (12)
// ) module_name (
//     .in0       (in0),
//     .in1       (in1),
//     .in2       (in2),
//     .in3       (in3),
//     .in4       (in4),
//     .in5       (in5),
//     .in6       (in6),
//     .in7       (in7),
//     .in8       (in8),
//     .csa_cin   (csa_cin),    // [6:0]
//     .adder_cin (adder_cin),  // Carry-in for final CPA adder
//     .sum       (sum)
// );
// =============================================================================

module MIA9 #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [WIDTH-1:0] in5,
    input  [WIDTH-1:0] in6,
    input  [WIDTH-1:0] in7,
    input  [WIDTH-1:0] in8,
    input  [6:0]       csa_cin   = 7'b0,
    input              adder_cin = 1'b0,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;
    logic [WIDTH-1:0] s4, c4;
    logic [WIDTH-1:0] s5, c5;
    logic [WIDTH-1:0] s6, c6;
    logic [WIDTH-1:0] s7, c7;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .cin   (csa_cin[0]),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (in3),
        .b     (in4),
        .c     (in5),
        .cin   (csa_cin[1]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (in6),
        .b     (in7),
        .c     (in8),
        .cin   (csa_cin[2]),
        .sum   (s3),
        .carry (c3)
    );

    CSA #(.WIDTH(WIDTH)) u_csa4 (
        .a     (s1),
        .b     (c1),
        .c     (s2),
        .cin   (csa_cin[3]),
        .sum   (s4),
        .carry (c4)
    );

    CSA #(.WIDTH(WIDTH)) u_csa5 (
        .a     (c2),
        .b     (s3),
        .c     (c3),
        .cin   (csa_cin[4]),
        .sum   (s5),
        .carry (c5)
    );

    CSA #(.WIDTH(WIDTH)) u_csa6 (
        .a     (s4),
        .b     (c4),
        .c     (s5),
        .cin   (csa_cin[5]),
        .sum   (s6),
        .carry (c6)
    );

    CSA #(.WIDTH(WIDTH)) u_csa7 (
        .a     (s6),
        .b     (c6),
        .c     (c5),
        .cin   (csa_cin[6]),
        .sum   (s7),
        .carry (c7)
    );

    assign sum = s7 + c7 + adder_cin;

endmodule
