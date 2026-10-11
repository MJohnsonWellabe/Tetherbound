"""Merge every F36 native candidate placeholder into species.json (capture-only)."""
import json, glob, sys, collections
root = sys.argv[1]
path = f"{root}/data/creatures/species.json"
sp = json.load(open(path), object_pairs_hook=collections.OrderedDict)
done = []
for f in sorted(glob.glob(f"{root}/assets/creatures/tetherbound/*/candidate/source/species_candidate.json")):
    c = json.load(open(f))
    sid = c.get("species") or c.get("subject")
    entry = sp["species"].get(sid)
    if not isinstance(entry, dict):
        print("MISSING species entry", sid); continue
    entry.setdefault("placeholder", collections.OrderedDict()).update(c["placeholder"])
    done.append(sid)
json.dump(sp, open(path, "w"), indent=2, ensure_ascii=False)
open(path, "a").write("\n")
print("enabled", len(done), ",".join(done))
