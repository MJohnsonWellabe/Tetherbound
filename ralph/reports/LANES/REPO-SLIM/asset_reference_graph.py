#!/usr/bin/env python3
"""Classify asset files as REFERENCED or UNREFERENCED by the shipped game,
CI, tests and capture tools (REPO-SLIM lane, owner 4 Nov 2026).

Reads the tree of a git revision (default HEAD) straight from git objects, so
it works without a full working tree. Conservative by design: a file counts
as referenced if its path, basename, stem, directory, Godot UID or a dynamic
path pattern (%s / {x} / *) that matches it appears in any seed text file, or
it is a dependency (.import twin, glTF extracted textures, glTF uri) of a
referenced file. Referenced text files inside the scanned folders become seeds
in turn, to a fixpoint.

Policy-kept regardless of references: provenance/report JSON, prompts, notes,
scripts and every file under a reference/ folder or named like a reference
image (art rules), Blender sources, .gdignore markers.

Usage: asset_reference_graph.py [--rev REV] --out manifest.json
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict

TARGET_PREFIXES = (
    "assets/creatures/tetherbound/",
    "assets/props/meshy-",
    "assets/props/crossing_hall_hero/",
    "assets/props/generated_camp/",
    "assets/props/realm_gate_meshy/",
    "assets/props/vl-1103/",
)
# Folders whose text never seeds references (evidence/history, not loaded).
EXCLUDED_TOP = ("ralph/", "docs/", "shots/", "assets_raw/", "archive/")
TEXT_EXT = {
    "gd", "tscn", "tres", "json", "jsonl", "cfg", "godot", "py", "sh", "mjs",
    "js", "cjs", "yml", "yaml", "import", "gdshader", "gdshaderinc", "txt",
    "md", "csv", "ini", "toml", "html", "material", "gltf", "ps1", "bat",
}
BINARY_ASSET_EXT = {
    "glb", "gltf", "png", "jpg", "jpeg", "webp", "exr", "hdr", "ktx", "ktx2",
    "bin", "fbx", "obj", "mtl", "res", "scn", "mesh", "anim", "wav", "ogg",
    "mp3", "tga", "bmp", "svg", "dds",
}
KEEP_POLICY_EXT = {"json", "jsonl", "txt", "md", "py", "gd", "blend", "blend1",
                   "gdignore", "sh", "csv", "yml", "yaml"}
REF_NAME_RE = re.compile(r"(^|[_\-/])(ref|reference|prompt|concept|thumb|thumbnail|thumbs|scale_check|preview|preview_3view)([_\-.0-9]|$)", re.I)
TOKEN_RE = re.compile(r"[A-Za-z0-9_\-./%{}*:]+")
PATTERN_LOG: list = []
# Dynamic strings inspected by hand that never load the files they match.
NON_LOADING_PATTERNS = {
    # assert_false(model.begins_with(".../%s/models/")): a prefix check only.
    ("assets/creatures/tetherbound/%s/models", "tests/test_water_species_catalog.gd"),
}
FORMAT_RE = re.compile(r"%[sd0-9.]*[sd]|\{[^{}/]*\}|\*")


def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], check=True, capture_output=True).stdout


def ext_of(path: str) -> str:
    base = path.rsplit("/", 1)[-1]
    return base.rsplit(".", 1)[-1].lower() if "." in base else ""


def norm_token(tok: str) -> str:
    tok = tok.strip("./:")  # leading ./ and trailing punctuation
    if tok.startswith("res://"):
        tok = tok[6:]
    elif "res://" in tok:
        tok = tok.split("res://", 1)[1]
    return tok.rstrip("/").lstrip("/")


def read_blobs(rev: str, paths_shas: list[tuple[str, str]]) -> dict[str, str]:
    """Batch-read blobs via cat-file --batch."""
    out: dict[str, str] = {}
    if not paths_shas:
        return out
    proc = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE)
    assert proc.stdin and proc.stdout
    for path, sha in paths_shas:
        proc.stdin.write((sha + "\n").encode())
        proc.stdin.flush()
        header = proc.stdout.readline().split()
        size = int(header[2])
        data = proc.stdout.read(size)
        proc.stdout.read(1)
        out[path] = data.decode("utf-8", "replace")
    proc.stdin.close()
    proc.wait()
    return out


def glb_uris(sha: str) -> list[str]:
    data = git("cat-file", "blob", sha)
    if len(data) < 20 or data[:4] != b"glTF":
        return []
    chunk_len = int.from_bytes(data[12:16], "little")
    try:
        doc = json.loads(data[20:20 + chunk_len])
    except ValueError:
        return []
    uris = []
    for key in ("images", "buffers"):
        for item in doc.get(key, []) or []:
            uri = item.get("uri")
            if uri and not uri.startswith("data:"):
                uris.append(uri)
    return uris


SEED_EXT_IN_TARGETS = {"tscn", "tres", "import", "gdshader", "gdshaderinc",
                       "material", "gd", "gltf", "json"}
METADATA_NAME_RE = re.compile(r"provenance|report|prepare|apply|candidate|prompt|notes", re.I)


def loads_resources(path: str) -> bool:
    """A referenced file inside the scanned folders seeds further references
    only if it is something the engine loads. Provenance records, prep/apply
    scripts and reports under source/ document an asset; they never load one."""
    base = path.rsplit("/", 1)[-1]
    if "/source/" in path or ext_of(path) not in SEED_EXT_IN_TARGETS:
        return False
    return not (ext_of(path) == "json" and METADATA_NAME_RE.search(base))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rev", default="HEAD")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    tree: dict[str, tuple[str, int]] = {}
    for line in git("ls-tree", "-r", "-l", args.rev).decode().splitlines():
        meta, path = line.split("\t", 1)
        mode, typ, sha, size = meta.split()
        if typ == "blob":
            tree[path] = (sha, int(size))

    targets = {p for p in tree if p.startswith(TARGET_PREFIXES)}
    seeds = [p for p in tree
             if p not in targets and not p.startswith(EXCLUDED_TOP)
             and (ext_of(p) in TEXT_EXT or p.endswith("project.godot"))]
    target_text = [p for p in targets if ext_of(p) in TEXT_EXT]
    texts = read_blobs(args.rev, [(p, tree[p][0]) for p in seeds + target_text])

    dirs_of: dict[str, list[str]] = defaultdict(list)
    by_base: dict[str, list[str]] = defaultdict(list)
    by_stem: dict[str, list[str]] = defaultdict(list)
    for p in targets:
        d, b = p.rsplit("/", 1)
        dirs_of[d].append(p)
        by_base[b].append(p)
        stem = b.split(".", 1)[0]
        by_stem[stem].append(p)

    # UIDs of target files (from their .import twins).
    uid_of: dict[str, str] = {}
    for p in target_text:
        if p.endswith(".import"):
            m = re.search(r'^uid="(uid://[a-z0-9]+)"', texts.get(p, ""), re.M)
            if m:
                uid_of[m.group(1)] = p[: -len(".import")]

    referenced: dict[str, str] = {}

    def mark(p: str, why: str) -> bool:
        if p in targets and p not in referenced:
            referenced[p] = why
            return True
        return False

    patterns: list[tuple[re.Pattern, str]] = []
    processed: set[str] = set()
    queue = list(seeds)

    def scan(src: str) -> None:
        body = texts.get(src, "")
        for uid in re.findall(r"uid://[a-z0-9]+", body):
            if uid in uid_of:
                mark(uid_of[uid], f"uid in {src}")
        for raw in TOKEN_RE.findall(body):
            tok = norm_token(raw)
            if not tok:
                continue
            if "**" in tok:
                continue  # prose globs such as assets/props/** in comments
            if FORMAT_RE.search(tok) and "/" in tok:
                if (tok, src) in NON_LOADING_PATTERNS:
                    continue
                if "*" in tok and ext_of(src) in {"json", "md", "txt"}:
                    continue  # prose glob in a comment field, not a load
                if not any(len(seg) >= 3 and not FORMAT_RE.search(seg)
                           for seg in tok.split("/")[:-1]):
                    continue  # e.g. "%s/%s": no literal directory anchor
                rx = re.escape(tok)
                rx = re.sub(r"%[sd0-9.]*[sd]|\\\{[^/]*?\\\}|\\\*", "[^/]+", rx)
                last = tok.rsplit("/", 1)[-1]
                is_dir = "." not in last or tok.endswith("/") or raw.rstrip().endswith("/")
                rx = r"(^|/)" + rx + (r"/[^/]+$" if is_dir else "$")
                PATTERN_LOG.append((tok, src, "dir" if is_dir else "file"))
                try:
                    patterns.append((re.compile(rx), f"pattern '{tok}' in {src}"))
                except re.error:
                    pass
                continue
            if tok in targets:
                mark(tok, f"path in {src}")
                continue
            if tok in dirs_of:
                for p in dirs_of[tok]:
                    mark(p, f"directory {tok} named in {src}")
                continue
            base = tok.rsplit("/", 1)[-1]
            if "/" in tok:
                # partial path: suffix match on targets with this basename
                for p in by_base.get(base, ()):
                    if p.endswith("/" + tok) or p == tok:
                        mark(p, f"path suffix in {src}")
                for p in by_stem.get(base, ()):
                    if ("/" + p).rsplit(".", 1)[0].endswith("/" + tok):
                        mark(p, f"path stem suffix in {src}")
                continue
            if len(by_base.get(base, ())) <= 3:
                for p in by_base.get(base, ()):
                    mark(p, f"basename '{base}' in {src}")
            if len(by_stem.get(base, ())) <= 6 and len(base) >= 6 and ("_" in base or "-" in base):
                for p in by_stem.get(base, ()):
                    mark(p, f"stem '{base}' in {src}")

    changed = True
    while changed:
        changed = False
        while queue:
            src = queue.pop()
            if src in processed:
                continue
            processed.add(src)
            scan(src)
        for rx, why in patterns:
            for p in targets:
                if p not in referenced and rx.search(p):
                    mark(p, why)
        # dependencies of referenced files
        for p in list(referenced):
            if p + ".import" in targets:
                if mark(p + ".import", f"import twin of {p}"):
                    changed = True
            if p.lower().endswith((".glb", ".gltf")):
                d, b = p.rsplit("/", 1)
                stem = b.rsplit(".", 1)[0]
                for q in dirs_of[d]:
                    qb = q.rsplit("/", 1)[1]
                    if qb.startswith(stem + "_") and ext_of(q) in BINARY_ASSET_EXT | {"import"}:
                        if mark(q, f"extracted resource of {p}"):
                            changed = True
                for uri in glb_uris(tree[p][0]):
                    q = d + "/" + uri
                    if mark(q, f"glTF uri of {p}"):
                        changed = True
        for p in referenced:
            if p in texts and p not in processed and loads_resources(p):
                queue.append(p)
                changed = True

    manifest = []
    for p in sorted(targets):
        sha, size = tree[p]
        e = ext_of(p)
        base = p.rsplit("/", 1)[-1]
        if p in referenced:
            cls, why = "REFERENCED", referenced[p]
        elif "/reference/" in p or "/references/" in p or REF_NAME_RE.search(base):
            cls, why = "KEPT_POLICY", "reference, scale check or review image (art rules)"
        elif e in KEEP_POLICY_EXT or base == ".gdignore":
            cls, why = "KEPT_POLICY", "provenance/metadata/source text kept on main"
        elif e == "import" and p[: -len(".import")] not in targets:
            cls, why = "KEPT_POLICY", "orphan .import (no source file); ambiguous"
        elif e in BINARY_ASSET_EXT or e == "import":
            cls, why = "UNREFERENCED", "no path, basename, stem, directory, uid or pattern reference in seeds"
        else:
            cls, why = "KEPT_POLICY", f"unknown type .{e}; ambiguous"
        manifest.append({"path": p, "size": size, "class": cls, "why": why})

    import os
    # an .import twin follows its source file's class
    cls = {m["path"]: m for m in manifest}
    for m in manifest:
        if m["path"].endswith(".import") and m["class"] == "UNREFERENCED":
            src = cls.get(m["path"][: -len(".import")])
            if src and src["class"] != "UNREFERENCED":
                m["class"], m["why"] = src["class"], "import twin of a kept file"
    with open(os.path.join(os.path.dirname(args.out), "patterns.txt"), "w") as fh:
        for tok, src, kind in sorted(set(PATTERN_LOG)):
            n = sum(1 for p in referenced if referenced[p] == f"pattern '{tok}' in {src}")
            fh.write(f"{kind}\t{n}\t{tok}\t{src}\n")
    with open(args.out, "w") as fh:
        json.dump({"rev": git("rev-parse", args.rev).decode().strip(),
                   "target_prefixes": TARGET_PREFIXES,
                   "seed_files": len(seeds), "files": manifest}, fh, indent=1)
    tot = defaultdict(lambda: [0, 0])
    for m in manifest:
        tot[m["class"]][0] += 1
        tot[m["class"]][1] += m["size"]
    for k, (n, s) in sorted(tot.items()):
        print(f"{k:13s} {n:6d} files {s / 1e9:7.3f} GB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
