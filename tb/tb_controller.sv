`timescale 1ns/1ps

module tb_controller;

    localparam int WIDTH_SIZE  = 8;   // Small test size for fast simulation
    localparam int HEIGHT_SIZE = 5;
    localparam int ROWS        = 3;
    localparam int XWIN        = 3;
    localparam int YWIN        = 3;

    logic clk;
    logic rst;

    logic start;
    logic ready;
    logic busy;
    logic done;

    logic gx_sign;
    logic gy_sign;
    logic xy_ctrl;
    logic gx_en;
    logic gy_en;
    logic [1:0] xm_ctrl;
    logic [1:0] ym_ctrl;
    logic valid_pixel;

    logic linebuffer_wenable;
    logic [$clog2(ROWS)-1:0] wrow;
    logic [$clog2(WIDTH_SIZE)-1:0] waddress;
    logic window_shiften;
    logic [$clog2(ROWS)-1:0] row_ref;
    logic [$clog2(WIDTH_SIZE)-1:0] raddress;

    controller #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .ROWS        (ROWS),
        .XWIN        (XWIN),
        .YWIN        (YWIN)
    ) dut (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .ready              (ready),
        .busy               (busy),
        .done               (done),
        .gx_sign            (gx_sign),
        .gy_sign            (gy_sign),
        .xy_ctrl            (xy_ctrl),
        .gx_en              (gx_en),
        .gy_en              (gy_en),
        .xm_ctrl            (xm_ctrl),
        .ym_ctrl            (ym_ctrl),
        .valid_pixel        (valid_pixel),
        .linebuffer_wenable (linebuffer_wenable),
        .wrow               (wrow),
        .waddress           (waddress),
        .window_shiften     (window_shiften),
        .row_ref            (row_ref),
        .raddress           (raddress)
    );

    always #5 clk = ~clk;

    int pixel_count = 0;

    always @(posedge clk) begin
        if (valid_pixel) begin
            pixel_count++;
            $display("[Time %0t] VALID PIXEL #%0d produced (xm_ctrl=%0d, ym_ctrl=%0d)", $time, pixel_count, xm_ctrl, ym_ctrl);
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        gx_sign = 0;
        gy_sign = 0;

        #20;
        rst = 0;
        #15;

        // Check ready state
        assert (ready == 1 && busy == 0) else $error("Controller not ready in IDLE!");

        // Start pulse
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Alternate sign bits to test negative branching
        fork
            begin
                while (!done) begin
                    @(posedge clk);
                    if (gx_en && !xy_ctrl) begin
                        gx_sign <= ~gx_sign; // Toggle sign
                    end
                    if (gy_en && xy_ctrl) begin
                        gy_sign <= ~gy_sign; // Toggle sign
                    end
                end
            end
            begin
                // Wait for done or timeout
                wait(done);
                $display("Controller finished successfully! Total valid pixels = %0d", pixel_count);
                #20;
                $finish;
            end
            begin
                #20000;
                $error("Simulation timed out!");
                $finish;
            end
        join_any

    end

endmodule
