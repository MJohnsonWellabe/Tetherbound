import sys
from PIL import Image

# Simple pixel-region sampler, same spirit as the T1-ARCH report's manual
# pixel sample of a wall face. Usage: _sample_castle_wall.py <png> <x> <y> <box>
path = sys.argv[1]
cx = int(sys.argv[2])
cy = int(sys.argv[3])
box = int(sys.argv[4]) if len(sys.argv) > 4 else 6
img = Image.open(path).convert("RGB")
w, h = img.size
xs = range(max(0, cx - box), min(w, cx + box))
ys = range(max(0, cy - box), min(h, cy + box))
pixels = [img.getpixel((x, y)) for x in xs for y in ys]
r = sum(p[0] for p in pixels) / len(pixels)
g = sum(p[1] for p in pixels) / len(pixels)
b = sum(p[2] for p in pixels) / len(pixels)
print(f"{path} @({cx},{cy})±{box}: avg RGB = ({r:.1f}, {g:.1f}, {b:.1f}) over {len(pixels)} px")
