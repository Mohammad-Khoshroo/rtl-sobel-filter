`ifndef SLIDING_WINDOW_BUFFER_PIPELINE_SVA_SV
`define SLIDING_WINDOW_BUFFER_PIPELINE_SVA_SV

// =============================================================================
// SVA Checker for SlidingWindowBuffer_pipeline
// =============================================================================

module SlidingWindowBuffer_pipeline_sva #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter SIZE  = 640,
    parameter XWIN  = 3,
    parameter YWIN  = 3
)(
    input logic                   clk,
    input logic                   rst,
    input logic                   wenable,
    input logic [WIDTH-1:0]       wdata,
    input logic                   wrow,
    input logic [$clog2(SIZE)-1:0] waddress,
    input logic                   renable,
    input logic                   rrow,
    input logic [$clog2(SIZE)-1:0] raddress,
    input logic [WIDTH-1:0]       rdata [XWIN-1:0][YWIN-1:0]
);

    always @(posedge clk) begin
        if (!rst) begin
            WEN_UNKNOWN: assert (!$isunknown(wenable))
                else $error("[SVA SlidingWindowBuffer_pipeline] wenable is X or Z!");

            REN_UNKNOWN: assert (!$isunknown(renable))
                else $error("[SVA SlidingWindowBuffer_pipeline] renable is X or Z!");

            if (wenable) begin
                WADDR_RANGE: assert (int'(waddress) < SIZE)
                    else $error("[SVA SlidingWindowBuffer_pipeline] waddress out of range: %0d", int'(waddress));
                WDATA_UNKNOWN: assert (!$isunknown(wdata))
                    else $warning("[SVA SlidingWindowBuffer_pipeline] wdata has X or Z bits!");
            end

            if (renable) begin
                RADDR_RANGE: assert (int'(raddress) < SIZE)
                    else $error("[SVA SlidingWindowBuffer_pipeline] raddress out of range: %0d", int'(raddress));
            end
        end
    end

endmodule

`endif // SLIDING_WINDOW_BUFFER_PIPELINE_SVA_SV
