`include "CSA.sv"

module MIA3 #( parameter WIDTH = 12 ) (
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    input adder_cin,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .sum   (s1),
        .carry (c1)
    );
    assign sum = s1 + c1 + WIDTH'(adder_cin);

endmodule


module MIA5 #( parameter WIDTH = 12 ) (
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    input [WIDTH-1:0] in3,
    input [WIDTH-1:0] in4,
    input [1:0] csa_cin,
    input adder_cin,
    output logic [WIDTH-1:0] sum
);

    logic [WIDTH-1:0] s1, c1;
    logic [WIDTH-1:0] s2, c2;
    logic [WIDTH-1:0] s3, c3;

    CSA #(.WIDTH(WIDTH)) u_csa1 (
        .a     (in0),
        .b     (in1),
        .c     (in2),
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (s1),
        .b     (c1),
        .c     (in3),
        .cin   (csa_cin[0]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s2),
        .b     (c2),
        .c     (in4),
        .cin   (csa_cin[1]),
        .sum   (s3),
        .carry (c3)
    );

    // Final CPA
    assign sum = s3 + c3 + WIDTH'(adder_cin);

endmodule

module MIA7 #( parameter WIDTH = 12 ) (
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    input [WIDTH-1:0] in3,
    input [WIDTH-1:0] in4,
    input [WIDTH-1:0] in5,
    input [WIDTH-1:0] in6,
    input [3:0] csa_cin,   
    input adder_cin, 
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
        .sum   (s1),
        .carry (c1)
    );

    CSA #(.WIDTH(WIDTH)) u_csa2 (
        .a     (in3),
        .b     (in4),
        .c     (in5),
        .cin   (csa_cin[0]),
        .sum   (s2),
        .carry (c2)
    );

    CSA #(.WIDTH(WIDTH)) u_csa3 (
        .a     (s1),
        .b     (c1),
        .c     (s2),
        .cin   (csa_cin[1]),
        .sum   (s3),
        .carry (c3)
    );

    CSA #(.WIDTH(WIDTH)) u_csa4 (
        .a     (s3),
        .b     (c3),
        .c     (c2),
        .cin   (csa_cin[2]),
        .sum   (s4),
        .carry (c4)
    );

    CSA #(.WIDTH(WIDTH)) u_csa5 (
        .a     (s4),
        .b     (c4),
        .c     (in6),
        .cin   (csa_cin[3]),
        .sum   (s5),
        .carry (c5)
    );

    assign sum = s5 + c5 + WIDTH'(adder_cin);

endmodule