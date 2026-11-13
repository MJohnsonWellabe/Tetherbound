"""Flag-flip arm helper (local GPU-pass). The capture worktree is re-checked-out by CleanCrA before every preset, which restores the file.

Usage:
  python json_flip.py <file> <dotted.key> <json value>          set one existing value (rewrites the JSON with indent 2)
  python json_flip.py --from <sha> <repo path> <worktree root>    replace the file with its exact bytes at <sha> (the candidate branch),
                                                                 so the flipped tree matches that branch byte for byte
Prints a receipt; exits 1 on any mismatch.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

if sys.argv[1] == "--from":
    sha, rel, root = sys.argv[2], sys.argv[3], sys.argv[4]
    dest = os.path.join(root, rel.replace("/", os.sep))
    # A file the branch adds (10 Nov, stormwood_horizon_groves.gd) is written new; the caller removes it after the run,
    # since CleanCrA keeps untracked files it does not recognise as generated.
    if os.path.exists(dest):
        before = hashlib.sha256(open(dest, "rb").read()).hexdigest()[:12]
    else:
        before = "new file"
        os.makedirs(os.path.dirname(dest), exist_ok=True)
    blob = subprocess.run(["git", "-C", root, "cat-file", "blob", f"{sha}:{rel}"], capture_output=True, check=True).stdout
    with open(dest, "wb") as f:
        f.write(blob)
    after = hashlib.sha256(open(dest, "rb").read()).hexdigest()[:12]
    if after != hashlib.sha256(blob).hexdigest()[:12]:
        sys.exit("FLIP FAILED: write mismatch")
    print(f"flip {rel} <- {sha[:9]}:{rel} (sha256 {before} -> {after})")
    sys.exit(0)

if sys.argv[1] == "--overlay":  # python json_flip.py --overlay <sha> <repo path of overlay json> <worktree root>
    sha, rel, root = sys.argv[2], sys.argv[3], sys.argv[4]
    # sha "local" reads <repo path> as a file on disk (queue entries that carry their overlay inline).
    overlay = json.load(open(rel, encoding="utf-8")) if sha == "local" else json.loads(subprocess.run(["git", "-C", root, "cat-file", "blob", f"{sha}:{rel}"], capture_output=True, check=True).stdout)

    def merge(node, patch, prefix, log):
        for k, v in patch.items():
            if isinstance(v, dict) and isinstance(node.get(k), dict):
                merge(node[k], v, prefix + k + ".", log)
            elif v is None:  # null removes the key; stored as a literal null it breaks typed readers (character_model.gd:651, found 9 Nov).
                log.append(f"{prefix}{k}: {json.dumps(node.get(k, '<absent>'))} -> <removed>")
                node.pop(k, None)
            else:
                log.append(f"{prefix}{k}: {json.dumps(node.get(k, '<absent>'))} -> {json.dumps(v)}")
                node[k] = v

    def contains(node, patch):
        return all(contains(node[k], v) if isinstance(v, dict) else node.get(k) == v for k, v in patch.items())

    def walk(node, path):
        # "placements[81].at" -> the parent container and last key; a path that is not in the file aborts the arm.
        steps = [int(i) if i else k for k, i in re.findall(r"([^.\[\]]+)|\[(\d+)\]", path)]
        for s in steps[:-1]:
            try:
                node = node[s]
            except (KeyError, IndexError, TypeError):
                sys.exit(f"FLIP FAILED: {path} not in file")
        try:
            node[steps[-1]]
        except (KeyError, IndexError, TypeError):
            sys.exit(f"FLIP FAILED: {path} not in file")
        return node, steps[-1]

    for target, patch in overlay.items():
        if target.startswith("_"):
            continue
        dest = os.path.join(root, target.replace("/", os.sep))
        doc, log = json.load(open(dest, encoding="utf-8")), []
        by_path = any("[" in k for k in patch)  # path-patch overlay: a deep merge would add these as literal keys and still read back fine
        if by_path:
            for path, value in patch.items():
                parent, last = walk(doc, path)
                log.append(f"{path}: {json.dumps(parent[last])} -> {json.dumps(value)}")
                parent[last] = value
        else:
            merge(doc, patch, "", log)
        with open(dest, "w", encoding="utf-8", newline="\n") as f:
            json.dump(doc, f, indent=2, ensure_ascii=False)
            f.write("\n")
        check = json.load(open(dest, encoding="utf-8"))
        if not (all(walk(check, p)[0][walk(check, p)[1]] == v for p, v in patch.items()) if by_path else contains(check, patch)):
            sys.exit(f"FLIP FAILED: read-back mismatch in {target}")
        print(f"overlay {target} <- {sha[:9]}: " + "; ".join(log))
    sys.exit(0)

path, key, raw = sys.argv[1], sys.argv[2], sys.argv[3]
doc = json.load(open(path, encoding="utf-8"))
node = doc
parts = key.split(".")
for p in parts[:-1]:
    if not isinstance(node, dict) or p not in node:
        sys.exit(f"FLIP FAILED: {key} not in {path}")
    node = node[p]
if not isinstance(node, dict) or parts[-1] not in node:
    sys.exit(f"FLIP FAILED: {key} not in {path}")
old, new = node[parts[-1]], json.loads(raw)
node[parts[-1]] = new
with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(doc, f, indent=2, ensure_ascii=False)
    f.write("\n")
check = json.load(open(path, encoding="utf-8"))
for p in parts:
    check = check[p]
print(f"flip {path} {key}: {json.dumps(old)} -> {json.dumps(check)}")
if check != new:
    sys.exit("FLIP FAILED: read-back mismatch")
