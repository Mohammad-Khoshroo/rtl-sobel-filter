`timescale 1ns/1ps

// =============================================================================
// Streaming Controller for 2-Line Sobel Accelerator
// Throughput: 1.0 Pixel/Cycle streaming
// Architecture:
//   - IDLE: Wait for start pulse
//   - STREAM: Simultaneously streams pixel_in into LineBuffer and WindowBuffer
//             Generates 1 valid pixel every cycle (after 2-row prefill + 2-col latency)
//   - DONE: Assert done interrupt when all 542,938 valid pixels are produced
// =============================================================================

module controller #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,

    output logic                   ready,
    output logic                   busy,
    output logic                   done,
    output logic                   valid_pixel,

    // Controls to SlidingWindowBuffer
    output logic                   linebuffer_wenable,
    output logic                   window_shiften,
    output logic                   row_pointer,
    output logic [9:0]             waddress,
    output logic [9:0]             raddress
);

    typedef enum logic [1:0] {
        IDLE   = 2'd0,
        STREAM = 2'd1,
        FLUSH  = 2'd2,
        DONE_S = 2'd3
    } state_t;

    state_t state, next_state;

    logic [9:0] col;
    logic [9:0] row;
    logic       row_ptr;

    assign row_pointer = row_ptr;
    assign waddress    = col;
    assign raddress    = col;

    // LineBuffer is written during streaming
    assign linebuffer_wenable = (state == STREAM);
    assign window_shiften     = (state == STREAM) || (state == FLUSH);

    // Coordinate check: pixel at window center is valid when:
    // row in [2, HEIGHT_SIZE-1] and col in [2, WIDTH_SIZE-1]
    wire win_valid_raw = (state == STREAM) && (row >= 10'd2) && (col >= 10'd2) && (col < WIDTH_SIZE);

    // 2-cycle pipeline delay matching BRAM read latency (1 cycle) + WindowBuffer shift (1 cycle)
    logic pipe_v1, pipe_v2;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pipe_v1 <= 1'b0;
            pipe_v2 <= 1'b0;
        end else begin
            pipe_v1 <= win_valid_raw;
            pipe_v2 <= pipe_v1;
        end
    end

    assign valid_pixel = pipe_v2;

    // FSM State Transition
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Counters for row, col, and circular row_ptr
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            col     <= 10'd0;
            row     <= 10'd0;
            row_ptr <= 1'b0;
        end else if (state == IDLE) begin
            col     <= 10'd0;
            row     <= 10'd0;
            row_ptr <= 1'b0;
        end else if (state == STREAM) begin
            if (col == (WIDTH_SIZE - 1)) begin
                col     <= 10'd0;
                row     <= row + 10'd1;
                row_ptr <= ~row_ptr;
            end else begin
                col <= col + 10'd1;
            end
        end
    end

    // Flush cycle counter to drain final pipeline stages
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

    // Next State Logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = STREAM;
                end
            end

            STREAM: begin
                // All input pixels fed (HEIGHT_SIZE rows * WIDTH_SIZE cols)
                if ((row == HEIGHT_SIZE - 1) && (col == WIDTH_SIZE - 1)) begin
                    next_state = FLUSH;
                end
            end

            FLUSH: begin
                // 3 cycles to drain BRAM + Window + Core pipeline
                if (flush_cnt == 3'd3) begin
                    next_state = DONE_S;
                end
            end

            DONE_S: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Status Signals
    assign ready = (state == IDLE) || (state == DONE_S);
    assign busy  = (state != IDLE) && (state != DONE_S);
    assign done  = (state == DONE_S);

endmodule
