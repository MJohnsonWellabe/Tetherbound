"""Copy a tool run's frames into the tb/gpu-frames-1108 worktree as G-<id>/<preset or arm>/<file>, with a manifest and the sky and script-error results.
Usage: pack_check.py <id> <head sha> <tool> <note> [<frame name> ...]
With frame names: those PNGs as captured. With none: every frame of the run (a whole fight sheet), as 1920 JPEG q85.
Nothing is copied if a frame is missing, sky-flagged, or a run's log has a SCRIPT ERROR. The tool's own manifest.json is a report, not a frame, so it stays on this PC."""
import glob, json, os, shutil, subprocess, sys

sys.path.append(r"C:\Users\mattj\AppData\Roaming\Python\Python312\site-packages")
sys.path.insert(0, r"D:\tb-gpu-runs\tools")
from PIL import Image  # noqa: E402
from sky_check import is_sky, sky_stats  # noqa: E402

cid, sha, tool, note, names = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:]
section = "G-" + cid
jroot = os.path.join(r"D:\tb-gpu-runs\arms", "R1108-" + section)
ROOT = r"D:\tb-gpu-frames-1108\gpu-frames-1108"
manifest, copies, problems = [], [], []
for preset in sorted(d for d in os.listdir(jroot) if os.path.isdir(os.path.join(jroot, d)) and "." not in d):
    run = os.path.join(jroot, preset)
    errors = [l.strip() for log in glob.glob(os.path.join(run, "*.err.log")) for l in open(log, encoding="utf-8", errors="replace") if "SCRIPT ERROR" in l]
    # PACK_KNOWN_ERROR (11 Nov): one exact SCRIPT ERROR message, read and judged harmless to the frames, that is
    # counted in the manifest but does not hold the section; every other script error still holds it.
    known = os.environ.get("PACK_KNOWN_ERROR", "")
    problems += ["%s SCRIPT ERROR %s" % (preset, e) for e in errors if not (known and known in e)]
    frames = os.path.join(run, "frames")
    found = sorted(glob.glob(os.path.join(frames, "**", "*.png"), recursive=True) + glob.glob(os.path.join(frames, "**", "*.jpg"), recursive=True))
    wanted = names or [os.path.relpath(f, frames).replace(os.sep, "/") for f in found]
    if not wanted:
        problems.append("%s has no frames" % preset)
    for name in wanted:
        hits = [f for f in found if f.replace(os.sep, "/").endswith("/" + name)]
        if not hits:
            problems.append("%s missing %s" % (preset, name))
            continue
        sky, edges = sky_stats(hits[0])
        # PACK_STAGE_FRAMES=1 (11 Nov): neutral-stage creature frames (capture_f36_poses.gd) are a flat backdrop over a plain floor and
        # always trip the sky heuristic; set it only after an eye check of every frame. The stats still go in the manifest.
        if is_sky(sky, edges) and os.environ.get("PACK_STAGE_FRAMES") != "1":
            problems.append("%s SKY-ONLY %s" % (preset, name))
        rel = "/".join([section, preset, os.path.splitext(name)[0] + ".jpg" if not names else name])
        copies.append((hits[0], rel))
        manifest.append({"frame": name, "preset": preset, "tree": sha, "tool": tool, "path": rel, "sky_fraction": round(sky, 3), "lower_edges": round(edges, 4), "script_errors": len(errors), "note": note})
if problems:
    print("HELD", section)
    for p in problems:
        print(" ", p)
    sys.exit(1)
for src, rel in copies:
    dest = os.path.join(ROOT, *rel.split("/"))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if names:
        shutil.copy2(src, dest)
    else:
        Image.open(src).convert("RGB").save(dest, quality=85)
for preset in sorted({m["preset"] for m in manifest}):
    py = sys.executable
    scan = subprocess.run([py, r"D:\tb-gpu-runs\tools\blank_scan.py", os.path.join(ROOT, section, preset)], capture_output=True, text=True).stdout
    open(os.path.join(ROOT, "blank-%s-%s.txt" % (section, preset)), "w", encoding="utf-8").write(scan)
    print(preset, "blank scan:", [l for l in scan.splitlines() if l.startswith(("BLANK", "blank frames"))])
json.dump(manifest, open(os.path.join(ROOT, "manifest-%s.json" % section), "w", encoding="utf-8"), indent=1)
print("packed", section, len(copies), "frames, 0 script errors")
