`include "LineBuffer.sv"
`include "ReorderBuffer.sv"
`include "WindowBuffer.sv"

module SlidingWindowBuffer #( parameter WIDTH = 8, ROWS  = 3, SIZE  = 640, XWIN  = 3, YWIN  = 3 ) (
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

    LineBuffer #(WIDTH, ROWS, SIZE) line_buffer (
        .clk      (clk),
        .rst      (rst),
        .wdata    (wdata),
        .wenable  (wenable),
        .wrow     (wrow),
        .waddress (waddress),
        .raddress (raddress),
        .rdata    (raw_col)
    );

    ReorderBuffer #(WIDTH, ROWS, YWIN) reorder_buffer (
        .row_ref     (rrow),
        .raw_col     (raw_col),
        .ordered_col (ordered_col)
    );

    WindowBuffer #(WIDTH, XWIN, YWIN) window_buffer (
        .clk        (clk),
        .rst        (rst),
        .shift_en   (renable),
        .col_in     (ordered_col),
        .window_out (rdata)
    );

endmodule
