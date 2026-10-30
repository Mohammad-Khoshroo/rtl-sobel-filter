// =============================================================================
// LineBuffer_pipeline #(
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

module LineBuffer_pipeline #(
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

    (* ram_style = "block" *) reg [WIDTH-1:0] mem [ROWS-1:0][SIZE-1:0];

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
