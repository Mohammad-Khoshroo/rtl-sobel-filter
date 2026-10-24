module LineBuffer #( WIDTH = 8, ROWS = 3, SIZE = 640, XWIN = 3, YWIN = 3 ) (
    input clk, rst, 
    input [WIDTH-1:0] wdata,
    input wenable,
    input [$clog2(ROWS)-1:0] wrow,
    input [$clog2(SIZE)-1:0]  waddress,
    input [$clog2(ROWS)-1:0] rrow,
    input [$clog2(SIZE)-1:0]  raddress,
    output logic [WIDTH-1:0] rdata [XWIN-1:0][YWIN-1:0]
);

    initial begin
        PARAM_CHECK_X: assert (SIZE >= XWIN)
            else $fatal(1, "Parameter Error: SIZE (%0d) must be >= XWIN (%0d)", SIZE, XWIN);
        PARAM_CHECK_Y: assert (ROWS >= YWIN)
            else $fatal(1, "Parameter Error: ROWS (%0d) must be >= YWIN (%0d)", ROWS, YWIN);
    end
    
    reg [WIDTH-1:0]  mem [ROWS-1:0][SIZE-1:0];

    always @(posedge clk or posedge rst) begin
        
        if (rst) begin 
        
            foreach (mem[i, j]) begin
                mem[i][j] <= '0;
            end
            foreach (rdata[x, y]) begin
                rdata[x][y] <= '0;
            end
        
        end
        
        else begin

            EN_UNKNOWN: assert (!$isunknown(wenable))
                else $error("Control signal wenable is X or Z!");

            if (wenable) begin

                WRITE_UNKNOWN: assert (!$isunknown(wdata) && !$isunknown(wrow) && !$isunknown(waddress))
                    else $warning("Input contains X or Z bits!");
                WRITE_RANGE: assert ((wrow < ROWS) && (waddress < SIZE))
                    else $error("Address out of range!");
                
                mem[wrow][waddress] <= wdata;
            end 
            
            READ_UNKNOWN: assert (!$isunknown(rrow) && !$isunknown(raddress))
                else $warning("Read address or row contains X or Z bits!");
            
            READ_ROW_RANGE: assert (rrow < ROWS)
                else $error("Read row (rrow) out of range!");
            READ_ADDRESS_RANGE: assert ((int'(raddress) + XWIN) <= SIZE)
                else $error("Window horizontal range exceeds SIZE!");   
            
            for (int x = 0; x < XWIN; x++) begin    
                for (int y = 0; y < YWIN; y++) begin
                    
                    int phys_row = (rrow + y) % ROWS;
                    int phys_col = (raddress + x);
                    
                    rdata[x][y] <= mem[phys_row][phys_col];

                end
            end

        end

    end
    
endmodule
