import json, os, random, shutil, sys
from PIL import Image, ImageDraw
before, after, out, seed = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
random.seed(seed)
shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
key = {}
groups = [["00","02","04","06"], ["10","16","24"]]
for shot in ["quick","charged","crit","incoming"]:
    a_after = random.random() < 0.5
    key[shot] = {"A": "after" if a_after else "before", "B": "before" if a_after else "after"}
    for label, src in (("A", after if a_after else before), ("B", before if a_after else after)):
        for gi, offs in enumerate(groups):
            sheet = Image.new("RGB", (1920, 1080), (20, 20, 20))
            draw = ImageDraw.Draw(sheet)
            for i, off in enumerate(offs):
                tile = Image.open(f"{src}/{shot}-{off}.png").convert("RGB").resize((960, 540), Image.LANCZOS)
                x, y = (i % 2) * 960, (i // 2) * 540
                sheet.paste(tile, (x, y))
                draw.rectangle([x, y, x + 150, y + 34], fill=(0, 0, 0))
                draw.text((x + 8, y + 8), f"{shot} {label} +{off}f", fill=(255, 255, 255))
            sheet.save(f"{out}/{shot}-{label}-sheet{gi+1}.png")
json.dump(key, open(out + ".key.json", "w"), indent=1)
print(len(os.listdir(out)))
