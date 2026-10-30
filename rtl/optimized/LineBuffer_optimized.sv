// =============================================================================
// LineBuffer_optimized #(
//     .WIDTH    (8),
//     .ROWS     (2),
//     .SIZE     (640)
// ) module_name (
//     .clk      (clk),
//     .rst      (rst),
//     .wdata    (wdata),
//     .wenable  (wenable),
//     .wrow     (wrow),
//     .waddress (waddress),
//     .raddress (raddress),
//     .rdata    (rdata)
// );
// =============================================================================

module LineBuffer_optimized #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter SIZE  = 640
)(
    input  logic                   clk,
    input  logic                   rst, 

    input  logic [WIDTH-1:0]       wdata,
    input  logic                   wenable,
    input  logic [$clog2(ROWS)-1:0] wrow,
    input  logic [$clog2(SIZE)-1:0] waddress,
    
    input  logic [$clog2(SIZE)-1:0] raddress,
    output logic [WIDTH-1:0]       rdata [ROWS-1:0]
);

    genvar r;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : GEN_LINE_RAM
            (* ram_style = "block" *) reg [WIDTH-1:0] ram [SIZE-1:0];

            always @(posedge clk) begin
                if (wenable && (wrow == r)) begin
                    ram[waddress] <= wdata;
                end
            end

            always @(posedge clk) begin
                rdata[r] <= ram[raddress];
            end
        end
    endgenerate

endmodule
