`ifndef ACCELERATOR_OPTIMIZED_SVA_SV
`define ACCELERATOR_OPTIMIZED_SVA_SV

module accelerator_optimized_sva #(parameter WIDTH_SIZE  = 640, HEIGHT_SIZE = 853, PIXEL_WIDTH = 8)(
    input logic clk, rst,
    input logic start,
    input logic ready,
    input logic busy,
    input logic done,
    input logic valid_pixel,
    input logic [PIXEL_WIDTH-1:0] pixel_in,
    input logic [PIXEL_WIDTH-1:0] pixel_out
);

    always @(posedge clk) begin
        if (!rst) begin

            TOP_STATUS_UNKNOWN: assert (!$isunknown({ready, busy, done, valid_pixel}))
                else $error("[SVA] Accelerator status signals contain X or Z");

            MUTUAL_EXCL: assert (!(ready && busy))
                else $error("[SVA] Ready and busy cannot both be high");

            VALID_PIXEL_KNOWN: assert (!valid_pixel || !$isunknown(pixel_out)) // valid_pixel -> isnotunknown(pixel_out)
                else $error("[SVA] valid_pixel is high but pixel_out is X or Z");

            VALID_WHEN_BUSY: assert (!valid_pixel || busy) // valid_pixel -> busy
                else $error("[SVA] valid_pixel is high while accelerator is not busy");
        end
        else begin
            CTRL_SIG_UNKNOWN: assert ((valid_pixel == 1'b0) &&
                                      (busy        == 1'b0) &&
                                      (done        == 1'b0) &&
                                      (ready       == 1'b1))
                else $error("[SVA controller_optimized] One or more control signals are not in IDLE state value");

        end
    end

endmodule

`endif // ACCELERATOR_OPTIMIZED_SVA_SV
