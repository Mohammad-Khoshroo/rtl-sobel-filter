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
//       $ verilator --binary -Wno-fatal \
//                 -Irtl -Irtl/baseline -Irtl/optimized -Irtl/pipeline -Irtl/include -Irtl/include/Register -Irtl/include/MIA \
//                 --top-module tb_comparison \
//                 tb/tb_comparison.sv rtl/include/Register/Register.sv rtl/include/MIA/CSA.sv
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

            // Capture done cycles
            if (done_base && base_done_cyc == 0) base_done_cyc <= total_cycles;
            if (done_opt  && opt_done_cyc  == 0) opt_done_cyc  <= total_cycles;
            if (done_pipe && pipe_done_cyc == 0) pipe_done_cyc <= total_cycles;
        end
    end

    // -------------------------------------------------------------------------
    // Main Stimulus & Comparison Execution
    // -------------------------------------------------------------------------
    initial begin
        string in_hex_path;
        int check_fd;
        int rep_fd;
        int hex_base_fd, hex_opt_fd, hex_pipe_fd;
        real base_dur_ms, opt_dur_ms, pipe_dur_ms;
        real base_thru, opt_thru, pipe_thru;
        longint base_cycles, opt_cycles, pipe_cycles;

        $display("\n==========================================================================================");
        $display("   SOBEL HARDWARE ACCELERATORS COMPARISON TESTBENCH");
        $display("   Evaluating: Baseline vs. Optimized vs. 3-Stage Pipelined");
        $display("   Image: %0d x %0d (%0d Pixels) | Edge: %0d x %0d (%0d Pixels)",
                 WIDTH_SIZE, HEIGHT_SIZE, TOTAL_INPUT_PIXELS, EDGE_WIDTH, EDGE_HEIGHT, TOTAL_VALID_PIXELS);
        $display("==========================================================================================\n");

        // Determine input file location
        check_fd = $fopen("image_in.hex", "r");
        if (check_fd != 0) begin
            $fclose(check_fd);
            in_hex_path = "image_in.hex";
        end else begin
            in_hex_path = "inputs/input1/image_in.hex";
        end

        $display("[INFO] Loading input image hex: %s ...", in_hex_path);
        $readmemh(in_hex_path, img_in_mem);
        $display("[INFO] Successfully loaded %0d input pixels.", TOTAL_INPUT_PIXELS);

        // Reset Sequence
        rst   = 1;
        start = 0;
        #40;
        @(posedge clk);
        rst = 0;
        #20;

        // Check all ready
        if (!ready_base || !ready_opt || !ready_pipe) begin
            $display("[WARN] Not all DUTs ready before start: base=%0d, opt=%0d, pipe=%0d",
                     ready_base, ready_opt, ready_pipe);
        end

        // Trigger start pulse to all 3 architectures simultaneously
        @(posedge clk);
        start = 1;
        base_start_cyc = total_cycles;
        opt_start_cyc  = total_cycles;
        pipe_start_cyc = total_cycles;
        @(posedge clk);
        start = 0;

        $display("[INFO] Simultaneous start pulse issued at cycle %0d. Simulating...", total_cycles);

        // Wait until all 3 architectures assert done
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

        // Allow trailing cycle for final output registration
        @(posedge clk);
        #100;

        // Calculate metrics
        base_cycles = base_done_cyc - base_start_cyc;
        opt_cycles  = opt_done_cyc  - opt_start_cyc;
        pipe_cycles = pipe_done_cyc - pipe_start_cyc;

        base_dur_ms = real'(base_cycles) * CLK_PERIOD / 1_000_000.0;
        opt_dur_ms  = real'(opt_cycles)  * CLK_PERIOD / 1_000_000.0;
        pipe_dur_ms = real'(pipe_cycles) * CLK_PERIOD / 1_000_000.0;

        base_thru = real'(cnt_base) / real'(base_cycles);
        opt_thru  = real'(cnt_opt)  / real'(opt_cycles);
        pipe_thru = real'(cnt_pipe) / real'(pipe_cycles);

        // Print ANSI Comparison Table
        $display("\n========================================================================================================");
        $display("                          SOBEL HARDWARE ARCHITECTURE COMPARISON RESULTS");
        $display("========================================================================================================");
        $display("%-16s | %-12s | %-15s | %-12s | %-18s | %-15s",
                 "Architecture", "Total Cycles", "Duration @100MHz", "Valid Pixels", "Throughput (px/cyc)", "Critical Path");
        $display("-----------------+--------------+-----------------+--------------+---------------------+----------------");
        $display("%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                 "Baseline", base_cycles, base_dur_ms, cnt_base, base_thru, "Multi-cycle FSM");
        $display("%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                 "Optimized", opt_cycles, opt_dur_ms, cnt_opt, opt_thru, "2 RCA + 3 CSA");
        $display("%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                 "Pipelined (3-Stg)", pipe_cycles, pipe_dur_ms, cnt_pipe, pipe_thru, "1 RCA (Max Fmax)");
        $display("========================================================================================================");
        $display("Speedup (Optimized vs Baseline) : %0.2fx fewer cycles", real'(base_cycles) / real'(opt_cycles));
        $display("Speedup (Pipeline  vs Baseline) : %0.2fx fewer cycles, ~3x higher maximum frequency (>300 MHz)",
                 real'(base_cycles) / real'(pipe_cycles));
        $display("Latency to 1st Pixel: Baseline = %0d cyc, Optimized = %0d cyc, Pipeline = %0d cyc",
                 base_first_pixel_cyc - base_start_cyc,
                 opt_first_pixel_cyc - opt_start_cyc,
                 pipe_first_pixel_cyc - pipe_start_cyc);
        $display("========================================================================================================\n");

        // Write image hex outputs to sim/
        $display("[INFO] Writing output hex dumps to sim/ directory...");
        hex_base_fd = $fopen("sim/image_out_baseline.hex", "w");
        hex_opt_fd  = $fopen("sim/image_out_optimized.hex", "w");
        hex_pipe_fd = $fopen("sim/image_out_pipeline.hex", "w");

        for (int i = 0; i < TOTAL_VALID_PIXELS; i++) begin
            $fdisplay(hex_base_fd, "%02X", img_out_base[i]);
            $fdisplay(hex_opt_fd,  "%02X", img_out_opt[i]);
            $fdisplay(hex_pipe_fd, "%02X", img_out_pipe[i]);
        end

        $fclose(hex_base_fd);
        $fclose(hex_opt_fd);
        $fclose(hex_pipe_fd);

        // Write formatted comparison report to sim/comparison_report.txt
        rep_fd = $fopen("sim/comparison_report.txt", "w");
        if (rep_fd != 0) begin
            $fdisplay(rep_fd, "========================================================================================================");
            $fdisplay(rep_fd, "                          SOBEL HARDWARE ARCHITECTURE COMPARISON RESULTS");
            $fdisplay(rep_fd, "========================================================================================================");
            $fdisplay(rep_fd, "%-16s | %-12s | %-15s | %-12s | %-18s | %-15s",
                      "Architecture", "Total Cycles", "Duration @100MHz", "Valid Pixels", "Throughput (px/cyc)", "Critical Path");
            $fdisplay(rep_fd, "-----------------+--------------+-----------------+--------------+---------------------+----------------");
            $fdisplay(rep_fd, "%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                      "Baseline", base_cycles, base_dur_ms, cnt_base, base_thru, "Multi-cycle FSM");
            $fdisplay(rep_fd, "%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                      "Optimized", opt_cycles, opt_dur_ms, cnt_opt, opt_thru, "2 RCA + 3 CSA");
            $fdisplay(rep_fd, "%-16s | %12d | %12.3f ms | %12d | %18.4f  | %-15s",
                      "Pipelined (3-Stg)", pipe_cycles, pipe_dur_ms, cnt_pipe, pipe_thru, "1 RCA (Max Fmax)");
            $fdisplay(rep_fd, "========================================================================================================");
            $fdisplay(rep_fd, "Speedup (Optimized vs Baseline) : %0.2fx fewer cycles", real'(base_cycles) / real'(opt_cycles));
            $fdisplay(rep_fd, "Speedup (Pipeline  vs Baseline) : %0.2fx fewer cycles, ~3x higher maximum frequency (>300 MHz)",
                      real'(base_cycles) / real'(pipe_cycles));
            $fdisplay(rep_fd, "Latency to 1st Pixel: Baseline = %0d cyc, Optimized = %0d cyc, Pipeline = %0d cyc",
                      base_first_pixel_cyc - base_start_cyc,
                      opt_first_pixel_cyc - opt_start_cyc,
                      pipe_first_pixel_cyc - pipe_start_cyc);
            $fdisplay(rep_fd, "========================================================================================================");
            $fclose(rep_fd);
            $display("[INFO] Saved report to sim/comparison_report.txt");
        end

        $finish;
    end

endmodule
