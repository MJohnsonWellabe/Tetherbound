"""R14 byte/source audit only, no Godot/parser/native acceptance."""
from pathlib import Path
import hashlib, json, re
P = Path(__file__).resolve().parent
HUB = P.parents[4]
H = lambda b: hashlib.sha256(b).hexdigest()
checks = []
def check(name, ok): checks.append({"name": name, "passed": bool(ok)})
def read(n): return (P/n).read_text(encoding="utf-8").replace("\r\n", "\n")
def functions(s):
    lines, result = s.splitlines(), {}
    for i, line in enumerate(lines):
        match = re.match(r"(?:static )?func (\w+)\(", line)
        if match:
            end = i + 1
            while end < len(lines) and (not lines[end] or lines[end].startswith("\t")): end += 1
            result[match[1]] = "\n".join(lines[i:end]).rstrip()
    return result
m = json.loads(read("manifest.json"))
for n, pin in m["files"].items():
    b = (P/n).read_bytes()
    check("frozen "+n, len(b)==pin["bytes"] and H(b)==pin["sha256"])
for n, pin in m["protected_hub_sha256"].items(): check("unchanged protected "+n, H((HUB/n).read_bytes())==pin)
for n in m["changed_paths"]: check("live proposal "+n, (HUB/n).read_bytes()==(P/"proposal"/n).read_bytes())
drive, test = m["changed_paths"]
old, new = read("originals/"+drive), read("proposal/"+drive)
of, nf = functions(old), functions(new)
check("only legacy approach changed", [k for k in of if of[k]!=nf.get(k)]==["_walk_to_and_engage_wild"])
check("one pure metadata planner added", set(nf)-set(of)=={"wild_approach_road"})
for n in of:
    if n!="_walk_to_and_engage_wild": check("unchanged inherited function "+n, of[n]==nf[n])
for prefix in ["const", "var"]: check("all drive "+prefix+" declarations exact", re.findall(r"^"+prefix+r" .*",old,re.M)==re.findall(r"^"+prefix+r" .*",new,re.M))
f, o = nf["_walk_to_and_engage_wild"], of["_walk_to_and_engage_wild"]
check("exact target/offer/recheck/physical action block", o[o.index("\t\tif not is_instance_valid(target):"):o.index("\t\t# A player")]==f[f.index("\t\tif not is_instance_valid(target):"):f.index("\t\tif int(Engine.get_physics_frames() - started_frame) >= budget:",f.index("\t\tif not is_instance_valid(target):"))])
marker='\t_stop_left_stick()\n\tprint("wild approach: exhausted'
check("exhaustion diagnostics exact", o[o.index(marker):]==f[f.index(marker):])
check("same live target fallback", "\t\tvar goal := target.global_position" in f and "_drive_body_toward(_player, goal, 1)" in f)
check("same real drive only", f.count("_drive_body_toward(")==o.count("_drive_body_toward(")==2 and "nav.step" not in f)
check("existing .8m plus nativefloor road arrival", "offset.length() <= 0.8 and _player.is_on_floor()" in f)
check("one caller budget with capped sidesteps", "for _i in budget:" in f and f.count(">= budget:")==2 and "budget - int(Engine.get_physics_frames() - started_frame)" in f and "mini(SIDESTEP_FRAMES, remaining)" in f and "_walk_toward(" not in f)
check("same stall/side distance/alternation", all(s in f for s in ["if _stall_frames >= STALL_FRAMES:", "* (4.0 * _stall_side)", "_stall_side = -_stall_side"]))
check("actual farmhouse marker and missing-world fallback", 'house.call("marker", "door")' in f and 'as Node3D if _world != null else null' in f)
h = nf["wild_approach_road"]
check("pure planner without native queries/body writes", not any(s in h for s in [".call(", "Input.", "global_position", "intersect_", "collide_shape", "cast_motion", "get_ticks_", "set("]))
check("finite bounded metadata", all(s in h for s in ["from.is_finite()", "house.is_finite()", "door.is_finite()", "routes.size() > 32", "raw.size() > 64", "not is_finite(float(point[0]))", "not is_finite(float(point[1]))", "> 180.0"]))
check("one exact route required", '"Practice Meadow"' in h and '"valid": matches == 1' in h)
check("same fresh clearance geometry", all(s in h for s in ["door + front * 1.8", "offset.dot(front) < 1.0", "offset.length() >= 4.0"]))
check("farfield needs no metadata", h.index("if offset.length() >= 4.0:")<h.index("not routes is Array"))
ot, nt = functions(read("originals/"+test)), functions(read("proposal/"+test))
check("two route regressions added", set(nt)-set(ot)=={"test_legacy_wild_approach_clears_door_and_uses_actual_field_road","test_legacy_field_road_refuses_ambiguous_or_malformed_near_door_metadata"})
for n in ot: check("existing opening regression "+n, ot[n]==nt.get(n))
for n in set(nt)-set(ot): check("synchronous regression "+n, "await " not in nt[n])
config=json.loads(read("root-actual/data/config/terrain_playground.json"))
routes=[r for r in config["paths"]["routes"] if r.get("label")=="Practice Meadow"]
check("actual authored seven points", len(routes)==1 and routes[0]["points"]==[[20,14],[20,-12],[20,-18],[20,-26],[14.6,-31],[21,-37.5],[30,-40]])
player=read("root-actual/scripts/player/player_controller.gd")
check("actual movement directions agree", "basis_value * Vector3(input.x, 0.0, input.y)" in player and "basis.inverse() * direction.normalized()" in nf["_drive_body_toward"] and "_send_axis(JOY_AXIS_LEFT_Y, local.z)" in nf["_drive_body_toward"])
director=read("root-actual/scripts/combat/encounter_director.gd")
check("recall is nonactionable status", "0.0, -2, false" in director and "Put %s away" in director)
r1,r2=read("prior-failure/ci6165-110344653602.log"),read("prior-failure/ci6165-110344653729.log")
check("actual CI checkout retained", all("HEAD is now at d87a50c Merge a795173a3c82058e0bef9558a5ab83487dbe0e1a" in r for r in [r1,r2]))
check("actual three distances retained", "closest 56.25m; final 56.25m" in r1 and "closest 37.88m; final 38.28m" in r1 and "closest 56.25m; final 56.25m" in r2)
check("legacy failures not substituted with fresh proof", "gate B continuous FAIL" in r1 and "gate A opening segment FAIL" in r2)
result={"classification":"AUTHOR SOURCE ONLY; LEGACY NATIVE SMOKES REQUIRED; F17#4 OPEN","passed":all(c["passed"] for c in checks),"checks":checks}
(P/"source-results.json").write_bytes((json.dumps(result,indent=2)+"\n").encode("utf-8"))
print(json.dumps({"passed":result["passed"],"checks":len(checks),"failed":[c["name"] for c in checks if not c["passed"]]}))
raise SystemExit(0 if result["passed"] else 1)
