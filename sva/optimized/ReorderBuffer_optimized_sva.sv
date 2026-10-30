`ifndef REORDER_BUFFER_OPTIMIZED_SVA_SV
`define REORDER_BUFFER_OPTIMIZED_SVA_SV

module ReorderBuffer_optimized_sva #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter YWIN  = 3
)(
    input logic [$clog2(ROWS)-1:0] row_ref,
    input logic [WIDTH-1:0] raw_col [ROWS-1:0],
    input logic [WIDTH-1:0] live_pixel,
    input logic [WIDTH-1:0] ordered_col [YWIN-1:0]
);

    always_comb begin
        ROW_UNKNOWN: assert #0 (!$isunknown(row_ref))
            else $warning("[SVA] row_ref contains X or Z bits!");

        ROW_RANGE: assert #0 (int'(row_ref) < ROWS)
            else $error("[SVA] row_ref out of range! row_ref=%0d", int'(row_ref));

        LIVE_PIXEL_MAP: assert #0 (ordered_col[YWIN-1] == live_pixel)
            else $error("[SVA] ordered_col[%0d] does not match live_pixel!", YWIN-1);
    end

endmodule

`endif // REORDER_BUFFER_OPTIMIZED_SVA_SV
