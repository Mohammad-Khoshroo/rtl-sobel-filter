module controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    output logic       alu_enable, // ALU activation command
    output logic [1:0] alu_op,     // Operation type: 00=ADD, 01=SUB, 10=DIV
    output logic       done        // Operation complete
);
    // State machine state definitions (a fully internal signal)
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        FETCH   = 2'b01,
        EXECUTE = 2'b10,
        WRITE   = 2'b11
    } state_t;

    state_t current_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
            alu_enable    <= 1'b0;
            alu_op        <= 2'b00;
            done          <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) current_state <= FETCH;
                end
                FETCH: begin
                    alu_enable    <= 1'b1;
                    alu_op        <= 2'b10; // Issue a division command, for example
                    current_state <= EXECUTE;
                end
                EXECUTE: begin
                    alu_enable    <= 1'b0;
                    current_state <= WRITE;
                end
                WRITE: begin
                    done          <= 1'b1; // Work is done
                    current_state <= IDLE;
                end
            endcase
        end
    end
endmodule

