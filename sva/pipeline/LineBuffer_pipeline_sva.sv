`ifndef LINE_BUFFER_PIPELINE_SVA_SV
`define LINE_BUFFER_PIPELINE_SVA_SV

// =============================================================================
// SVA Checker for LineBuffer_pipeline
// =============================================================================

module LineBuffer_pipeline_sva #(
    parameter WIDTH = 8,
    parameter ROWS  = 2,
    parameter SIZE  = 640
)(
    input logic clk,
    input logic rst,
    input logic [WIDTH-1:0] wdata,
    input logic wenable,
    input logic [$clog2(ROWS)-1:0] wrow,
    input logic [$clog2(SIZE)-1:0] waddress,
    input logic [$clog2(SIZE)-1:0] raddress,
    input logic [WIDTH-1:0] rdata [ROWS-1:0]
);

    always @(posedge clk) begin
        RST_UNKNOWN: assert #0 (!$isunknown(rst))
            else $error("[SVA LineBuffer_pipeline] Reset signal (rst) is X or Z!");

        if (!rst) begin
            EN_UNKNOWN: assert (!$isunknown(wenable))
                else $error("[SVA LineBuffer_pipeline] Control signal wenable is X or Z!");

            if (wenable) begin
                WRITE_UNKNOWN: assert (!$isunknown(wdata) && !$isunknown(wrow) && !$isunknown(waddress))
                    else $warning("[SVA LineBuffer_pipeline] Write operation contains X or Z bits!");

                WRITE_RANGE: assert ((int'(wrow) < ROWS) && (int'(waddress) < SIZE))
                    else $error("[SVA LineBuffer_pipeline] Write address out of bounds! wrow=%0d, waddress=%0d",
                                int'(wrow), int'(waddress));
            end

            READ_UNKNOWN: assert (!$isunknown(raddress))
                else $warning("[SVA LineBuffer_pipeline] Read address contains X or Z bits!");

            READ_ADDRESS_RANGE: assert (int'(raddress) < SIZE)
                else $error("[SVA LineBuffer_pipeline] Read address out of bounds! raddress=%0d",
                            int'(raddress));
        end
    end

endmodule

`endif // LINE_BUFFER_PIPELINE_SVA_SV
