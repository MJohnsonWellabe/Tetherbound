# seam_receipts.py <from_dir> <to_dir> <out.json>: f49_piece_seam for cloudreach/tidewake/stormwood runner pieces (receipt after vs next before)
import json, sys, math
def load(p): return json.load(open(p + '/receipt.json'))
a, b = load(sys.argv[1]), load(sys.argv[2])
def state(s):
    t = s.get('training') or {}
    party = [{"uid": c.get("uid"), "species": c.get("species"), "level": c.get("level"), "cap_level": c.get("cap_level"),
              "breakthroughs": c.get("breakthroughs")} for c in t.get("party", [])] or \
            [{"uid": c.get("uid"), "species": c.get("species"), "level": c.get("level")} for c in s.get("party", [])]
    return {"realm": s.get("realm"), "position": [round(float(x), 2) for x in (s.get("player") or s.get("position") or [])],
            "flags": sorted(s.get("flags") or []), "inventory": s.get("items") or s.get("inventory") or {},
            "party": party, "master_wins": sorted(t.get("master_wins", [])), "feast_recipes": sorted(t.get("feast_recipes", []))}
end, start = state(a["after"]), state(b["before"])
diffs = []
for k in end:
    if k == "position":
        if end[k] and start[k]:
            d = math.dist(end[k], start[k])
            if d > 1.0: diffs.append({"field": k, "saved": end[k], "loaded": start[k], "distance_m": round(d, 2), "reason": "UNEXPLAINED"})
        continue
    if end[k] != start[k]:
        diffs.append({"field": k, "saved": end[k], "loaded": start[k], "reason": "UNEXPLAINED"})
out = {"kind": "f49_piece_seam", "from_piece": a.get("segment"), "from_commit": a.get("commit"), "to_piece": b.get("segment"),
       "to_commit": b.get("commit"), "to_loaded_from": b.get("from"), "end_state": end, "differences": diffs, "matches": not diffs}
json.dump(out, open(sys.argv[3], "w"), indent=1); print(sys.argv[3].split('/')[-1], "MATCH" if not diffs else "DIFF " + ",".join(d["field"] for d in diffs))
