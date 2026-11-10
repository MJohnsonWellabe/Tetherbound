"""Draw keyboard_tab.png: the vendored Kenney keyboard_escape keycap with its
cut-out label replaced by the standard Tab symbol (an arrow into a bar, as on
physical keycaps), rendered at 4x and downsampled. No external source."""
import sys
from PIL import Image, ImageDraw
src, out = sys.argv[1:3]
im = Image.open(src).convert("RGBA")
px = im.load()
for y in range(14, 50):
    for x in range(14, 50):
        px[x, y] = (255, 255, 255, 255)
S = 4
mask = Image.new("L", (64 * S, 64 * S), 0)
d = ImageDraw.Draw(mask)
cy = 32 * S
d.rectangle([20 * S, cy - 2 * S, 38 * S, cy + 2 * S], fill=255)        # shaft
d.polygon([(36 * S, cy - 8 * S), (44 * S, cy), (36 * S, cy + 8 * S)], fill=255)  # head
d.rectangle([45 * S, cy - 9 * S, 49 * S, cy + 9 * S], fill=255)        # stop bar
mask = mask.resize((64, 64), Image.LANCZOS)
for y in range(64):
    for x in range(64):
        a = mask.getpixel((x, y))
        if a > 0 and px[x, y][3] > 0:
            px[x, y] = (255, 255, 255, 255 - a)
im.save(out)
