`ifndef CONTROLLER_OPTIMIZED_SVA_SV
`define CONTROLLER_OPTIMIZED_SVA_SV

// =============================================================================
// SVA Checker for controller_optimized
// =============================================================================

module controller_optimized_sva #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853
)(
    input logic       clk,
    input logic       rst,
    input logic       start,
    input logic       ready,
    input logic       busy,
    input logic       done,
    input logic       valid_pixel,
    input logic       linebuffer_wenable,
    input logic       window_shiften,
    input logic       row_pointer,
    input logic [9:0] waddress,
    input logic [9:0] raddress
);

    always @(posedge clk) begin
        if (!rst) begin
            CTRL_SIG_UNKNOWN: assert (!$isunknown({ready, busy, done, valid_pixel,
                                                  linebuffer_wenable, window_shiften, row_pointer}))
                else $error("[SVA controller_optimized] One or more control signals are X or Z!");

            MUTUAL_EXCL: assert (!(ready && busy))
                else $error("[SVA controller_optimized] Controller cannot be both ready and busy!");

            if (linebuffer_wenable) begin
                WADDR_RANGE: assert (waddress < WIDTH_SIZE)
                    else $error("[SVA controller_optimized] waddress out of bounds: %0d", waddress);
            end

            if (window_shiften) begin
                RADDR_RANGE: assert (raddress < WIDTH_SIZE)
                    else $error("[SVA controller_optimized] raddress out of bounds: %0d", raddress);
            end

            VALID_IMPLIES_BUSY: assert (!valid_pixel || busy)
                else $error("[SVA controller_optimized] valid_pixel asserted while not busy!");
        end
    end

endmodule

`endif // CONTROLLER_OPTIMIZED_SVA_SV
