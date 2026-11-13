"""Export one batch-driver capture to JPEG for the cloud judges (local GPU-pass helper, 1 Nov).

    python vb_export.py arms <job arm dir> <out tree dir>      # an arm_run job, e.g. arms/VB-main-meadows/main-High
    python vb_export.py flat <frames dir> <out tree dir> <set> # one launch's frames (F36 roster, F17-6 hall set)

Every image becomes <out tree dir>/<set>/<stand>.jpg, 1920 wide, quality 85. In an arm_run job a grouped launch is the set
'<biome>-<tool>'; a single command is '<biome>-<tool>-<hash of its args>' (stable across trees: the same job.json command), so the
same stand names appear in both trees. Member folders that only hold a grouped launch's copied frames are skipped.
"""
import hashlib
import json
import os
import sys
from pathlib import Path

# run_tool.ps1 points APPDATA at an isolated Godot profile for the whole PowerShell session, which hides the per-user site-packages
# (where Pillow is installed) from a python started later in that session.
sys.path.append(r"C:\Users\mattj\AppData\Roaming\Python\Python312\site-packages")
from PIL import Image

ROOT = Path(__import__("os").environ.get("TB_ITEMS_ROOT") or "D:/tb-gpu-runs/itemscores")


def cmds():
    by = {}
    for f in ("cmds.json", "cmds_extra.json"):
        p = ROOT / f
        if p.exists():
            for c in json.loads(p.read_text(encoding="utf-8-sig")):
                by[(c["biome"], c["key"])] = c
    return by


def tool_of(c):
    a = c["args"]
    return Path(a[a.index("--script") + 1]).stem.replace("phase2_capture_", "")


def save(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(src) as im:
        im = im.convert("RGB")
        if im.width != 1920:
            im = im.resize((1920, round(im.height * 1920 / im.width)), Image.LANCZOS)
        im.save(dest, "JPEG", quality=85)


def images(folder):
    for r, _, fs in os.walk(folder):
        for f in fs:
            if f.lower().endswith((".png", ".jpg")):
                yield Path(r) / f


def export_arms(job_dir, out):
    by = cmds()
    n = 0
    seen = set()
    for d in sorted(Path(job_dir).iterdir()):
        if not d.is_dir() or (d / "_grouped.txt").exists() or d.name.endswith(tuple(f".try{i}" for i in range(1, 4))):
            continue
        if d.name.startswith("_grp-"):
            biome, key = d.name[5:].rsplit("-", 1)
            set_name = f"{biome}-{tool_of(by[(biome, key)])}"
        else:
            biome, key = d.name.rsplit("-", 1)
            c = by[(biome, key)]
            set_name = f"{biome}-{tool_of(c)}-{hashlib.sha1(' '.join(c['args']).encode()).hexdigest()[:6]}"
        for img in images(d):
            dest = out / set_name / (img.stem + ".jpg")
            if dest in seen:
                continue
            seen.add(dest)
            save(img, dest)
            n += 1
    return n


def export_flat(frames, out, set_name):
    n = 0
    for img in images(frames):
        save(img, out / set_name / (img.stem + ".jpg"))
        n += 1
    return n


if __name__ == "__main__":
    mode, src, out = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
    n = export_arms(src, out) if mode == "arms" else export_flat(src, out, sys.argv[4])
    print(f"exported {n} frames from {src} -> {out}")
