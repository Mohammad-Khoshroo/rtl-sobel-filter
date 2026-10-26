`timescale 1ns/1ps

module tb_core;

    localparam WIDTH = 11;
    logic clk, rst;
    logic [7:0] window [2:0][2:0];

    logic xy_ctrl;
    logic G_reg_en;
    logic gx_en, gy_en;
    logic xm_ctrl, ym_ctrl;

    logic [7:0] G;
    logic signed [WIDTH-1:0] Gx_out, Gy_out;

    Core #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .window(window),
        .xy_ctrl(xy_ctrl),
        .gx_en(gx_en),
        .gy_en(gy_en),
        .xm_ctrl(xm_ctrl),
        .ym_ctrl(ym_ctrl),
        .G(G),
        .Gx_out(Gx_out),
        .Gy_out(Gy_out)
    );

    always #5 clk = ~clk;

    int errors = 0;

    task automatic run_test(input int iter);
        int exp_gx, exp_gy, exp_g;
        int abs_gx, abs_gy;

        // Generate random 3x3 window
        for (int x = 0; x < 3; x++) begin
            for (int y = 0; y < 3; y++) begin
                window[x][y] = $urandom_range(0, 255);
            end
        end

        // Expected Gx:
        // [-1 0 +1]
        // [-2 0 +2]
        // [-1 0 +1]
        exp_gx = (int'(window[2][0]) + 2*int'(window[2][1]) + int'(window[2][2]))
               - (int'(window[0][0]) + 2*int'(window[0][1]) + int'(window[0][2]));

        // Expected Gy:
        // [-1 -2 -1]
        // [ 0  0  0]
        // [+1 +2 +1]
        exp_gy = (int'(window[0][2]) + 2*int'(window[1][2]) + int'(window[2][2]))
               - (int'(window[0][0]) + 2*int'(window[1][0]) + int'(window[2][0]));

        abs_gx = (exp_gx < 0) ? -exp_gx : exp_gx;
        abs_gy = (exp_gy < 0) ? -exp_gy : exp_gy;
        exp_g  = abs_gx + abs_gy;
        if (exp_g > 255) exp_g = 255;

        // Step 1: Compute Gx and store into Gx register
        @(posedge clk);
        xy_ctrl  <= 1'b0; // Gx terms
        xm_ctrl  <= 1'b0; // CSA sum
        ym_ctrl  <= 1'b0; // CSA carry
        gx_en    <= 1'b1; // write Gx
        gy_en    <= 1'b0;

        // Step 2: Compute Gy and store into Gy register
        @(posedge clk);
        gx_en    <= 1'b0;
        xy_ctrl  <= 1'b1; // Gy terms
        xm_ctrl  <= 1'b0; // CSA sum
        ym_ctrl  <= 1'b0; // CSA carry
        gy_en    <= 1'b1; // write Gy

        // Step 3: Compute G = |Gx| + |Gy|
        @(posedge clk);
        gy_en    <= 1'b0;
        xm_ctrl  <= 1'b1; // |Gx|
        ym_ctrl  <= 1'b1; // |Gy|

        #1; // Sample output after combinational adder settles
        if (Gx_out !== exp_gx[WIDTH-1:0]) begin
            $display("[Iter %0d] Gx mismatch! got=%0d, exp=%0d", iter, $signed(Gx_out), exp_gx);
            errors++;
        end

        if (Gy_out !== exp_gy[WIDTH-1:0]) begin
            $display("[Iter %0d] Gy mismatch! got=%0d, exp=%0d", iter, $signed(Gy_out), exp_gy);
            errors++;
        end

        if (G !== exp_g[7:0]) begin
            $display("[Iter %0d] G mismatch! got=%0d, exp=%0d (abs_gx=%0d, abs_gy=%0d)", iter, G, exp_g, abs_gx, abs_gy);
            errors++;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        xy_ctrl = 0;
        G_reg_en = 0;
        gx_en = 0;
        gy_en = 0;
        xm_ctrl = 0;
        ym_ctrl = 0;

        for (int x = 0; x < 3; x++)
            for (int y = 0; y < 3; y++)
                window[x][y] = 0;

        #20;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        $display("Testing Core datapath with 1000 random windows...");
        for (int i = 0; i < 1000; i++) begin
            run_test(i);
        end

        if (errors == 0) begin
            $display("=================================================");
            $display("SUCCESS: ALL 1000 CORE TESTS PASSED WITH 0 ERRORS!");
            $display("=================================================");
        end else begin
            $display("FAILED with %0d errors.", errors);
        end

        $finish;
    end

endmodule
