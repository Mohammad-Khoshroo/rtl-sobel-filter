`ifndef WINDOW_BUFFER_PIPELINE_SVA_SV
`define WINDOW_BUFFER_PIPELINE_SVA_SV

// =============================================================================
// SVA Checker for WindowBuffer_pipeline
// =============================================================================

module WindowBuffer_pipeline_sva #(
    parameter WIDTH = 8,
    parameter XWIN  = 3,
    parameter YWIN  = 3
)(
    input logic clk,
    input logic rst,
    input logic shift_en,
    input logic [WIDTH-1:0] col_in [YWIN-1:0],
    input logic [WIDTH-1:0] window_out [XWIN-1:0][YWIN-1:0]
);

    always @(posedge clk) begin
        if (!rst) begin
            SHIFT_UNKNOWN: assert #0 (!$isunknown(shift_en))
                else $error("[SVA WindowBuffer_pipeline] shift_en contains X or Z!");

            if (shift_en) begin
                for (int unsigned y = 0; y < YWIN; y++) begin
                    COL_UNKNOWN: assert #0 (!$isunknown(col_in[y]))
                        else $warning("[SVA WindowBuffer_pipeline] col_in[%0d] contains X or Z bits!", y);
                end
            end
        end
    end

endmodule

`endif // WINDOW_BUFFER_PIPELINE_SVA_SV
