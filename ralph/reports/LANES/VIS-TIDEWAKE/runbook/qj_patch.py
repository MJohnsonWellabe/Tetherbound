#!/usr/bin/env python3
"""Apply the VIS-TIDEWAKE quick_judge fixes to the tracked tools/visual_judge/quick_judge.py (idempotent).
1. find_frame: Tidewake route/location tools write water__<stand> files for tidewake__<stand> ids.
2. Tool-forced output dirs: frames go to <parent>/qj_tmp/ (one ignored folder a lane can symlink to RAM)."""
from pathlib import Path
p = Path("/home/user/Tetherbound/tools/visual_judge/quick_judge.py"); s = p.read_text()
a_old = '''    if fid.count("__") >= 2:
        names.append(fid.split("__", 2)[2])
    for n in names:'''
a_new = '''    if fid.count("__") >= 2:
        names.append(fid.split("__", 2)[2])
    if fid.startswith("tidewake__"):  # Tidewake route/location tools write water__<stand> files
        names.append("water__" + fid.split("__", 1)[1])
    for n in names:'''
if a_new not in s:
    assert a_old in s; s = s.replace(a_old, a_new)
b_old = '''    tmp_rel = f"{rel_parent}/qj_{side_key}_{key}"'''
b_new = '''    # One qj_tmp/ folder under the tool's forced parent, so a disk-tight lane can symlink it to RAM.
    tmp_rel = f"{rel_parent}/qj_tmp/qj_{side_key.replace('/', '_')}_{key}"'''
if b_new not in s:
    assert b_old in s; s = s.replace(b_old, b_new)
p.write_text(s); print("quick_judge patched")
