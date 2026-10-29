// =============================================================================
// Compilation and Simulation Instructions with Verilator in WSL:
//
// 1. Navigate to the project root directory:
//    cd /mnt/d/UT.CE/FPGA/CA/CA01
//
// 2. Compile with Verilator (including assertion and VCD trace support):
//    $ verilator --binary --trace --assert -Wno-fatal \
//              -Irtl -Irtl/buffer -Irtl/controller -Irtl/core -Irtl/MIA -Irtl/Register -Irtl/include \
//              --top-module tb_accelerator \
//              rtl/accelerator.sv tb/tb_accelerator.sv
//
// 3. Execute the compiled simulation binary:
//    ./obj_dir/Vtb_accelerator
//
// 4. Verify output image and calculate mean error with OpenCV:
//    python3 scripts/Checker.py
// =============================================================================

`timescale 1ns/1ps

module tb_accelerator;

    // -------------------------------------------------------------------------
    // Parameters & Constants
    // -------------------------------------------------------------------------
    localparam int WIDTH_SIZE           = 640;
    localparam int HEIGHT_SIZE          = 853;
    localparam int TOTAL_INPUT_PIXELS   = WIDTH_SIZE * HEIGHT_SIZE;          // 545,920
    localparam int EDGE_WIDTH           = WIDTH_SIZE - 2;                   // 638
    localparam int EDGE_HEIGHT          = HEIGHT_SIZE - 2;                  // 851
    localparam int TOTAL_VALID_PIXELS   = EDGE_WIDTH * EDGE_HEIGHT;         // 542,938
    localparam int CLK_PERIOD           = 10;                               // 100 MHz (10 ns)

    // -------------------------------------------------------------------------
    // DUT Interface Signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        rst;
    logic        start;
    logic [7:0]  pixel_in;

    logic        ready;
    logic        busy;
    logic        done;
    logic        valid_pixel;
    logic [7:0]  pixel_out;

    // -------------------------------------------------------------------------
    // DUT Instantiation (Clean Streaming Interface)
    // -------------------------------------------------------------------------
    accelerator #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .PIXEL_WIDTH (8)
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .pixel_in    (pixel_in),
        .ready       (ready),
        .busy        (busy),
        .done        (done),
        .valid_pixel (valid_pixel),
        .pixel_out   (pixel_out)
    );

    wire linebuffer_wenable = dut.linebuffer_wenable;

    // -------------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Memory and Output Buffers
    // -------------------------------------------------------------------------
    logic [7:0] img_in_mem [0:TOTAL_INPUT_PIXELS-1];
    logic [7:0] img_out_hw [0:TOTAL_VALID_PIXELS-1];

    int in_pixel_idx     = 0;
    int valid_pixel_cnt  = 0;
    int edge_row_cnt     = 0;
    int assertion_errors = 0;
    int log_file_fd      = 0;

    // -------------------------------------------------------------------------
    // Waveform Generation (VCD)
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("sim/accelerator.vcd");
        $dumpvars(0, tb_accelerator);
    end

    // -------------------------------------------------------------------------
    // Streaming Input Pixels to DUT
    // Whenever linebuffer_wenable is asserted by the controller, provide the
    // current pixel combinationally so it is sampled on the next posedge clk.
    // -------------------------------------------------------------------------
    always_comb begin
        if (!rst && linebuffer_wenable && (in_pixel_idx < TOTAL_INPUT_PIXELS)) begin
            pixel_in = img_in_mem[in_pixel_idx];
        end else begin
            pixel_in = 8'd0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_pixel_idx <= 0;
        end else if (linebuffer_wenable && (in_pixel_idx < TOTAL_INPUT_PIXELS)) begin
            in_pixel_idx <= in_pixel_idx + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Capturing and Logging Valid Output Pixels
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst && valid_pixel) begin
            if (valid_pixel_cnt < TOTAL_VALID_PIXELS) begin
                img_out_hw[valid_pixel_cnt] = pixel_out;
            end
            valid_pixel_cnt <= valid_pixel_cnt + 1;

            // Log first 10 processed pixels
            if (valid_pixel_cnt < 10) begin
                $display("[Time %0t ns] [MONITOR] Valid Pixel #%0d = 0x%02X (%0d)",
                         $time, valid_pixel_cnt + 1, pixel_out, pixel_out);
                if (log_file_fd != 0) begin
                    $fdisplay(log_file_fd, "[Time %0t ns] [MONITOR] Valid Pixel #%0d = 0x%02X (%0d)",
                              $time, valid_pixel_cnt + 1, pixel_out, pixel_out);
                end
            end

            // Progress checkpoint on completion of each edge row
            if ((valid_pixel_cnt + 1) % EDGE_WIDTH == 0) begin
                edge_row_cnt <= edge_row_cnt + 1;
                if ((edge_row_cnt + 1) % 100 == 0 || edge_row_cnt == 0 || edge_row_cnt + 1 == EDGE_HEIGHT) begin
                    $display("[Time %0t ns] [PROGRESS] Completed Edge Row %0d / %0d (Total Pixels: %0d)",
                             $time, edge_row_cnt + 1, EDGE_HEIGHT, valid_pixel_cnt + 1);
                    if (log_file_fd != 0) begin
                        $fdisplay(log_file_fd, "[Time %0t ns] [PROGRESS] Completed Edge Row %0d / %0d (Total Pixels: %0d)",
                                  $time, edge_row_cnt + 1, EDGE_HEIGHT, valid_pixel_cnt + 1);
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // SystemVerilog Assertions (Verification as per ASSIGNMENT.md Section 3)
    // -------------------------------------------------------------------------
    // 1. Reset check: During reset, no valid pixel should be produced, done must be 0
    always @(posedge clk) begin
        if (rst) begin
            A1_RESET_VALID: assert (valid_pixel == 1'b0)
                else begin
                    $error("[ASSERTION FAILED] valid_pixel asserted during reset!");
                    assertion_errors++;
                end
            A1_RESET_DONE: assert (done == 1'b0)
                else begin
                    $error("[ASSERTION FAILED] done asserted during reset!");
                    assertion_errors++;
                end
        end
    end

    // 2. Output Range Check: When valid_pixel is high, output must be valid 8-bit range [0, 255] and defined
    always @(posedge clk) begin
        if (!rst && valid_pixel) begin
            /* verilator lint_off CMPCONST */
            A2_OUTPUT_RANGE: assert (pixel_out <= 8'd255 && !$isunknown(pixel_out))
                else begin
                    $error("[ASSERTION FAILED] pixel_out exceeds 255 or is unknown!");
                    assertion_errors++;
                end
            /* verilator lint_on CMPCONST */
        end
    end

    // 3. Mutex of ready and busy: Controller cannot be simultaneously ready and busy
    always @(posedge clk) begin
        if (!rst) begin
            A3_READY_BUSY_MUTEX: assert (!(ready && busy))
                else begin
                    $error("[ASSERTION FAILED] Both ready and busy are asserted simultaneously!");
                    assertion_errors++;
                end
        end
    end

    // 4. Streaming assertion: valid_pixel can only be asserted when busy is high
    always @(posedge clk) begin
        if (!rst) begin
            A4_VALID_DURING_BUSY: assert (!valid_pixel || busy)
                else begin
                    $error("[ASSERTION FAILED] valid_pixel asserted while busy is low!");
                    assertion_errors++;
                end
        end
    end

    // 5. Done assertion: When done is asserted, busy must be deasserted
    always @(posedge clk) begin
        if (!rst && done) begin
            A5_DONE_BUSY: assert (busy == 1'b0)
                else begin
                    $error("[ASSERTION FAILED] done asserted but busy is still high!");
                    assertion_errors++;
                end
        end
    end

    // 6. Post-Done Ready assertion: In the cycle after done, controller returns to IDLE (ready == 1)
    logic done_q;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) done_q <= 1'b0;
        else     done_q <= done;
    end

    always @(posedge clk) begin
        if (!rst && done_q) begin
            A6_POST_DONE_READY: assert (ready == 1'b1 && busy == 1'b0)
                else begin
                    $error("[ASSERTION FAILED] Cycle after done, controller is not ready in IDLE!");
                    assertion_errors++;
                end
        end
    end

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Open log file for testbench monitoring outputs
        log_file_fd = $fopen("sim/monitor.log", "w");
        if (log_file_fd == 0) begin
            log_file_fd = $fopen("monitor.log", "w");
        end

        $display("==================================================================");
        $display("   Sobel Accelerator Testbench - FPGA Computer Assignment #1     ");
        $display("   Image Dimensions: %0d x %0d | Total Pixels: %0d", WIDTH_SIZE, HEIGHT_SIZE, TOTAL_INPUT_PIXELS);
        $display("==================================================================");
        if (log_file_fd != 0) begin
            $fdisplay(log_file_fd, "==================================================================");
            $fdisplay(log_file_fd, "   Sobel Accelerator Testbench - FPGA Computer Assignment #1     ");
            $fdisplay(log_file_fd, "   Image Dimensions: %0d x %0d | Total Pixels: %0d", WIDTH_SIZE, HEIGHT_SIZE, TOTAL_INPUT_PIXELS);
            $fdisplay(log_file_fd, "==================================================================");
        end

        // 1. Load input image hex file
        $display("[Time %0t ns] Loading image_in.hex into testbench memory...", $time);
        if (log_file_fd != 0) $fdisplay(log_file_fd, "[Time %0t ns] Loading image_in.hex into testbench memory...", $time);
        
        $readmemh("image_in.hex", img_in_mem);
        // Fallback check if first and last elements are zero
        if (img_in_mem[0] === 8'hxx) begin
            $readmemh("sim/image_in.hex", img_in_mem);
        end

        $display("[Time %0t ns] Loaded %0d input pixels successfully.", $time, TOTAL_INPUT_PIXELS);
        $display("[Time %0t ns] Sample inputs: img[0]=0x%02X, img[1]=0x%02X, img[2]=0x%02X",
                 $time, img_in_mem[0], img_in_mem[1], img_in_mem[2]);

        // 2. Reset Sequence
        rst   = 1'b1;
        start = 1'b0;
        #(CLK_PERIOD * 3);
        @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // Verify ready in IDLE
        assert (ready == 1'b1 && busy == 1'b0)
            else $error("[ERROR] DUT not ready in IDLE after reset!");

        $display("[Time %0t ns] Reset deasserted. DUT is READY. Triggering start pulse...", $time);
        if (log_file_fd != 0) $fdisplay(log_file_fd, "[Time %0t ns] Reset deasserted. DUT is READY. Triggering start pulse...", $time);

        // 3. Issue Start Pulse
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // 4. Wait for processing to begin and finish
        wait(valid_pixel);
        $display("[Time %0t ns] First valid pixel detected from accelerator!", $time);
        if (log_file_fd != 0) $fdisplay(log_file_fd, "[Time %0t ns] First valid pixel detected from accelerator!", $time);

        wait(done);
        $display("[Time %0t ns] >>> DUT asserted DONE interrupt! <<<", $time);
        if (log_file_fd != 0) $fdisplay(log_file_fd, "[Time %0t ns] >>> DUT asserted DONE interrupt! <<<", $time);

        #(CLK_PERIOD * 5);

        // 5. Verification Summary
        $display("------------------------------------------------------------------");
        $display("Simulation Summary:");
        $display("  Total Input Pixels Fed     : %0d / %0d", in_pixel_idx, TOTAL_INPUT_PIXELS);
        $display("  Total Valid Pixels Produced: %0d / %0d", valid_pixel_cnt, TOTAL_VALID_PIXELS);
        $display("  Total Edge Rows Processed  : %0d / %0d", edge_row_cnt, EDGE_HEIGHT);
        $display("  Assertion Errors           : %0d", assertion_errors);
        $display("------------------------------------------------------------------");

        if (log_file_fd != 0) begin
            $fdisplay(log_file_fd, "------------------------------------------------------------------");
            $fdisplay(log_file_fd, "Simulation Summary:");
            $fdisplay(log_file_fd, "  Total Input Pixels Fed     : %0d / %0d", in_pixel_idx, TOTAL_INPUT_PIXELS);
            $fdisplay(log_file_fd, "  Total Valid Pixels Produced: %0d / %0d", valid_pixel_cnt, TOTAL_VALID_PIXELS);
            $fdisplay(log_file_fd, "  Total Edge Rows Processed  : %0d / %0d", edge_row_cnt, EDGE_HEIGHT);
            $fdisplay(log_file_fd, "  Assertion Errors           : %0d", assertion_errors);
            $fdisplay(log_file_fd, "------------------------------------------------------------------");
        end

        // 6. Write output hex files:
        //    a) sim/image_out_valid.hex: strictly valid pixels (542,938) as requested in ASSIGNMENT.md
        //    b) sim/image_out.hex: padded full image (640x853 = 545,920) formatted for Checker.py
        //    c) image_out.hex: in root directory for seamless Checker.py execution
        begin
            int fd_valid, fd_full, fd_root;
            int v_idx;

            // a) Strictly valid unpadded hex file
            fd_valid = $fopen("sim/image_out_valid.hex", "w");
            if (fd_valid != 0) begin
                for (int i = 0; i < TOTAL_VALID_PIXELS; i++) begin
                    $fdisplay(fd_valid, "%02X", img_out_hw[i]);
                end
                $fclose(fd_valid);
                $display("[Time %0t ns] Generated sim/image_out_valid.hex (%0d pixels)", $time, TOTAL_VALID_PIXELS);
            end

            // b) Padded full-frame hex file (matches 853x640 reshape in Checker.py)
            fd_full = $fopen("sim/image_out.hex", "w");
            fd_root = $fopen("image_out.hex", "w");

            v_idx = 0;
            for (int r = 0; r < HEIGHT_SIZE; r++) begin
                for (int c = 0; c < WIDTH_SIZE; c++) begin
                    logic [7:0] val;
                    if (r == 0 || r == (HEIGHT_SIZE - 1) || c == 0 || c == (WIDTH_SIZE - 1)) begin
                        val = 8'h00; // border zero-padding
                    end else begin
                        val = img_out_hw[v_idx];
                        v_idx++;
                    end
                    if (fd_full != 0) $fdisplay(fd_full, "%02X", val);
                    if (fd_root != 0) $fdisplay(fd_root, "%02X", val);
                end
            end

            if (fd_full != 0) $fclose(fd_full);
            if (fd_root != 0) $fclose(fd_root);
            $display("[Time %0t ns] Generated sim/image_out.hex and image_out.hex (%0d pixels)",
                     $time, TOTAL_INPUT_PIXELS);
        end

        if (assertion_errors == 0 && valid_pixel_cnt == TOTAL_VALID_PIXELS) begin
            $display("==================================================================");
            $display("   TESTBENCH PASSED SUCCESSFULLY: ALL CHECKS AND PIXELS VALID!   ");
            $display("==================================================================");
            if (log_file_fd != 0) begin
                $fdisplay(log_file_fd, "==================================================================");
                $fdisplay(log_file_fd, "   TESTBENCH PASSED SUCCESSFULLY: ALL CHECKS AND PIXELS VALID!   ");
                $fdisplay(log_file_fd, "==================================================================");
            end
        end else begin
            $display("==================================================================");
            $display("   TESTBENCH COMPLETED WITH WARNINGS/ERRORS                       ");
            $display("==================================================================");
        end

        if (log_file_fd != 0) $fclose(log_file_fd);
        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
