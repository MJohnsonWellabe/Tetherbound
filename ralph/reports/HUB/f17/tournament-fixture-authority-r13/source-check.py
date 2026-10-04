"""R13 source preservation audit, no parser/native/unit acceptance."""
from pathlib import Path
import hashlib, json, re

P = Path(__file__).resolve().parent
HUB = P.parents[4]
H = lambda b: hashlib.sha256(b).hexdigest()
checks = []
def check(name, ok): checks.append({"name": name, "passed": bool(ok)})
def read(n): return (P / n).read_text(encoding="utf-8").replace("\r\n", "\n")
m = json.loads(read("manifest.json"))
for n, pin in m["files"].items():
    b = (P / n).read_bytes()
    check("frozen " + n, len(b) == pin["bytes"] and H(b) == pin["sha256"])
for n, pin in m["protected_hub_sha256"].items():
    check("unchanged live production/helper " + n, H((HUB / n).read_bytes()) == pin)
path = m["changed_path"]
old, new = read("originals/" + path), read("proposal/" + path)
check("live proposal byte exact", (HUB / path).read_bytes() == (P / "proposal" / path).read_bytes())
addition = '''class GuestSession extends Node:
\tfunc _authority_character(peer_id: int) -> String:
\t\treturn "guest" if peer_id == 2 else ""


'''
insertions = [addition, '\tvar session := GuestSession.new()\n\tdirector._session = session\n', '\tassert_true(director._deployed_by.has(2), "session authority must admit the guest before roster assertions")\n', '\tsession.free()\n']
trimmed = new
for i, insertion in enumerate(insertions):
    check("one bounded fixture insertion " + str(i), trimmed.count(insertion) == 1)
    trimmed = trimmed.replace(insertion, "", 1)
check("entire original test source otherwise exact", trimmed == old)
check("same complete test method list", re.findall(r"^func test_\w+", old, re.M) == re.findall(r"^func test_\w+", new, re.M))
check("all original assertions retained in sequence", re.findall(r"\tassert_.*", old) == [s for s in re.findall(r"\tassert_.*", new) if 'session authority must admit' not in s])
check("one added admission assertion", new.count("assert_") == old.count("assert_") + 1)
check("no asynchronous or skipped fixture", "await " not in new and "skip(" not in new)
director = read("root-actual/scripts/combat/encounter_director.gd")
check("actual production guard requires canonical owner before row insertion", director.index('var character_id := _strike_authority_character(peer_id)', director.index('func _host_set_deployed(')) < director.index('_deployed_by[peer_id] = row.duplicate(true)', director.index('func _host_set_deployed(')))
check("canonical Session API observed", 'if _session != null and _session.has_method("_authority_character"):' in director and '_session.call("_authority_character", peer_id)' in director)
check("guest never falls back to claimed packet character", 'return _local_character_id() if peer_id == _local_peer_id() else ""' in director)
reference = read("root-actual/tests/test_director_projectile_deployment_binding.gd")
check("same established fixture boundary", 'func _authority_character(peer_id: int) -> String:' in reference and 'director.set("_session", session)' in reference)
raw = read("prior-failure/ci6165-110344653258.log")
check("actual CI missing deployment row error", "SCRIPT ERROR: Out of bounds get index '2' (on base: 'Dictionary')" in raw and "test_tournament_network_selection.gd:78" in raw)
check("CI misleading ok does not count as acceptance", 'ok    test_tournament_network_selection.gd :: test_frozen_roster_rejects_an_outside_deployment_without_replacing_current' in raw)
result = {"classification": "AUTHOR SOURCE ONLY; ROOT NAMED ENGINE TEST REQUIRED; F17#4 OPEN", "passed": all(c["passed"] for c in checks), "checks": checks}
(P / "source-results.json").write_bytes((json.dumps(result, indent=2) + "\n").encode("utf-8"))
print(json.dumps({"passed": result["passed"], "checks": len(checks), "failed": [c["name"] for c in checks if not c["passed"]]}))
raise SystemExit(0 if result["passed"] else 1)
