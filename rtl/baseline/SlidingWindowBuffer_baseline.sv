`include "LineBuffer_baseline.sv"
`include "ReorderBuffer_baseline.sv"
`include "WindowBuffer_baseline.sv"

// =============================================================================
// SlidingWindowBuffer_baseline #(
//     .WIDTH    (8),
//     .ROWS     (3),
//     .SIZE     (640),
//     .XWIN     (3),
//     .YWIN     (3)
// ) module_name (
//     .clk      (clk),
//     .rst      (rst),
//     .wenable  (wenable),
//     .wdata    (wdata),
//     .wrow     (wrow),
//     .waddress (waddress),
//     .renable  (renable),
//     .rrow     (rrow),       // Pointer to top row for circular alignment
//     .raddress (raddress),
//     .rdata    (rdata)
// );
// =============================================================================

module SlidingWindowBuffer_baseline #( parameter WIDTH = 8, ROWS  = 3, SIZE  = 640, XWIN  = 3, YWIN  = 3 ) (
    input  clk, rst,

    input  wenable,
    input  [WIDTH-1:0] wdata,
    input  [$clog2(ROWS)-1:0] wrow,
    input  [$clog2(SIZE)-1:0] waddress,

    input  renable,
    input  [$clog2(ROWS)-1:0] rrow,
    input  [$clog2(SIZE)-1:0] raddress,

    output [WIDTH-1:0] rdata [XWIN-1:0][YWIN-1:0]
);

    logic [WIDTH-1:0] raw_col     [ROWS-1:0];
    logic [WIDTH-1:0] ordered_col [YWIN-1:0];

    LineBuffer_baseline #(WIDTH, ROWS, SIZE) line_buffer (
        .clk      (clk),
        .rst      (rst),
        .wdata    (wdata),
        .wenable  (wenable),
        .wrow     (wrow),
        .waddress (waddress),
        .raddress (raddress),
        .rdata    (raw_col)
    );

    ReorderBuffer_baseline #(WIDTH, ROWS, YWIN) reorder_buffer (
        .row_ref     (rrow),
        .raw_col     (raw_col),
        .ordered_col (ordered_col)
    );

    WindowBuffer_baseline #(WIDTH, XWIN, YWIN) window_buffer (
        .clk        (clk),
        .rst        (rst),
        .shift_en   (renable),
        .col_in     (ordered_col),
        .window_out (rdata)
    );

endmodule
