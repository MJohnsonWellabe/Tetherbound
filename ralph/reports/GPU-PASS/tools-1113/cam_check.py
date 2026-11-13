"""Compare capture_manifest camera_position for named frames between a side and one or more references.
Usage: cam_check.py <side_frames_dir> <ref_frames_dir> [<ref_frames_dir> ...] --frames a.png,b.png [--tol 0.3]
Exit 0 when every named frame is within tol metres of the first reference, 1 otherwise, 2 when a manifest is missing."""
import json, math, sys


def cams(d):
    m = json.load(open(d + "/capture_manifest.json", encoding="utf-8"))
    out = {}
    for fr in m.get("frames", []):
        n = (fr.get("file") or fr.get("name") or fr.get("path") or "").replace("\\", "/").split("/")[-1]
        out[n] = fr.get("camera_position")
    return out


args = sys.argv[1:]
tol = 0.3
if "--tol" in args:
    i = args.index("--tol"); tol = float(args[i + 1]); del args[i:i + 2]
i = args.index("--frames"); frames = args[i + 1].split(","); del args[i:i + 2]
try:
    side, refs = cams(args[0]), [cams(r) for r in args[1:]]
except (OSError, ValueError) as e:
    print("cam_check: " + str(e)); sys.exit(2)
worst = 0.0
for f in frames:
    ds = [round(math.dist(side[f], r[f]), 2) if side.get(f) and r.get(f) else None for r in refs]
    print("  cam %s: %s" % (f, ds))
    if ds[0] is None or ds[0] > tol:
        worst = max(worst, ds[0] if ds[0] is not None else 99)
print("cam_check worst=%.2f tol=%.2f -> %s" % (worst, tol, "OK" if worst <= tol else "SHIFTED"))
sys.exit(0 if worst <= tol else 1)
