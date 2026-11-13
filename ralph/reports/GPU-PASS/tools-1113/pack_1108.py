"""Copy one re-score section's judged frames into the tb/gpu-frames-1108 worktree and write its manifest.
Usage: pack_1108.py <section> <arm=sha> [<arm=sha> ...]   (env PACK_LABEL/PACK_NOTE: publish under another section name, with a note)
Layout: gpu-frames-1108/<row>/<arm>/High/<frame id>.jpg (row "F38#19" becomes folder "F38-19"), plus gpu-frames-1108/manifest-<label>.json.
Frame ids resolve through frame_match (the same rules arm_resolve.py uses); images are written 1920 wide, JPEG q85.
If any frame does not resolve, nothing is staged: the packed section goes to frames-1108/held-<label> for a look before any push."""
import json, os, re, shutil, sys

sys.path.append(r"C:\Users\mattj\AppData\Roaming\Python\Python312\site-packages")
sys.path.insert(0, r"D:\tb-gpu-runs\tools")
from PIL import Image  # noqa: E402
from frame_match import images, match  # noqa: E402
from sky_check import is_sky, sky_stats  # noqa: E402

section, arms = sys.argv[1], dict(a.split("=", 1) for a in sys.argv[2:])
label, note = os.environ.get("PACK_LABEL") or section, os.environ.get("PACK_NOTE") or ""; PRESET = os.environ.get("PACK_PRESET") or "High"
RUNS = r"D:\tb-gpu-runs"
ITEMS = os.environ.get("TB_ITEMS_ROOT") or os.path.join(RUNS, "itemscores-1108")
job = json.load(open(os.path.join(ITEMS, "job.json"), encoding="utf-8"))
rows = {it["item"]: it["board_row"] for doc in job["biomes"].values() for it in doc["items"]}
cmds = {(c["biome"], c["key"]): c["args"] for c in json.load(open(os.path.join(ITEMS, "cmds.json"), encoding="utf-8"))}
index = json.load(open(os.path.join(RUNS, "arms", "R1108-" + section, "items.json"), encoding="utf-8-sig"))
if isinstance(index, dict):
    index = [index]
manifest, missing, copies = [], [], []
semantic = json.load(open(os.environ["PACK_SEMANTIC"], encoding="utf-8")) if os.environ.get("PACK_SEMANTIC") else {}  # {frame id: source image}
for arm, sha in arms.items():
    for e in index:
        row = rows.get(e["item"], e["item"])
        args = cmds[(e["biome"], e["cmd"])]
        rec = {"row": row, "item": e["item"], "frame": e["frame"], "arm": arm, "tree": sha, "preset": PRESET,
               "tool": next((a for a in args if a.startswith("tools/")), ""), "args": args}
        if note:
            rec["note"] = note
        folder = os.path.join(RUNS, "arms", "R1108-" + section, arm + "-" + PRESET, e["biome"] + "-" + e["cmd"], "frames")
        path, how = match(e["frame"], images(folder), secs_tol=1.0)  # coordinator 8 Nov: nearest within 1 s, marked match: nearest
        log = os.path.join(os.path.dirname(folder), "_run.log")
        if "live_fight" in rec["tool"] and os.path.exists(log):  # the live-fight pilot can lose; judges need to know which run this is
            won = re.findall(r"PHASE2 CLOUDREACH FIGHT won=(true|false)", open(log, encoding="utf-8", errors="replace").read())
            if won:
                rec["won"] = won[-1] == "true"
        if not path and e["frame"] in semantic:  # coordinator 9 Nov: published for its beat whatever the time
            path, how = semantic[e["frame"]], "semantic"
        rec["match"] = how
        if not path:
            rec["path"] = None
            missing.append(arm + " " + row + " " + e["frame"])
        else:
            # G sections live in their own folder: an arm tag like "live" recurs on other trees, and the same path would overwrite section F's frames (8 Nov).
            rel = "/".join(([section] if section.startswith("G-") else []) + [row.replace("#", "-"), arm, PRESET, e["frame"] + ".jpg"])
            rec["path"] = rel
            copies.append((str(path), rel))
        manifest.append(rec)
# A frame that genuinely does not exist in this capture may be published as null, with its reason, from frames-1108/reasons-<label>.json.
rp = os.path.join(RUNS, "frames-1108", "reasons-%s.json" % label)
reasons = json.load(open(rp, encoding="utf-8")) if os.path.exists(rp) else {}
for m in manifest:
    if not m["path"] and m["frame"] in reasons:
        m["missing_reason"] = reasons[m["frame"]]
# Sky-only frames pass blank_scan, so each packed frame also goes through sky_check; a flagged frame holds the section like a null does.
sources = dict((rel, path) for path, rel in copies)
for m in manifest:
    if m["path"]:
        sky, edges = sky_stats(sources[m["path"]])
        m["sky_fraction"], m["lower_edges"] = round(sky, 3), round(edges, 4)
        if is_sky(sky, edges):
            m["sky_flag"] = True
            if m["frame"] not in reasons:
                missing.append(m["arm"] + " " + m["row"] + " " + m["frame"] + " SKY-ONLY")
held = any((not m["path"] and "missing_reason" not in m) or (m.get("sky_flag") and m["frame"] not in reasons) for m in manifest)
ROOT = os.path.join(RUNS, "frames-1108", "held-" + label) if held else (os.environ.get("PACK_ROOT") or os.path.join(r"D:\tb-gpu-frames-1108", "gpu-frames-1108"))
for path, rel in copies:
    dest = os.path.join(ROOT, *rel.split("/"))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im = Image.open(path).convert("RGB")
    if im.width != 1920:
        im = im.resize((1920, round(im.height * 1920 / im.width)), Image.LANCZOS)
    im.save(dest, quality=85)
os.makedirs(ROOT, exist_ok=True)
for arm in arms:
    blank = os.path.join(RUNS, "frames-1108", section, arm, PRESET, "_blank.txt")
    if os.path.exists(blank):
        shutil.copy2(blank, os.path.join(ROOT, "blank-%s-%s.txt" % (label, arm)))
json.dump(manifest, open(os.path.join(ROOT, "manifest-%s.json" % label), "w", encoding="utf-8"), indent=1)
print("packed", label, "frames", sum(1 for m in manifest if m["path"]), "of", len(manifest), "missing", len(missing), "HELD, not staged" if held else "")
for m in missing:
    print("  MISSING", m)
hows = {}
for m in manifest:
    hows[m["match"]] = hows.get(m["match"], 0) + 1
print("  match rules:", hows)
