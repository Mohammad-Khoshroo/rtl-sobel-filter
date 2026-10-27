module controller (
    input  clk, rst,
    input  logic start,

    output logic ready,
    output logic busy,
    output logic done
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        RUN   = 2'b01,
        WAIT  = 2'b10,
        DONE  = 2'b11
    } state_t;

    state_t current_state, next_state;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin

        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = RUN;
                end
            end

            RUN: begin
                next_state = WAIT;
            end

            WAIT: begin
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_comb begin

        ready = 1'b0;
        busy  = 1'b0;
        done  = 1'b0;

        case (current_state)
            IDLE: begin
                ready = 1'b1;
            end

            RUN: begin
                busy = 1'b1;
            end

            WAIT: begin
                busy = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: begin
                ready = 1'b0;
                busy  = 1'b0;
                done  = 1'b0;
            end
        endcase
    end

endmodule
