// =============================================================================
// LineBuffer_baseline #(
//     .WIDTH    (8),
//     .ROWS     (3),
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

module LineBuffer_baseline #(parameter WIDTH = 8, ROWS = 3, SIZE = 640) (
    input clk, rst, 

    input [WIDTH-1:0] wdata,
    input wenable,
    input [$clog2(ROWS)-1:0] wrow,
    input [$clog2(SIZE)-1:0]  waddress,
    
    input [$clog2(SIZE)-1:0]  raddress,
    output logic [WIDTH-1:0] rdata [ROWS-1:0]
);

    (* ram_style = "block" *) reg [WIDTH-1:0]  mem [ROWS-1:0][SIZE-1:0];

    always @(posedge clk) begin : WRITE_DATA
        if (!rst) begin
            if (wenable) begin
                mem[wrow][waddress] <= wdata;
            end        
        end
    end
    
    always @(posedge clk) begin : READ_DATA
        if (!rst) begin
            for (int r = 0; r < ROWS; r++) begin
                rdata[r] <= mem[r][raddress];
            end
        end
    end

endmodule
