`ifndef REORDER_BUFFER_BASELINE_SVA_SV
`define REORDER_BUFFER_BASELINE_SVA_SV

// =============================================================================
// SVA Checker for ReorderBuffer_baseline
// =============================================================================

module ReorderBuffer_baseline_sva #(
    parameter WIDTH = 8,
    parameter ROWS  = 3,
    parameter YWIN  = 3
)(
    input logic [$clog2(ROWS)-1:0] row_ref,
    input logic [WIDTH-1:0] raw_col [ROWS-1:0],
    input logic [WIDTH-1:0] ordered_col [YWIN-1:0]
);

    always_comb begin
        ROW_UNKNOWN: assert #0 (!$isunknown(row_ref))
            else $warning("[SVA ReorderBuffer_baseline] row_ref contains X or Z bits!");

        ROW_RANGE: assert #0 (int'(row_ref) < ROWS)
            else $error("[SVA ReorderBuffer_baseline] row_ref out of range! row_ref=%0d", int'(row_ref));
    end

endmodule

`endif // REORDER_BUFFER_BASELINE_SVA_SV
