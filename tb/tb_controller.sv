`timescale 1ns/1ps

module tb_controller;

    logic clk;
    logic rst;

    logic start;
    logic ready;
    logic busy;
    logic busy_load;
    logic busy_process;
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
    logic window_shiften;
    logic [1:0] row_pointer;
    logic [9:0] waddress;
    logic [9:0] raddress;

    controller dut (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .ready              (ready),
        .busy               (busy),
        .busy_load          (busy_load),
        .busy_process       (busy_process),
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
        .window_shiften     (window_shiften),
        .row_pointer        (row_pointer),
        .waddress           (waddress),
        .raddress           (raddress)
    );

    always #5 clk = ~clk;

    int pixel_count = 0;

    always @(posedge clk) begin
        if (valid_pixel) begin
            pixel_count++;
            if (pixel_count <= 10) begin
                $display("[Time %0t] VALID PIXEL #%0d produced (busy_process=%0d, waddress=%0d, raddress=%0d, xm_ctrl=%0d, ym_ctrl=%0d)",
                         $time, pixel_count, busy_process, waddress, raddress, xm_ctrl, ym_ctrl);
            end
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

        // Toggle sign bits to test negative branching
        fork
            begin
                while (!done) begin
                    @(posedge clk);
                    if (gx_en && !xy_ctrl) begin
                        gx_sign <= ~gx_sign;
                    end
                    if (gy_en && xy_ctrl) begin
                        gy_sign <= ~gy_sign;
                    end
                end
            end
            begin
                // Simulate until first row is fully processed
                wait(valid_pixel);
                $display("First valid pixel detected at time %0t!", $time);
                wait(pixel_count == 638);
                $display("First full row of pixels processed! Total pixels so far = %0d", pixel_count);
                #100;
                $finish;
            end
            begin
                #500000;
                $display("Reached simulation check time limit. Pixels = %0d", pixel_count);
                $finish;
            end
        join_any

    end

endmodule
