`timescale 1ns/1ps

`include "LineBuffer_optimized.sv"
`include "ReorderBuffer_optimized.sv"
`include "WindowBuffer_optimized.sv"

// =============================================================================
// SlidingWindowBuffer_optimized #(
//     .WIDTH    (8),
//     .ROWS     (2),
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

module SlidingWindowBuffer_optimized #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter SIZE  = 640,
    parameter XWIN  = 3,
    parameter YWIN  = 3
)(
    input  logic                   clk,
    input  logic                   rst,

    input  logic                   wenable,
    input  logic [WIDTH-1:0]       wdata,
    input  logic                   wrow,
    input  logic [$clog2(SIZE)-1:0] waddress,

    input  logic                   renable,
    input  logic                   rrow,
    input  logic [$clog2(SIZE)-1:0] raddress,

    output logic [WIDTH-1:0]       rdata [XWIN-1:0][YWIN-1:0]
);

    logic [WIDTH-1:0] raw_col [ROWS-1:0];
    logic [WIDTH-1:0] ordered_col [YWIN-1:0];

    logic [WIDTH-1:0] live_pixel_reg;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            live_pixel_reg <= '0;
        end else if (wenable) begin
            live_pixel_reg <= wdata;
        end
    end

    LineBuffer_optimized #(
        .WIDTH (WIDTH),
        .ROWS  (ROWS),
        .SIZE  (SIZE)
    ) line_buffer (
        .clk      (clk),
        .rst      (rst),
        .wdata    (wdata),
        .wenable  (wenable),
        .wrow     (wrow),
        .waddress (waddress),
        .raddress (raddress),
        .rdata    (raw_col)
    );

    ReorderBuffer_optimized #(
        .WIDTH (WIDTH),
        .ROWS  (ROWS),
        .YWIN  (YWIN)
    ) reorder_buffer (
        .row_ref     (rrow),
        .raw_col     (raw_col),
        .live_pixel  (live_pixel_reg),
        .ordered_col (ordered_col)
    );

    WindowBuffer_optimized #(
        .WIDTH (WIDTH),
        .XWIN  (XWIN),
        .YWIN  (YWIN)
    ) window_buffer (
        .clk        (clk),
        .rst        (rst),
        .shift_en   (renable),
        .col_in     (ordered_col),
        .window_out (rdata)
    );

endmodule
