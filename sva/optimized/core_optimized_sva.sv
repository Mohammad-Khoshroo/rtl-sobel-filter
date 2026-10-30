`ifndef CORE_OPTIMIZED_SVA_SV
`define CORE_OPTIMIZED_SVA_SV

module core_optimized_sva (
    input logic        clk,
    input logic        rst,
    input logic        shift_en,
    input logic [7:0]  window [2:0][2:0],
    input logic [7:0]  G_sat,
    input logic [10:0] G
);

    always @(posedge clk) begin
        if (!rst) begin
            SHIFT_UNKNOWN: assert (!$isunknown(shift_en))
                else $error("[SVA] shift_en contains X or Z!");

            G_SAT_UNKNOWN: assert (!$isunknown(G_sat))
                else $error("[SVA] G_sat output contains X or Z!");
           
            /* verilator lint_off CMPCONST */
            G_SAT_BOUND: assert (int'(G_sat) <= 255 && int'(G_sat) >= 0)
                else $error("[SVA] G_sat output exceeds 8-bit bounds [0, 255]!");
            /* verilator lint_on CMPCONST */

            SATURATION_CLAMP: assert (G < 11'd256 || G_sat == 8'd255)
                else $error("[SVA] Saturation failure! Gradient G=%0d exceeded 255 but G_sat was not clamped to 255 (got %0d)", G, G_sat);
        end
    end

endmodule

`endif // CORE_OPTIMIZED_SVA_SV
