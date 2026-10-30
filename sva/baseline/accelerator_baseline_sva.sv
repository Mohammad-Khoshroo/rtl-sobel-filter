`ifndef ACCELERATOR_BASELINE_SVA_SV
`define ACCELERATOR_BASELINE_SV

// =============================================================================
// SVA Checker for accelerator_baseline
// =============================================================================

module accelerator_baseline_sva #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853,
    parameter PIXEL_WIDTH = 8
)(
    input logic                   clk,
    input logic                   rst,
    input logic                   start,
    input logic [PIXEL_WIDTH-1:0] pixel_in,
    input logic                   ready,
    input logic                   busy,
    input logic                   busy_load,
    input logic                   busy_process,
    input logic                   done,
    input logic                   linebuffer_wenable,
    input logic                   valid_pixel,
    input logic [PIXEL_WIDTH-1:0] pixel_out
);

    always @(posedge clk) begin
        if (!rst) begin
            TOP_STATUS_UNKNOWN: assert (!$isunknown({ready, busy, busy_load, busy_process, done,
                                                    linebuffer_wenable, valid_pixel}))
                else $error("[SVA accelerator_baseline] Accelerator status signals contain X or Z!");

            MUTUAL_EXCL: assert (!(ready && busy))
                else $error("[SVA accelerator_baseline] Ready and busy cannot both be high!");

            VALID_PIXEL_KNOWN: assert (!valid_pixel || !$isunknown(pixel_out))
                else $error("[SVA accelerator_baseline] valid_pixel is high but pixel_out is X or Z!");

            VALID_WHEN_BUSY: assert (!valid_pixel || busy)
                else $error("[SVA accelerator_baseline] valid_pixel is high while accelerator is not busy!");
        end
    end

endmodule

`endif // ACCELERATOR_BASELINE_SVA_SV
