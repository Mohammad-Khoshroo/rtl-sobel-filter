// =============================================================================
// Compilation and Simulation Instructions with Verilator in WSL:
//
// Method 1: Single-command automated run (Compile, Simulate & Verify with OpenCV):
//    $ bash scripts/run_comparison.sh
//
// Method 2: Manual step-by-step commands:
//    1. Navigate to the project root directory:
//       cd /mnt/d/UT.CE/FPGA/CA/CA01
//
//    2. Compile comparison testbench and all 3 architectures with Verilator:
//       $ verilator --binary --assert -Wno-fatal \
//                 -Irtl -Irtl/baseline -Irtl/optimized -Irtl/pipeline \
//                 -Irtl/include \
//                 -Isva -Isva/baseline -Isva/optimized -Isva/pipeline \
//                 --top-module tb_comparison \
//                 tb/compare/tb_comparison.sv \
//                 rtl/baseline/accelerator_baseline.sv \
//                 rtl/optimized/accelerator_optimized.sv \
//                 rtl/pipeline/accelerator_pipeline.sv \
//                 rtl/include/Register.sv \
//                 rtl/include/CSA.sv
//
//    3. Run the compiled simulation binary:
//       $ ./obj_dir/Vtb_comparison
//
//    4. Verify images with OpenCV and display accuracy metrics:
//       $ python3 scripts/verify_all.py
// =============================================================================
// Comprehensive Comparison Testbench for Sobel Accelerator Architectures
// Compares:
//   1. Baseline Architecture  (Multi-cycle FSM, 3 LineBuffers, shared CSA datapath)
//   2. Optimized Architecture (Continuous 2-Line streaming, parallel Gx/Gy, 1 px/cyc)
//   3. Pipelined Architecture (3-Stage balanced pipeline, 1 RCA critical path, >300MHz)
//
// Outputs saved to:
//   - sim/image_out_baseline.hex
//   - sim/image_out_optimized.hex
//   - sim/image_out_pipeline.hex
//   - sim/comparison_report.txt
//   - sim/result_baseline.png
//   - sim/result_optimized.png
//   - sim/result_pipeline.png
// =============================================================================

`timescale 1ns/1ps

`include "accelerator_baseline.sv"
`include "accelerator_optimized.sv"
`include "accelerator_pipeline.sv"

// Baseline SVAs
`include "LineBuffer_baseline_sva.sv"
`include "ReorderBuffer_baseline_sva.sv"
`include "WindowBuffer_baseline_sva.sv"
`include "SlidingWindowBuffer_baseline_sva.sv"
`include "controller_baseline_sva.sv"
`include "core_baseline_sva.sv"
`include "accelerator_baseline_sva.sv"

// Optimized SVAs
`include "LineBuffer_optimized_sva.sv"
`include "ReorderBuffer_optimized_sva.sv"
`include "WindowBuffer_optimized_sva.sv"
`include "SlidingWindowBuffer_optimized_sva.sv"
`include "controller_optimized_sva.sv"
`include "core_optimized_sva.sv"
`include "accelerator_optimized_sva.sv"

// Pipeline SVAs
`include "LineBuffer_pipeline_sva.sv"
`include "ReorderBuffer_pipeline_sva.sv"
`include "WindowBuffer_pipeline_sva.sv"
`include "SlidingWindowBuffer_pipeline_sva.sv"
`include "controller_pipeline_sva.sv"
`include "core_pipeline_sva.sv"
`include "accelerator_pipeline_sva.sv"

module tb_comparison;

    localparam int WIDTH_SIZE         = 640;
    localparam int HEIGHT_SIZE        = 853;
    localparam int TOTAL_INPUT_PIXELS = WIDTH_SIZE * HEIGHT_SIZE;          // 545,920
    localparam int EDGE_WIDTH         = WIDTH_SIZE - 2;                   // 638
    localparam int EDGE_HEIGHT        = HEIGHT_SIZE - 2;                  // 851
    localparam int TOTAL_VALID_PIXELS = EDGE_WIDTH * EDGE_HEIGHT;         // 542,938
    localparam int CLK_PERIOD         = 10;                               // 100 MHz (10 ns)

    // -------------------------------------------------------------------------
    // Common Clock and Reset
    // -------------------------------------------------------------------------
    logic clk;
    logic rst;
    logic start;

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Baseline DUT Signals
    // -------------------------------------------------------------------------
    logic [7:0] pixel_in_base;
    logic       ready_base;
    logic       busy_base;
    logic       busy_load_base;
    logic       busy_process_base;
    logic       done_base;
    logic       linebuffer_wenable_base;
    logic       valid_pixel_base;
    logic [7:0] pixel_out_base;

    accelerator_baseline #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .PIXEL_WIDTH (8)
    ) dut_baseline (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .pixel_in           (pixel_in_base),
        .ready              (ready_base),
        .busy               (busy_base),
        .busy_load          (busy_load_base),
        .busy_process       (busy_process_base),
        .done               (done_base),
        .linebuffer_wenable (linebuffer_wenable_base),
        .valid_pixel        (valid_pixel_base),
        .pixel_out          (pixel_out_base)
    );

    // -------------------------------------------------------------------------
    // Optimized DUT Signals
    // -------------------------------------------------------------------------
    logic [7:0] pixel_in_opt;
    logic       ready_opt;
    logic       busy_opt;
    logic       done_opt;
    logic       valid_pixel_opt;
    logic [7:0] pixel_out_opt;

    accelerator_optimized #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .PIXEL_WIDTH (8)
    ) dut_optimized (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .pixel_in    (pixel_in_opt),
        .ready       (ready_opt),
        .busy        (busy_opt),
        .done        (done_opt),
        .valid_pixel (valid_pixel_opt),
        .pixel_out   (pixel_out_opt)
    );

    // -------------------------------------------------------------------------
    // Pipelined DUT Signals
    // -------------------------------------------------------------------------
    logic [7:0] pixel_in_pipe;
    logic       ready_pipe;
    logic       busy_pipe;
    logic       done_pipe;
    logic       valid_pixel_pipe;
    logic [7:0] pixel_out_pipe;

    accelerator_pipeline #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE),
        .PIXEL_WIDTH (8)
    ) dut_pipeline (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .pixel_in    (pixel_in_pipe),
        .ready       (ready_pipe),
        .busy        (busy_pipe),
        .done        (done_pipe),
        .valid_pixel (valid_pixel_pipe),
        .pixel_out   (pixel_out_pipe)
    );

    // =========================================================================
    // SVA Checker Bind Statements for All 3 Architectures
    // =========================================================================
    // 1. Baseline Binds
    bind LineBuffer_baseline LineBuffer_baseline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE)
    ) u_b_lb_sva (
        .clk(clk), .rst(rst), .wdata(wdata), .wenable(wenable),
        .wrow(wrow), .waddress(waddress), .raddress(raddress), .rdata(rdata)
    );

    bind ReorderBuffer_baseline ReorderBuffer_baseline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .YWIN (YWIN)
    ) u_b_rb_sva (
        .row_ref(row_ref), .raw_col(raw_col), .ordered_col(ordered_col)
    );

    bind WindowBuffer_baseline WindowBuffer_baseline_sva #(
        .WIDTH (WIDTH), .XWIN (XWIN), .YWIN (YWIN)
    ) u_b_wb_sva (
        .clk(clk), .rst(rst), .shift_en(shift_en), .col_in(col_in), .window_out(window_out)
    );

    bind SlidingWindowBuffer_baseline SlidingWindowBuffer_baseline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE), .XWIN (XWIN), .YWIN (YWIN)
    ) u_b_swb_sva (
        .clk(clk), .rst(rst), .wenable(wenable), .wdata(wdata), .wrow(wrow),
        .waddress(waddress), .renable(renable), .rrow(rrow), .raddress(raddress), .rdata(rdata)
    );

    bind controller_baseline controller_baseline_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE)
    ) u_b_ctrl_sva (
        .clk(clk), .rst(rst), .start(start), .ready(ready), .busy(busy),
        .busy_load(busy_load), .busy_process(busy_process), .done(done),
        .gx_sign(gx_sign), .gy_sign(gy_sign), .gx_en(gx_en), .gy_en(gy_en),
        .xy_ctrl(xy_ctrl), .xm_ctrl(xm_ctrl), .ym_ctrl(ym_ctrl),
        .valid_pixel(valid_pixel), .linebuffer_wenable(linebuffer_wenable),
        .window_shiften(window_shiften), .row_pointer(row_pointer),
        .waddress(waddress), .raddress(raddress)
    );

    bind core_baseline core_baseline_sva u_b_core_sva (
        .clk(clk), .rst(rst), .window(window), .xy_ctrl(xy_ctrl),
        .gx_en(gx_en), .gy_en(gy_en), .xm_ctrl(xm_ctrl), .ym_ctrl(ym_ctrl),
        .gx_sign(gx_sign), .gy_sign(gy_sign), .G(G)
    );

    bind accelerator_baseline accelerator_baseline_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE), .PIXEL_WIDTH (PIXEL_WIDTH)
    ) u_b_acc_sva (
        .clk(clk), .rst(rst), .start(start), .pixel_in(pixel_in),
        .ready(ready), .busy(busy), .busy_load(busy_load), .busy_process(busy_process),
        .done(done), .linebuffer_wenable(linebuffer_wenable), .valid_pixel(valid_pixel),
        .pixel_out(pixel_out)
    );

    // 2. Optimized Binds
    bind LineBuffer_optimized LineBuffer_optimized_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE)
    ) u_o_lb_sva (
        .clk(clk), .rst(rst), .wdata(wdata), .wenable(wenable),
        .wrow(wrow), .waddress(waddress), .raddress(raddress), .rdata(rdata)
    );

    bind ReorderBuffer_optimized ReorderBuffer_optimized_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .YWIN (YWIN)
    ) u_o_rb_sva (
        .row_ref(row_ref), .raw_col(raw_col), .live_pixel(live_pixel), .ordered_col(ordered_col)
    );

    bind WindowBuffer_optimized WindowBuffer_optimized_sva #(
        .WIDTH (WIDTH), .XWIN (XWIN), .YWIN (YWIN)
    ) u_o_wb_sva (
        .clk(clk), .rst(rst), .shift_en(shift_en), .col_in(col_in), .window_out(window_out)
    );

    bind SlidingWindowBuffer_optimized SlidingWindowBuffer_optimized_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE), .XWIN (XWIN), .YWIN (YWIN)
    ) u_o_swb_sva (
        .clk(clk), .rst(rst), .wenable(wenable), .wdata(wdata), .wrow(wrow),
        .waddress(waddress), .renable(renable), .rrow(rrow), .raddress(raddress), .rdata(rdata)
    );

    bind controller_optimized controller_optimized_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE)
    ) u_o_ctrl_sva (
        .clk(clk), .rst(rst), .start(start), .ready(ready), .busy(busy),
        .done(done), .valid_pixel(valid_pixel), .linebuffer_wenable(linebuffer_wenable),
        .window_shiften(window_shiften), .row_pointer(row_pointer),
        .waddress(waddress), .raddress(raddress)
    );

    bind core_optimized core_optimized_sva u_o_core_sva (
        .clk(clk), .rst(rst), .shift_en(shift_en), .window(window), .G_sat(G_sat)
    );

    bind accelerator_optimized accelerator_optimized_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE), .PIXEL_WIDTH (PIXEL_WIDTH)
    ) u_o_acc_sva (
        .clk(clk), .rst(rst), .start(start), .pixel_in(pixel_in),
        .ready(ready), .busy(busy), .done(done), .valid_pixel(valid_pixel),
        .pixel_out(pixel_out)
    );

    // 3. Pipeline Binds
    bind LineBuffer_pipeline LineBuffer_pipeline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE)
    ) u_p_lb_sva (
        .clk(clk), .rst(rst), .wdata(wdata), .wenable(wenable),
        .wrow(wrow), .waddress(waddress), .raddress(raddress), .rdata(rdata)
    );

    bind ReorderBuffer_pipeline ReorderBuffer_pipeline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .YWIN (YWIN)
    ) u_p_rb_sva (
        .row_ref(row_ref), .raw_col(raw_col), .live_pixel(live_pixel), .ordered_col(ordered_col)
    );

    bind WindowBuffer_pipeline WindowBuffer_pipeline_sva #(
        .WIDTH (WIDTH), .XWIN (XWIN), .YWIN (YWIN)
    ) u_p_wb_sva (
        .clk(clk), .rst(rst), .shift_en(shift_en), .col_in(col_in), .window_out(window_out)
    );

    bind SlidingWindowBuffer_pipeline SlidingWindowBuffer_pipeline_sva #(
        .WIDTH (WIDTH), .ROWS (ROWS), .SIZE (SIZE), .XWIN (XWIN), .YWIN (YWIN)
    ) u_p_swb_sva (
        .clk(clk), .rst(rst), .wenable(wenable), .wdata(wdata), .wrow(wrow),
        .waddress(waddress), .renable(renable), .rrow(rrow), .raddress(raddress), .rdata(rdata)
    );

    bind controller_pipeline controller_pipeline_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE)
    ) u_p_ctrl_sva (
        .clk(clk), .rst(rst), .start(start), .ready(ready), .busy(busy),
        .done(done), .valid_pixel(valid_pixel), .linebuffer_wenable(linebuffer_wenable),
        .window_shiften(window_shiften), .row_pointer(row_pointer),
        .waddress(waddress), .raddress(raddress)
    );

    bind core_pipeline core_pipeline_sva u_p_core_sva (
        .clk(clk), .rst(rst), .shift_en(shift_en), .window(window), .G_sat_reg(G_sat_reg)
    );

    bind accelerator_pipeline accelerator_pipeline_sva #(
        .WIDTH_SIZE (WIDTH_SIZE), .HEIGHT_SIZE (HEIGHT_SIZE), .PIXEL_WIDTH (PIXEL_WIDTH)
    ) u_p_acc_sva (
        .clk(clk), .rst(rst), .start(start), .pixel_in(pixel_in),
        .ready(ready), .busy(busy), .done(done), .valid_pixel(valid_pixel),
        .pixel_out(pixel_out)
    );

    // -------------------------------------------------------------------------
    // Memory and Output Buffers
    // -------------------------------------------------------------------------
    logic [7:0] img_in_mem [0:TOTAL_INPUT_PIXELS-1];

    logic [7:0] img_out_base [0:TOTAL_VALID_PIXELS-1];
    logic [7:0] img_out_opt  [0:TOTAL_VALID_PIXELS-1];
    logic [7:0] img_out_pipe [0:TOTAL_VALID_PIXELS-1];

    int idx_base = 0;
    int idx_opt  = 0;
    int idx_pipe = 0;

    int cnt_base = 0;
    int cnt_opt  = 0;
    int cnt_pipe = 0;

    // Measurement Counters
    longint total_cycles = 0;

    longint base_start_cyc = 0, base_done_cyc = 0, base_first_pixel_cyc = 0;
    longint opt_start_cyc  = 0, opt_done_cyc  = 0, opt_first_pixel_cyc  = 0;
    longint pipe_start_cyc = 0, pipe_done_cyc = 0, pipe_first_pixel_cyc = 0;

    // -------------------------------------------------------------------------
    // Input Feeding Logic
    // -------------------------------------------------------------------------
    // Baseline feeds on linebuffer_wenable
    always_comb begin
        if (!rst && linebuffer_wenable_base && (idx_base < TOTAL_INPUT_PIXELS))
            pixel_in_base = img_in_mem[idx_base];
        else
            pixel_in_base = 8'd0;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            idx_base <= 0;
        else if (linebuffer_wenable_base && (idx_base < TOTAL_INPUT_PIXELS))
            idx_base <= idx_base + 1;
    end

    // Optimized feeds continuously while busy
    always_comb begin
        if (!rst && busy_opt && (idx_opt < TOTAL_INPUT_PIXELS))
            pixel_in_opt = img_in_mem[idx_opt];
        else
            pixel_in_opt = 8'd0;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            idx_opt <= 0;
        else if (busy_opt && (idx_opt < TOTAL_INPUT_PIXELS))
            idx_opt <= idx_opt + 1;
    end

    // Pipeline feeds continuously while busy
    always_comb begin
        if (!rst && busy_pipe && (idx_pipe < TOTAL_INPUT_PIXELS))
            pixel_in_pipe = img_in_mem[idx_pipe];
        else
            pixel_in_pipe = 8'd0;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            idx_pipe <= 0;
        else if (busy_pipe && (idx_pipe < TOTAL_INPUT_PIXELS))
            idx_pipe <= idx_pipe + 1;
    end

    // -------------------------------------------------------------------------
    // Output Harvesting & Timing Logging
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst) begin
            total_cycles <= total_cycles + 1;

            // Baseline harvest
            if (valid_pixel_base) begin
                if (cnt_base == 0) base_first_pixel_cyc <= total_cycles;
                if (cnt_base < TOTAL_VALID_PIXELS)
                    img_out_base[cnt_base] <= pixel_out_base;
                cnt_base <= cnt_base + 1;
            end

            // Optimized harvest
            if (valid_pixel_opt) begin
                if (cnt_opt == 0) opt_first_pixel_cyc <= total_cycles;
                if (cnt_opt < TOTAL_VALID_PIXELS)
                    img_out_opt[cnt_opt] <= pixel_out_opt;
                cnt_opt <= cnt_opt + 1;
            end

            // Pipeline harvest
            if (valid_pixel_pipe) begin
                if (cnt_pipe == 0) pipe_first_pixel_cyc <= total_cycles;
                if (cnt_pipe < TOTAL_VALID_PIXELS)
                    img_out_pipe[cnt_pipe] <= pixel_out_pipe;
                cnt_pipe <= cnt_pipe + 1;
            end

            // Done cycle capture
            if (done_base && base_done_cyc == 0) base_done_cyc <= total_cycles;
            if (done_opt  && opt_done_cyc == 0)  opt_done_cyc  <= total_cycles;
            if (done_pipe && pipe_done_cyc == 0) pipe_done_cyc <= total_cycles;
        end
    end

    // -------------------------------------------------------------------------
    // Test Control and Performance Report
    // -------------------------------------------------------------------------
    initial begin
        string in_hex_path;
        int check_fd;

        $display("==================================================================");
        $display("   Sobel Hardware Accelerators Comprehensive Architectural Comparison ");
        $display("   Evaluating: Baseline vs. Optimized vs. Pipelined Architectures  ");
        $display("   Resolution: %0d x %0d (%0d Pixels) | Target Clock: 100 MHz      ",
                 WIDTH_SIZE, HEIGHT_SIZE, TOTAL_INPUT_PIXELS);
        $display("==================================================================");

        // Find input image hex file
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
        #(CLK_PERIOD * 4);
        @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // Start all 3 simultaneously
        @(posedge clk);
        start <= 1'b1;
        base_start_cyc = total_cycles;
        opt_start_cyc  = total_cycles;
        pipe_start_cyc = total_cycles;
        @(posedge clk);
        start <= 1'b0;

        $display("[INFO] Simulation running across all 3 hardware architectures...");

        // Wait independently until each architecture finishes
        fork
            begin
                wait(done_opt);
                $display("[INFO] >>> OPTIMIZED architecture completed at cycle %0d! <<<", total_cycles);
            end
            begin
                wait(done_pipe);
                $display("[INFO] >>> PIPELINED architecture completed at cycle %0d! <<<", total_cycles);
            end
            begin
                wait(done_base);
                $display("[INFO] >>> BASELINE architecture completed at cycle %0d! <<<", total_cycles);
            end
        join

        #(CLK_PERIOD * 10);

        // Save Hex Outputs
        save_hex_file("sim/image_out_baseline.hex", img_out_base);
        save_hex_file("sim/image_out_optimized.hex", img_out_opt);
        save_hex_file("sim/image_out_pipeline.hex", img_out_pipe);

        // Print and Save Report
        generate_report();

        $finish;
    end

    // Helper task to write hex outputs
    task save_hex_file(string filename, logic [7:0] data_arr [0:TOTAL_VALID_PIXELS-1]);
        int fd;
        fd = $fopen(filename, "w");
        if (fd != 0) begin
            for (int i = 0; i < TOTAL_VALID_PIXELS; i++) begin
                $fdisplay(fd, "%02x", data_arr[i]);
            end
            $fclose(fd);
            $display("[HEX DUMP] Successfully exported %s", filename);
        end else begin
            $display("[ERROR] Could not open %s for writing!", filename);
        end
    endtask

    // Performance and Comparison Report Task
    task generate_report();
        longint base_duration, opt_duration, pipe_duration;
        real base_time_ms, opt_time_ms, pipe_time_ms;
        real base_mpps, opt_mpps, pipe_mpps;
        real base_fps, opt_fps, pipe_fps;
        real speedup_opt, speedup_pipe;
        int rep_fd;

        base_duration = base_done_cyc - base_start_cyc;
        opt_duration  = opt_done_cyc  - opt_start_cyc;
        pipe_duration = pipe_done_cyc - pipe_start_cyc;

        base_time_ms = real'(base_duration * CLK_PERIOD) / 1_000_000.0;
        opt_time_ms  = real'(opt_duration  * CLK_PERIOD) / 1_000_000.0;
        pipe_time_ms = real'(pipe_duration * CLK_PERIOD) / 1_000_000.0;

        base_mpps = (real'(TOTAL_VALID_PIXELS) / (base_time_ms / 1000.0)) / 1_000_000.0;
        opt_mpps  = (real'(TOTAL_VALID_PIXELS) / (opt_time_ms  / 1000.0)) / 1_000_000.0;
        pipe_mpps = (real'(TOTAL_VALID_PIXELS) / (pipe_time_ms / 1000.0)) / 1_000_000.0;

        base_fps = 1000.0 / base_time_ms;
        opt_fps  = 1000.0 / opt_time_ms;
        pipe_fps = 1000.0 / pipe_time_ms;

        speedup_opt  = real'(base_duration) / real'(opt_duration);
        speedup_pipe = real'(base_duration) / real'(pipe_duration);

        $display("\n==========================================================================================");
        $display("                   HARDWARE PERFORMANCE & ARCHITECTURE COMPARISON                          ");
        $display("==========================================================================================");
        $display("%-22s | %-12s | %-12s | %-14s | %-10s | %-10s",
                 "Architecture", "Cycles", "Duration(ms)", "Throughput", "FPS", "Speedup");
        $display("------------------------------------------------------------------------------------------");
        $display("%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx (ref)",
                 "1. Baseline", base_duration, base_time_ms, base_mpps, base_fps, 1.0);
        $display("%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx",
                 "2. Optimized (1-Cyc)", opt_duration, opt_time_ms, opt_mpps, opt_fps, speedup_opt);
        $display("%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx",
                 "3. Pipeline (3-Stage)", pipe_duration, pipe_time_ms, pipe_mpps, pipe_fps, speedup_pipe);
        $display("==========================================================================================\n");

        rep_fd = $fopen("sim/comparison_report.txt", "w");
        if (rep_fd != 0) begin
            $fdisplay(rep_fd, "==========================================================================================");
            $fdisplay(rep_fd, "                   HARDWARE PERFORMANCE & ARCHITECTURE COMPARISON                          ");
            $fdisplay(rep_fd, "==========================================================================================");
            $fdisplay(rep_fd, "Evaluation conditions: 640x853 image (%0d pixels), 100 MHz clock period (10 ns)", TOTAL_INPUT_PIXELS);
            $fdisplay(rep_fd, "------------------------------------------------------------------------------------------");
            $fdisplay(rep_fd, "%-22s | %-12s | %-12s | %-14s | %-10s | %-10s",
                      "Architecture", "Cycles", "Duration(ms)", "Throughput", "FPS", "Speedup");
            $fdisplay(rep_fd, "------------------------------------------------------------------------------------------");
            $fdisplay(rep_fd, "%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx (ref)",
                      "1. Baseline", base_duration, base_time_ms, base_mpps, base_fps, 1.0);
            $fdisplay(rep_fd, "%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx",
                      "2. Optimized (1-Cyc)", opt_duration, opt_time_ms, opt_mpps, opt_fps, speedup_opt);
            $fdisplay(rep_fd, "%-22s | %12d | %12.3f | %8.2f Mpx/s | %7.2f    | %9.2fx",
                      "3. Pipeline (3-Stage)", pipe_duration, pipe_time_ms, pipe_mpps, pipe_fps, speedup_pipe);
            $fdisplay(rep_fd, "==========================================================================================");
            $fclose(rep_fd);
            $display("[REPORT] Comparison report written to sim/comparison_report.txt");
        end
    endtask

endmodule
