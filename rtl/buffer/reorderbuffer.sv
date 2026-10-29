`timescale 1ns/1ps

// =============================================================================
// ReorderBuffer for 2-Line Streaming Architecture
// Reorders 2 BRAM line buffers and the live pixel stream into a 3-row column:
//   - row_ref = 0: top = raw_col[0], mid = raw_col[1], bot = live_pixel
//   - row_ref = 1: top = raw_col[1], mid = raw_col[0], bot = live_pixel
// =============================================================================

module ReorderBuffer #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter YWIN  = 3
)(
    input  logic                     row_ref,
    input  logic [WIDTH-1:0]         raw_col [ROWS-1:0],
    input  logic [WIDTH-1:0]         live_pixel,
    output logic [WIDTH-1:0]         ordered_col [YWIN-1:0]
);

    always_comb begin
        if (row_ref == 1'b0) begin
            ordered_col[0] = raw_col[0];
            ordered_col[1] = raw_col[1];
        end else begin
            ordered_col[0] = raw_col[1];
            ordered_col[1] = raw_col[0];
        end
        ordered_col[2] = live_pixel;
    end

endmodule
