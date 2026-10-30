`ifndef CONTROLLER_OPTIMIZED_SVA_SV
`define CONTROLLER_OPTIMIZED_SVA_SV


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
                else $error("[SVA] One or more control signals are X or Z!");

            MUTUAL_EXCL: assert (!(ready && busy))
                else $error("[SVA] Controller cannot be both ready and busy!");

            if (linebuffer_wenable) begin
                WADDR_RANGE: assert (waddress < WIDTH_SIZE)
                    else $error("[SVA] waddress out of bounds: %0d", waddress);
            end

            if (window_shiften) begin
                RADDR_RANGE: assert (raddress < WIDTH_SIZE)
                    else $error("[SVA] raddress out of bounds: %0d", raddress);
            end

            VALID_IMPLIES_BUSY: assert (!valid_pixel || busy)
                else $error("[SVA] valid_pixel asserted while not busy!");
            
            NO_START_WHILE_PROCESS: assert (!start || !busy)
                else $error("[SVA] start asserted while controller is busy!");
        end
    end

    localparam int EXPECTED_LATENCY = (2 * WIDTH_SIZE) + 4;
    CORRECT_VALID_ISSUE: assert property (@(posedge clk) disable iff (rst) (ready && start) |-> ##(EXPECTED_LATENCY + 1) valid_pixel) 
    else 
        $error("[SVA] valid_pixel did not assert at the expected cycle!");

    START_TO_STREAM: assert property (@(posedge clk) disable iff (rst) (ready && start) |=> (busy && !ready))
        else $error("[SVA] start asserted while ready did not transition to busy!");

    DONE_TO_IDLE: assert property (@(posedge clk) disable iff (rst) done |=> (ready && !busy))
        else $error("[SVA] done asserted did not return to ready next cycle!");

    DONE_PULSE_DURATION: assert property (@(posedge clk) disable iff (rst) done |=> !done)
        else $error("[SVA] done pulse lasted more than 1 cycle!");

    FLUSH_PHASE_BEHAVIOR: assert property (
        @(posedge clk) disable iff (rst)
        ($fell(linebuffer_wenable) && busy) |-> (window_shiften && !linebuffer_wenable)[*4] ##1 done
    ) else $error("[SVA] FLUSH phase violation: window did not shift for 4 cycles before done!");
    
    FLUSH_STATUS_CHECK: assert property (
        @(posedge clk) disable iff (rst)
        (!linebuffer_wenable && window_shiften && busy) |-> (!ready && !done)
    ) else $error("[SVA] Invalid ready/done state during FLUSH phase!");


endmodule

`endif // CONTROLLER_OPTIMIZED_SVA_SV
