import json, random, sys, os, shutil
from PIL import Image, ImageDraw
# usage: build_judge.py <baseline_dir> <candidate_dir> <out_dir> <seed>
base, cand, out, seed = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
phases = ["launch", "flight", "contact", "impact", "aftermath"]
rng = random.Random(seed)
os.makedirs(out); os.makedirs(out + "/frames")
br = json.load(open(base + "/results.json")); cr = json.load(open(cand + "/results.json"))
order = list(range(len(cr["cases"]))); rng.shuffle(order)
mapping = []
for n, idx in enumerate(order):
    b, c = br["cases"][idx], cr["cases"][idx]
    assert (b["id"], b["rank"]) == (c["id"], c["rank"])
    sides = [("baseline", base), ("candidate", cand)]; rng.shuffle(sides)
    entry = {"sequence": "S%02d" % (n + 1), "case": c["id"], "rank": c["rank"]}
    for label, (kind, folder) in zip(["A", "B"], sides):
        entry[label] = kind
        strip = Image.new("RGB", (960 * 3, 540 * 2), (20, 20, 20))
        draw = ImageDraw.Draw(strip)
        for i, ph in enumerate(phases):
            src = "%s/sequence-%02d-%s.png" % (folder, idx, ph)
            dst = "%s/frames/S%02d%s-%d-%s.png" % (out, n + 1, label, i + 1, ph)
            shutil.copy(src, dst)
            strip.paste(Image.open(src).convert("RGB").resize((960, 540)), ((i % 3) * 960, (i // 3) * 540))
            draw.text(((i % 3) * 960 + 12, (i // 3) * 540 + 10), "%d %s" % (i + 1, ph), fill=(255, 255, 255))
        strip.save("%s/S%02d%s-strip.png" % (out, n + 1, label))
    mapping.append(entry)
json.dump(mapping, open(out + ".private-mapping.json", "w"), indent=1)
print(len(mapping), "sequences")
