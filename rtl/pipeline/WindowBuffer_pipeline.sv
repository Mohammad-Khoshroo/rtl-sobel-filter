// =============================================================================
// WindowBuffer_pipeline #(
//     .WIDTH      (8),
//     .XWIN       (3),
//     .YWIN       (3)
// ) module_name (
//     .clk        (clk),
//     .rst        (rst),
//     .shift_en   (shift_en),
//     .col_in     (col_in),
//     .window_out (window_out)
// );
// =============================================================================

module WindowBuffer_pipeline #( parameter WIDTH = 8, XWIN  = 3, YWIN  = 3 ) (
    input  logic clk, rst,
    input  logic shift_en,

    input  logic [WIDTH-1:0] col_in [YWIN-1:0],
    output logic [WIDTH-1:0] window_out [XWIN-1:0][YWIN-1:0]
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            foreach (window_out[x, y]) begin
                window_out[x][y] <= '0;
            end
        end else begin
            if (shift_en) begin
                for (int unsigned x = 0; x < XWIN - 1; x++) begin : SHIFT
                    for (int unsigned y = 0; y < YWIN; y++) begin
                        window_out[x][y] <= window_out[x + 1][y];
                    end
                end

                for (int unsigned y = 0; y < YWIN; y++) begin : UPDATE
                    window_out[XWIN - 1][y] <= col_in[y];
                end
            end
        end
    end

endmodule
