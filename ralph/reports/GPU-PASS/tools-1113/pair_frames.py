"""Per-frame camera pairing across runs of the same config: the fight camera is not deterministic run to run (13 Nov), so for each frame pick the
base run and arm run whose capture_manifest camera_position match best.
Usage: pair_frames.py --base dir1,dir2 --arm dir3,dir4 --frames a.png,b.png [--tol 0.3] [--json out.json]
(dirs are the runs' frames/ folders). Prints one line per frame: best distance, the chosen base and arm dirs, OK/NO MATCH."""
import argparse, json, math, sys

ap = argparse.ArgumentParser()
ap.add_argument("--base", required=True); ap.add_argument("--arm", required=True); ap.add_argument("--frames", required=True)
ap.add_argument("--tol", type=float, default=0.3); ap.add_argument("--json")
a = ap.parse_args()


def cams(d):
    try:
        m = json.load(open(d + "/capture_manifest.json", encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return {(fr.get("file") or fr.get("name") or fr.get("path") or "").replace("\\", "/").split("/")[-1]: fr.get("camera_position") for fr in m.get("frames", [])}


B = {d: cams(d) for d in a.base.split(",")}
A = {d: cams(d) for d in a.arm.split(",")}
out, bad = {}, 0
for f in a.frames.split(","):
    best = None
    for bd, bc in B.items():
        for ad, ac in A.items():
            if bc.get(f) and ac.get(f):
                dist = math.dist(bc[f], ac[f])
                if best is None or dist < best[0]:
                    best = (dist, bd, ad)
    if best is None:
        print("  %s: no camera data" % f); bad += 1; continue
    ok = best[0] <= a.tol
    bad += 0 if ok else 1
    out[f] = {"dist": round(best[0], 2), "base": best[1], "arm": best[2], "ok": ok}
    print("  %-28s %5.2f  %s  base=%s  arm=%s" % (f, best[0], "OK" if ok else "NO MATCH", best[1], best[2]))
if a.json:
    json.dump(out, open(a.json, "w"), indent=1)
print("pair_frames: %d of %d frames unmatched" % (bad, len(a.frames.split(","))))
sys.exit(0 if bad == 0 else 1)
