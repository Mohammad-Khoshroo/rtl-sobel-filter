#!/usr/bin/env python3
"""
generate_inputs.py
Generates 5 diverse and rich input images for testing the Sobel Accelerator (CA01):
1. input1: Original building architecture image (from inputs/input.png)
2. input2: University campus building entrance (from docs/images/input_image.png)
3. input3: Geometric test pattern & resolution benchmark
4. input4: FPGA PCB circuit board layout
5. input5: Natural landscape & terrain scene
"""

import os
import shutil
import numpy as np
import cv2
from PIL import Image

WIDTH = 640
HEIGHT = 853
TOTAL_PIXELS = WIDTH * HEIGHT

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, "inputs")


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def save_image_and_hex(img_array, out_dir, img_filename="input.png", hex_filename="image_in.hex"):
    ensure_dir(out_dir)
    img_path = os.path.join(out_dir, img_filename)
    hex_path = os.path.join(out_dir, hex_filename)

    # Save as PNG
    pil_img = Image.fromarray(img_array.astype(np.uint8), mode='L')
    pil_img.save(img_path)

    # Save as hex file (640 * 853 pixels, one 2-digit uppercase hex byte per line)
    with open(hex_path, "w") as f:
        for val in img_array.flatten():
            f.write(f"{int(val):02X}\n")

    print(f"[GENERATED] {img_path} ({WIDTH}x{HEIGHT}) and {hex_path} ({TOTAL_PIXELS} pixels)")
    return img_path, hex_path


def create_input1():
    """Input 1: Original assignment image"""
    orig_path = os.path.join(INPUTS_DIR, "input.png")
    if os.path.exists(orig_path):
        img = Image.open(orig_path).convert('L').resize((WIDTH, HEIGHT))
        return np.array(img, dtype=np.uint8)
    else:
        raise FileNotFoundError(f"Original input not found at {orig_path}")


def create_input2():
    """Input 2: Campus building entrance from docs"""
    campus_path = os.path.join(BASE_DIR, "docs", "images", "input_image.png")
    if os.path.exists(campus_path):
        img = Image.open(campus_path).convert('L').resize((WIDTH, HEIGHT))
        return np.array(img, dtype=np.uint8)
    else:
        raise FileNotFoundError(f"Campus image not found at {campus_path}")


def create_input3():
    """Input 3: Comprehensive Geometric & Frequency Benchmark"""
    img = np.full((HEIGHT, WIDTH), 240, dtype=np.uint8)

    # Grayscale intensity ramp at the top
    ramp_h = 45
    for c in range(WIDTH):
        img[10:10+ramp_h, c] = int(c * 255 / (WIDTH - 1))

    # Multi-frequency checkerboards
    for r in range(70, 150, 16):
        for c in range(25, 205, 16):
            if ((r // 16) + (c // 16)) % 2 == 0:
                img[r:r+16, c:c+16] = 20

    for r in range(70, 150, 8):
        for c in range(235, 395, 8):
            if ((r // 8) + (c // 8)) % 2 == 0:
                img[r:r+8, c:c+8] = 20

    for r in range(70, 150, 4):
        for c in range(425, 585, 4):
            if ((r // 4) + (c // 4)) % 2 == 0:
                img[r:r+4, c:c+4] = 20

    # Concentric circles
    c1 = (180, 275)
    for radius in range(12, 115, 12):
        cv2.circle(img, c1, radius, 30, 2)

    # Siemens star / radial spokes
    c2 = (460, 275)
    for angle_deg in range(0, 360, 10):
        rad = np.deg2rad(angle_deg)
        x2 = int(c2[0] + 105 * np.cos(rad))
        y2 = int(c2[1] + 105 * np.sin(rad))
        cv2.line(img, c2, (x2, y2), 20, 2)

    # Nested rotated diamonds and polygons
    c3 = (320, 470)
    for s in range(20, 150, 20):
        pts = np.array([[c3[0], c3[1]-s],
                        [c3[0]+s, c3[1]],
                        [c3[0], c3[1]+s],
                        [c3[0]-s, c3[1]]], np.int32)
        cv2.polylines(img, [pts], True, 30, 2)

    # Multi-angle line gratings (15, 30, 45, 60, 75 degrees)
    for i, angle in enumerate([15, 30, 45, 60, 75]):
        bx = 25 + i * 120
        by = 615
        cv2.rectangle(img, (bx, by), (bx + 110, by + 100), 20, 2)
        rad = np.deg2rad(angle)
        for offset in range(-80, 180, 10):
            p1 = (int(bx + offset), by)
            p2 = (int(bx + offset + 100 * np.cos(rad)), int(by + 100 * np.sin(rad)))
            cv2.line(img, p1, p2, 40, 2)

    # Text markings
    cv2.putText(img, "SOBEL ACCELERATOR TESTBENCH", (85, 755), cv2.FONT_HERSHEY_SIMPLEX, 0.9, 15, 2)
    cv2.putText(img, "RESOLUTION: 640x853 | FPGA CA01 BENCHMARK", (75, 795), cv2.FONT_HERSHEY_SIMPLEX, 0.65, 35, 2)

    return img


def create_input4():
    """Input 4: FPGA PCB Circuit Board Layout"""
    pcb = np.full((HEIGHT, WIDTH), 35, dtype=np.uint8)

    # Board edge and ground plane margin
    cv2.rectangle(pcb, (18, 18), (WIDTH - 18, HEIGHT - 18), 220, 2)
    cv2.rectangle(pcb, (24, 24), (WIDTH - 24, HEIGHT - 24), 170, 1)

    # Central large FPGA chip
    chip_s = 230
    cx, cy = WIDTH // 2, HEIGHT // 2 - 40
    cv2.rectangle(pcb, (cx - chip_s//2, cy - chip_s//2), (cx + chip_s//2, cy + chip_s//2), 85, -1)
    cv2.rectangle(pcb, (cx - chip_s//2, cy - chip_s//2), (cx + chip_s//2, cy + chip_s//2), 230, 2)
    cv2.circle(pcb, (cx - chip_s//2 + 20, cy - chip_s//2 + 20), 7, 240, -1)

    cv2.putText(pcb, "XILINX FPGA", (cx - 80, cy - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.75, 240, 2)
    cv2.putText(pcb, "XC7A100T-CSG324", (cx - 95, cy + 15), cv2.FONT_HERSHEY_SIMPLEX, 0.6, 200, 2)
    cv2.putText(pcb, "SOBEL-ACCEL 100MHz", (cx - 90, cy + 50), cv2.FONT_HERSHEY_SIMPLEX, 0.55, 180, 2)

    # Dense QFP/BGA Pins
    pin_len = 24
    for x in range(cx - chip_s//2 + 10, cx + chip_s//2 - 10, 8):
        cv2.line(pcb, (x, cy - chip_s//2), (x, cy - chip_s//2 - pin_len), 180, 2)
        cv2.line(pcb, (x, cy + chip_s//2), (x, cy + chip_s//2 + pin_len), 180, 2)
        cv2.circle(pcb, (x, cy - chip_s//2 - pin_len - 3), 2, 230, -1)
        cv2.circle(pcb, (x, cy + chip_s//2 + pin_len + 3), 2, 230, -1)

    for y in range(cy - chip_s//2 + 10, cy + chip_s//2 - 10, 8):
        cv2.line(pcb, (cx - chip_s//2, y), (cx - chip_s//2 - pin_len, y), 180, 2)
        cv2.line(pcb, (cx + chip_s//2, y), (cx + chip_s//2 + pin_len, y), 180, 2)
        cv2.circle(pcb, (cx - chip_s//2 - pin_len - 3, y), 2, 230, -1)
        cv2.circle(pcb, (cx + chip_s//2 + pin_len + 3, y), 2, 230, -1)

    # Bus traces
    for offset in range(-80, 90, 16):
        x_st = cx + offset
        cv2.line(pcb, (x_st, cy - chip_s//2 - 35), (x_st, 110), 160, 2)
        cv2.line(pcb, (x_st, 110), (x_st + 35, 75), 160, 2)
        cv2.circle(pcb, (x_st + 35, 75), 3, 230, -1)

    # SMD Component arrays
    for y in range(cy - 85, cy + 95, 26):
        # Left
        cv2.rectangle(pcb, (55, y), (85, y + 14), 130, -1)
        cv2.rectangle(pcb, (52, y), (57, y + 14), 220, -1)
        cv2.rectangle(pcb, (83, y), (88, y + 14), 220, -1)
        # Right
        cv2.rectangle(pcb, (WIDTH - 85, y), (WIDTH - 55, y + 14), 130, -1)
        cv2.rectangle(pcb, (WIDTH - 88, y), (WIDTH - 83, y + 14), 220, -1)
        cv2.rectangle(pcb, (WIDTH - 57, y), (WIDTH - 52, y + 14), 220, -1)

    # Gold Edge Connector Fingers
    for x in range(45, WIDTH - 45, 12):
        cv2.rectangle(pcb, (x, HEIGHT - 70), (x + 7, HEIGHT - 22), 235, -1)

    cv2.putText(pcb, "REV 1.0 (c) UT.CE 2026", (35, HEIGHT - 88), cv2.FONT_HERSHEY_SIMPLEX, 0.6, 210, 2)
    cv2.putText(pcb, "SOBEL HARDWARE ACCELERATOR TESTBENCH", (WIDTH - 460, HEIGHT - 88), cv2.FONT_HERSHEY_SIMPLEX, 0.5, 190, 1)

    return pcb


def create_input5():
    """Input 5: Natural Landscape & Terrain Scene"""
    landscape = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

    # Sky gradient
    for r in range(400):
        val = int(185 - (400 - r) * 0.25)
        landscape[r, :] = np.clip(val, 0, 255)

    # Sun with rays
    sun_c = (480, 140)
    cv2.circle(landscape, sun_c, 45, 252, -1)
    for a in range(0, 360, 20):
        rad = np.deg2rad(a)
        p2 = (int(sun_c[0] + 75 * np.cos(rad)), int(sun_c[1] + 75 * np.sin(rad)))
        cv2.line(landscape, sun_c, p2, 230, 2)

    # Distant Mountains
    pts_m1 = [[0, 360], [110, 240], [230, 310], [360, 190], [490, 280], [WIDTH, 220], [WIDTH, 420], [0, 420]]
    cv2.fillPoly(landscape, [np.array(pts_m1)], 125)
    # Snow caps
    cv2.fillPoly(landscape, [np.array([[110, 240], [80, 275], [140, 275]])], 245)
    cv2.fillPoly(landscape, [np.array([[360, 190], [320, 235], [400, 235]])], 245)
    cv2.fillPoly(landscape, [np.array([[WIDTH, 220], [WIDTH - 50, 255], [WIDTH, 265]])], 245)

    # Near Mountains
    pts_m2 = [[0, 450], [170, 320], [310, 410], [460, 330], [570, 390], [WIDTH, 350], [WIDTH, 520], [0, 520]]
    cv2.fillPoly(landscape, [np.array(pts_m2)], 75)

    # Pine Forest
    for x in range(0, WIDTH, 13):
        tree_h = int(35 + 20 * np.sin(x * 0.05) + 10 * np.cos(x * 0.13))
        base_y = 510 + int(10 * np.sin(x * 0.03))
        tree_pts = [[x, base_y], [x - 8, base_y], [x, base_y - tree_h], [x + 8, base_y]]
        cv2.fillPoly(landscape, [np.array(tree_pts)], 30)

    # Water lake
    for r in range(520, HEIGHT):
        landscape[r, :] = int(95 + (r - 520) * 0.22)

    # Water ripples
    np.random.seed(42)
    for _ in range(120):
        rx = np.random.randint(20, WIDTH - 80)
        ry = np.random.randint(530, HEIGHT - 20)
        rlen = np.random.randint(20, 70)
        rcolor = np.random.randint(140, 220)
        cv2.line(landscape, (rx, ry), (rx + rlen, ry), rcolor, 1)

    # Shoreline and rocks
    shore_pts = [[0, HEIGHT], [0, 740], [130, 760], [290, 800], [430, 780], [WIDTH, 820], [WIDTH, HEIGHT]]
    cv2.fillPoly(landscape, [np.array(shore_pts)], 45)
    for (cx, cy, rx, ry) in [(85, 790, 40, 20), (230, 815, 30, 15), (490, 825, 50, 22)]:
        cv2.ellipse(landscape, (cx, cy), (rx, ry), 0, 0, 360, 85, -1)
        cv2.ellipse(landscape, (cx, cy), (rx, ry), 0, 0, 360, 20, 2)

    return landscape


def main():
    generators = [
        ("input1", create_input1, "Architecture Building Facade (Original)"),
        ("input2", create_input2, "University Campus Entrance"),
        ("input3", create_input3, "Geometric & Frequency Test Pattern"),
        ("input4", create_input4, "FPGA PCB Electronic Circuit Layout"),
        ("input5", create_input5, "Natural Mountain & Lake Landscape")
    ]

    print("=== Generating 5 Input Images and Hex Files ===")
    for folder_name, gen_func, desc in generators:
        print(f"\nProcessing {folder_name}: {desc}...")
        img_arr = gen_func()
        target_dir = os.path.join(INPUTS_DIR, folder_name)
        if folder_name == "input1":
            ensure_dir(target_dir)
            orig_src = os.path.join(INPUTS_DIR, "input.png")
            shutil.copy(orig_src, os.path.join(target_dir, "input.png"))
            shutil.copy(orig_src, os.path.join(INPUTS_DIR, "input1.png"))
            # Generate hex
            hex_path = os.path.join(target_dir, "image_in.hex")
            with open(hex_path, "w") as f:
                for val in img_arr.flatten():
                    f.write(f"{int(val):02X}\n")
        else:
            save_image_and_hex(img_arr, target_dir)
            direct_png = os.path.join(INPUTS_DIR, f"{folder_name}.png")
            Image.fromarray(img_arr).save(direct_png)

    print("\nAll input images generated successfully!")


if __name__ == "__main__":
    main()
