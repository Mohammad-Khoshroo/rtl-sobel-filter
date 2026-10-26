`ifndef REGISTER_MODULE
`define REGISTER_MODULE

module Register #(
    parameter WIDTH = 32,
    parameter INIT  = {WIDTH{1'b0}}
)(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire pl_enable,         
    input  wire [WIDTH-1:0] d,
    input  wire [WIDTH-1:0] pl,
    output reg  [WIDTH-1:0] q
);

always @(posedge clk or posedge reset) begin
    if (reset)
        q <= INIT;
    else if (pl_enable)
        q <= pl;               
    else if (enable)
        q <= d;                
end

endmodule

`endif // REGISTER_MODULE
