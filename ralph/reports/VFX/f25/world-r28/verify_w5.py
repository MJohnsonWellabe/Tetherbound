import os, re, sys, json
# Match every PNG's mtime to a capture line printed by the surviving run.
S = sys.argv[1]; log = open(S + "/w5.log").read()
start = os.stat(S + "/w5.log").st_ctime  # log created at process start (approx)
caps = [(m.group(1), m.group(2), int(m.group(3))) for m in re.finditer(r"F25 capture (\S+) (\w+) wall=(\d+)ms", log)]
order = []
for enc, ph, ms in caps:
    if enc not in order: order.append(enc)
bad = []
deltas = []
for enc, ph, ms in caps:
    idx = order.index(enc)
    f = "%s/w5/sequence-%02d-%s.png" % (S, idx, ph)
    if not os.path.exists(f): bad.append((f, "missing")); continue
    deltas.append((os.path.basename(f), os.stat(f).st_mtime - ms / 1000.0))
# One process clock: every file's (mtime - logged wall) is the same constant.
base = sorted(d for _, d in deltas)[len(deltas) // 2] if deltas else 0
for name, d in deltas:
    if abs(d - base) > 20: bad.append((name, round(d - base, 1)))
expected = {"sequence-%02d-%s.png" % (order.index(e), p) for e, p, _ in caps}
stray = sorted(f for f in os.listdir(S + "/w5") if f.endswith(".png") and f not in expected)
print(len(caps), "captures logged by surviving run;", len(bad), "off its clock;", len(stray), "files it never wrote:", stray)
for b in bad: print(" ", b)
