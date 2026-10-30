`ifndef CONTROLLER_BASELINE_SVA_SV
`define CONTROLLER_BASELINE_SVA_SV

// =============================================================================
// SVA Checker for controller_baseline
// =============================================================================

module controller_baseline_sva #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853
)(
    input logic       clk,
    input logic       rst,
    input logic       start,
    input logic       ready,
    input logic       busy,
    input logic       busy_load,
    input logic       busy_process,
    input logic       done,
    input logic       gx_sign,
    input logic       gy_sign,
    input logic       gx_en,
    input logic       gy_en,
    input logic       xy_ctrl,
    input logic [1:0] xm_ctrl,
    input logic [1:0] ym_ctrl,
    input logic       valid_pixel,
    input logic       linebuffer_wenable,
    input logic       window_shiften,
    input logic [1:0] row_pointer,
    input logic [9:0] waddress,
    input logic [9:0] raddress
);

    always @(posedge clk) begin
        if (!rst) begin
            CTRL_SIG_UNKNOWN: assert (!$isunknown({ready, busy, busy_load, busy_process, done,
                                                  gx_en, gy_en, xy_ctrl, xm_ctrl, ym_ctrl,
                                                  valid_pixel, linebuffer_wenable, window_shiften,
                                                  row_pointer}))
                else $error("[SVA controller_baseline] One or more control signals are X or Z!");

            MUTUAL_EXCL: assert (!(ready && busy))
                else $error("[SVA controller_baseline] Controller cannot be both ready and busy!");

            BUSY_SUBSTATES: assert (!busy || (busy_load || busy_process))
                else $error("[SVA controller_baseline] Busy asserted without busy_load or busy_process!");

            ROW_PTR_RANGE: assert (row_pointer < 2'd3)
                else $error("[SVA controller_baseline] row_pointer out of range: %0d", row_pointer);

            if (linebuffer_wenable) begin
                WADDR_RANGE: assert (waddress < WIDTH_SIZE)
                    else $error("[SVA controller_baseline] waddress out of bounds: %0d", waddress);
            end

            if (window_shiften) begin
                RADDR_RANGE: assert (raddress < WIDTH_SIZE)
                    else $error("[SVA controller_baseline] raddress out of bounds: %0d", raddress);
            end

            VALID_IMPLIES_BUSY: assert (!valid_pixel || busy_process)
                else $error("[SVA controller_baseline] valid_pixel asserted outside busy_process!");
        end
    end

endmodule

`endif // CONTROLLER_BASELINE_SVA_SV
