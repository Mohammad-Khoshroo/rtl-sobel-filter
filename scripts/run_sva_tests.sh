#!/bin/bash
# ==============================================================================
# SVA Verification Test Suite for Sobel Optimized Architecture
# Tests 5 targeted bugged designs against SystemVerilog Assertions using Verilator
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

LOG_DIR="sim/assertion_bug_logs"
mkdir -p "$LOG_DIR"

echo "========================================================================"
echo "          Sobel Optimized Architecture - SVA Verification Suite        "
echo "========================================================================"

run_test() {
    local name="$1"
    local inc_dir="$2"
    local log_file="$LOG_DIR/${name}.log"
    local expected_fail="$3"

    echo -n "Running $name ... "

    verilator --binary --trace --assert -Wno-fatal \
              -I"$inc_dir" -Irtl/optimized -Irtl/include -Isva/optimized \
              --top-module tb_accelerator_optimized \
              tb/optimized/tb_accelerator_optimized.sv \
              rtl/optimized/accelerator_optimized.sv \
              rtl/include/Register.sv rtl/include/CSA.sv > /dev/null 2>&1

    set +e
    ./obj_dir/Vtb_accelerator_optimized > "$log_file" 2>&1
    local exit_code=$?
    set -e

    if [ "$expected_fail" -eq 1 ]; then
        if [ "$exit_code" -ne 0 ]; then
            local err_msg=$(grep "Assertion failed" "$log_file" | head -n 1)
            echo "FAILED as expected [ASSERTION CAUGHT] -> $err_msg"
        else
            echo "UNEXPECTED PASS (Bug was not caught!)"
        fi
    else
        if [ "$exit_code" -eq 0 ]; then
            echo "PASSED cleanly (Zero Assertion errors)"
        else
            echo "UNEXPECTED FAIL"
        fi
    fi
}

# 1. Bug 1: Reset Status Violation
run_test "bug1_reset" "rtl/bugged_optimized/bug1_reset" 1

# 2. Bug 2: Datapath Latency Mismatch
run_test "bug2_latency" "rtl/bugged_optimized/bug2_latency" 1

# 3. Bug 3: Control Signals Mutual Exclusion / Handshake
run_test "bug3_control" "rtl/bugged_optimized/bug3_control" 1

# 4. Bug 4: Output Validity Violation
run_test "bug4_validity" "rtl/bugged_optimized/bug4_validity" 1

# 5. Bug 5: Output Range & Missing Saturation Clamp
run_test "bug5_output_range" "rtl/bugged_optimized/bug5_output_range" 1

# 6. Golden Design (Correct Reference)
run_test "golden_clean" "rtl/optimized" 0

echo "========================================================================"
echo "All logs are saved in: $LOG_DIR/"
echo "========================================================================"
