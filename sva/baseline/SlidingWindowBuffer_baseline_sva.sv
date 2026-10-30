`ifndef SLIDING_WINDOW_BUFFER_BASELINE_SVA_SV
`define SLIDING_WINDOW_BUFFER_BASELINE_SVA_SV

// =============================================================================
// SVA Checker for SlidingWindowBuffer_baseline
// =============================================================================

module SlidingWindowBuffer_baseline_sva #(
    parameter WIDTH = 8,
    parameter ROWS  = 3,
    parameter SIZE  = 640,
    parameter XWIN  = 3,
    parameter YWIN  = 3
)(
    input logic                   clk,
    input logic                   rst,
    input logic                   wenable,
    input logic [WIDTH-1:0]       wdata,
    input logic [$clog2(ROWS)-1:0] wrow,
    input logic [$clog2(SIZE)-1:0] waddress,
    input logic                   renable,
    input logic [$clog2(ROWS)-1:0] rrow,
    input logic [$clog2(SIZE)-1:0] raddress,
    input logic [WIDTH-1:0]       rdata [XWIN-1:0][YWIN-1:0]
);

    always @(posedge clk) begin
        if (!rst) begin
            WEN_UNKNOWN: assert (!$isunknown(wenable))
                else $error("[SVA SlidingWindowBuffer_baseline] wenable is X or Z!");

            REN_UNKNOWN: assert (!$isunknown(renable))
                else $error("[SVA SlidingWindowBuffer_baseline] renable is X or Z!");

            if (wenable) begin
                WROW_RANGE: assert (int'(wrow) < ROWS)
                    else $error("[SVA SlidingWindowBuffer_baseline] wrow out of range: %0d", int'(wrow));
                WADDR_RANGE: assert (int'(waddress) < SIZE)
                    else $error("[SVA SlidingWindowBuffer_baseline] waddress out of range: %0d", int'(waddress));
                WDATA_UNKNOWN: assert (!$isunknown(wdata))
                    else $warning("[SVA SlidingWindowBuffer_baseline] wdata has X or Z bits!");
            end

            if (renable) begin
                RROW_RANGE: assert (int'(rrow) < ROWS)
                    else $error("[SVA SlidingWindowBuffer_baseline] rrow out of range: %0d", int'(rrow));
                RADDR_RANGE: assert (int'(raddress) < SIZE)
                    else $error("[SVA SlidingWindowBuffer_baseline] raddress out of range: %0d", int'(raddress));
            end
        end
    end

endmodule

`endif // SLIDING_WINDOW_BUFFER_BASELINE_SVA_SV
