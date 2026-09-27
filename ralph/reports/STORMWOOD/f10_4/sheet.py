"""Contact sheet: rows = stands, columns = phases. usage: sheet.py <dir> <out.jpg> [cell_w]"""
import sys, os
from PIL import Image, ImageDraw
d, out = sys.argv[1], sys.argv[2]
cw = int(sys.argv[3]) if len(sys.argv) > 3 else 640
stands = ["forest", "giant", "glass", "rod_line", "stormheart"]
cols = ["calm", "break", "aftermath_calm"]
ch = cw * 9 // 16
sheet = Image.new("RGB", (cw * len(cols), (ch + 18) * len(stands)), (20, 20, 24))
dr = ImageDraw.Draw(sheet)
for r, s in enumerate(stands):
    for c, p in enumerate(cols):
        f = os.path.join(d, f"{s}_{p}.jpg")
        if not os.path.exists(f):
            continue
        sheet.paste(Image.open(f).resize((cw, ch)), (c * cw, r * (ch + 18) + 18))
        dr.text((c * cw + 4, r * (ch + 18) + 3), f"{s}_{p}", fill=(230, 230, 230))
sheet.save(out, quality=85)
