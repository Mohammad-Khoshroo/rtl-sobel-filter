`timescale 1ns/1ps

module tb_controller;

    logic clk;
    logic rst;

    logic start;
    logic ready;
    logic busy;
    logic done;
    logic valid_pixel;

    logic linebuffer_wenable;
    logic window_shiften;
    logic row_pointer;
    logic [9:0] waddress;
    logic [9:0] raddress;

    controller dut (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .ready              (ready),
        .busy               (busy),
        .done               (done),
        .valid_pixel        (valid_pixel),
        .linebuffer_wenable (linebuffer_wenable),
        .window_shiften     (window_shiften),
        .row_pointer        (row_pointer),
        .waddress           (waddress),
        .raddress           (raddress)
    );

    always #5 clk = ~clk;

    int pixel_count;
    int row_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_count <= 0;
            row_count   <= 0;
        end else if (valid_pixel) begin
            pixel_count <= pixel_count + 1;
            if (pixel_count < 5) begin
                $display("[Time %0t] VALID PIXEL #%0d produced (busy=%0d, waddress=%0d, raddress=%0d, row_ptr=%0d)",
                         $time, pixel_count + 1, busy, waddress, raddress, row_pointer);
            end
            if ((pixel_count + 1) % 638 == 0) begin
                row_count <= row_count + 1;
                if ((row_count + 1) % 100 == 0 || row_count == 0 || row_count + 1 == 851) begin
                    $display("[Time %0t] >>> Completed Edge Row %0d / 851! Total pixels = %0d, row_pointer = %0d <<<",
                             $time, row_count + 1, pixel_count + 1, row_pointer);
                end
            end
        end
    end

    // Assertions
    always @(posedge clk) begin
        if (!rst) begin
            // Ready and busy are mutually exclusive
            assert (!(ready && busy)) else $error("[ASSERTION FAILED] Both ready and busy asserted simultaneously!");
            // valid_pixel only when busy is high
            assert (!valid_pixel || busy) else $error("[ASSERTION FAILED] valid_pixel asserted while busy is low!");
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        #20;
        rst = 0;
        #15;

        // Check ready state in IDLE
        assert (ready == 1 && busy == 0) else $error("Controller not ready in IDLE!");

        // Start pulse
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait until streaming starts
        wait(valid_pixel);
        $display("[Time %0t] First valid pixel detected!", $time);

        // Wait until done
        wait(done);
        $display("[Time %0t] Controller asserted DONE!", $time);
        assert (busy == 0) else $error("Busy still asserted during DONE!");

        // In cycle after done, controller returns to IDLE (ready == 1)
        @(posedge clk);
        #1;
        assert (ready == 1 && busy == 0) else $error("Controller not ready after done!");

        $display("SUCCESS: Entire image processed! Total valid pixels = %0d, Total edge rows = %0d", pixel_count, row_count);
        assert (pixel_count == 542938) else $error("Incorrect pixel count! Expected 542938, got %0d", pixel_count);
        assert (row_count == 851) else $error("Incorrect row count! Expected 851, got %0d", row_count);

        #100;
        $finish;
    end

endmodule
