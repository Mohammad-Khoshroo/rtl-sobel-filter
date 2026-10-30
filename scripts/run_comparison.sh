#!/usr/bin/env bash
set -e

# Navigate to project root
cd "$(dirname "$0")/.."

echo "=================================================================="
echo " Building and Simulating All 3 Sobel Architectures (Comparison)   "
echo "=================================================================="

verilator --binary --assert -Wno-fatal \
    -Irtl -Irtl/baseline -Irtl/optimized -Irtl/pipeline \
    -Irtl/include \
    -Isva -Isva/baseline -Isva/optimized -Isva/pipeline \
    --top-module tb_comparison \
    tb/compare/tb_comparison.sv \
    rtl/baseline/accelerator_baseline.sv \
    rtl/optimized/accelerator_optimized.sv \
    rtl/pipeline/accelerator_pipeline.sv \
    rtl/include/Register.sv \
    rtl/include/CSA.sv

echo ""
echo "Running Simulation..."
./obj_dir/Vtb_comparison

echo ""
echo "Running OpenCV Image Verification..."
python3 scripts/verify_all.py

echo ""
echo "Simulation and Verification Complete!"
