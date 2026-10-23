import numpy as np
from PIL import Image
import cv2

width, height = 640,853
pixels= []

with open('image_out.hex','r') as f:
    for line in f:
        if line.strip():
            pixels.append(int(line.strip(), 16))

hw_img_array= np.array(pixels[:width*height],dtype=np.uint8).reshape((height, width))
hw_image =Image.fromarray(hw_img_array)
hw_image.save('hardware_sobel_result.png')

input_img =cv2.imread('input.png',cv2.IMREAD_GRAYSCALE)
input_img= cv2.resize(input_img,(width, height))

sobelx=cv2.Sobel(input_img, cv2.CV_64F, 1,0, ksize=3)
sobely = cv2.Sobel(input_img,cv2.CV_64F,0,1, ksize=3)
abs_sobel= np.abs(sobelx) +np.abs(sobely)
sw_img_array = np.clip(abs_sobel, 0, 255).astype(np.uint8)

diff = np.abs(hw_img_array.astype(int)- sw_img_array.astype(int))
print(f"Mean error when comparing:{np.mean(diff):.2f}")