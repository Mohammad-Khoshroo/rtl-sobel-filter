import cv2
import numpy as np

ref_img = cv2.imread('inputs/input1/input.png', cv2.IMREAD_GRAYSCALE)
ref_img = cv2.resize(ref_img, (640, 853))

gx = cv2.Sobel(ref_img, cv2.CV_16S, 1, 0, ksize=3)
gy = cv2.Sobel(ref_img, cv2.CV_16S, 0, 1, ksize=3)
g = cv2.add(np.abs(gx), np.abs(gy))
g = np.clip(g, 0, 255).astype(np.uint8)
ref_cropped = g[1:-1, 1:-1]

print("==========================================================")
print(" OpenCV Verification of Simulation Dumps")
print("==========================================================")
for arch in ['baseline', 'optimized', 'pipeline']:
    hex_path = f'sim/image_out_{arch}.hex'
    try:
        with open(hex_path, 'r') as f:
            vals = [int(line.strip(), 16) for line in f if line.strip()]
        hw_arr = np.array(vals, dtype=np.uint8).reshape((851, 638))
        mean_err = np.mean(np.abs(ref_cropped.astype(float) - hw_arr.astype(float)))
        # Save output image
        out_png = f'sim/result_{arch}.png'
        cv2.imwrite(out_png, hw_arr)
        print(f"[{arch.upper():9s}] Total Pixels: {len(vals):6d} | Mean Error: {mean_err:.2f} | Saved: {out_png}")
    except Exception as e:
        print(f"[{arch.upper():9s}] Error reading {hex_path}: {e}")
print("==========================================================")
