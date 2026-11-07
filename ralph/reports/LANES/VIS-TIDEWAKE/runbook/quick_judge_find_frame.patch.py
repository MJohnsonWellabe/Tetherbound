#!/usr/bin/env python3
"""Re-apply VIS-TIDEWAKE's find_frame fallback (F39#28 blocker) to the local quick_judge.py copy. Idempotent."""
import re, pathlib
p = pathlib.Path("/home/user/Tetherbound/tools/visual_judge/quick_judge.py")
s = p.read_text()
if "nearest in time" in s:
    raise SystemExit(0)
old = """    for n in names:
        for ext in ("png", "jpg"):
            hits = sorted(Path(d).rglob(f"{n}.{ext}"))
            if hits:
                return hits[0]
    return None
"""
new = old[:-len("    return None\n")] + """    # Fight tools write "<tag>-SSS.SS"; catalogue ids spell "<tag>-SSS_SS" and come
    # from GPU runs whose beat times differ on CPU (VIS-TIDEWAKE F39#28). Fall back
    # to the dotted spelling, then to the same-tag frame nearest in time.
    m = re.match(r"^(.*)-(\\d+)_(\\d+)$", fid.rsplit("__", 1)[-1])
    if m:
        tag, want = m.group(1), float(f"{m.group(2)}.{m.group(3)}")
        best = None
        for ext in ("png", "jpg"):
            for hit in Path(d).rglob(f"{tag}-*.{ext}"):
                t = re.match(rf"^{re.escape(tag)}-(\\d+\\.\\d+)$", hit.stem)
                if t and (best is None or abs(float(t.group(1)) - want) < best[0]):
                    best = (abs(float(t.group(1)) - want), hit)
        if best:
            return best[1]
    return None
"""
assert s.count(old) == 1
p.write_text(s.replace(old, new))

