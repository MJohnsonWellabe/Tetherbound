"""Read-only source/receipt audit; no GDScript parsing or native execution."""
import hashlib
import json
import re
from pathlib import Path

PACKET = Path(__file__).resolve().parent
WORKSPACE = PACKET.parents[4]
PATH = "tests/helpers/meadows_earned_team_segment.gd"
checks = []


def check(name, passed):
    checks.append({"name": name, "pass": bool(passed)})
    if not passed:
        raise AssertionError(name)


def sha(data):
    return hashlib.sha256(data).hexdigest()


manifest = json.loads((PACKET / "manifest.json").read_text("utf8"))
for relative, expected in manifest["files"].items():
    data = (PACKET / relative).read_bytes()
    check("frozen " + relative, len(data) == expected["bytes"] and sha(data) == expected["sha256"])
for relative, expected in manifest["unchanged_paths"].items():
    check("unchanged " + relative, sha((WORKSPACE / relative).read_bytes()) == expected["sha256"])
original = (PACKET / "originals" / PATH).read_bytes()
proposal = (PACKET / "proposal" / PATH).read_bytes()
check("working proposal exact", (WORKSPACE / PATH).read_bytes() == proposal)
check("actual frozen failure used original source",
      (PACKET / "root-failed" / PATH).read_bytes() == original)
receipt_line = b'\t\t_receipt("wild_boundary_refused", boundary.get("diagnostic", {}))\n'
old_return = (
    b'\treturn boundary_approach(config, Vector2(_player.global_position.x, _player.global_position.z),\n'
    b'\t\tVector2(target.global_position.x, target.global_position.z), open_ids)\n'
)
new_return = (
    b'\tvar from := Vector2(_player.global_position.x, _player.global_position.z)\n'
    b'\tvar to := Vector2(target.global_position.x, target.global_position.z)\n'
    b'\tvar route := boundary_approach(config, from, to, open_ids)\n'
    b'\tif bool(route.required) and (route.points as Array).is_empty():\n'
    b'\t\troute["diagnostic"] = _boundary_refusal_diagnostic(config, target, from, to, open_ids)\n'
    b'\treturn route\n'
)
check("one refusal-only receipt", proposal.count(receipt_line) == 1 and receipt_line not in original)
check("one observed wrapper", proposal.count(new_return) == 1 and original.count(old_return) == 1)
start = proposal.index(b"## Refusal evidence only.")
end = proposal.index(b"func _open_boundary_gate(", start)
helper = proposal[start:end]
restored = proposal[:start] + proposal[end:]
restored = restored.replace(receipt_line, b"", 1).replace(new_return, old_return, 1)
check("full original recovered by reversing only diagnostic additions", restored == original)
check("no extra await, input or navigator step", all(proposal.count(token) == original.count(token)
      for token in [b"await ", b"_stick(", b"_nav.step(", b"_tap(", b"Input.parse_input_event"]))
check("same selection and admission call counts", all(proposal.count(token) == original.count(token)
      for token in [b"_choose_wild(", b'_director.call("_engageable")', b"_verify_engagement("]))
check("no snapshot admission/LOS/native query",
      all(token not in helper for token in [b"Physics", b"Input.", b"intersect_", b"test_move",
          b".call(", b"_engageable", b"interaction_offer", b"await ", b"_stick(", b"_tap(",
          b"_nav.", b".disabled =", b".position =", b".velocity =", b".set(", b"global_position ="]))
calls = set(re.findall(rb"\.([A-Za-z_][A-Za-z_0-9]*)\(", helper))
check("snapshot methods limited to metadata/getter/local-array reads",
      calls <= {b"append", b"get", b"is_point_in_polygon", b"size", b"is_empty",
                b"get_node_or_null", b"has", b"get_script", b"get_path", b"get_physics_frames", b"duplicate"})
check("receipt precedes original exact failure without route fallback",
      receipt_line + b'\t\treturn _fail("The selected wild needs a physical village crossing but no current open gate route is available")'
      in proposal)
check("diagnostic called only for the same required/empty plan",
      b'if bool(route.required) and (route.points as Array).is_empty():\n\t\troute["diagnostic"]' in proposal)
check("gate authorization copies original sampled IDs",
      b'"authorized_by_original_check": open_ids.has(id)' in helper)
check("helper does not call or override gate authorization", b"_open_boundary_gate(" not in helper)
for name in ["_choose_wild", "_training_eligible", "_open_boundary_gate", "boundary_approach",
             "exterior_path", "exterior_edge_clear", "crosses_boundary", "_verify_engagement"]:
    pattern = rb"(?m)^(?:static )?func " + name.encode() + rb"\("
    def body(data):
        match = re.search(pattern, data)
        next_function = re.search(rb"(?m)^(?:static )?func ", data[match.end():])
        return data[match.start():match.end() + next_function.start()] if next_function else data[match.start():]
    check("exact original function " + name, body(original) == body(proposal))
for marker in ["same_side_chord_crosses_fence", "no_authorized_live_open_leaf",
               "no_valid_single_gate_path", "invalid_outline", "invalid_gate_clearance",
               "target_name", "target_position", "player", "from_xz", "target_xz",
               "from_inside", "target_inside", "direct_chord_crosses", "open_ids",
               "script", "flag_id", "logical_open", "leaf_present", "leaf_disabled"]:
    check("refusal diagnostic includes " + marker, marker.encode() in helper)
receipt = json.loads((PACKET / "prior-failure/receipt.json").read_text("utf8"))
check("actual frozen run head", receipt["head"] == manifest["root_failed_commit"])
check("actual closure unchanged", receipt["source_before"] == receipt["source_after"]
      and receipt["closure_sha256"] == receipt["after_digest"])
check("actual parser pass native fail", receipt["runs"][0]["exit"] == 0 and receipt["runs"][1]["exit"] == 1)
result = receipt["campaign_result"]
check("actual fresh requested prefix still failed", result["reached"] == "village"
      and result["requested_prefix_passed"] is False and result["campaign_complete"] is False)
check("actual fresh no checkpoints/resume", result["checkpoints"] == [] and result["resume"] == {}
      and result["resumed_from"] == "")
log = (PACKET / "prior-failure/native.log").read_text("utf8", errors="replace")
check("original failure lacks selected/gate refusal receipt", "wild_boundary_refused" not in log)
check("actual team failure before wild approach receipt",
      '"beat":"world_seed","world_seed":4' in log and '"beat":"wild_approach"' not in log
      and "no current open gate route is available" in log)
check("native failure raw log matches receipt", sha((PACKET / "prior-failure/native.log").read_bytes())
      == receipt["runs"][1]["raw_log_sha256"])
print(json.dumps({"classification": "AUTHOR REFUSAL DIAGNOSTIC SOURCE CANDIDATE ONLY; ACTUAL FRESH NATIVE FAIL; R18 PARSER/NATIVE UNRUN; F17#4 OPEN",
                  "checks": checks, "passed": len(checks)}, indent=2) + "\n")
