// =============================================================================
// Compilation and Simulation Instructions with Verilator in WSL:
//
// 1. Navigate to the project root directory:
//    cd /mnt/d/UT.CE/FPGA/CA/CA01
//
// 2. Compile pipelined testbench with Verilator:
//    $ verilator --binary --trace --assert -Wno-fatal \
//              -Irtl -Irtl/pipeline -Irtl/include \
//              -Isva/pipeline \
//              --top-module tb_accelerator_pipeline \
//              tb/pipeline/tb_accelerator_pipeline.sv \
//              rtl/pipeline/accelerator_pipeline.sv \
//              rtl/include/Register.sv \
//              rtl/include/CSA.sv
//
// 3. Execute the compiled simulation binary:
//    ./obj_dir/Vtb_accelerator_pipeline
//
// 4. Verify output image:
//    python3 scripts/verify_all.py
// =============================================================================

`timescale 1ns/1ps

`include "accelerator_pipeline.sv"
`include "LineBuffer_pipeline_sva.sv"
`include "ReorderBuffer_pipeline_sva.sv"
`include "WindowBuffer_pipeline_sva.sv"
`include "SlidingWindowBuffer_pipeline_sva.sv"
`include "controller_pipeline_sva.sv"
`include "core_pipeline_sva.sv"
`include "accelerator_pipeline_sva.sv"

module tb_accelerator_pipeline;

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
    // DUT Instantiation
    // -------------------------------------------------------------------------
    accelerator_pipeline #(
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

    // -------------------------------------------------------------------------
    // SVA Checker Bind Statements for Pipelined Architecture
    // -------------------------------------------------------------------------
    bind LineBuffer_pipeline LineBuffer_pipeline_sva #(
        .WIDTH (WIDTH),
        .ROWS  (ROWS),
        .SIZE  (SIZE)
    ) u_line_buffer_sva (
        .clk      (clk),
        .rst      (rst),
        .wdata    (wdata),
        .wenable  (wenable),
        .wrow     (wrow),
        .waddress (waddress),
        .raddress (raddress),
        .rdata    (rdata)
    );

    bind ReorderBuffer_pipeline ReorderBuffer_pipeline_sva #(
        .WIDTH (WIDTH),
        .ROWS  (ROWS),
        .YWIN  (YWIN)
    ) u_reorder_buffer_sva (
        .row_ref     (row_ref),
        .raw_col     (raw_col),
        .live_pixel  (live_pixel),
        .ordered_col (ordered_col)
    );

    bind WindowBuffer_pipeline WindowBuffer_pipeline_sva #(
        .WIDTH (WIDTH),
        .XWIN  (XWIN),
        .YWIN  (YWIN)
    ) u_window_buffer_sva (
        .clk        (clk),
        .rst        (rst),
        .shift_en   (shift_en),
        .col_in     (col_in),
        .window_out (window_out)
    );

    bind SlidingWindowBuffer_pipeline SlidingWindowBuffer_pipeline_sva #(
        .WIDTH (WIDTH),
        .ROWS  (ROWS),
        .SIZE  (SIZE),
        .XWIN  (XWIN),
        .YWIN  (YWIN)
    ) u_sliding_window_buffer_sva (
        .clk      (clk),
        .rst      (rst),
        .wenable  (wenable),
        .wdata    (wdata),
        .wrow     (wrow),
        .waddress (waddress),
        .renable  (renable),
        .rrow     (rrow),
        .raddress (raddress),
        .rdata    (rdata)
    );

    bind controller_pipeline controller_pipeline_sva #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE)
    ) u_controller_sva (
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

    bind core_pipeline core_pipeline_sva u_core_sva (
        .clk       (clk),
        .rst       (rst),
        .shift_en  (shift_en),
        .window    (window),
        .G_sat_reg (G_sat_reg)
    );

    bind accelerator_pipeline accelerator_pipeline_sva #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .PIXEL_WIDTH (PIXEL_WIDTH)
    ) u_accelerator_sva (
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

    // -------------------------------------------------------------------------
    // Continuous Input Feeding Logic
    // -------------------------------------------------------------------------
    always_comb begin
        if (!rst && busy && (in_pixel_idx < TOTAL_INPUT_PIXELS)) begin
            pixel_in = img_in_mem[in_pixel_idx];
        end else begin
            pixel_in = 8'd0;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            in_pixel_idx <= 0;
        end else if (busy && (in_pixel_idx < TOTAL_INPUT_PIXELS)) begin
            in_pixel_idx <= in_pixel_idx + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Output Harvesting
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst && valid_pixel) begin
            if (valid_pixel_cnt < TOTAL_VALID_PIXELS) begin
                img_out_hw[valid_pixel_cnt] <= pixel_out;
            end
            valid_pixel_cnt <= valid_pixel_cnt + 1;

            if (valid_pixel_cnt < 10) begin
                $display("[Time %0t ns] [PIPELINE] Valid Pixel #%0d = 0x%02X (%0d)",
                         $time, valid_pixel_cnt + 1, pixel_out, pixel_out);
            end

            if ((valid_pixel_cnt + 1) % EDGE_WIDTH == 0) begin
                edge_row_cnt <= edge_row_cnt + 1;
                if ((edge_row_cnt + 1) % 100 == 0 || edge_row_cnt == 0 || edge_row_cnt + 1 == EDGE_HEIGHT) begin
                    $display("[Time %0t ns] [PIPELINE PROGRESS] Edge Row %0d / %0d (Pixels: %0d)",
                             $time, edge_row_cnt + 1, EDGE_HEIGHT, valid_pixel_cnt + 1);
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        string in_hex_path;
        int check_fd;

        $display("==================================================================");
        $display("   Sobel Pipeline Accelerator Testbench with SVA Verification    ");
        $display("   Image Dimensions: %0d x %0d | Total Pixels: %0d", WIDTH_SIZE, HEIGHT_SIZE, TOTAL_INPUT_PIXELS);
        $display("==================================================================");

        check_fd = $fopen("image_in.hex", "r");
        if (check_fd != 0) begin
            $fclose(check_fd);
            in_hex_path = "image_in.hex";
        end else begin
            check_fd = $fopen("inputs/input1/image_in.hex", "r");
            if (check_fd != 0) begin
                $fclose(check_fd);
                in_hex_path = "inputs/input1/image_in.hex";
            end else begin
                in_hex_path = "sim/input1/image_in.hex";
            end
        end

        $display("[INFO] Loading input image hex from: %s ...", in_hex_path);
        $readmemh(in_hex_path, img_in_mem);
        $display("[INFO] Successfully loaded %0d input pixels.", TOTAL_INPUT_PIXELS);

        // Reset Sequence
        rst   = 1'b1;
        start = 1'b0;
        #(CLK_PERIOD * 3);
        @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // Issue Start Pulse
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait(valid_pixel);
        $display("[Time %0t ns] First valid pixel detected!", $time);

        wait(done);
        $display("[Time %0t ns] DUT asserted DONE interrupt!", $time);

        #(CLK_PERIOD * 5);

        $display("------------------------------------------------------------------");
        $display("Pipeline Simulation Complete:");
        $display("  Total Input Pixels Fed     : %0d / %0d", in_pixel_idx, TOTAL_INPUT_PIXELS);
        $display("  Total Valid Pixels Produced: %0d / %0d", valid_pixel_cnt, TOTAL_VALID_PIXELS);
        $display("------------------------------------------------------------------");

        // Save output hex
        begin
            int fd;
            fd = $fopen("sim/image_out_pipeline.hex", "w");
            if (fd != 0) begin
                for (int i = 0; i < TOTAL_VALID_PIXELS; i++) begin
                    $fdisplay(fd, "%02x", img_out_hw[i]);
                end
                $fclose(fd);
                $display("Saved pipeline hex output to sim/image_out_pipeline.hex");
            end
        end

        $finish;
    end

endmodule
