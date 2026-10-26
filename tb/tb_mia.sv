`timescale 1ns/1ps

module tb_mia;

    localparam WIDTH = 12;
    int errors = 0;

    // --- Inputs ---
    logic [WIDTH-1:0] in[0:8];
    logic [6:0] csa_cin;
    logic adder_cin;

    // --- Outputs ---
    logic [WIDTH-1:0] sum3, sum4, sum5, sum6, sum7, sum8, sum9;

    // --- Expected sums ---
    logic [WIDTH-1:0] exp3, exp4, exp5, exp6, exp7, exp8, exp9;

    // --- DUTs ---
    MIA3 #(.WIDTH(WIDTH)) dut3 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]),
        .csa_cin(csa_cin[0:0]), .adder_cin(adder_cin), .sum(sum3)
    );

    MIA4 #(.WIDTH(WIDTH)) dut4 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]),
        .csa_cin(csa_cin[1:0]), .adder_cin(adder_cin), .sum(sum4)
    );

    MIA5 #(.WIDTH(WIDTH)) dut5 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]), .in4(in[4]),
        .csa_cin(csa_cin[2:0]), .adder_cin(adder_cin), .sum(sum5)
    );

    MIA6 #(.WIDTH(WIDTH)) dut6 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]), .in4(in[4]), .in5(in[5]),
        .csa_cin(csa_cin[3:0]), .adder_cin(adder_cin), .sum(sum6)
    );

    MIA7 #(.WIDTH(WIDTH)) dut7 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]), .in4(in[4]), .in5(in[5]), .in6(in[6]),
        .csa_cin(csa_cin[4:0]), .adder_cin(adder_cin), .sum(sum7)
    );

    MIA8 #(.WIDTH(WIDTH)) dut8 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]), .in4(in[4]), .in5(in[5]), .in6(in[6]), .in7(in[7]),
        .csa_cin(csa_cin[5:0]), .adder_cin(adder_cin), .sum(sum8)
    );

    MIA9 #(.WIDTH(WIDTH)) dut9 (
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]), .in4(in[4]), .in5(in[5]), .in6(in[6]), .in7(in[7]), .in8(in[8]),
        .csa_cin(csa_cin[6:0]), .adder_cin(adder_cin), .sum(sum9)
    );

    initial begin
        $display("Starting MIA Verification (Wallace Tree 3..9)...");

        for (int iter = 0; iter < 1000; iter++) begin
            for (int i = 0; i < 9; i++) in[i] = $urandom_range(0, (1 << (WIDTH-4)) - 1);
            csa_cin = $urandom;
            adder_cin = $urandom_range(0, 1);

            #1;

            exp3 = in[0] + in[1] + in[2] + WIDTH'(csa_cin[0]) + WIDTH'(adder_cin);
            exp4 = exp3 + in[3] + WIDTH'(csa_cin[1]);
            exp5 = exp4 + in[4] + WIDTH'(csa_cin[2]);
            exp6 = exp5 + in[5] + WIDTH'(csa_cin[3]);
            exp7 = exp6 + in[6] + WIDTH'(csa_cin[4]);
            exp8 = exp7 + in[7] + WIDTH'(csa_cin[5]);
            exp9 = exp8 + in[8] + WIDTH'(csa_cin[6]);

            if (sum3 !== exp3) begin $display("MISMATCH MIA3: got %0d, exp %0d", sum3, exp3); errors++; end
            if (sum4 !== exp4) begin $display("MISMATCH MIA4: got %0d, exp %0d", sum4, exp4); errors++; end
            if (sum5 !== exp5) begin $display("MISMATCH MIA5: got %0d, exp %0d", sum5, exp5); errors++; end
            if (sum6 !== exp6) begin $display("MISMATCH MIA6: got %0d, exp %0d", sum6, exp6); errors++; end
            if (sum7 !== exp7) begin $display("MISMATCH MIA7: got %0d, exp %0d", sum7, exp7); errors++; end
            if (sum8 !== exp8) begin $display("MISMATCH MIA8: got %0d, exp %0d", sum8, exp8); errors++; end
            if (sum9 !== exp9) begin $display("MISMATCH MIA9: got %0d, exp %0d", sum9, exp9); errors++; end
        end

        if (errors == 0) begin
            $display("ALL TESTS PASSED! (1000 random iterations for MIA3..MIA9)");
        end else begin
            $display("FAILED with %0d errors!", errors);
        end
        $finish;
    end

endmodule
