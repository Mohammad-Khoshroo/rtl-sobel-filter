module LineBuffer #(parameter WIDTH = 8, ROWS = 3, SIZE = 640) (
    input clk, rst, 

    input [WIDTH-1:0] wdata,
    input wenable,
    input [$clog2(ROWS)-1:0] wrow,
    input [$clog2(SIZE)-1:0]  waddress,
    
    input [$clog2(SIZE)-1:0]  raddress,
    output logic [WIDTH-1:0] rdata [ROWS-1:0]
);

    reg [WIDTH-1:0]  mem [ROWS-1:0][SIZE-1:0];

    always @(posedge clk) begin : WRITE_DATA
        
        RST_UNKNOWN: assert #0 (!$isunknown(rst))
            else $error("Reset signal (rst) is X or Z!");

        if (!rst) begin
            
            EN_UNKNOWN: assert (!$isunknown(wenable))
                else $error("Control signal wenable is X or Z!");

            if (wenable) begin

                WRITE_UNKNOWN: assert (!$isunknown(wdata) && !$isunknown(wrow) && !$isunknown(waddress))
                    else $warning("Input contains X or Z bits!");
                WRITE_RANGE: assert ((wrow < ROWS) && (waddress < SIZE))
                    else $error("Address out of range!");
                
                mem[wrow][waddress] <= wdata;
            end        

        end
    
    end
    
    always_comb begin : READ_DATA

        READ_UNKNOWN: assert #0 (!$isunknown(raddress))
            else $warning("Read address or row contains X or Z bits!");
        
        READ_ADDRESS_RANGE: assert #0 (int'(raddress) < SIZE)
            else $error("Window horizontal range exceeds SIZE!");   
        
        for (int r = 0; r < ROWS; r++) begin
        rdata[r] = mem[r][raddress];
        end
        
    end

endmodule
