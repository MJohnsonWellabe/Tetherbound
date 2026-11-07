#!/usr/bin/env python3
"""Quick A/B judging round for one catalogue item (owner, 4 Nov 2026: "Set up a fast way to judge").

The yardstick is unchanged: the same JUDGE_PROMPT.md block (verbatim), 3+ anchor pairs from
anchor_tiles.py, three fresh code-blind judges and calibrate.py. The speed comes from capturing
only the item's own stands, never re-importing, reusing the base capture for an unchanged tree,
and running the 3 judges in one message.

    quick_judge.py plan    F39#23                       # stands + the deduped launches
    quick_judge.py run     F39#23 [--overlay o.json]    # capture base (cached) + candidate, build packet
    quick_judge.py capture F39#23 [--overlay o.json]    # capture only
    quick_judge.py packet  <round dir>                  # (re)build the judge packet from captures
    quick_judge.py finish  <round dir>                  # judges' replies -> batch, mapped, VERDICT, sheet
    quick_judge.py revert                               # restore files from a crashed overlay

Overlay (JSON over data/config files). Each file maps to an RFC 7386 merge patch, or to a list
of dotted keys to switch ON (creatures-ralph `overlay.py` style: a dict gets "enabled": true,
a bare false becomes true):

    {"data/config/capture_readout_visual.json": {"readout_side_enabled": true},
     "data/config/house_textiles.json": ["comforter"]}

Every overlaid file is restored byte-identically (sha256 checked) when the candidate capture
ends, even on error or Ctrl-C; a crash leaves a backup that `revert` restores.

Rounds live in .artifacts/qj/<round>/ (local, never committed). `finish` writes the committable
VERDICT.md, batch.json, key.json, spec.json, mapped.json and one _sheet_<round>.jpg (<1.5 MB)
into --report (default ralph/reports/LANES/<LANE>/qj/<round>/ from $QJ_LANE, else
ralph/reports/VISUAL/quick/<round>/).
"""
import argparse
import hashlib
import json
import os
import random
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
from contextlib import contextmanager
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
JOB = ROOT / "ralph/reports/VISUAL/item-scores/job.json"
# Extra item definitions (same schema) merged over job.json: rows such as the F40 matrix pieces that
# the catalogue job does not list (NEAR6-CR, 4 Nov 2026: F40#19 had no quick-judge stand).
EXTRA_JOB = os.environ.get("QJ_JOB", "")
ART = ROOT / ".artifacts/qj"
CACHE = ART / "cache"            # base/candidate launch captures keyed by (tree, overlay, launch)
BACKUP = ART / "overlay_backup"  # present only while an overlay is applied
LOCKS = Path(os.environ.get("QJ_LOCK_DIR", "/tmp/claude-0/work"))  # shared with lane_bin's locks
BIOME = {"F38": "Meadows", "F39": "Tidewake", "F40": "Cloudreach", "F41": "Stormwood"}
SHEET_LIMIT = 1_450_000
# Pinned anchor set (the v1/b5 batch's; it reproduced b5 within RMSE, 4 Nov). A fixed set keeps one round's
# mapped level comparable with the next; a random draw moved the level by 0.5-0.9 in the parity check.
PINNED_ANCHORS = "craft,f10_2_r3_capacitor,f04_6_r22"

# Per-tool narrowing: extra arguments that keep the stage, camera and timings but skip frames the
# item does not use. Only tools whose own docs say the filter keeps framing are listed.
def _narrow_creature_poses(frames):
    poses = sorted({f.rsplit("__", 1)[-1] for f in frames})
    known = {"idle", "moving", "attacking", "hurt", "resting", "fainted", "shiny_idle", "alpha_idle"}
    return [f"--poses={','.join(poses)}"] if poses and set(poses) <= known else []


def _narrow_ui_tabs(frames):
    # --tabs only filters the menu loop (the exploration HUD is shot before it). Narrow only when every
    # frame is a plain menu_<tab> or the HUD, and at least one is a menu tab.
    names = [f.split("__", 1)[-1] for f in frames]
    tabs = sorted({n[5:] for n in names if n.startswith("menu_")})
    ok = all(n.startswith("menu_") or n == "exploration_hud" for n in names)
    return [f"--tabs={','.join(tabs)}"] if ok and tabs and all(re.fullmatch(r"[a-z_]+", t) for t in tabs) else []


NARROW = {"tools/phase2_capture_creatures.gd": _narrow_creature_poses,
          "tools/phase2_capture_ui.gd": _narrow_ui_tabs}
# Per-tool filters that take a comma list: launches differing only in this filter share one boot.
MERGE = {"tools/phase2_capture_creatures.gd": "--only="}
# Tools that accept a reusable prepared-world cache (byte-identical buffers on a hit).
WORLD_CACHE = {"cloudreach": "--ground-cover-cache"}


# ---------------------------------------------------------------- stand lookup

def load_items(job=JOB):
    out = {}
    for path in [job] + ([ROOT / EXTRA_JOB] if EXTRA_JOB else []):
        _load_job(Path(path), out)
    return out


def _load_job(path, out):
    d = json.loads(Path(path).read_text())
    bs = d["biomes"]
    for biome, b in (bs.items() if isinstance(bs, dict) else enumerate(bs)):
        for it in (b["items"] if isinstance(b, dict) else b):
            out[it["board_row"]] = dict(it, biome=biome)
            out.setdefault(it["item"], out[it["board_row"]])


def split_repro(repro):
    toks = shlex.split(repro)
    i = toks.index("--script")
    engine = [t for t in toks[1:i] if t != "--path" and t != "."]
    script = toks[i + 1]
    rest = toks[toks.index("--") + 1:] if "--" in toks else []
    return engine, script.removeprefix("res://"), rest


def plan(rows, job=JOB):
    """Deduped launches for the rows: one boot per (script, args), subsets merged."""
    items = load_items(job)
    launches = {}
    stands = []
    for r in rows:
        if r not in items:
            raise SystemExit(f"quick_judge: unknown item {r!r} (not in {JOB.relative_to(ROOT)})")
        it = items[r]
        for f in it.get("frames", []):
            engine, script, rest = split_repro(f["repro"])
            out = next((t for t in rest if t.startswith(("--output=", "--out="))), "--output=")
            subs = [t for t in rest if t.startswith("--subset=")]
            mp = MERGE.get(script)
            merged = [v for t in rest if mp and t.startswith(mp) for v in t[len(mp):].split(",") if v]
            norm = tuple(t for t in rest if not t.startswith(("--subset=", "--output=", "--out=", mp or "\0")))
            k = (script, norm, bool(subs))
            e = launches.setdefault(k, {"engine": engine, "script": script, "args": list(norm), "subsets": [],
                                        "outflag": out.split("=", 1)[0], "out_parent": out.split("=", 1)[1].rsplit("/", 1)[0],
                                        "frames": [], "rows": [], "merge": []})
            for v in merged:
                if v not in e["merge"]:
                    e["merge"].append(v)
            for s in subs:
                if s not in e["subsets"]:
                    e["subsets"].append(s)
            if f["id"] not in e["frames"]:
                e["frames"].append(f["id"])
            if it["board_row"] not in e["rows"]:
                e["rows"].append(it["board_row"])
            stands.append({"row": it["board_row"], "frame": f["id"], "launch": None})
    out = []
    for n, e in enumerate(launches.values(), 1):
        e["narrow"] = NARROW.get(e["script"], lambda fr: [])(e["frames"])
        if e["merge"]:
            e["narrow"] = [MERGE[e["script"]] + ",".join(e["merge"])] + e["narrow"]
        e["id"] = n
        out.append(e)
        for s in stands:
            if s["frame"] in e["frames"] and s["row"] in e["rows"]:
                s["launch"] = n
    return {"rows": rows, "items": {r: items[r] for r in rows}, "launches": out, "stands": stands}


# ---------------------------------------------------------------- overlay

def _merge(dst, patch):
    if not isinstance(patch, dict):
        return patch
    if not isinstance(dst, dict):
        dst = {}
    for k, v in patch.items():
        if v is None:
            dst.pop(k, None)
        else:
            dst[k] = _merge(dst.get(k), v)
    return dst


def _switch_on(d, dotted):
    keys = [k for k in dotted.split(".") if k]
    o = d
    # A numeric key indexes a list (e.g. "clusters.6.candidate" in a band props file).
    keys = [int(k) if k.isdigit() else k for k in keys]
    for k in keys[:-1]:
        o = o[k]
    if keys and o[keys[-1]] is False:
        o[keys[-1]] = True
        return
    t = o[keys[-1]] if keys else o
    if not isinstance(t, dict) or t.get("enabled") is not False:
        raise ValueError(f"{dotted}: not an OFF flag (already ON? remove it from the overlay)")
    t["enabled"] = True


def load_overlay(spec):
    """Path to JSON, inline JSON, or creatures-ralph 'file:dotted.key' specs separated by spaces."""
    if not spec:
        return {}
    p = Path(spec)
    if p.exists():
        text = p.read_text().strip()
        if not text.startswith("{"):   # lane_bin overlay.txt
            spec = text
        else:
            return json.loads(text)
    if spec.lstrip().startswith("{"):
        return json.loads(spec)
    out = {}
    for s in spec.split():
        fn, key = s.split(":", 1)
        out.setdefault(fn, []).append(key)
    return out


def overlay_digest(overlay):
    return hashlib.sha256(json.dumps(overlay, sort_keys=True).encode()).hexdigest()[:12] if overlay else "base"


def apply_overlay(overlay, root=ROOT, backup=BACKUP):
    """Write the overlay; return the manifest needed to restore every file byte-identically."""
    if backup.exists() and any(backup.iterdir()):
        raise RuntimeError(f"an overlay is already applied (backup in {backup}); run `quick_judge.py revert`")
    backup.mkdir(parents=True, exist_ok=True)
    manifest = {}
    try:
        for rel, patch in overlay.items():
            path = (root / rel).resolve()
            if root.resolve() not in path.parents:
                raise ValueError(f"overlay path outside the repo: {rel}")
            existed = path.exists()
            raw = path.read_bytes() if existed else b""
            name = hashlib.sha256(rel.encode()).hexdigest()[:16]
            (backup / name).write_bytes(raw)
            manifest[rel] = {"backup": name, "existed": existed, "sha256": hashlib.sha256(raw).hexdigest()}
            (backup / "manifest.json").write_text(json.dumps(manifest, indent=1))
            d = json.loads(raw) if existed else {}
            if isinstance(patch, list):
                for key in patch:
                    _switch_on(d, key)
            else:
                d = _merge(d, patch)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(d, indent=2) + "\n")
    except BaseException:
        revert(root, backup)
        raise
    return manifest


def revert(root=ROOT, backup=BACKUP):
    mf = backup / "manifest.json"
    if not mf.exists():
        return []
    manifest = json.loads(mf.read_text())
    restored = []
    for rel, m in manifest.items():
        path = root / rel
        if m["existed"]:
            raw = (backup / m["backup"]).read_bytes()
            path.write_bytes(raw)
            if hashlib.sha256(path.read_bytes()).hexdigest() != m["sha256"]:
                raise RuntimeError(f"restore of {rel} is not byte-identical; backup kept in {backup}")
        elif path.exists():
            path.unlink()
        restored.append(rel)
    shutil.rmtree(backup)
    return restored


@contextmanager
def overlaid(overlay, root=ROOT, backup=BACKUP):
    if not overlay:
        yield {}
        return
    old = {s: signal.getsignal(s) for s in (signal.SIGTERM, signal.SIGHUP)}

    def _raise(signum, frame):
        raise KeyboardInterrupt(f"signal {signum}")
    for s in old:
        signal.signal(s, _raise)
    try:
        yield apply_overlay(overlay, root, backup)
    finally:
        revert(root, backup)
        for s, h in old.items():
            signal.signal(s, h)


# ---------------------------------------------------------------- capture

def git(*a):
    return subprocess.run(["git", *a], cwd=ROOT, capture_output=True, text=True).stdout.strip()


# Paths that never change a render: judging tools, reports, docs and markdown. Edits there keep the base.
KEY_SKIP = ("ralph/", "docs/", ".artifacts/", "tools/visual_judge/", ".claude/", ".agents/", ".github/")


def _keep(path):
    return not path.startswith(KEY_SKIP) and not path.endswith(".md")


def tree_key():
    """Content key of every render-relevant file: HEAD blob ids plus any tracked edits (hashed from the
    working tree, so no blob is fetched in a blob-less clone). A base is reused only on an identical key."""
    env = dict(os.environ, GIT_NO_LAZY_FETCH="1")
    ls = subprocess.run(["git", "ls-tree", "-r", "HEAD"], cwd=ROOT, capture_output=True, text=True, env=env).stdout
    h = hashlib.sha256("\n".join(l for l in ls.splitlines() if _keep(l.split("\t", 1)[1])).encode())
    key = h.hexdigest()[:12]
    names = subprocess.run(["git", "diff", "HEAD", "--name-only", "--no-renames"], cwd=ROOT, capture_output=True,
                           text=True, env=env).stdout.split()
    dirty = hashlib.sha256()
    n = 0
    for name in sorted(x for x in names if _keep(x)):
        p = ROOT / name
        dirty.update(name.encode() + b"\0" + (p.read_bytes() if p.exists() else b"<deleted>"))
        n += 1
    return key + ("-" + dirty.hexdigest()[:8] if n else "")


def command(e, out_res, sha, biome):
    engine = list(e["engine"])
    if "--rendering-method" not in " ".join(engine):
        engine += ["--rendering-method", "gl_compatibility"]
    args = e["args"] + e["subsets"] + e["narrow"]
    script_text = (ROOT / e["script"]).read_text(errors="ignore")
    # The F40 matrix tools take --source-commit through lookdev_capture_bootstrap.gd, not their own text.
    if "source-commit" in script_text or "capture_lookdev_catalogue" in script_text:
        args.append(f"--source-commit={sha}")
    flag = WORLD_CACHE.get(biome)
    if flag and flag in script_text and not any(a.startswith(flag) for a in args):
        args.append(f"{flag}={(ART / 'world_cache' / biome).as_posix()}")
    return (["godot", "--path", ".", *engine, "--script", f"res://{e['script']}", "--", *args,
             f"{e['outflag']}={out_res}"])


@contextmanager
def flock(name):
    LOCKS.mkdir(parents=True, exist_ok=True)
    import fcntl
    with open(LOCKS / name, "w") as fh:
        fcntl.flock(fh, fcntl.LOCK_EX)
        yield


def run_launch(e, side_key, biome, sha, log, timeout=3000, dry=False):
    """Capture one launch into the cache; returns (dir, seconds, cached)."""
    key = hashlib.sha256(json.dumps([e["script"], e["args"], e["subsets"], e["narrow"], e["engine"]]).encode()).hexdigest()[:12]
    dst = CACHE / side_key / key
    if (dst / ".ok").exists():
        return dst, 0.0, True
    # Write where the tool expects its own output (some tools only write under VISUAL/phase2/),
    # then move into the cache: frames never stay in ralph/.
    rel_parent = e["out_parent"].removeprefix("res://") or ".artifacts/qj/tmp"
    # Some job.json repros carry a Windows checkout path (D:/tetherbound/x04-capture/ralph/...):
    # keep only the repo-relative part, or a tool that checks its output root refuses to run.
    rel_parent = re.sub(r"^[A-Za-z]:/(?:[^/]+/)*?(?=ralph/)", "", rel_parent)
    tmp_rel = f"{rel_parent}/qj_{side_key}_{key}"
    tmp = ROOT / tmp_rel
    shutil.rmtree(tmp, ignore_errors=True)
    cmd = command(e, f"res://{tmp_rel}", sha, biome)
    prefix = ["timeout", str(timeout), "xvfb-run", "-a", "-s", "-screen 0 1920x1080x24"]
    log.write(f"[{time.strftime('%H:%M:%S')}] {side_key} #{e['id']}: {shlex.join(cmd)}\n")
    log.flush()
    if dry:
        return dst, 0.0, False
    env = dict(os.environ, XDG_DATA_HOME=os.environ.get("XDG_DATA_HOME", str(LOCKS / "xdg")))
    (ART / "logs").mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    with flock("godot.lock"):
        t1 = time.time()
        with open(ART / "logs" / f"{side_key.replace('/', '_')}_{key}.log", "w") as out:
            rc = subprocess.run(prefix + cmd, cwd=ROOT, stdout=out, stderr=subprocess.STDOUT, env=env).returncode
    secs = time.time() - t1
    shutil.rmtree(dst, ignore_errors=True)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if tmp.exists():
        shutil.move(str(tmp), dst)
    else:
        dst.mkdir()
    n = len(list(dst.rglob("*.png")) + list(dst.rglob("*.jpg")))
    stale = "stale" in (ART / "logs" / f"{side_key.replace('/', '_')}_{key}.log").read_text(errors="ignore").lower()
    log.write(f"    exit {rc}, {n} frames, {secs:.0f}s run (+{t1 - t0:.0f}s lock wait){'  WARNING: log mentions stale' if stale else ''}\n")
    if n:   # frame_cap/124 exits after writing frames are normal for some tools
        (dst / ".ok").write_text(json.dumps({"rc": rc, "secs": round(secs), "frames": n}))
    return dst, secs, False


def find_frame(d, fid):
    names = [fid]
    if "__" in fid:
        names.append(fid.split("__", 1)[1])
    if "__catching__" in fid:
        names.append(fid.split("__catching__", 1)[1])
    if fid.count("__") >= 2:
        names.append(fid.split("__", 2)[2])
    if fid.startswith("tidewake__"):  # Tidewake route/location tools write water__<stand> files
        names.append("water__" + fid.split("__", 1)[1])
    for n in names:
        for ext in ("png", "jpg"):
            hits = sorted(Path(d).rglob(f"{n}.{ext}"))
            if hits:
                return hits[0]
    # Fight tools write <trainer>/<tag>-<sss.ss>.png for ..__fight__<trainer>__<tag>-<sss_ss> ids;
    # tell moments drift run to run, so take the same tag nearest in time (t- ticks match exactly).
    m = re.search(r"__fight__([a-z0-9_]+?)__([a-z-]+)-(\d+)_(\d+)$", fid)
    if m:
        want = float(f"{m.group(3)}.{m.group(4)}")
        best = None
        hits = []
        for q in Path(d).rglob(f"{m.group(1)}/{m.group(2)}-*.png"):
            mm = re.fullmatch(rf"{re.escape(m.group(2))}-(\d+\.\d+)", q.stem)
            if mm:
                hits.append(q)
                if best is None or abs(float(mm.group(1)) - want) < best[0]:
                    best = (abs(float(mm.group(1)) - want), q)
        # A one-off moment (win, aftermath) is that moment whatever second it lands on.
        if best and (best[0] <= 1.0 or len(hits) == 1):
            return best[1]
    # phase2_capture_realm_flight.gd numbers its frames (02-glide.png) and
    # the job ids name the moment (meadows__flying__glide).
    for n in names:
        for ext in ("png", "jpg"):
            hits = sorted(Path(d).rglob(f"[0-9][0-9]-{n}.{ext}"))
            if hits:
                return hits[0]
    return None


def capture(rows, overlay, name, dry=False, timeout=3000):
    p = plan(rows)
    rd = ART / name
    rd.mkdir(parents=True, exist_ok=True)
    sha = git("rev-parse", "HEAD")
    tk = tree_key()
    biome = p["items"][rows[0]]["biome"]
    sides = {"base": f"{tk}/base", "cand": f"{tk}/{overlay_digest(overlay)}"}
    timing = {"tree": tk, "head": sha, "launches": len(p["launches"]), "base_s": 0.0, "cand_s": 0.0,
              "base_cached": True, "started": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    frames = {"base": {}, "cand": {}}
    t0 = time.time()
    with open(rd / "capture.log", "a") as log:
        for side in ("base", "cand"):
            if side == "cand" and not overlay:
                log.write("no overlay: candidate = base (dry check only)\n")
            ctx = overlaid(overlay) if side == "cand" and not dry else overlaid({})
            lock = flock("scene.lock")   # no other lane capture while this tree is overlaid
            with lock, ctx:
                for e in p["launches"]:
                    d, secs, cached = run_launch(e, sides[side], biome, sha, log, timeout, dry)
                    timing[f"{side}_s"] += secs
                    if side == "base" and not cached:
                        timing["base_cached"] = False
                    for fid in e["frames"]:
                        hit = find_frame(d, fid)
                        frames[side][fid] = str(hit) if hit else None
    timing["wall_s"] = round(time.time() - t0)
    state = {"rows": rows, "overlay": overlay, "sides": sides, "frames": frames, "timing": timing, "plan": p}
    (rd / "round.json").write_text(json.dumps(state, indent=1))
    return state


# ---------------------------------------------------------------- packet

def sheet(paths, dst, w=640, h=360):
    from PIL import Image
    n = len(paths)
    W, H = (w * 2, h * 2) if n == 1 else (w, h)
    cols = 1 if n == 1 else 2
    rws = 1 if n == 1 else (n + 1) // 2
    im = Image.new("RGB", (W * cols, H * rws), (30, 30, 30))
    for i, p in enumerate(paths):
        im.paste(Image.open(p).convert("RGB").resize((W, H)), ((i % cols) * W, (i // cols) * H))
    im.save(dst, quality=88)


def fill_prompt(judge_dir, key_dir):
    t = (HERE / "JUDGE_PROMPT.md").read_text()
    t = re.search(r"```text\n(.*?)```", t, re.S).group(1)
    return (t.replace("[JUDGE FOLDER]", str(judge_dir))
             .replace("[SET LIST]", (Path(judge_dir) / "sets.md").read_text().strip())
             .replace("[RECORDED DEFECTS]", (Path(key_dir) / "recorded_defects.txt").read_text().strip()))


def link_tree(src, dst):
    """Hard-link docs/reference into the judge folder (no 30 MB copy per round)."""
    for p in Path(src).rglob("*"):
        q = Path(dst) / p.relative_to(src)
        if p.is_dir():
            q.mkdir(parents=True, exist_ok=True)
        else:
            q.parent.mkdir(parents=True, exist_ok=True)
            try:
                os.link(p, q)
            except OSError:
                shutil.copy2(p, q)


def packet(rd, seed=None, include=PINNED_ANCHORS, pairs=3):
    rd = Path(rd)
    st = json.loads((rd / "round.json").read_text())
    k, j = rd / "k", rd / "judge"
    for d in (k, j):
        shutil.rmtree(d, ignore_errors=True)
    (k / "sides").mkdir(parents=True)
    spec, missing = [], []
    for r in st["rows"]:
        it = st["plan"]["items"][r]
        ok = [(f["id"], st["frames"]["base"].get(f["id"]), st["frames"]["cand"].get(f["id"])) for f in it["frames"]]
        missing += [f"{r}:{f}" for f, a, b in ok if not (a and b)]
        ok = [x for x in ok if x[1] and x[2]]
        if not ok:
            continue
        sa, sb = k / "sides" / f"{r.replace('#', '_')}_base.jpg", k / "sides" / f"{r.replace('#', '_')}_cand.jpg"
        sheet([a for _, a, _ in ok], sa)
        sheet([b for _, _, b in ok], sb)
        n = len(ok)
        spec.append({"label": r, "a": str(sa), "b": str(sb),
                     "brief": f"{n} in-game frame{'s' if n > 1 else ''} ({BIOME.get(r.split('#')[0], '')}) for one "
                              f"catalogue subject: {it['subject']}. Judge that subject as the game's real look - "
                              "identity and read at a glance, silhouette, palette, lighting and fit with the key art "
                              "and its chapter board.",
                     "defects": [it["defect"]]})
    if not spec:
        raise SystemExit(f"quick_judge: no frame pair found for any row; missing {missing}")
    (k / "spec.json").write_text(json.dumps(spec, indent=1))
    seed = seed if seed is not None else random.SystemRandom().randrange(1 << 30)
    cmd = [sys.executable, str(HERE / "anchor_tiles.py"), "--out", str(j), "--key", str(k / "key.json"),
           "--candidates", str(k / "spec.json"), "--pairs", str(pairs), "--seed", str(seed)]
    for g in (include or "").split(","):
        if g:
            cmd += ["--include", g]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
    link_tree(ROOT / "docs/reference", j / "reference")
    prompt = fill_prompt(j.resolve(), k)
    (k / "JUDGE_PROMPT_FILLED.txt").write_text(prompt)
    launch = (
        "# Launch the 3 judges in ONE message: three Agent calls (general-purpose, fresh), in parallel\n\n"
        f"Each Agent call's prompt is the full text of {(k / 'JUDGE_PROMPT_FILLED.txt').resolve()}, verbatim\n"
        "(the JUDGE_PROMPT.md block with its three slots filled; descriptions \"code-blind judge 1|2|3\").\n"
        "Never point a judge at that file or anything else outside the judge folder: paste the text.\n\n"
        f"Save each judge's full reply (or only its final JSON block) as\n"
        f"    {(rd / 'replies').resolve()}/j1.txt  j2.txt  j3.txt\n"
        f"then run:\n    python3 tools/visual_judge/quick_judge.py finish {rd}\n"
    )
    (rd / "LAUNCH_JUDGES.md").write_text(launch)
    (rd / "replies").mkdir(exist_ok=True)
    st["packet"] = {"seed": seed, "missing": missing, "sets": len(spec)}
    (rd / "round.json").write_text(json.dumps(st, indent=1))
    return launch, missing


# ---------------------------------------------------------------- finish

def judge_json(path):
    t = Path(path).read_text()
    try:
        return json.loads(t)["sets"]
    except (json.JSONDecodeError, KeyError):
        pass
    starts = [m.start() for m in re.finditer(r'\{\s*"sets"', t)]
    for s in reversed(starts):
        depth = 0
        for i, ch in enumerate(t[s:], s):
            depth += ch == "{"
            depth -= ch == "}"
            if depth == 0:
                return json.loads(t[s:i + 1])["sets"]
    raise SystemExit(f"quick_judge: no {{\"sets\": ...}} JSON block in {path}")


def assemble(key, judges):
    batch, defects = {"anchors": {}, "candidates": {}}, {}
    for code, k in key.items():
        for side in "AB":
            vals, calls = [], []
            for j in judges:
                s = j.get(code, {}).get(side)
                vals.append(None if s is None else float(s["bar_a"]))
                calls.append(None if s is None else s.get("defects", {}))
            if None in vals:
                raise SystemExit(f"quick_judge: a judge omitted set {code} side {side}; re-ask that judge for it once")
            if k["anchor"]:
                batch["anchors"][k[side]] = vals
            else:
                arm = "cand" if k[side].endswith("_cand.jpg") else "base"
                batch["candidates"][f"{k['label']} {arm}"] = vals
                defects[f"{k['label']} {arm}"] = calls
    return batch, defects


def finish(rd, report=None):
    rd = Path(rd)
    st = json.loads((rd / "round.json").read_text())
    key = json.loads((rd / "k/key.json").read_text())
    replies = sorted((rd / "replies").glob("j*.*"))
    if len(replies) != 3:
        raise SystemExit(f"quick_judge: need exactly 3 replies in {rd / 'replies'}, found {len(replies)}")
    batch, defects = assemble(key, [judge_json(p) for p in replies])
    lane = os.environ.get("QJ_LANE")
    report = Path(report) if report else ROOT / (f"ralph/reports/LANES/{lane}/qj/{rd.name}" if lane else f"ralph/reports/VISUAL/quick/{rd.name}")
    report.mkdir(parents=True, exist_ok=True)
    (report / "batch.json").write_text(json.dumps(batch, indent=1) + "\n")
    (report / "defects.json").write_text(json.dumps(defects, indent=1) + "\n")
    subprocess.run([sys.executable, str(HERE / "calibrate.py"), str(report / "batch.json"), "--out",
                    str(report / "mapped.json")], check=True, stdout=subprocess.DEVNULL)
    m = json.loads((report / "mapped.json").read_text())
    shutil.copy(rd / "k/key.json", report / "key.json")
    shutil.copy(rd / "k/spec.json", report / "spec.json")
    # contact sheet: per row base | cand, under the size limit
    from PIL import Image
    spec = json.loads((rd / "k/spec.json").read_text())
    tiles = []
    for s in spec:
        a, b = Image.open(s["a"]).convert("RGB"), Image.open(s["b"]).convert("RGB")
        row = Image.new("RGB", (a.width + b.width + 8, max(a.height, b.height)), (30, 30, 30))
        row.paste(a, (0, 0))
        row.paste(b, (a.width + 8, 0))
        tiles.append(row)
    W = max(t.width for t in tiles)
    im = Image.new("RGB", (W, sum(t.height + 8 for t in tiles)), (30, 30, 30))
    y = 0
    for t in tiles:
        im.paste(t, (0, y))
        y += t.height + 8
    out = report / f"_sheet_{rd.name}.jpg"
    q, scale = 85, 1.0
    while True:
        im2 = im if scale == 1.0 else im.resize((int(im.width * scale), int(im.height * scale)))
        im2.save(out, quality=q)
        if out.stat().st_size < SHEET_LIMIT:
            break
        q, scale = (q - 10, scale) if q > 55 else (q, scale * 0.8)
    f, tm = m["fit"], st["timing"]
    lines = [f"# Quick judge {rd.name}: {', '.join(st['rows'])}", "",
             f"- Head `{tm['head']}`, tree `{tm['tree']}`; CPU llvmpipe, Compatibility (`quick_judge.py`).",
             f"- Overlay: `{json.dumps(st['overlay']) if st['overlay'] else 'none (base vs base)'}`",
             f"- Capture: {tm['launches']} launch(es); base {tm['base_s']:.0f}s{' (cached)' if tm['base_cached'] else ''}, "
             f"candidate {tm['cand_s']:.0f}s, wall {tm['wall_s']}s.",
             f"- Yardstick: JUDGE_PROMPT verbatim, {len(batch['anchors']) // 2} anchor pairs, three fresh code-blind judges, "
             f"`calibrate.py`: {f['method']}, slope {f['slope']}, intercept {f['intercept']}, r {f['pearson_r']}, "
             f"anchor RMSE {m['anchor_rmse']}{', confirming batch' if m['confirming_batch'] else ''}.",
             "", "| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |",
             "|---|---|---|---|---|---|---|"]
    for s in spec:
        r = s["label"]
        cb, cc = m["candidates"].get(f"{r} base"), m["candidates"].get(f"{r} cand")
        if not (cb and cc):
            continue
        rawb = " ".join(f"{x:g}" for x in batch["candidates"][f"{r} base"])
        rawc = " ".join(f"{x:g}" for x in batch["candidates"][f"{r} cand"])
        calls = lambda arm: ",".join(sorted({v for c in defects[f"{r} {arm}"] for v in (c or {}).values()}) or ["-"])
        lines.append(f"| {r} | {st['plan']['items'][r]['subject']} | {cb['mapped_mean']:.2f} | **{cc['mapped_mean']:.2f}** | "
                     f"{cc['mapped_mean'] - cb['mapped_mean']:+.2f} | {rawb} / {rawc} | {calls('base')} / {calls('cand')} |")
    if m["warnings"]:
        lines += ["", "**Warnings:**"] + [f"- {w}" for w in m["warnings"]]
    if st.get("packet", {}).get("missing"):
        lines += ["", f"Missing frames (not judged): {', '.join(st['packet']['missing'])}"]
    lines += ["", "CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium)."]
    (report / "VERDICT.md").write_text("\n".join(lines) + "\n")
    return report, m


# ---------------------------------------------------------------- cli

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("plan", "capture", "run"):
        s = sub.add_parser(name)
        s.add_argument("rows", nargs="+", help="board rows (F39#23) or catalogue items (P2-114)")
        if name != "plan":
            s.add_argument("--overlay", help="overlay JSON file, inline JSON, or lane_bin 'file:key' specs")
            s.add_argument("--name", help="round name (default <rows>-<overlay digest>-<time>)")
            s.add_argument("--dry-run", action="store_true", help="print the launches, do not run Godot")
            s.add_argument("--timeout", type=int, default=3000)
            s.add_argument("--seed", type=int)
    s = sub.add_parser("packet")
    s.add_argument("round")
    s.add_argument("--seed", type=int)
    s.add_argument("--include", default=PINNED_ANCHORS, help=f"anchor groups, comma-separated (default {PINNED_ANCHORS})")
    s = sub.add_parser("finish")
    s.add_argument("round")
    s.add_argument("--report")
    sub.add_parser("revert")
    a = ap.parse_args(argv)
    if a.cmd == "revert":
        print("restored:", revert() or "nothing to restore")
        return
    if a.cmd == "plan":
        p = plan([load_items()[r]["board_row"] if r in load_items() else r for r in a.rows])
        for e in p["launches"]:
            print(f"#{e['id']} {e['script']} {' '.join(e['args'] + e['subsets'] + e['narrow'])}")
            print(f"    rows {','.join(e['rows'])}; frames {', '.join(e['frames'])}")
        return
    if a.cmd in ("capture", "run"):
        items = load_items()
        rows = [items[r]["board_row"] if r in items else r for r in a.rows]
        ov = load_overlay(a.overlay)
        name = a.name or f"{'_'.join(r.replace('#', '-') for r in rows)}-{overlay_digest(ov)}-{time.strftime('%m%d%H%M')}"
        st = capture(rows, ov, name, a.dry_run, a.timeout)
        rd = ART / name
        print(json.dumps(st["timing"]))
        miss = [f for s in st["frames"].values() for f, v in s.items() if not v]
        if a.dry_run:
            print((rd / "capture.log").read_text())
            return
        if a.cmd == "run":
            launch, missing = packet(rd, a.seed)
            print(launch)
            if missing:
                print("missing frames:", missing)
        elif miss:
            print("missing frames:", miss)
        print("round dir:", rd)
        return
    if a.cmd == "packet":
        launch, missing = packet(a.round, a.seed, a.include)
        print(launch)
        return
    if a.cmd == "finish":
        report, m = finish(a.round, a.report)
        print((report / "VERDICT.md").read_text())


if __name__ == "__main__":
    main()
