`ifndef CORE_PIPELINE_SVA_SV
`define CORE_PIPELINE_SVA_SV

// =============================================================================
// SVA Checker for core_pipeline
// =============================================================================

module core_pipeline_sva (
    input logic       clk,
    input logic       rst,
    input logic       shift_en,
    input logic [7:0] window [2:0][2:0],
    input logic [7:0] G_sat_reg
);

    always @(posedge clk) begin
        if (!rst) begin
            SHIFT_UNKNOWN: assert (!$isunknown(shift_en))
                else $error("[SVA core_pipeline] shift_en contains X or Z!");

            G_SAT_UNKNOWN: assert (!$isunknown(G_sat_reg))
                else $error("[SVA core_pipeline] G_sat_reg output contains X or Z!");
        end
    end

endmodule

`endif // CORE_PIPELINE_SVA_SV
