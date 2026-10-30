module controller_optimized #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853
)(
    input  logic clk, rst,
    
    input  logic start,
    output logic ready,
    output logic busy,
    output logic done,
    output logic valid_pixel,

    output logic linebuffer_wenable,
    output logic window_shiften,
    output logic row_pointer,
    output logic [9:0] waddress,
    output logic [9:0] raddress
);

    typedef enum logic [1:0] {
        IDLE   = 2'd0,
        STREAM = 2'd1,
        FLUSH  = 2'd2,
        DONE   = 2'd3
    } state_t;

    state_t state, next_state;

    logic [9:0] col;
    logic [9:0] row;

    assign waddress    = col;
    assign raddress    = col;

    assign linebuffer_wenable = (state == STREAM);
    assign window_shiften     = (state == STREAM) || (state == FLUSH);

    logic pipe_v1, pipe_v2;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pipe_v1 <= 1'b0;
            pipe_v2 <= 1'b0;
        end else begin
            pipe_v1 <= (state == STREAM) && (row >= 10'd2) && (col >= 10'd2) && (col < WIDTH_SIZE);
            pipe_v2 <= pipe_v1;
        end
    end
    assign valid_pixel = pipe_v2;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            col         <= 10'd0;
            row         <= 10'd0;
            row_pointer <= 1'b0;
        end else if (state == IDLE) begin
            col         <= 10'd0;
            row         <= 10'd0;
            row_pointer <= 1'b0;
        end else if (state == STREAM) begin
            if (col == (WIDTH_SIZE - 1)) begin
                col         <= 10'd0;
                row         <= row + 10'd1;
                row_pointer <= ~row_pointer;
            end else begin
                col <= col + 10'd1;
            end
        end
    end

    logic [2:0] flush_cnt;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            flush_cnt <= 3'd0;
        end else if (state == FLUSH) begin
            flush_cnt <= flush_cnt + 3'd1;
        end else begin
            flush_cnt <= 3'd0;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = STREAM;
                end
            end

            STREAM: begin
                if ((row == HEIGHT_SIZE - 1) && (col == WIDTH_SIZE - 1)) begin
                    next_state = FLUSH;
                end
            end

            FLUSH: begin
                if (flush_cnt == 3'd3) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    assign ready = state == IDLE;
    assign busy  = (state != IDLE) && (state != DONE);
    assign done  = (state == DONE);

endmodule
