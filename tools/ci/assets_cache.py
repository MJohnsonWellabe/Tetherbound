#!/usr/bin/env python3
"""Shared assets/ cache for ci.yml's engine jobs (CI-SPEED, owner 4 Nov 2026:
"Do all the fixes to make the download faster without losing any meshy
assets permanently").

WHY. Every engine job used to materialise ~7 GB of assets/ through a blobless
`actions/checkout`, ~30 jobs at once against the git server: 4-47 min a job
on run 41722777593 (3 Nov). Now each job checks out everything EXCEPT
/assets/ (small), and assets/ comes from the Actions cache instead.

HOW. assets/ is split into CHUNKS fixed-size groups. A path's chunk is a hash
of its first four components (assets/<a>/<b>/<c>), so one creature or one
Meshy folder always lands in the same chunk, and a change re-saves ~1 GB, not
7 GB. A chunk's cache key is the sha256 of its exact "mode oid path" listing
from `git ls-tree` (trees only; works in a blobless clone), so a key can never
name different bytes. The cached file is a plain tar of the chunk's files.

  plan        -> keys for $GITHUB_OUTPUT (key0..keyN-1) and per-chunk lists
  materialize -> the `assets-cache` prep job: build the tar of each chunk the
                 cache does not hold (fetch its blobs, write files, tar them)
  restore     -> every engine job: unpack the restored tars; any chunk that
                 did not restore is fetched from git instead (the old path);
                 then VERIFY every file against its git blob id and hand the
                 paths back to git as ordinary checked-out files.

Verification is git's own: assets/ index entries lose skip-worktree and
`git update-index --refresh` re-hashes every file against its index blob id;
any modified, missing or extra file fails the job. Nothing is trusted
unverified, and the worktree ends identical to a full checkout's (`git
status` clean, `git ls-files`/`git diff` behave as before).

Tested by tests/test_ci_assets_cache.py.
"""
import argparse
import concurrent.futures
import hashlib
import os
import shutil
import subprocess
import sys
import tarfile

CHUNKS = 8
# Bump to invalidate every assets cache entry (layout or format change).
VERSION = "v1"
PREFIX = "assets-%s-" % VERSION
FETCH_PARALLEL = 4


def git(*args, **kw):
    return subprocess.run(["git", *args], check=True, **kw)


def listing(rev="HEAD"):
    """[(mode, oid, path)] for every blob under assets/ at rev."""
    out = subprocess.run(["git", "ls-tree", "-r", "-z", "--full-tree", rev, "--", "assets"],
                         check=True, capture_output=True).stdout.decode("utf-8")
    rows = []
    for rec in out.split("\0"):
        if not rec:
            continue
        meta, path = rec.split("\t", 1)
        mode, kind, oid = meta.split()
        if kind != "blob":
            raise SystemExit("assets_cache: unsupported %s entry %s" % (kind, path))
        rows.append((mode, oid, path))
    return rows


def chunk_of(path, chunks=CHUNKS):
    unit = "/".join(path.split("/")[:4])
    return int(hashlib.sha1(unit.encode("utf-8")).hexdigest()[:8], 16) % chunks


def plan(rows, chunks=CHUNKS):
    """{chunk: (key, rows)} for every chunk (an empty chunk still has a key)."""
    groups = {i: [] for i in range(chunks)}
    for row in rows:
        groups[chunk_of(row[2], chunks)].append(row)
    out = {}
    for i, grp in groups.items():
        grp.sort(key=lambda r: r[2])
        h = hashlib.sha256()
        for mode, oid, path in grp:
            h.update(("%s %s %s\n" % (mode, oid, path)).encode("utf-8"))
        out[i] = ("%sc%d-%s" % (PREFIX, i, h.hexdigest()[:40]), grp)
    return out


def tar_path(cache_dir, i):
    return os.path.join(cache_dir, "c%d.tar" % i)


def fetch_blobs(oids):
    """Fetch blobs into a blobless clone the way git's own lazy fetch does,
    split across FETCH_PARALLEL connections (one connection is what made the
    old checkout slow). Each fetch writes its own pack, so they can overlap."""
    oids = sorted(set(oids))
    if not oids:
        return
    parts = [oids[k::FETCH_PARALLEL] for k in range(FETCH_PARALLEL)]

    def one(part):
        if not part:
            return
        subprocess.run(["git", "-c", "fetch.negotiationAlgorithm=noop", "fetch", "origin",
                        "--no-tags", "--no-write-fetch-head", "--recurse-submodules=no",
                        "--filter=blob:none", "--stdin"],
                       input=("\n".join(part) + "\n").encode(), check=True)

    with concurrent.futures.ThreadPoolExecutor(FETCH_PARALLEL) as pool:
        for fut in [pool.submit(one, p) for p in parts]:
            fut.result()


def write_files(rows):
    """Write each blob to its path from the local object store."""
    if not rows:
        return
    proc = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE)
    try:
        for mode, oid, path in rows:
            proc.stdin.write((oid + "\n").encode())
            proc.stdin.flush()
            header = proc.stdout.readline().decode().split()
            if len(header) != 3 or header[1] != "blob":
                raise SystemExit("assets_cache: cannot read %s (%s): %s" % (path, oid, header))
            size = int(header[2])
            os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
            if os.path.lexists(path):
                os.remove(path)
            with open(path, "wb") as fh:
                left = size
                while left:
                    buf = proc.stdout.read(min(left, 1 << 20))
                    if not buf:
                        raise SystemExit("assets_cache: short read for %s" % path)
                    fh.write(buf)
                    left -= len(buf)
            proc.stdout.read(1)  # trailing newline
            os.chmod(path, 0o755 if mode == "100755" else 0o644)
    finally:
        proc.stdin.close()
        proc.wait()


def materialize(rows):
    fetch_blobs([oid for _m, oid, _p in rows])
    write_files(rows)


def make_tar(cache_dir, i, rows):
    os.makedirs(cache_dir, exist_ok=True)
    tmp = tar_path(cache_dir, i) + ".part"
    with tarfile.open(tmp, "w", format=tarfile.GNU_FORMAT) as tf:
        for _mode, _oid, path in rows:
            tf.add(path, arcname=path, recursive=False)
    os.replace(tmp, tar_path(cache_dir, i))


def unpack(cache_dir, i, rows):
    """Unpack chunk i's tar. False (and nothing written) when the tar is not
    exactly the chunk's file list; the caller then fetches the chunk from git.
    Content is checked afterwards by adopt_and_verify."""
    path = tar_path(cache_dir, i)
    try:
        with tarfile.open(path, "r") as tf:
            members = tf.getmembers()
            names = sorted(m.name for m in members)
            if names != sorted(p for _m, _o, p in rows) or not all(m.isreg() for m in members):
                print("::warning::cached chunk %d does not list exactly its files; ignoring it" % i)
                return False
            try:  # members were checked above; keep their modes and mtimes as stored
                tf.extractall(".", filter="tar")
            except TypeError:  # Python without extraction filters
                tf.extractall(".")
        return True
    except (tarfile.TarError, OSError) as exc:
        print("::warning::cached chunk %d could not be unpacked (%s); ignoring it" % (i, exc))
        return False
    finally:
        if os.path.exists(path):
            os.remove(path)


def adopt_and_verify(rows):
    """Hand assets/ back to git as normal checked-out paths, then let git
    re-hash every file against its blob id. Returns a list of problems."""
    paths = [p for _m, _o, p in rows]
    data = ("\0".join(paths) + "\0").encode("utf-8")
    git("update-index", "-z", "--no-skip-worktree", "--stdin", input=data)
    # Keep git's sparse patterns in step with the index: assets/ is now part
    # of the work tree, so a later checkout/reapply must not drop it again.
    sparse = os.path.join(subprocess.run(["git", "rev-parse", "--git-path", "info/sparse-checkout"],
                                         check=True, capture_output=True, text=True).stdout.strip())
    if os.path.exists(sparse):
        with open(sparse) as fh:
            lines = fh.read().splitlines()
        kept = [l for l in lines if l.strip() not in ("!/assets/", "!/assets")]
        if kept != lines:
            with open(sparse, "w") as fh:
                fh.write("\n".join(kept) + "\n")
    problems = []
    # --refresh hashes each file whose stat data is unknown (all of them here)
    # and prints "<path>: needs update" for content that differs, or a
    # deletion. It never reads blobs, so a mismatch cannot trigger a fetch.
    res = subprocess.run(["git", "update-index", "-q", "--refresh"], capture_output=True, text=True)
    problems += [l for l in (res.stdout + res.stderr).splitlines() if l.strip()]
    res = subprocess.run(["git", "ls-files", "-z", "--modified", "--deleted", "--", "assets"],
                         check=True, capture_output=True)
    problems += ["modified/deleted: " + p for p in res.stdout.decode().split("\0") if p]
    res = subprocess.run(["git", "ls-files", "-z", "--others", "--", "assets"],
                         check=True, capture_output=True)
    problems += ["not in git: " + p for p in res.stdout.decode().split("\0") if p]
    return problems


def gh_output(pairs):
    out = os.environ.get("GITHUB_OUTPUT")
    text = "".join("%s=%s\n" % kv for kv in pairs)
    if out:
        with open(out, "a") as fh:
            fh.write(text)
    sys.stdout.write(text)


def cmd_plan(_args):
    p = plan(listing())
    pairs = [("key%d" % i, p[i][0]) for i in sorted(p)]
    for i in sorted(p):
        size = len(p[i][1])
        print("chunk %d: %d files" % (i, size))
    gh_output(pairs)


def cmd_materialize(args):
    """Prep job: build the tar of every chunk the cache does not already hold
    (--hit lists the exact-key hits). One chunk at a time, so a tar that is
    finished is on disk for its save step even if a later chunk runs out of
    time, and each chunk's files are removed once tarred (disk stays ~1 GB +
    the tars)."""
    p = plan(listing())
    hit = {h for h in args.hit.split(",") if h}
    missing = [i for i in sorted(p) if str(i) not in hit]
    print("chunks to build: %s" % (",".join(map(str, missing)) or "none"), flush=True)
    for i in missing:
        rows = p[i][1]
        materialize(rows)
        make_tar(args.cache_dir, i, rows)
        for _mode, _oid, path in rows:
            os.remove(path)
        print("built %s (%d files)" % (p[i][0], len(rows)), flush=True)


def cmd_restore(args):
    p = plan(listing())
    every = [r for i in sorted(p) for r in p[i][1]]
    fallback = []
    for i in sorted(p):
        if not (os.path.exists(tar_path(args.cache_dir, i)) and unpack(args.cache_dir, i, p[i][1])):
            fallback.append(i)
    if fallback:
        print("::warning::assets cache missed chunk(s) %s; fetching them from git instead"
              % ",".join(map(str, fallback)))
        materialize([r for i in fallback for r in p[i][1]])
    problems = adopt_and_verify(every)
    if problems:
        # Never trust a stale or damaged cache: rewrite every file from git
        # and verify again; fail only if git's own bytes still disagree.
        print("::warning::%d asset file(s) did not match git after restore; rewriting from git"
              % len(problems))
        for line in problems[:50]:
            print("  " + line)
        bad = set()
        for line in problems:
            for tag in ("modified/deleted: ", "not in git: "):
                if line.startswith(tag):
                    bad.add(line[len(tag):])
        for path in bad:
            if os.path.lexists(path):
                os.remove(path)
        redo = [r for r in every if r[2] in bad]
        # A problem git did not name by path: rewrite everything.
        if not bad or any(not l.startswith(("modified/deleted: ", "not in git: ")) for l in problems):
            redo = every
        materialize(redo)
        problems = adopt_and_verify(every)
        if problems:
            for line in problems[:50]:
                print("::error::" + line)
            raise SystemExit("assets_cache: assets/ does not match git after rewriting from git")
    print("assets/ verified: %d files match their git blob ids (%d chunk(s) from git)"
          % (len(every), len(fallback)))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("plan")
    m = sub.add_parser("materialize")
    m.add_argument("--cache-dir", required=True)
    m.add_argument("--hit", default="", help="comma list of chunks the cache already holds")
    r = sub.add_parser("restore")
    r.add_argument("--cache-dir", required=True)
    args = ap.parse_args(argv)
    {"plan": cmd_plan, "materialize": cmd_materialize, "restore": cmd_restore}[args.cmd](args)


if __name__ == "__main__":
    main()
