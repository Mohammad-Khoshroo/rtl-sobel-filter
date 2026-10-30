`ifndef CORE_OPTIMIZED_SVA_SV
`define CORE_OPTIMIZED_SVA_SV

// =============================================================================
// SVA Checker for core_optimized
// =============================================================================

module core_optimized_sva (
    input logic       clk,
    input logic       rst,
    input logic       shift_en,
    input logic [7:0] window [2:0][2:0],
    input logic [7:0] G_sat
);

    always @(posedge clk) begin
        if (!rst) begin
            SHIFT_UNKNOWN: assert (!$isunknown(shift_en))
                else $error("[SVA core_optimized] shift_en contains X or Z!");

            G_SAT_UNKNOWN: assert (!$isunknown(G_sat))
                else $error("[SVA core_optimized] G_sat output contains X or Z!");
        end
    end

endmodule

`endif // CORE_OPTIMIZED_SVA_SV
