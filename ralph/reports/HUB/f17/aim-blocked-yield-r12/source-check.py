"""R12 author source audit only; never a Godot parse or native acceptance."""
from pathlib import Path
import hashlib, json, re

P = Path(__file__).resolve().parent
HUB = P.parents[4]
sha = lambda b: hashlib.sha256(b).hexdigest()
checks = []

def check(name, passed):
    checks.append({"name": name, "passed": bool(passed)})

def read(path):
    return (P / path).read_text(encoding="utf-8").replace("\r\n", "\n")

def functions(source):
    lines, result = source.splitlines(), {}
    for i, line in enumerate(lines):
        match = re.match(r"(?:static )?func (\w+)\(", line)
        if match:
            end = i + 1
            while end < len(lines) and (not lines[end] or lines[end].startswith("\t")):
                end += 1
            result[match[1]] = "\n".join(lines[i:end]).rstrip()
    return result

m = json.loads(read("manifest.json"))
r = json.loads(read("prior-failure/receipt.json"))
for name, pin in m["files"].items():
    data = (P / name).read_bytes()
    check("frozen " + name, len(data) == pin["bytes"] and sha(data) == pin["sha256"])
for name, pin in m["protected_hub_sha256"].items():
    check("unchanged protected HUB " + name, sha((HUB / name).read_bytes()) == pin)
for name, pin in m["root_input_executed_sha256"].items():
    check("production input matches actual executed closure " + name, r["source_before"].get(name) == pin)
for name in m["changed_paths"]:
    check("executed original " + name, sha((P / "originals" / name).read_bytes()) == r["source_before"].get(name))
    check("live proposal " + name, (P / "proposal" / name).read_bytes() == (HUB / name).read_bytes())
check("failure source closure unchanged during run", r["source_before"] == r["source_after"])
check("actual failure head", r["head"] == m["root_failure_head"])
check("actual closure digest", r["closure_sha256"] == m["executed_closure_sha256"])
c = r["campaign_result"]
check("no actual earned acceptance", not c["campaign_complete"] and not c["requested_prefix_passed"] and c["reached"] == "title")
check("fresh original failure without checkpoints/resume/dry run", not c["checkpoints"] and not c["resume"] and not c["resumed_from"] and not c["dry_run"])
check("exact terminal failure", c["failures"] == ["live catch right-stick aim did not converge"])

drive, fresh, test = m["changed_paths"]
old_drive, new_drive = read("originals/" + drive), read("proposal/" + drive)
od, nd = functions(old_drive), functions(new_drive)
check("only existing camera loop changed", [k for k in od if od[k] != nd.get(k)] == ["_aim_camera_at"])
check("only base movement hook added", set(nd) - set(od) == {"_aim_readiness_requires_movement"})
for name in od:
    if name != "_aim_camera_at":
        check("unchanged inherited function " + name, od[name] == nd[name])
added = "\t\t\tif _aim_readiness_requires_movement():\n\t\t\t\treturn false\n"
check("camera loop adds only two failure yields", nd["_aim_camera_at"].count(added) == 2 and nd["_aim_camera_at"].replace(added, "") == od["_aim_camera_at"])
check("base hook preserves historical callers", nd["_aim_readiness_requires_movement"].endswith("\n\treturn false"))
check("each movement yield follows settled strict false", nd["_aim_camera_at"].count("if await _released_aim_is_ready():\n\t\t\t\treturn true\n" + added) == 2)
check("timers/retries/ranges/constants exact", re.findall(r"^const .*", old_drive, re.M) == re.findall(r"^const .*", new_drive, re.M))
check("scene phase settling remains exact", od["_released_aim_is_ready"] == nd["_released_aim_is_ready"] and "create_timer(0.0, true, false)" in nd["_released_aim_is_ready"] and "create_timer(0.0, true, true)" in nd["_released_aim_is_ready"])

old_fresh, new_fresh = read("originals/" + fresh), read("proposal/" + fresh)
of, nf = functions(old_fresh), functions(new_fresh)
check("only existing transient readiness changed", [k for k in of if of[k] != nf.get(k)] == ["_aim_readiness_ready"])
check("one fresh movement hook added", set(nf) - set(of) == {"_aim_readiness_requires_movement"})
for name in of:
    if name != "_aim_readiness_ready":
        check("unchanged fresh earned function " + name, of[name] == nf[name])
flag = "\t_aim_requires_movement = false\n"
decision = '''\tif not preview.is_empty():
\t\t_aim_requires_movement = (
\t\t\t(bool(current.get("eligible", false)) and bool(preview.get("trajectory_blocked", false)))
\t\t\tor (str(current.get("reason", "")) == "line_of_sight_blocked"
\t\t\tand bool(current.get("inside_body", false))))
'''
check("strict readiness exactly preserved around cached decision", nf["_aim_readiness_ready"].replace(flag, "").replace(decision, "") == of["_aim_readiness_ready"])
check("movement flag reset before all refusal branches", nf["_aim_readiness_ready"].splitlines()[1].strip() == flag.strip())
check("fresh hook reads cached sample only", nf["_aim_readiness_requires_movement"].endswith("\n\treturn _aim_requires_movement"))
check("same number of native diagnostic reads in readiness", nf["_aim_readiness_ready"].count('call("launch_assist_diagnostics")') == of["_aim_readiness_ready"].count('call("launch_assist_diagnostics")') == 1)
check("aim-active and entry guard precede decision", nf["_aim_readiness_ready"].index('is_aiming') < nf["_aim_readiness_ready"].index('if not preview.is_empty()') and nf["_aim_readiness_ready"].index('throw.get("_guard")') < nf["_aim_readiness_ready"].index('if not preview.is_empty()'))
check("single new transient flag, no constant changes", re.findall(r"^var .*", new_fresh, re.M) == re.findall(r"^var .*", old_fresh, re.M) + ["var _aim_requires_movement := false"] and re.findall(r"^const .*", old_fresh, re.M) == re.findall(r"^const .*", new_fresh, re.M))

ot, nt = functions(read("originals/" + test)), functions(read("proposal/" + test))
check("one synchronous meaningful verdict regression added", set(nt) - set(ot) == {"test_settled_obstruction_requests_movement_without_admitting_a_throw"} and "await " not in nt["test_settled_obstruction_requests_movement_without_admitting_a_throw"])
for name in ot:
    check("existing target regression exact " + name, ot[name] == nt.get(name))
check("regression retains final launch refusal", "assert_false(opening._final_throw_verdict_ready()" in nt["test_settled_obstruction_requests_movement_without_admitting_a_throw"])

raw = read("prior-failure/native.log")
samples = [line for line in raw.splitlines() if line.startswith("AIM READINESS")]
blocked = [line for line in samples if '"eligible": true' in line.split("current=", 1)[1].split(" preview=", 1)[0] and '"trajectory_blocked": true' in line.split(" preview=", 1)[1]]
check("105 actual readiness samples, 87 eligible but trajectory blocked", len(samples) == 105 and len(blocked) == 87)
check("actual arc blocker recorded", all('"trajectory_blocker": "Wild_mudsnout_1070_2"' in line for line in blocked))
check("terminal LOS blocker and absent preview are evidence, not readiness", '"first_hit": &"Wild_mudsnout_1070_1"' in samples[-1] and "preview={  }" in samples[-1])
check("one observed circling recovery", raw.count("aim: line of sight blocked") == 1)
check("no save payload or stone proof in failed prefix", "SAVE PAYLOAD" not in raw and "gather stone" not in raw.lower())
result = {"classification": "AUTHOR SOURCE AUDIT ONLY; NO NATIVE/PARSER ACCEPTANCE; F17#4 OPEN", "passed": all(c["passed"] for c in checks), "checks": checks}
(P / "source-results.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"passed": result["passed"], "checks": len(checks), "failed": [c["name"] for c in checks if not c["passed"]]}))
raise SystemExit(0 if result["passed"] else 1)
