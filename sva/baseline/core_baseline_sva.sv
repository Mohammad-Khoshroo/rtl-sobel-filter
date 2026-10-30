`ifndef CORE_BASELINE_SVA_SV
`define CORE_BASELINE_SVA_SV

// =============================================================================
// SVA Checker for core_baseline
// =============================================================================

module core_baseline_sva (
    input logic       clk,
    input logic       rst,
    input logic [7:0] window [2:0][2:0],
    input logic       xy_ctrl,
    input logic       gx_en,
    input logic       gy_en,
    input logic [1:0] xm_ctrl,
    input logic [1:0] ym_ctrl,
    input logic       gx_sign,
    input logic       gy_sign,
    input logic [7:0] G
);

    always @(posedge clk) begin
        if (!rst) begin
            CTRL_UNKNOWN: assert (!$isunknown({xy_ctrl, gx_en, gy_en, xm_ctrl, ym_ctrl}))
                else $error("[SVA core_baseline] Control inputs contain X or Z!");

            SIGN_UNKNOWN: assert (!$isunknown({gx_sign, gy_sign}))
                else $error("[SVA core_baseline] gx_sign or gy_sign contains X or Z!");

            G_UNKNOWN: assert (!$isunknown(G))
                else $error("[SVA core_baseline] Core output G contains X or Z!");
        end
    end

endmodule

`endif // CORE_BASELINE_SVA_SV
