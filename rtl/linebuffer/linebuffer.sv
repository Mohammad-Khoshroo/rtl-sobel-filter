module LineBuffer #( WIDTH = 8, DEPTH = 3, SIZE = 640, XWIN = 3, YWIN = 3 ) (
    input clk, rst, 
    input [WIDTH-1:0] wdata,
    input wenable,
    input [$clog2(DEPTH)-1:0] wrow,
    input [$clog2(SIZE)-1:0]  waddress,
    input [$clog2(DEPTH)-1:0] rrow,
    input [$clog2(SIZE)-1:0]  raddress,
    output [WIDTH-1:0] rdata [XWIN-1:0][YWIN-1:0]
);

    reg [WIDTH-1:0]  mem [DEPTH-1:0][SIZE-1:0];
    
    always @(posedge clk or rst) begin
        
        if (rst)
        begin 
            all mem <= 0;
        end
        else if (wenable) begin
            
            UNKNOWN: assert (!$isunknown(wdata) && !$isunknown(wrow) && !$isunknown(waddress))
                else $warning("Input contains X or Z bits!");
            RANGE: assert ((wrow < DEPTH) && (waddress < SIZE))
                else $error("Address out of range!");
            mem[wrow][waddress] <= wdata;
        
        end

        for (indexex)
        rdata <= mem[][]
        
    end
    
endmodule
