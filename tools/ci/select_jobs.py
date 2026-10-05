#!/usr/bin/env python3
"""Affected-only CI job selection (owner-approved, 2026-10-04).

    git diff --name-only --no-renames <base> HEAD \
      | python3 tools/ci/select_jobs.py --event <name> [--ci .github/workflows/ci.yml]
    python3 tools/ci/select_jobs.py --all --event <name>
        # prints `jobs=|a|b|` (or `jobs=|ALL|...`), `all=...`, `net=...`

ci.yml's `changes` job runs this on the paths a change touches; each
full-tier verify job runs only if its name (or ALL) is in `jobs`. The rule is
CONSERVATIVE (owner): a miss may only cost speed, never a missed bug. So a path
selects EVERYTHING unless the rules prove it can only reach a named subset of
jobs; every suite still runs on the 8-hourly full tier.

EVERYTHING is selected for:
  * a schedule or a dispatch (`--all`), an empty diff, a missing base, more
    than MAX_PATHS non-documentation paths, or a selector failure (ci.yml then
    fails the `changes` job rather than selecting nothing);
  * any CORE path: autoloads, save, session, ledger, encounter director,
    combat manager, project/export settings, workflows, test helpers and
    fixtures, CI tools, addons, boot/player/story/data scripts;
  * gameplay code or data outside a realm family (combat, creatures, ui,
    homestead/build, training/masters, Meadows world, economy, npcs, ...):
    every world-booting smoke, the net smokes included, boots the Meadows
    playground or crosses through it, fights and opens the HUD;
  * anything no rule recognises;
  * any file that is reached -- TRANSITIVELY -- from core or from gameplay
    outside its own realm family (see "reach" below).

A NAMED SUBSET is selected for a realm-family file, a test or tool, or media,
when its reach stays bounded: that realm's jobs (every job that runs a smoke
carrying the realm in its name, plus REALM_JOBS) and the net group; the jobs
that run each test/tool on the reach (by file stem, `SMOKE: <name>` or
`--only=<name>`); the net group for tools/net and net smokes; PRESENTATION_JOBS
for media. The ALWAYS_JOBS (unit shards, bake freshness, export, handoffs)
run on every code change regardless.

REACH: a breadth-first walk over the files that name a file. A file is named
by its stem as a whole word (`cloudreach_bell` in "res://.../cloudreach_bell.gd",
`preload`, `extends`, a JSON path or a bare id) or by its `class_name` (global
classes need no path). Text is scanned in SCAN_ROOTS (scripts, scenes,
autoload, all of data/ JSON, assets' scenes/resources, shaders, tests incl.
fixture scripts, tools, project.godot). A referrer that is CORE, or game code
outside the starting realm family, makes the change select everything; a
referrer test/tool adds the jobs that run it, and the walk continues from
every referrer. Game or core text that names a test/tool only in a GDScript
comment line, a JSON `_why`/`_comment*`/`_note(s)`/`_doc(s)` prose key or by
bare file name is
skipped: loading one needs its res:// path or its class_name in code, and
either counts. More than MAX_REACH files on the walk
selects everything.

Realm families: a directory or file name equal to the realm prefix or
starting `<prefix>_` (cloudreach, stormwood/stormheart, water/tidewake).
Renamed files are diffed with --no-renames so the old path is classified too.
tests/test_ci_select_jobs.py checks sample and real-repository paths.
"""
import argparse
import os
import re
import sys

MAX_PATHS = 200
MAX_REACH = 400

DOC_RE = re.compile(r"(\.md$|^site/|^docs/|^ralph/|^archive/|^\.claude/)")

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
    "tidewake": ("water", "tidewake"),
}

# Realm jobs that do not carry a realm smoke's name in their steps.
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
               "verify-segment-handoffs",
               # Queue-order jobs (ci.yml QUEUE ORDER): ungated, they only sequence tiers.
               "queue-after-longest", "queue-after-long",
               # Runs the packed suites; each suite keeps its own selection
               # (tools/ci/packed.py evaluates its original `if:`).
               "verify-packed"}

# Where the reference scan looks (text only).
SCAN_ROOTS = ("scripts/", "scenes/", "autoload/", "data/", "tests/", "tools/", "shaders/", "assets/")
SCAN_EXT = {
    "assets/": (".tscn", ".tres"),
    "data/": (".json", ".tres", ".cfg"),
    "tests/fixtures/": (".gd",),
}
DEFAULT_EXT = (".gd", ".tscn", ".tres", ".json", ".py", ".sh", ".cfg", ".gdshader", ".gdshaderinc")
SCAN_FILES = ("project.godot",)
# Sentinels, one per scan root, that must be in the corpus or the selection
# runs everything (a partial checkout must never mean a partial walk).
REQUIRED_SCAN = ("project.godot", "autoload/game_state.gd", "scripts/world/playground_world.gd",
                 "scenes/ui/playground_hud.tscn", "shaders/cover_tier.gdshader",
                 "data/creatures/species.json", "data/config/combat.json",
                 "assets/props/built/torch_prop.tscn", "tests/smoke_relay.gd",
                 "tests/card_t1_tidewake_retained_five.sh", "tests/helpers/net_harness.gd",
                 "tests/fixtures/foundation_flag_mirror.gd", "tools/net/peer_runner.gd")
REQUIRED_SCAN_CHECK = True

WORD = re.compile(r"[A-Za-z0-9_]+")
CLASS_NAME = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)


def ci_jobs(ci_text):
    """Job ids in ci.yml, with the text of each job's block. The text may also
    hold .github/ci/suites.yml (`suites:`): a packed suite keeps its job id, and
    a job split between both files (verify-regions-shard) gets both texts."""
    jobs, name, buf = {}, None, []
    in_jobs = False

    def flush():
        if name:
            jobs[name] = (jobs[name] + "\n" if name in jobs else "") + "\n".join(buf)
    for line in ci_text.splitlines():
        if re.match(r"^(jobs|suites):\s*$", line):
            flush()
            name, buf = None, []
            in_jobs = True
            continue
        if re.match(r"^\S", line) and not line.startswith("#"):
            flush()
            name, buf = None, []
            in_jobs = False
            continue
        if not in_jobs:
            continue
        m = re.match(r"^  ([a-z0-9][a-z0-9-]*):\s*$", line)
        if m:
            flush()
            name, buf = m.group(1), []
        elif name:
            buf.append(line)
    flush()
    return jobs


def ci_text_with_suites(ci_path):
    """ci.yml plus the packed suites file beside it (.github/ci/suites.yml)."""
    with open(ci_path) as fh:
        text = fh.read()
    suites = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(ci_path))), "ci", "suites.yml")
    if os.path.exists(suites):
        with open(suites) as fh:
            text += "\n" + fh.read()
    return text


class Corpus:
    """Repository text, indexed by word -> files containing it."""

    def __init__(self, files):
        self.files = files
        self.index = {}
        self.class_of = {}
        for path, text in files.items():
            for word in set(WORD.findall(text)):
                self.index.setdefault(word, set()).add(path)
            if path.endswith(".gd"):
                m = CLASS_NAME.search(text)
                if m:
                    self.class_of[path] = m.group(1)

    def referrers(self, path):
        names = {stem_of(path)}
        if path in self.class_of:
            names.add(self.class_of[path])
        out = set()
        for name in names:
            out |= self.index.get(name, set())
        out.discard(path)
        return out


def stem_of(path):
    """File name without extensions (.import/.uid sidecars and the type)."""
    base = os.path.basename(path)
    for ext in (".import", ".uid"):
        base = base[: -len(ext)] if base.endswith(ext) else base
    return base.split(".")[0]


def realm_of(path):
    """A realm when a directory or file name below the top level IS the realm
    prefix or starts with `<prefix>_` (cloudreach_world.gd, data/terrain/water/)."""
    for realm, prefixes in REALMS.items():
        for part in path.split("/")[1:]:
            name = part.split(".")[0]
            if any(name == p or name.startswith(p + "_") for p in prefixes):
                return realm
    return None


def realm_of_test(path):
    """A test/tool carries a realm when its file name does (smoke_cloudreach_*,
    smoke_net_water_*, proof_steps_stormwood)."""
    stem = stem_of(path)
    for realm, prefixes in REALMS.items():
        if any(stem.startswith(p + "_") or ("_" + p + "_") in stem or stem.endswith("_" + p) for p in prefixes):
            return realm
    return None


def is_game(path):
    return path.split("/")[0] in ("scripts", "scenes", "autoload", "data", "assets", "shaders") \
        or path in SCAN_FILES


def is_test_or_tool(path):
    return path.startswith("tests/") or path.startswith("tools/")


def is_net(path):
    return path.startswith("tools/net/") or path.startswith("tests/smoke_net_")


def jobs_running(path, jobs):
    """ci.yml jobs whose block names this test/tool: by file stem, as
    `SMOKE: <name>` (tests/smoke_${SMOKE}.gd) or `--only=<name>` lists."""
    stem = stem_of(path)
    short = re.sub(r"^(smoke|test)_", "", stem)
    out = set()
    for job, block in jobs.items():
        if re.search(r"\b%s\b" % re.escape(stem), block) \
                or re.search(r"SMOKE: %s\b" % re.escape(short), block) \
                or re.search(r"--only=[^\s]*\b%s\b" % re.escape(short), block):
            out.add(job)
    return out


def realm_jobs(realm, jobs, corpus):
    """Every job running a smoke that carries the realm, plus REALM_JOBS."""
    out = set(REALM_JOBS[realm])
    for path in corpus.files:
        if path.startswith("tests/smoke_") and realm_of_test(path) == realm:
            out |= jobs_running(path, jobs)
    return out


COMMENT_LINE = re.compile(r"(?m)^\s*#.*$")
# Only the repo's prose keys; any other key may be data the game reads.
JSON_PROSE = re.compile(r'"_(?:why|comment|comment_[A-Za-z0-9_]*|note|notes|doc|docs)"\s*:\s*"(?:[^"\\]|\\.)*"')


def code_text(corpus, ref):
    """`ref`'s text without what cannot load anything: GDScript comment lines
    and JSON `_why`/`_comment`-style prose keys."""
    cache = corpus.__dict__.setdefault("_code", {})
    if ref not in cache:
        text = corpus.files.get(ref, "")
        if ref.endswith(".gd"):
            text = COMMENT_LINE.sub("", text)
        elif ref.endswith(".json"):
            text = JSON_PROSE.sub('""', text)
        cache[ref] = text
    return cache[ref]


def loads_by_path(corpus, ref, node):
    """Does `ref`'s code (comments and prose keys removed) name `node` by
    repository path or by class_name?"""
    text = code_text(corpus, ref)
    # A changed sidecar (`x.gd.uid`, `x.png.import`) stands for its file.
    node = re.sub(r"\.(uid|import)$", "", node)
    if node in text:
        return True
    # A folder constant joined with the file name (`DIR := "res://tools/"`,
    # then `DIR + "x.gd"`): the stem matched, so the directory in code counts.
    if ("res://%s/" % os.path.dirname(node)) in text:
        return True
    cls = corpus.class_of.get(node)
    return bool(cls) and re.search(r"\b%s\b" % re.escape(cls), text) is not None


def reach(path, jobs, corpus, family):
    """Walk the files that name `path`, transitively. Returns ('all', why) or
    (jobs, why)."""
    chosen, seen, queue = set(), {path}, [path]
    while queue:
        node = queue.pop(0)
        for ref in sorted(corpus.referrers(node)):
            if ref in seen:
                continue
            if DOC_RE.search(ref):
                continue
            if is_test_or_tool(node) and (is_game(ref) or CORE_RE.search(ref)) \
                    and not loads_by_path(corpus, ref, node):
                # Game or core text that only mentions a test/tool (a comment,
                # a `_why` string) cannot load it: Godot needs its res:// path
                # or its class_name. NOT marked seen: the same file may
                # really load another node of this walk.
                continue
            seen.add(ref)
            if len(seen) > MAX_REACH:
                return "all", "reach of %s exceeds %d files" % (path, MAX_REACH)
            if CORE_RE.search(ref):
                return "all", "%s reaches core %s (via %s)" % (path, ref, node)
            if is_game(ref):
                if family is None or realm_of(ref) != family:
                    return "all", "%s reaches game code %s (via %s)" % (path, ref, node)
            elif is_test_or_tool(ref):
                chosen |= jobs_running(ref, jobs)
                if is_net(ref):
                    chosen |= NET_JOBS
            else:
                return "all", "%s reaches unmapped %s" % (path, ref)
            queue.append(ref)
    return chosen, "reach of %s: %d files" % (path, len(seen))


def classify(path, jobs, corpus):
    """('all' | set_of_jobs, reason)."""
    if DOC_RE.search(path):
        return set(), "documentation"
    if CORE_RE.search(path):
        return "all", "core/shared path"
    if path.endswith(".gd") and (path not in corpus.files or path in corpus.class_of):
        # A deleted/renamed script's users may name it only by a class_name
        # the HEAD index no longer has; a script declaring one is reachable
        # from anywhere without its path.
        return "all", "deleted/renamed script or global class_name"
    if MEDIA_RE.search(path):
        family = realm_of(path)
        extra, why = reach(path, jobs, corpus, family)
        if extra == "all":
            return "all", why
        base = set(PRESENTATION_JOBS) | ((realm_jobs(family, jobs, corpus) | NET_JOBS) if family else set())
        return base | extra, "presentation media/shader; " + why
    if is_test_or_tool(path):
        extra, why = reach(path, jobs, corpus, None)
        if extra == "all":
            return "all", why
        chosen = jobs_running(path, jobs) | extra | (NET_JOBS if is_net(path) else set())
        return chosen, "test/tool run by %s; %s" % (",".join(sorted(chosen)) or "no CI job", why)
    family = realm_of(path)
    if family and is_game(path):
        extra, why = reach(path, jobs, corpus, family)
        if extra == "all":
            return "all", why
        return realm_jobs(family, jobs, corpus) | NET_JOBS | extra, "%s family; %s" % (family, why)
    return "all", "gameplay code/data outside a realm family, or unmapped"


def select(changed, event, ci_text, corpus, force_all=False):
    """Returns (jobs_selected:set, everything:bool, explanation:list)."""
    jobs = ci_jobs(ci_text)
    every = set(jobs)
    changed = [p.strip() for p in changed if p.strip()]
    if force_all or event in ("schedule", "workflow_dispatch"):
        return every, True, ["%s: everything" % (event or "forced")]
    if not changed:
        return every, True, ["empty diff: everything"]
    code = [p for p in changed if not DOC_RE.search(p)]
    if len(code) > MAX_PATHS:
        return every, True, ["%d code paths > %d: everything" % (len(code), MAX_PATHS)]
    if not isinstance(corpus, Corpus):
        corpus = Corpus(corpus)
    missing = [f for f in REQUIRED_SCAN if f not in corpus.files]
    if REQUIRED_SCAN_CHECK and missing:
        # The checkout did not hold what the reference walk needs (ci.yml's
        # `changes` sparse checkout must list every SCAN_ROOTS text): a walk
        # over a partial corpus could under-select, so run everything.
        return every, True, ["scan corpus incomplete (missing %s): everything" % missing]
    chosen, why = set(ALWAYS_JOBS & every), []
    for path in changed:
        result, reason = classify(path, jobs, corpus)
        why.append("%s -> %s (%s)" % (path, "ALL" if result == "all" else (",".join(sorted(result)) or "-"), reason))
        if result == "all":
            return every, True, why
        chosen |= result
    return chosen & every, False, why


def load_corpus(root="."):
    files = {}
    for scan in SCAN_ROOTS:
        for dirpath, _dirs, names in os.walk(os.path.join(root, scan)):
            rel_dir = os.path.relpath(dirpath, root).replace(os.sep, "/") + "/"
            exts = DEFAULT_EXT
            for prefix, allowed in SCAN_EXT.items():
                if rel_dir.startswith(prefix):
                    exts = allowed
            for f in names:
                if f.endswith(exts):
                    full = os.path.join(dirpath, f)
                    try:
                        with open(full, encoding="utf-8", errors="ignore") as fh:
                            files[os.path.relpath(full, root).replace(os.sep, "/")] = fh.read()
                    except OSError:
                        pass
    for f in SCAN_FILES:
        try:
            with open(os.path.join(root, f), encoding="utf-8", errors="ignore") as fh:
                files[f] = fh.read()
        except OSError:
            pass
    return Corpus(files)


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--event", default="")
    ap.add_argument("--ci", default=".github/workflows/ci.yml")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args(argv)
    ci_text = ci_text_with_suites(args.ci)
    if args.all:
        chosen, everything, why = select([], args.event, ci_text, {}, force_all=True)
    else:
        changed = sys.stdin.read().splitlines()
        chosen, everything, why = select(changed, args.event, ci_text, load_corpus())
    for line in why:
        print("select: " + line, file=sys.stderr)
    # `|a|b|`: ci.yml tests `contains(jobs, '|ALL|') || contains(jobs, '|<job>|')`.
    names = (["ALL"] if everything else []) + sorted(chosen)
    print("jobs=|%s|" % "|".join(names))
    print("all=%s" % ("true" if everything else "false"))
    print("net=%s" % ("true" if everything or (chosen & NET_JOBS) else "false"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
