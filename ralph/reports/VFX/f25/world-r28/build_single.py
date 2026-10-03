import json, random, sys, os, shutil
from PIL import Image, ImageDraw
# usage: build_single.py <capture_dir> <out_dir> <seed> [prefix=sequence]
src, out, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
prefix = sys.argv[4] if len(sys.argv) > 4 else "sequence"
res = json.load(open(src + "/results.json"))
phases = sorted({f.split("-", 2)[2][:-4] for f in os.listdir(src) if f.startswith(prefix + "-")},
                key=lambda p: ["launch", "windup", "flight", "travel", "contact", "impact", "peak", "aftermath", "late"].index(p))
rng = random.Random(seed)
order = list(range(len(res["cases"]))); rng.shuffle(order)
os.makedirs(out + "/frames")
mapping = []
for n, idx in enumerate(order):
    c = res["cases"][idx]
    seq = "S%02d" % (n + 1)
    strip = Image.new("RGB", (960 * 3, 540 * 2), (20, 20, 20)); draw = ImageDraw.Draw(strip)
    for i, ph in enumerate(phases):
        f = "%s/%s-%02d-%s.png" % (src, prefix, idx, ph)
        Image.open(f).convert("RGB").resize((1600, 900)).save("%s/frames/%s-%d-%s.jpg" % (out, seq, i + 1, ph), quality=90)
        strip.paste(Image.open(f).convert("RGB").resize((960, 540)), ((i % 3) * 960, (i // 3) * 540))
        draw.text(((i % 3) * 960 + 12, (i // 3) * 540 + 10), "%d %s" % (i + 1, ph), fill=(255, 255, 255))
    strip.save("%s/%s-strip.jpg" % (out, seq), quality=90)
    mapping.append({"sequence": seq, "case": c.get("id"), "rank": c.get("rank"), "breakthrough_count": c.get("breakthrough_count"), "index": idx})
json.dump(mapping, open(out + ".private-mapping.json", "w"), indent=1)
print(len(mapping), "sequences", phases)
