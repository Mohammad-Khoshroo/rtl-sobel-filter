#!/usr/bin/env python3
"""
run_simulation_all.py
Automates the compilation, simulation, verification, and output organization
for all input test images using Verilator and OpenCV.

Workflow:
1. Compiles RTL + Testbench using Verilator in WSL.
2. For each input in inputs/ (input1 .. input5):
   - Feeds image_in.hex into the accelerator testbench.
   - Executes Vtb_accelerator.
   - Verifies hardware output with OpenCV Sobel reference and generates hardware_sobel_result.png.
   - Organizes all output files into sim/inputX/ (matching sim/ structure).
3. Cleans up all extra/compiled files:
   - Removes obj_dir/ (compiled Verilator files).
   - Removes *.vcd traces (including sim/accelerator.vcd).
   - Cleans temporary root files.
"""

import os
import sys
import shutil
import subprocess
import glob
import numpy as np
import cv2
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, "inputs")
SIM_DIR = os.path.join(BASE_DIR, "sim")
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")

WIDTH = 640
HEIGHT = 853
TOTAL_PIXELS = WIDTH * HEIGHT
EDGE_WIDTH = WIDTH - 2
EDGE_HEIGHT = HEIGHT - 2
TOTAL_VALID_PIXELS = EDGE_WIDTH * EDGE_HEIGHT


def run_command(cmd, cwd=BASE_DIR):
    print(f"\n[EXEC] {cmd}")
    res = subprocess.run(cmd, shell=True, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if res.returncode != 0:
        print(f"[ERROR] Command failed with exit code {res.returncode}:\n{res.stdout}")
        sys.exit(res.returncode)
    return res.stdout


def compile_verilator():
    print("==================================================================")
    print(" 1. Compiling Sobel Accelerator with Verilator                   ")
    print("==================================================================")
    compile_cmd = (
        "verilator --binary --assert -Wno-fatal "
        "-Irtl -Irtl/buffer -Irtl/controller -Irtl/core -Irtl/MIA -Irtl/Register -Irtl/include "
        "--top-module tb_accelerator "
        "rtl/accelerator.sv tb/tb_accelerator.sv"
    )
    stdout = run_command(compile_cmd)
    print("[COMPILE OK] Verilator compilation finished successfully.")


def run_checker(input_png_path, hw_hex_path, out_result_png_path):
    """
    Executes OpenCV Sobel reference comparison against hardware hex output
    and saves the visualized edge result image.
    """
    pixels = []
    with open(hw_hex_path, 'r') as f:
        for line in f:
            stripped = line.strip()
            if stripped:
                pixels.append(int(stripped, 16))

    if len(pixels) < TOTAL_PIXELS:
        raise ValueError(f"Insufficient pixels in {hw_hex_path}: got {len(pixels)}, expected {TOTAL_PIXELS}")

    hw_img_array = np.array(pixels[:TOTAL_PIXELS], dtype=np.uint8).reshape((HEIGHT, WIDTH))
    hw_image = Image.fromarray(hw_img_array)
    hw_image.save(out_result_png_path)

    # OpenCV Software Reference Calculation
    input_img = cv2.imread(input_png_path, cv2.IMREAD_GRAYSCALE)
    input_img = cv2.resize(input_img, (WIDTH, HEIGHT))

    sobelx = cv2.Sobel(input_img, cv2.CV_64F, 1, 0, ksize=3)
    sobely = cv2.Sobel(input_img, cv2.CV_64F, 0, 1, ksize=3)
    abs_sobel = np.abs(sobelx) + np.abs(sobely)
    sw_img_array = np.clip(abs_sobel, 0, 255).astype(np.uint8)

    diff = np.abs(hw_img_array.astype(int) - sw_img_array.astype(int))
    mean_error = np.mean(diff)
    max_error = np.max(diff)

    return mean_error, max_error


def simulate_all():
    inputs = [
        ("input1", "Original Architecture Facade"),
        ("input2", "University Campus Entrance"),
        ("input3", "Geometric & Frequency Benchmark"),
        ("input4", "FPGA PCB Electronic Circuit Layout"),
        ("input5", "Natural Mountain Landscape")
    ]

    results_summary = []

    print("\n==================================================================")
    print(" 2. Running Simulations on All Input Test Images                 ")
    print("==================================================================")

    for folder_name, desc in inputs:
        print(f"\n------------------------------------------------------------------")
        print(f" >>> Simulating: {folder_name} - {desc}")
        print(f"------------------------------------------------------------------")

        in_dir = os.path.join(INPUTS_DIR, folder_name)
        in_png = os.path.join(in_dir, "input.png")
        in_hex = os.path.join(in_dir, "image_in.hex")

        if not os.path.exists(in_hex):
            raise FileNotFoundError(f"Input hex not found at {in_hex}")

        # Place image_in.hex into project root for testbench $readmemh
        root_image_in = os.path.join(BASE_DIR, "image_in.hex")
        shutil.copy(in_hex, root_image_in)
        # Also copy into sim/image_in.hex
        shutil.copy(in_hex, os.path.join(SIM_DIR, "image_in.hex"))

        # Run Verilator simulation binary
        sim_stdout = run_command("./obj_dir/Vtb_accelerator")

        # Parse testbench verification metrics
        passed = "TESTBENCH PASSED SUCCESSFULLY" in sim_stdout
        assertion_errors = 0
        for line in sim_stdout.splitlines():
            if "Assertion Errors" in line:
                try:
                    assertion_errors = int(line.split(":")[-1].strip())
                except Exception:
                    pass

        # Destination directory for this input's outputs
        sim_target_dir = os.path.join(SIM_DIR, folder_name)
        os.makedirs(sim_target_dir, exist_ok=True)

        hw_result_png = os.path.join(sim_target_dir, "hardware_sobel_result.png")
        mean_err, max_err = run_checker(in_png, os.path.join(SIM_DIR, "image_out.hex"), hw_result_png)

        # Copy sim artifacts into sim/inputX/
        shutil.copy(os.path.join(SIM_DIR, "image_in.hex"), os.path.join(sim_target_dir, "image_in.hex"))
        shutil.copy(os.path.join(SIM_DIR, "image_out.hex"), os.path.join(sim_target_dir, "image_out.hex"))
        shutil.copy(os.path.join(SIM_DIR, "image_out_valid.hex"), os.path.join(sim_target_dir, "image_out_valid.hex"))
        shutil.copy(os.path.join(SIM_DIR, "monitor.log"), os.path.join(sim_target_dir, "monitor.log"))

        # If input1, ensure root sim/ is also updated with input1's hardware_sobel_result.png
        if folder_name == "input1":
            shutil.copy(hw_result_png, os.path.join(SIM_DIR, "hardware_sobel_result.png"))

        # Clean temporary root files generated during simulation
        if os.path.exists(root_image_in):
            os.remove(root_image_in)
        root_image_out = os.path.join(BASE_DIR, "image_out.hex")
        if os.path.exists(root_image_out):
            os.remove(root_image_out)

        status_str = "PASS" if passed and assertion_errors == 0 else "FAIL"
        print(f"[RESULT] {folder_name}: Status={status_str}, Mean OpenCV Error={mean_err:.2f}, Max Error={max_err}, Assertions={assertion_errors}")
        results_summary.append({
            "name": folder_name,
            "desc": desc,
            "status": status_str,
            "mean_error": mean_err,
            "max_error": max_err,
            "assertions": assertion_errors
        })

    # Restore root sim/ files to match input1 (default reference)
    input1_sim_dir = os.path.join(SIM_DIR, "input1")
    for f in ["hardware_sobel_result.png", "image_in.hex", "image_out.hex", "image_out_valid.hex", "monitor.log"]:
        src_f = os.path.join(input1_sim_dir, f)
        if os.path.exists(src_f):
            shutil.copy(src_f, os.path.join(SIM_DIR, f))

    return results_summary


def cleanup():
    print("\n==================================================================")
    print(" 3. Cleaning Up Unnecessary and Compiled Files                   ")
    print("==================================================================")

    # 1. Remove obj_dir/ (compiled Verilator files in WSL)
    obj_dir_path = os.path.join(BASE_DIR, "obj_dir")
    if os.path.exists(obj_dir_path):
        print(f"[CLEANUP] Removing compiled Verilator directory: {obj_dir_path}")
        shutil.rmtree(obj_dir_path, ignore_errors=True)

    # 2. Remove all .vcd files (e.g. sim/accelerator.vcd)
    vcd_files = glob.glob(os.path.join(BASE_DIR, "**", "*.vcd"), recursive=True)
    for vcd in vcd_files:
        print(f"[CLEANUP] Removing waveform trace file: {vcd}")
        try:
            os.remove(vcd)
        except Exception as e:
            print(f"[WARNING] Could not remove {vcd}: {e}")

    # 3. Remove leftover temporary hex / log files in project root
    for temp_file in ["image_in.hex", "image_out.hex", "monitor.log", "input.png", "hardware_sobel_result.png"]:
        p = os.path.join(BASE_DIR, temp_file)
        if os.path.exists(p):
            print(f"[CLEANUP] Removing temporary root file: {p}")
            os.remove(p)

    # 4. Remove __pycache__ folders
    for pycache in glob.glob(os.path.join(BASE_DIR, "**", "__pycache__"), recursive=True):
        print(f"[CLEANUP] Removing python cache: {pycache}")
        shutil.rmtree(pycache, ignore_errors=True)

    print("[CLEANUP OK] Cleanup finished completely.")


def print_summary(results):
    print("\n==================================================================")
    print("                      FINAL EXECUTION REPORT                      ")
    print("==================================================================")
    print(f"{'Input':<10} | {'Description':<35} | {'Status':<6} | {'Mean Err':<8} | {'Assertions'}")
    print("-" * 75)
    for r in results:
        print(f"{r['name']:<10} | {r['desc']:<35} | {r['status']:<6} | {r['mean_error']:<8.2f} | {r['assertions']}")
    print("==================================================================")


def main():
    compile_verilator()
    results = simulate_all()
    cleanup()
    print_summary(results)


if __name__ == "__main__":
    main()
