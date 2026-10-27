// =============================================================================
// Project: Sobel Hardware Accelerator (FPGA CA01 - University of Tehran)
// Module:  controller
// Description:
//   FSM Controller implemented using the 3-always-block Huffman model.
//   Coordinates the dataflow across LineBuffer, ReorderBuffer, WindowBuffer,
//   and the arithmetic Core.
//
// 3-Always-Block Architecture:
//   1. State & Counter Registers: always_ff @(posedge clk or posedge rst)
//   2. Next-State Combinational Logic: always_comb
//   3. Output Combinational Logic: always_comb
// =============================================================================

`timescale 1ns/1ps

module controller #(
    parameter int WIDTH_SIZE  = 640,
    parameter int HEIGHT_SIZE = 853,
    parameter int ROWS        = 3,
    parameter int XWIN        = 3,
    parameter int YWIN        = 3
)(
    // Clock and Reset
    input  logic                          clk,
    input  logic                          rst,

    // External Interface Protocol
    input  logic                          start,
    output logic                          ready,
    output logic                          busy,
    output logic                          done,

    // Interface with Core (Datapath Execution)
    input  logic                          gx_sign,      // Sign bit of Gx (reg_Gx[10])
    input  logic                          gy_sign,      // Sign bit of Gy (reg_Gy[10])
    output logic                          xy_ctrl,      // 0: Gx mode, 1: Gy mode
    output logic                          gx_en,        // Gx register write enable
    output logic                          gy_en,        // Gy register write enable
    output logic [1:0]                    xm_ctrl,      // MUX control for X operand (0, 1, 2, 3)
    output logic [1:0]                    ym_ctrl,      // MUX control for Y operand (0, 1, 2, 3)
    output logic                          valid_pixel,  // Strobe: output G is valid

    // Interface with SlidingWindowBuffer & LineBuffer
    output logic                          linebuffer_wenable,
    output logic [$clog2(ROWS)-1:0]       wrow,
    output logic [$clog2(WIDTH_SIZE)-1:0] waddress,
    output logic                          window_shiften,
    output logic [$clog2(ROWS)-1:0]       row_ref,
    output logic [$clog2(WIDTH_SIZE)-1:0] raddress
);

    // =========================================================================
    // Local Parameters & State Definitions
    // =========================================================================
    localparam int COL_WIDTH    = $clog2(WIDTH_SIZE);
    localparam int ROW_WIDTH    = $clog2(ROWS);
    localparam int IMG_R_WIDTH  = $clog2(HEIGHT_SIZE + 1);
    localparam int WIN_C_WIDTH  = $clog2(XWIN);

    typedef enum logic [3:0] {
        S_IDLE        = 4'd0,   // Interface Protocol: Waiting for start
        S_ROW_CHECK   = 4'd1,   // GET DATA: Check if initial 3 rows are loaded
        S_WRITE_COL   = 4'd2,   // GET DATA: Stream row pixels into LineBuffer
        S_LB_FULL     = 4'd3,   // Address Processing: Initial 3 rows buffer full
        S_SET_PREV    = 4'd4,   // Address Processing: col_prev <= col
        S_SHIFT_WIN   = 4'd5,   // Address Processing: Shift 3 columns into WindowBuffer
        S_PREP_EXE    = 4'd6,   // Address Processing: col <= col_prev + 1, prep for EXE
        S_CALC_GX     = 4'd7,   // EXE: Compute Gx
        S_NEG_GX      = 4'd8,   // EXE: Negate Gx if negative
        S_CALC_GY     = 4'd9,   // EXE: Compute Gy
        S_NEG_GY      = 4'd10,  // EXE: Negate Gy if negative
        S_DONE_PIXEL  = 4'd11,  // EXE: Add |Gx| + |Gy|, output valid_pixel
        S_DONE        = 4'd12   // Interface Protocol: Full image processing done
    } state_t;

    state_t current_state, next_state;

    // =========================================================================
    // Internal Registers & Counters
    // =========================================================================
    logic [COL_WIDTH-1:0]   reg_col;         // Column index pointer
    logic [COL_WIDTH-1:0]   reg_col_prev;    // Starting column of current 3x3 window
    logic [ROW_WIDTH:0]     reg_init_row;    // Counter for initial 3 rows (0..3)
    logic [ROW_WIDTH-1:0]   reg_row_ref;     // Top-row pointer for circular buffer alignment
    logic [ROW_WIDTH-1:0]   reg_wrow;        // Physical LineBuffer row being written
    logic [IMG_R_WIDTH-1:0] reg_img_row;     // Total image rows processed (0..HEIGHT_SIZE)
    logic [WIN_C_WIDTH-1:0] reg_window_cnt;  // 3-column shift counter (0..2)
    logic                   reg_initial_done;// Flag indicating initial 3-row load completed

    // Condition Flags (Combinational Status Signals)
    logic co_col;        // Terminal count for column (end of row: col == WIDTH_SIZE - 1)
    logic co_row;        // Terminal count for initial rows (reg_init_row == ROWS)
    logic co_window;     // Terminal count for window shift (reg_window_cnt == XWIN - 1)
    logic co_col_prev;   // Terminal count for row windows (col_prev == WIDTH_SIZE - XWIN)
    logic co_img_row;    // Terminal count for full image (reg_img_row >= HEIGHT_SIZE)

    assign co_col      = (reg_col == (WIDTH_SIZE - 1));
    assign co_row      = (reg_init_row == ROWS);
    assign co_window   = (reg_window_cnt == (XWIN - 1));
    assign co_col_prev = (reg_col_prev >= (WIDTH_SIZE - XWIN));
    assign co_img_row  = (reg_img_row >= HEIGHT_SIZE);

    // =========================================================================
    // Block 1: Sequential Logic (State & Data Registers)
    // Updates current_state, counters, and address pointers
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state    <= S_IDLE;
            reg_col          <= '0;
            reg_col_prev     <= '0;
            reg_init_row     <= '0;
            reg_row_ref      <= '0;
            reg_wrow         <= '0;
            reg_img_row      <= '0;
            reg_window_cnt   <= '0;
            reg_initial_done <= 1'b0;
        end else begin
            current_state <= next_state;

            case (current_state)
                S_IDLE: begin
                    reg_col          <= '0;
                    reg_col_prev     <= '0;
                    reg_init_row     <= '0;
                    reg_row_ref      <= '0;
                    reg_wrow         <= '0;
                    reg_img_row      <= '0;
                    reg_window_cnt   <= '0;
                    reg_initial_done <= 1'b0;
                end

                S_ROW_CHECK: begin
                    reg_col <= '0;
                end

                S_WRITE_COL: begin
                    if (!co_col) begin
                        reg_col <= reg_col + 1'b1;
                    end else begin
                        reg_col <= '0;
                        if (!reg_initial_done) begin
                            // Initial 3-row load phase
                            reg_init_row <= reg_init_row + 1'b1;
                            reg_wrow     <= reg_wrow + 1'b1;
                        end else begin
                            // Subsequent row refill phase (circular buffer shift)
                            reg_wrow    <= (reg_wrow == (ROWS - 1)) ? '0 : (reg_wrow + 1'b1);
                            reg_row_ref <= (reg_row_ref == (ROWS - 1)) ? '0 : (reg_row_ref + 1'b1);
                        end
                    end
                end

                S_LB_FULL: begin
                    reg_col          <= '0;
                    reg_row_ref      <= '0;
                    reg_initial_done <= 1'b1;
                    reg_img_row      <= ROWS; // Initial 3 rows loaded
                end

                S_SET_PREV: begin
                    reg_col_prev   <= reg_col;
                    reg_window_cnt <= '0;
                end

                S_SHIFT_WIN: begin
                    reg_col        <= reg_col + 1'b1;
                    reg_window_cnt <= reg_window_cnt + 1'b1;
                end

                S_PREP_EXE: begin
                    reg_col <= reg_col_prev + 1'b1;
                end

                S_DONE_PIXEL: begin
                    if (co_col_prev) begin
                        reg_img_row <= reg_img_row + 1'b1;
                        reg_col     <= '0;
                    end
                end

                S_DONE: begin
                    // Done state
                end

                default: begin
                    // Retain registers
                end
            endcase
        end
    end

    // =========================================================================
    // Block 2: Next-State Logic (Combinational)
    // Evaluates transitions strictly according to the Huffman FSM model
    // =========================================================================
    always_comb begin
        // Default transition maintains current state to avoid latches
        next_state = current_state;

        case (current_state)
            S_IDLE: begin
                if (start) begin
                    next_state = S_ROW_CHECK;
                end else begin
                    next_state = S_IDLE;
                end
            end

            // GET DATA Phase
            S_ROW_CHECK: begin
                if (!co_row) begin
                    next_state = S_WRITE_COL;
                end else begin
                    next_state = S_LB_FULL;
                end
            end

            S_WRITE_COL: begin
                if (!co_col) begin
                    next_state = S_WRITE_COL;
                end else begin
                    if (!reg_initial_done) begin
                        next_state = S_ROW_CHECK;
                    end else begin
                        next_state = S_SET_PREV;
                    end
                end
            end

            // Address Processing Phase
            S_LB_FULL: begin
                next_state = S_SET_PREV;
            end

            S_SET_PREV: begin
                next_state = S_SHIFT_WIN;
            end

            S_SHIFT_WIN: begin
                if (!co_window) begin
                    next_state = S_SHIFT_WIN;
                end else begin
                    next_state = S_PREP_EXE;
                end
            end

            S_PREP_EXE: begin
                next_state = S_CALC_GX;
            end

            // EXE Phase
            S_CALC_GX: begin
                if (gx_sign) begin
                    next_state = S_NEG_GX;
                end else begin
                    next_state = S_CALC_GY;
                end
            end

            S_NEG_GX: begin
                next_state = S_CALC_GY;
            end

            S_CALC_GY: begin
                if (gy_sign) begin
                    next_state = S_NEG_GY;
                end else begin
                    next_state = S_DONE_PIXEL;
                end
            end

            S_NEG_GY: begin
                next_state = S_DONE_PIXEL;
            end

            S_DONE_PIXEL: begin
                if (!co_col_prev) begin
                    // Next pixel in the current row
                    next_state = S_SET_PREV;
                end else if (!co_img_row) begin
                    // End of row: fetch next row into circular LineBuffer
                    next_state = S_WRITE_COL;
                end else begin
                    // All rows completed
                    next_state = S_DONE;
                end
            end

            S_DONE: begin
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // =========================================================================
    // Block 3: Output Combinational Logic
    // Generates Moore/Mealy outputs with default values to prevent latches
    // =========================================================================
    always_comb begin
        // Safe default assignments
        ready              = 1'b0;
        busy               = 1'b0;
        done               = 1'b0;
        valid_pixel        = 1'b0;

        xy_ctrl            = 1'b0;
        gx_en              = 1'b0;
        gy_en              = 1'b0;
        xm_ctrl            = 2'd0;
        ym_ctrl            = 2'd0;

        linebuffer_wenable = 1'b0;
        window_shiften     = 1'b0;

        wrow               = reg_wrow;
        waddress           = reg_col;
        row_ref            = reg_row_ref;
        raddress           = reg_col;

        case (current_state)
            S_IDLE: begin
                ready = 1'b1;
                busy  = 1'b0;
            end

            S_ROW_CHECK: begin
                busy = 1'b1;
            end

            S_WRITE_COL: begin
                busy               = 1'b1;
                linebuffer_wenable = 1'b1;
                wrow               = reg_wrow;
                waddress           = reg_col;
            end

            S_LB_FULL: begin
                busy    = 1'b1;
                row_ref = 1'b0;
            end

            S_SET_PREV: begin
                busy = 1'b1;
            end

            S_SHIFT_WIN: begin
                busy           = 1'b1;
                window_shiften = 1'b1;
                row_ref        = reg_row_ref;
                raddress       = reg_col;
            end

            S_PREP_EXE: begin
                busy = 1'b1;
            end

            S_CALC_GX: begin
                busy    = 1'b1;
                xy_ctrl = 1'b0;  // X orientation
                gx_en   = 1'b1;  // Load Gx
                xm_ctrl = 2'd0;
                ym_ctrl = 2'd0;
            end

            S_NEG_GX: begin
                busy    = 1'b1;
                gx_en   = 1'b1;  // Reload inverted/negated Gx
                xm_ctrl = 2'd1;
                ym_ctrl = 2'd1;
            end

            S_CALC_GY: begin
                busy    = 1'b1;
                xy_ctrl = 1'b1;  // Y orientation
                gy_en   = 1'b1;  // Load Gy
                xm_ctrl = 2'd0;
                ym_ctrl = 2'd0;
            end

            S_NEG_GY: begin
                busy    = 1'b1;
                gy_en   = 1'b1;  // Reload inverted/negated Gy
                xm_ctrl = 2'd2;
                ym_ctrl = 2'd2;
            end

            S_DONE_PIXEL: begin
                busy        = 1'b1;
                valid_pixel = 1'b1;  // G = |Gx| + |Gy| output is valid
                xm_ctrl     = 2'd3;
                ym_ctrl     = 2'd3;
            end

            S_DONE: begin
                done  = 1'b1;
                ready = 1'b1;
                busy  = 1'b0;
            end

            default: begin
                ready = 1'b0;
                busy  = 1'b0;
                done  = 1'b0;
            end
        endcase
    end

endmodule
