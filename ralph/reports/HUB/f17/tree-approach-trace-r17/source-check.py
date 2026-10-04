"""Engine-free source preservation and trace-bound audit; not a native test."""
import hashlib
import json
import re
from pathlib import Path

PACKET = Path(__file__).resolve().parent
WORKSPACE = PACKET.parents[4]
PROBE = "tools/_probe_scatter_tree_prompt_height.gd"
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
for relative, expected in manifest["unchanged_production"].items():
    check("unchanged " + relative, sha((WORKSPACE / relative).read_bytes()) == expected["sha256"])
prior = WORKSPACE / "ralph/reports/HUB/f17/tree-probe-fixture-r16"
check("R16 original packet seal unchanged", sha((prior / "seal.json").read_bytes()) == manifest["prior_seal_sha256"])
original = (PACKET / "originals" / PROBE).read_bytes()
proposal = (PACKET / "proposal" / PROBE).read_bytes()
check("working proposal matches frozen bytes", (WORKSPACE / PROBE).read_bytes() == proposal)
check("ROOT native failure ran exact R16 proposal",
      (PACKET / "root-failed" / PROBE).read_bytes() == original
      == (prior / "proposal" / PROBE).read_bytes())
new_blocks = [
    b'const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")\n',
    b'\t# At most nine cached observations; no additional physics query or frame.\n'
    b'\tvar approach_trace := [_approach_sample("settled", 0, Vector3.ZERO)]\n'
    b'\tvar saw_wall := false\n',
    b'\t\tif frame == 0 or (frame + 1) % 30 == 0 or (_player.is_on_wall() and not saw_wall):\n'
    b'\t\t\tapproach_trace.append(_approach_sample("approach", frame + 1, offset))\n'
    b'\t\t\tsaw_wall = saw_wall or _player.is_on_wall()\n',
    b'\t# Flush outside the moving sample; these observations cannot admit success.\n'
    b'\tfor sample: Dictionary in approach_trace:\n'
    b'\t\tprint("APPROACH cached sample=", sample)\n',
]
restored = proposal
for index, block in enumerate(new_blocks):
    check("one diagnostic insertion " + str(index), proposal.count(block) == 1 and block not in original)
    restored = restored.replace(block, b"", 1)
helper_start = restored.index(b"func _approach_sample(")
helper_end = restored.index(b"func _build_floor(", helper_start)
helper = restored[helper_start:helper_end]
restored = restored[:helper_start] + restored[helper_end:]
check("entire R16 source recovered by removing diagnostic additions", restored == original)
check("helper absent from original", b"func _approach_sample(" not in original)
check("no additional await or frame", proposal.count(b"await ") == original.count(b"await "))
check("same native input writes", proposal.count(b"Input.parse_input_event") == original.count(b"Input.parse_input_event")
      and proposal.count(b"_axis(") == original.count(b"_axis("))
check("same fixture start pose and terrain sampling", b"_player.position = TARGET + Vector3(0, 1, 4)" in proposal
      and proposal.count(b"field.height_at(") == original.count(b"field.height_at("))
check("same exact record and scale provenance", re.search(rb"^const TARGET.*$", proposal, re.M).group()
      == re.search(rb"^const TARGET.*$", original, re.M).group())
check("same success expression", proposal[proposal.index(b"\tvar success:"):proposal.index(b'\tprint("RESULT')]
      == original[original.index(b"\tvar success:"):original.index(b'\tprint("RESULT')])
check("same touched assignment and original break", proposal.count(b"touched = true") == 1
      and b"\t\tif touched:\n\t\t\tbreak" in proposal)
check("snapshot cannot wait or write input/pose/query",
      all(token not in helper for token in [b"await ", b"_axis(", b"parse_input_event", b"Physics",
          b"intersect_", b"test_move", b"call_deferred", b"set(", b".position =", b".velocity =",
          b"global_position =", b"interaction_offer", b"interaction_activate"]))
calls = set(re.findall(rb"\.([A-Za-z_][A-Za-z_0-9]*)\(", helper))
allowed_calls = {b"append", b"get_slide_collision_count", b"get_slide_collision", b"get_collider",
                 b"get_position", b"get_normal", b"get_depth", b"current", b"get_physics_frames",
                 b"get_vector", b"get", b"is_on_floor", b"is_on_wall"}
check("snapshot method calls limited to cached/read APIs and local append", calls <= allowed_calls)
check("flush happens after released-stick physical result, before unchanged process await",
      proposal.index(b'print("PHYSICAL tree-contact') < proposal.index(b'print("APPROACH cached sample')
      < proposal.index(b"\tawait process_frame", proposal.index(b'print("PHYSICAL tree-contact')))
for marker in ["requested_stick", "resolved_stick", "last_controller_wanted", "input_owner",
               "velocity", "position", "grounded", "wall", "floor_stop_on_slope",
               "floor_constant_speed", "deflect_left", "deflect", "locomotion_enabled",
               "carried", "contacts", "unsticks", "physics_frame", "approach_frame"]:
    check("snapshot includes " + marker, ('"' + marker + '"').encode() in helper)
maximum, modeled = 0, 0
for first_wall in range(-1, 180):
    for first_touch in range(-1, 180):
        samples, saw_wall = [0], False
        for frame in range(180):
            wall = frame == first_wall
            if frame == 0 or (frame + 1) % 30 == 0 or (wall and not saw_wall):
                samples.append(frame + 1)
                saw_wall = saw_wall or wall
            if frame == first_touch:
                break
        maximum = max(maximum, len(samples))
        modeled += 1
        if len(samples) > 9:
            raise AssertionError("trace bound")
check("all first-wall/first-touch combinations fit nine observations", maximum == 9 and modeled == 32761)
log = (PACKET / "prior-failure/smoke.log").read_text("utf8", errors="replace")
check("actual bound record loaded", "layer=trees order=886" in log)
check("actual native failure has no trunk contact", "touched_actual_trunk=false" in log)
check("actual native failure remains authoritative", "activated=false success=false" in log)
check("native failure has only sampled terrain contact", '"body": "CanonicalLocalTerrain"' in log)
print(json.dumps({"classification": "AUTHOR SOURCE DIAGNOSTIC CANDIDATE ONLY; R16 NATIVE FAIL; R17 PARSER/NATIVE UNRUN; F17#4 OPEN",
                  "checks": checks, "passed": len(checks), "trace_bound_models": modeled,
                  "maximum_cached_observations": maximum}, indent=2) + "\n")
