"""Build R1108-G-<section>/{base,arm}-<preset>/frames from a pair_frames.py JSON (camera-matched frames that may come from different runs),
copying each source run's *.err.log so pack_check.py still sees every script error. Usage: compose_pairs.py <pairs.json> <section> <preset>"""
import json, os, shutil, sys
pairs, section, preset = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
A = r"D:\tb-gpu-runs\arms"
root = os.path.join(A, "R1108-G-" + section)
shutil.rmtree(root, ignore_errors=True)
for side in ("base", "arm"):
    d = os.path.join(root, "%s-%s" % (side, preset), "frames"); os.makedirs(d)
    srcs = sorted({p[side] for p in pairs.values()})
    for i, s in enumerate(srcs):
        run = os.path.dirname(os.path.join(A, s.replace("/", os.sep)))
        for f in os.listdir(run):
            if f.endswith(".err.log"):
                shutil.copy2(os.path.join(run, f), os.path.join(os.path.dirname(d), "src%d-%s" % (i, f)))
    for f, p in pairs.items():
        shutil.copy2(os.path.join(A, p[side].replace("/", os.sep), f), os.path.join(d, f))
print(root, {f: (p["dist"], p["ok"]) for f, p in pairs.items()})
