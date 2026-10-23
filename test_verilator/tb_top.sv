// for compile use: verilator --binary --assert -Wno-fatal --top-module tb_top *.sv
// ./obj_dir/Vtb_top

module tb_top;
    
    logic       clk = 0;
    logic       rst;
    logic       start;
    logic [7:0] data_a, data_b;
    logic [7:0] final_res;
    logic       system_done;


    // Clock generation (period: 10 nanoseconds)
    always #5 clk = ~clk;

    // 1. Instantiate the top-level system module
    top_system dut (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .data_a      (data_a),
        .data_b      (data_b),
        .final_res   (final_res),
        .system_done (system_done)
    );

    // =========================================================================
    // 2. BIND Magic: Injecting Assertions into submodules without touching RTL files
    // =========================================================================

    // a) Connect controller_asserts to the controller module:
    // Since the port names of controller_asserts exactly match the internal signals
    // of the controller (including the internal signal current_state),
    // we use (.*) for automatic port connection!
    bind controller controller_asserts u_ctrl_chk (.*);

    // b) Connect alu_asserts to the alu module:
    // Here, to demonstrate both methods, ports are wired explicitly.
    // Note that signals inside the parentheses like (temp_add) are read
    // directly from within the alu module's scope!
    bind alu alu_asserts u_alu_chk (
        .clk      (clk),
        .en       (en),
        .op       (op),
        .b        (b),
        .temp_add (temp_add) // Internal wire inside alu.sv
    );

    // =========================================================================
    // 3. Test Scenario (Stimulating the circuit to observe Assertion behavior)
    // =========================================================================
    initial begin
        // Initialize inputs and reset the system
        rst = 1; start = 0; data_a = 8'd20; data_b = 8'd4;
        #15 rst = 0;

        // Test 1: Normal operation (divide 20 by 4)
        #10 start = 1;
        #10 start = 0;
        #40; // Wait for the state machine to finish (no errors should be printed)

        // Test 2: Intentionally trigger a divide-by-zero error (b = 0)
        $display("--- Starting Test 2 (Expecting Divide by Zero Error) ---");
        data_a = 8'd50; 
        data_b = 8'd0; // Divisor is zero!
        #10 start = 1;
        #10 start = 0;
        #40;

        $finish;
    end
endmodule
