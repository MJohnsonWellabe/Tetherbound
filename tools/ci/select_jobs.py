#!/usr/bin/env python3
"""Affected-only CI job selection (owner-approved, 2026-10-04).

    python3 tools/ci/select_jobs.py --event <name> --ci .github/workflows/ci.yml \
        [--all] < changed-paths.txt     # prints `jobs=|a|b|` and `all=...`

ci.yml's `changes` job runs this on the paths a change touches and each
full-tier verify job runs only if its name is in `jobs`. The rule the table
below implements is CONSERVATIVE: a miss may only cost speed, never a missed
bug. So a path selects EVERYTHING unless a rule proves it can only reach a
named subset of jobs, and every test still runs on the 8-hourly full tier.

EVERYTHING is selected for:
  * a schedule or a dispatch (`--all`), an empty diff, a missing base;
  * more than MAX_PATHS non-documentation paths (a large change);
  * any CORE path (shared engine of every suite: autoloads, save, session,
    ledger, encounter director, combat manager, project/export settings,
    workflows, test helpers and fixtures, CI tools, addons, boot/player/story);
  * gameplay code and data outside a realm family (combat, creatures, ui,
    homestead/build, training/masters, Meadows world, economy, npcs, ...):
    every world-booting smoke, the net smokes included, boots the Meadows
    playground or crosses through it, fights and opens the HUD, so none of
    those areas can be shown to stay inside a subset of suites;
  * a realm-family file that anything outside its own family references
    (then it is shared, e.g. a water_* script the Meadows ponds use);
  * a test/tool file another file references (a shared harness piece);
  * anything no rule recognises.

A NAMED SUBSET is selected for:
  * a realm-family file (basename or a directory starting cloudreach_,
    stormwood_/stormheart_, water_/tidewake_/ripplet_, or exactly the
    realm name) referenced only inside
    its own family -> that realm's jobs (REALM_JOBS) plus the net group, which
    holds realm net smokes;
  * tools/net/** and tests/smoke_net_*.gd -> the net group;
  * image/audio media, their .import sidecars and .gdshader files ->
    PRESENTATION_JOBS (unit tests, bake freshness, import errors and the
    export always run on a code change anyway);
  * any other unreferenced test/tool file -> exactly the jobs whose ci.yml
    block names it (nothing, if no job runs it);
  * tests/test_*.gd -> nothing extra (the unit shards always run).

ALWAYS_JOBS run whenever their own tier/code gate says so; selection never
removes them. Documentation-only changes are decided earlier (`code=false`).
tests/test_ci_select_jobs.py classifies sample paths, unmapped ones included.
"""
import argparse
import os
import re
import sys

MAX_PATHS = 200

DOC_RE = re.compile(r"(\.md$|^site/|^docs/|^ralph/|^archive/|^\.claude/|^\.agents/)")

CORE_RE = re.compile(
    r"^(autoload/|scripts/save/|scripts/net/session\.gd|scripts/net/ledger_rpc\.gd|"
    r"scripts/combat/encounter_director\.gd|scripts/combat/combat_manager\.gd|"
    r"project\.godot$|export_presets\.cfg$|default_bus_layout\.tres$|\.github/|"
    r"tests/helpers/|tests/fixtures/|tests/run_tests\.gd|tests/test_case\.gd|tools/ci/|"
    r"addons/|scripts/boot/|scripts/player/|scripts/story/|scripts/data/|scenes/player/|resources/)")

MEDIA_RE = re.compile(r"\.(png|jpe?g|webp|ktx2|exr|hdr|svg|ogg|wav|mp3|gdshader)(\.import|\.uid)?$")

REALMS = {
    "cloudreach": ("cloudreach",),
    "stormwood": ("stormwood", "stormheart"),
    "tidewake": ("water", "tidewake", "ripplet"),
}

# Jobs that run a realm's own smokes (beyond the net group).
REALM_JOBS = {
    "cloudreach": {"verify-regions-shard", "verify-cloudreach-persistence", "verify-cloudreach-midride-rejoin",
                   "verify-unbroken-chains"},
    "stormwood": {"verify-regions-shard"},
    "tidewake": {"verify-regions-shard", "verify-regions-relay"},
}
NET_JOBS = {"discover-net-smokes", "verify-multiplayer-shard", "verify-veridian-offer",
            "verify-cloudreach-midride-rejoin", "verify-unbroken-chains"}
# Character texture binding / material cache and the terrain mipmap probe.
PRESENTATION_JOBS = {"verify-regions-shard"}
ALWAYS_JOBS = {"changes", "ci-gate", "verify-bake-freshness", "verify-unit-tests", "export",
               "verify-segment-handoffs"}

# Where the reference scan looks (text only).
SCAN_ROOTS = ("scripts/", "scenes/", "autoload/", "data/config/", "tests/", "tools/")
SCAN_EXT = (".gd", ".tscn", ".tres", ".json", ".py", ".sh", ".cfg")


def ci_jobs(ci_text):
    """Job ids in ci.yml, with the text of each job's block."""
    jobs, name, buf = {}, None, []
    in_jobs = False
    for line in ci_text.splitlines():
        if line.startswith("jobs:"):
            in_jobs = True
            continue
        if not in_jobs:
            continue
        m = re.match(r"^  ([a-z0-9][a-z0-9-]*):\s*$", line)
        if m:
            if name:
                jobs[name] = "\n".join(buf)
            name, buf = m.group(1), []
        elif name:
            buf.append(line)
    if name:
        jobs[name] = "\n".join(buf)
    return jobs


def stem_of(path):
    base = os.path.basename(path)
    for ext in (".import", ".uid"):
        base = base[: -len(ext)] if base.endswith(ext) else base
    return base


def realm_of(path):
    """A realm when a directory or file name below the top level IS the realm
    prefix or starts with `<prefix>_` (cloudreach_world.gd, data/terrain/water/)."""
    parts = path.split("/")
    for realm, prefixes in REALMS.items():
        for part in parts[1:]:
            name = part.split(".")[0]
            if any(name == p or name.startswith(p + "_") for p in prefixes):
                return realm
    return None


def is_game(path):
    return path.split("/")[0] in ("scripts", "scenes", "autoload", "data", "assets")


def is_unit_test(path):
    return re.match(r"^tests/test_[A-Za-z0-9_]+\.gd$", path) is not None


def referenced_by(path, corpus):
    """Files in `corpus` (path -> text) other than `path` that name its file."""
    stem = stem_of(path)
    return [other for other, text in corpus.items() if other != path and stem in text]


def jobs_running(path, jobs):
    """ci.yml jobs whose block names this test/tool: by file stem, or as
    `SMOKE: <name>` (the retry-loop steps run tests/smoke_${SMOKE}.gd)."""
    stem = stem_of(path).split(".")[0]
    short = stem[len("smoke_"):] if stem.startswith("smoke_") else None
    out = set()
    for job, block in jobs.items():
        if stem in block or (short and re.search(r"SMOKE: %s\b" % re.escape(short), block)):
            out.add(job)
    return out


def widen(path, jobs, corpus, family=None):
    """What the files referencing `path` add: ('all', culprit) when game code
    outside `family`, or a core/shared file, uses it; else the set of jobs that
    run the tests/tools using it (net smokes and tools/net add the net group).
    Unit tests add nothing: the unit shards always run."""
    out = set()
    for ref in referenced_by(path, corpus):
        if is_unit_test(ref):
            continue
        if is_game(ref):
            if family and realm_of(ref) == family:
                continue
            return "all", ref
        if CORE_RE.search(ref):
            return "all", ref
        if ref.startswith("tools/net/") or ref.startswith("tests/smoke_net_"):
            out |= NET_JOBS
        out |= jobs_running(ref, jobs)
    return out, None


def classify(path, jobs, corpus):
    """('all' | set_of_jobs, reason)."""
    if DOC_RE.search(path):
        return set(), "documentation"
    if CORE_RE.search(path):
        return "all", "core/shared path"
    if re.match(r"^tests/test_[A-Za-z0-9_]+\.gd(\.uid)?$", path):
        return set(), "unit test (the unit shards always run)"
    if MEDIA_RE.search(path):
        return set(PRESENTATION_JOBS), "presentation media/shader"
    if path.startswith("tests/") or path.startswith("tools/"):
        chosen = set(NET_JOBS) if (path.startswith("tools/net/") or path.startswith("tests/smoke_net_")) else set()
        extra, culprit = widen(path, jobs, corpus)
        if extra == "all":
            return "all", "test/tool used by %s" % culprit
        chosen |= jobs_running(path, jobs) | extra
        return chosen, "test/tool run by %s" % (",".join(sorted(chosen)) or "no CI job")
    realm = realm_of(path)
    if realm and is_game(path):
        extra, culprit = widen(path, jobs, corpus, family=realm)
        if extra == "all":
            return "all", "%s file used outside its family by %s" % (realm, culprit)
        return set(REALM_JOBS[realm]) | set(NET_JOBS) | extra, "%s family" % realm
    return "all", "gameplay code/data outside a realm family, or unmapped"


def select(changed, event, ci_text, corpus, force_all=False):
    """Returns (jobs_selected:set, everything:bool, explanation:list)."""
    jobs = ci_jobs(ci_text)
    every = set(jobs)
    changed = [p for p in changed if p.strip()]
    if force_all or event in ("schedule", "workflow_dispatch"):
        return every, True, ["%s: everything" % (event or "forced")]
    if not changed:
        return every, True, ["empty diff: everything"]
    code = [p for p in changed if not DOC_RE.search(p)]
    if len(code) > MAX_PATHS:
        return every, True, ["%d code paths > %d: everything" % (len(code), MAX_PATHS)]
    chosen, why = set(ALWAYS_JOBS & every), []
    for path in changed:
        result, reason = classify(path, jobs, corpus)
        why.append("%s -> %s (%s)" % (path, "ALL" if result == "all" else (",".join(sorted(result)) or "-"), reason))
        if result == "all":
            return every, True, why
        chosen |= result
    return chosen & every, False, why


def load_corpus(root="."):
    corpus = {}
    for scan in SCAN_ROOTS:
        base = os.path.join(root, scan)
        for dirpath, _dirs, files in os.walk(base):
            if "/tests/fixtures" in dirpath.replace(os.sep, "/"):
                continue
            for f in files:
                if f.endswith(SCAN_EXT):
                    full = os.path.join(dirpath, f)
                    try:
                        with open(full, encoding="utf-8", errors="ignore") as fh:
                            corpus[os.path.relpath(full, root).replace(os.sep, "/")] = fh.read()
                    except OSError:
                        pass
    return corpus


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--event", default="")
    ap.add_argument("--ci", default=".github/workflows/ci.yml")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args(argv)
    changed = [] if args.all else sys.stdin.read().splitlines()
    with open(args.ci) as fh:
        ci_text = fh.read()
    corpus = {} if args.all else load_corpus()
    chosen, everything, why = select(changed, args.event, ci_text, corpus, force_all=args.all)
    for line in why:
        print("select: " + line, file=sys.stderr)
    # `|a|b|`: ci.yml tests `contains(jobs, '|<job>|')`; no whitespace to trim.
    print("jobs=|%s|" % "|".join(sorted(chosen)))
    print("all=%s" % ("true" if everything else "false"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
