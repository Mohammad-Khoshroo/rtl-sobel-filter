// =============================================================================
// ReorderBuffer_baseline #(
//     .WIDTH       (8),
//     .ROWS        (3),
//     .YWIN        (3)
// ) module_name (
//     .row_ref     (row_ref),     // Pointer to top row for circular alignment
//     .raw_col     (raw_col),
//     .ordered_col (ordered_col)
// );
// =============================================================================

module ReorderBuffer_baseline #( parameter WIDTH = 8, ROWS  = 3, YWIN  = 3 ) (
    input  logic [$clog2(ROWS)-1:0] row_ref,
    input  logic [WIDTH-1:0] raw_col [ROWS-1:0],
    output logic [WIDTH-1:0] ordered_col [YWIN-1:0]
);

    always_comb begin
        for (int unsigned y = 0; y < YWIN; y++) begin
            int unsigned index;
            int unsigned phys_row;

            index    = int'(row_ref) + y;
            phys_row = (index >= ROWS) ? (index - ROWS) : index;
            
            ordered_col[y] = raw_col[phys_row];
        end
    end

endmodule
