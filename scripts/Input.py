from PIL import Image

img = Image.open('input.png').convert('L')
img = img.resize((640,853))

with open('image_in.hex','w') as f:
    for pixel in list(img.getdata()):
        f.write(f"{pixel:02X}\n")

print("image_in.hex generated successfully!")