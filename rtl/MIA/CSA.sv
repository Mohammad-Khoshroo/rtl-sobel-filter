module CSA #( parameter WIDTH = 12 ) (
    input  [WIDTH-1:0] a, b, c,
    
    // Injected directly into carry[0]
    input logic cin = 1'b0,   
    
    output logic [WIDTH-1:0] sum,
    output logic [WIDTH-1:0] carry
);

    logic [WIDTH-1:0] cout;

    assign sum  = a ^ b ^ c;
    assign cout = (a & b) | (b & c) | (a & c);

    assign carry = {cout[WIDTH-2:0], cin};

endmodule
