`timescale 1ns/1ps

module controller_baseline (
    input clk,
    input rst,

    input start,
    output logic ready,
    output logic busy,
    output logic busy_load,
    output logic busy_process,
    output logic done,

    input gx_sign, gy_sign,
    output logic gx_en, gy_en,
    output logic xy_ctrl,        // 0: Gx mode, 1: Gy mode
    output logic [1:0] xm_ctrl, ym_ctrl,

    output logic       valid_pixel,

    output logic       linebuffer_wenable,
    output logic       window_shiften,

    output logic [1:0] row_pointer,
    output logic [9:0] waddress,
    output logic [9:0] raddress
);

    localparam WIDTH_SIZE  = 640;
    localparam HEIGHT_SIZE = 853;

    typedef enum logic [3:0] {
        IDLE         = 4'd0,
        // DATA
        LOAD_CHECK   = 4'd1,
        LOAD_ROW     = 4'd2,
        PREPARE_WIN  = 4'd3,
        // EXE
        CALC_GX      = 4'd4,
        NEG_GX       = 4'd5,
        CALC_GY      = 4'd6,
        NEG_GY       = 4'd7,
        DONE_PIXEL   = 4'd8,
        DONE         = 4'd9
    } state_t;

    state_t current_state, next_state;

    logic [9:0] row;
    logic [9:0] col;

    wire is_load_last = (current_state == LOAD_ROW) && co_wcol;
    assign waddress = col;
    assign raddress = is_load_last                  ? 10'd0 :
                      (current_state == PREPARE_WIN) ? ((col + 10'd1 >= WIDTH_SIZE) ? (WIDTH_SIZE - 10'd1) : (col + 10'd1)) :
                      (col >= WIDTH_SIZE)            ? (WIDTH_SIZE - 10'd1) : col;

    logic co_wcol;
    logic co_rcol;
    logic co_row;

    assign co_wcol       = (col == (WIDTH_SIZE - 1));
    assign co_rcol       = (col == WIDTH_SIZE);
    assign co_row        = (row >= HEIGHT_SIZE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            col         <= 10'd0;
            row         <= 10'd0;
            row_pointer <= 2'd0;
        end else begin
            case (current_state)
                
                IDLE: begin
                    col         <= 10'd0;
                    row         <= 10'd0;
                    row_pointer <= 2'd0;
                end

                LOAD_CHECK: begin
                    col <= 10'd0;
                end

                LOAD_ROW: begin
                    if (!co_wcol) begin
                        col <= col + 10'd1;
                    end else begin
                        col <= 10'd0;
                        row <= row + 10'd1;
                        row_pointer <= (row_pointer == 2'd2) ? 2'd0 : (row_pointer + 2'd1);
                    end
                end

                PREPARE_WIN: begin
                    col <= col + 10'd1;
                end

                DONE_PIXEL: begin
                    if (co_rcol) begin
                        col <= 10'd0;
                    end
                end
                
                default: begin end
            
            endcase
        end
    end

    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD_CHECK;
                end else begin
                    next_state = IDLE;
                end
            end

            LOAD_CHECK: begin
                if (row < 3) begin
                    next_state = LOAD_ROW;
                end else begin
                    next_state = PREPARE_WIN;
                end
            end

            LOAD_ROW: begin
                if (!co_wcol) begin
                    next_state = LOAD_ROW;
                end else begin
                    if (row < 10'd2) begin
                        next_state = LOAD_CHECK;
                    end else begin
                        next_state = PREPARE_WIN;
                    end
                end
            end

            PREPARE_WIN: begin
                if (col < 10'd2) begin
                    next_state = PREPARE_WIN;
                end else begin
                    next_state = CALC_GX;
                end
            end

            CALC_GX: begin
                if (gx_sign) begin
                    next_state = NEG_GX;
                end else begin
                    next_state = CALC_GY;
                end
            end

            NEG_GX: begin
                next_state = CALC_GY;
            end

            CALC_GY: begin
                if (gy_sign) begin
                    next_state = NEG_GY;
                end else begin
                    next_state = DONE_PIXEL;
                end
            end

            NEG_GY: begin
                next_state = DONE_PIXEL;
            end

            DONE_PIXEL: begin
                if (!co_rcol) begin
                    next_state = PREPARE_WIN;
                end else if (!co_row) begin
                    next_state = LOAD_ROW;
                end else begin
                    next_state = DONE;
                end
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
        ready              = 1'b0;
        busy               = 1'b0;
        busy_load          = 1'b0;
        busy_process       = 1'b0;
        done               = 1'b0;
        valid_pixel        = 1'b0;

        xy_ctrl            = 1'b0;
        gx_en              = 1'b0;
        gy_en              = 1'b0;
        xm_ctrl            = 2'd0;
        ym_ctrl            = 2'd0;

        linebuffer_wenable = 1'b0;
        window_shiften     = 1'b0;

        case (current_state)
            IDLE: begin
                ready        = 1'b1;
                busy         = 1'b0;
                busy_load    = 1'b0;
                busy_process = 1'b0;
            end

            LOAD_CHECK: begin
                busy         = 1'b1;
                busy_load    = 1'b1;
                busy_process = 1'b0;
            end

            LOAD_ROW: begin
                busy               = 1'b1;
                busy_load          = 1'b1;
                busy_process       = 1'b0;
                linebuffer_wenable = 1'b1;
            end

            PREPARE_WIN: begin
                busy           = 1'b1;
                busy_load      = 1'b0;
                busy_process   = 1'b1;
                window_shiften = 1'b1;
            end

            CALC_GX: begin
                busy         = 1'b1;
                busy_load    = 1'b0;
                busy_process = 1'b1;
                xy_ctrl      = 1'b0;  // X
                gx_en        = 1'b1;  // update Gx
                xm_ctrl      = 2'd0;
                ym_ctrl      = 2'd0;
            end

            NEG_GX: begin
                busy         = 1'b1;
                busy_load    = 1'b0;
                busy_process = 1'b1;
                gx_en        = 1'b1;  // update Gx with abs
                xm_ctrl      = 2'd1;
                ym_ctrl      = 2'd1;
            end

            CALC_GY: begin
                busy         = 1'b1;
                busy_load    = 1'b0;
                busy_process = 1'b1;
                xy_ctrl      = 1'b1;  // Y
                gy_en        = 1'b1;  // update Gy
                xm_ctrl      = 2'd0;
                ym_ctrl      = 2'd0;
            end

            NEG_GY: begin
                busy         = 1'b1;
                busy_load    = 1'b0;
                busy_process = 1'b1;
                gy_en        = 1'b1;  // update Gy with abs
                xm_ctrl      = 2'd2;
                ym_ctrl      = 2'd2;
            end

            DONE_PIXEL: begin
                busy         = 1'b1;
                busy_load    = 1'b0;
                busy_process = 1'b1;
                valid_pixel  = 1'b1;
                xm_ctrl      = 2'd3;
                ym_ctrl      = 2'd3;
            end

            DONE: begin
                done         = 1'b1;
                ready        = 1'b1;
                busy         = 1'b0;
                busy_load    = 1'b0;
                busy_process = 1'b0;
            end

            default: begin
                ready        = 1'b0;
                busy         = 1'b0;
                busy_load    = 1'b0;
                busy_process = 1'b0;
                done         = 1'b0;
            end
        endcase
    end

endmodule
