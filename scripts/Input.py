import cv2

# Load image using OpenCV Grayscale to ensure bit-level consistency with Checker.py
img = cv2.imread('input.png', cv2.IMREAD_GRAYSCALE)
img = cv2.resize(img, (640, 853))

with open('image_in.hex', 'w') as f:
    for pixel in img.flatten():
        f.write(f"{pixel:02X}\n")

print("image_in.hex generated successfully!")
