"""Source preservation and provisional steering models; native path unproved."""
import hashlib
import json
import math
import re
import struct
from pathlib import Path

PACKET = Path(__file__).resolve().parent
WORKSPACE = PACKET.parents[4]
PROBE = "tools/_probe_scatter_tree_prompt_height.gd"
TEST = "tests/test_vegetation_human_prompt_height.gd"
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
old = (PACKET / "originals" / PROBE).read_bytes()
new = (PACKET / "proposal" / PROBE).read_bytes()
check("working probe exact", (WORKSPACE / PROBE).read_bytes() == new)
check("ROOT failed probe exact baseline", (PACKET / "root-failed" / PROBE).read_bytes() == old)
constants = b"const BANK_TURN_FRAMES := 26\nconst MAX_BANK_TURNS := 3\n"
locals_block = (
    b'\tvar terrain := world.get_node("CanonicalLocalTerrain") as StaticBody3D\n'
    b'\tvar bank_left := 0\n\tvar bank_direction := Vector3.ZERO\n'
    b'\tvar bank_turns: Array[Dictionary] = []\n'
)
old_axes = b"\t\t_axis(JOY_AXIS_LEFT_X, offset.x)\n\t\t_axis(JOY_AXIS_LEFT_Y, offset.z)\n"
new_axes_start = new.index(b"\t\tvar steering := offset\n")
new_axes_end = new.index(b"\t\tawait physics_frame\n", new_axes_start)
new_axes = new[new_axes_start:new_axes_end]
turn_print = b'\tprint("TERRAIN stick turns=", bank_turns, " within_original_180_frames=true")\n'
restored = new.replace(constants, b"", 1).replace(locals_block, b"", 1)
restored = restored.replace(new_axes, old_axes, 1).replace(turn_print, b"", 1)
restored = restored.replace(b'_approach_sample("approach", frame + 1, steering)',
                            b'_approach_sample("approach", frame + 1, offset)', 1)
start = restored.index(b"func _terrain_bank_normal(")
end = restored.index(b"func _approach_sample(", start)
helpers = restored[start:end]
restored = restored[:start] + restored[end:]
check("entire R17 probe recovered by reversing only steering edits", restored == old)
check("same target fixed identity", re.search(rb"^const TARGET.*$", old, re.M).group()
      == re.search(rb"^const TARGET.*$", new, re.M).group())
check("same frame and await counts", old.count(b"await ") == new.count(b"await ")
      and old.count(b"for frame in 180:") == new.count(b"for frame in 180:") == 1)
check("same actual input event writer and axis call counts",
      old.count(b"Input.parse_input_event") == new.count(b"Input.parse_input_event")
      and old.count(b"_axis(") == new.count(b"_axis("))
check("same original start", b"_player.position = TARGET + Vector3(0, 1, 4)" in new)
check("same entire contact detection, release, offer, interact and success tail",
      new[new.index(b"\t\tfor index in _player.get_slide_collision_count():"):new.index(b"func _terrain_bank_normal(")]
      .replace(turn_print, b"") == old[old.index(b"\t\tfor index in _player.get_slide_collision_count():"):old.index(b"func _approach_sample(")])
check("terrain trigger uses exact existing floor node", locals_block in new and b"hit.get_collider() != terrain" in helpers)
check("trigger requires actual grounded and wall state",
      b"if not _player.is_on_floor() or not _player.is_on_wall():" in helpers)
check("trigger reads unchanged native floor angle without modifying it",
      b"normal.y > 0.0 and normal.y < cos(_player.floor_max_angle)" in helpers
      and b"floor_max_angle =" not in new)
check("trigger requires opposing cached wall", b".dot(wanted) < -0.0001" in helpers)
check("no helper native query, state or input write",
      all(token not in helpers for token in [b"Physics", b"intersect_", b"test_move", b"await ",
          b".set(", b".call(", b"global_position =", b".velocity =", b".position =",
          b"Input.", b"height_at", b"_axis(", b"shape.radius =", b"mask =", b"floor_snap"]))
calls = set(re.findall(rb"\.([A-Za-z_][A-Za-z_0-9]*)\(", helpers))
check("helper APIs are cached getters and vector arithmetic",
      calls <= {b"is_on_floor", b"is_on_wall", b"get_slide_collision_count", b"get_slide_collision",
                b"get_collider", b"get_normal", b"dot", b"length_squared", b"normalized"})
check("no success admission depends on steering metadata",
      b"bank_" not in new[new.index(b"\tvar success:"):new.index(b'\tprint("RESULT')])
old_test = (PACKET / "originals" / TEST).read_bytes()
new_test = (PACKET / "proposal" / TEST).read_bytes()
check("working tests exact", (WORKSPACE / TEST).read_bytes() == new_test)
test_restored = new_test.replace(b'const TREE_PROBE := preload("res://tools/_probe_scatter_tree_prompt_height.gd")\n', b"", 1)
test_start = test_restored.index(b"\n\nfunc test_recorded_terrain_wall_")
test_end = test_restored.index(b"\nfunc test_measured_large_stone", test_start)
test_restored = test_restored[:test_start] + test_restored[test_end:]
check("all original producer tests and assertions recovered byte-exact", test_restored == old_test)
check("two synchronous new regressions", new_test.count(b"\nfunc test_") == old_test.count(b"\nfunc test_") + 2
      and b"await " not in new_test)


def f32(v):
    return struct.unpack("<f", struct.pack("<f", v))[0]


def vector(v):
    return tuple(f32(x) for x in v)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def tangent(wanted, normal, previous=(0.0, 0.0, 0.0)):
    wanted, normal, previous = vector(wanted), vector(normal), vector(previous)
    if not all(math.isfinite(x) for x in (*wanted, *normal, *previous)):
        return (0.0, 0.0, 0.0)
    at = (-normal[2], 0.0, normal[0])
    length2 = dot(at, at)
    if length2 < .0001 or wanted[0] ** 2 + wanted[2] ** 2 < .0001:
        return (0.0, 0.0, 0.0)
    at = vector(tuple(x / math.sqrt(length2) for x in at))
    reference = previous if dot(previous, previous) >= .0001 else wanted
    return vector(tuple(-x for x in at)) if dot(at, reference) < 0 else at


first_normal = vector((-.470884, .630212, .617333))
later_normal = vector((-.237581, .669214, .704066))
first = tangent((0, 0, -1), first_normal)
later = tangent((.46911, 0, -.88314), later_normal, first)
for label, at, normal in [("first", first, first_normal), ("later", later, later_normal)]:
    check(label + " recorded normal above unchanged 45 degree limit", normal[1] < math.cos(.7854))
    check(label + " horizontal unit provisional request", at[1] == 0 and abs(dot(at, at) - 1) < .000001)
    check(label + " provisional tangent orthogonal to cached wall", abs(dot(at, normal)) < .000001)
    check(label + " first west/north side preserved", at[0] < 0 and at[2] < 0)
check("later side continuity", dot(first, later) > 0)
check("first retains positive target progress", dot(first, (0, 0, -1)) > 0)
check("later may temporarily trade direct target progress to keep side",
      dot(later, (.46911, 0, -.88314)) < 0)
for label, wanted, normal in [
    ("zero wanted", (0, 0, 0), (-1, 0, 0)),
    ("up normal", (0, 0, -1), (0, 1, 0)),
    ("nonfinite wanted", (math.inf, 0, -1), (-1, 0, 0)),
    ("nonfinite normal", (0, 0, -1), (math.inf, 0, 1)),
]:
    check(label + " refuses tangent", tangent(wanted, normal) == (0, 0, 0))
models, maximum_turns, maximum_tangent_frames = 0, 0, 0
for first_available in range(180):
    for first_touch in range(-1, 180):
        left, turns, frames = 0, 0, 0
        for frame in range(180):
            if left == 0 and turns < 3 and frame >= first_available:
                turns += 1
                left = 26
            if left > 0:
                frames += 1
                left -= 1
            if frame == first_touch:
                break
        maximum_turns = max(maximum_turns, turns)
        maximum_tangent_frames = max(maximum_tangent_frames, frames)
        models += 1
        if turns > 3 or frames > 78:
            raise AssertionError("steering bound")
check("all available-wall/contact-stop models preserve 3x26 within180",
      models == 32580 and maximum_turns == 3 and maximum_tangent_frames == 78)
log = (PACKET / "prior-failure/smoke.log").read_text("utf8", errors="replace")
result = json.loads((PACKET / "prior-failure/result.json").read_text("utf8"))
check("actual native failure remains authoritative", result["exit"] == 1 and result["errors"] == []
      and "activated=false success=false" in log)
check("actual first wall and later wall normals frozen", "(-0.470884, 0.630212, 0.617333)" in log
      and "(-0.237581, 0.669214, 0.704066)" in log)
check("actual failed raw matches result", sha((PACKET / "prior-failure/smoke.log").read_bytes()) == result["raw_log_sha256"])
print(json.dumps({"classification": "AUTHOR PROVISIONAL STICK SOURCE CANDIDATE ONLY; R17 NATIVE FAIL; R19 PARSER/UNIT/NATIVE UNRUN; F17#4 OPEN",
                  "checks": checks, "passed": len(checks), "steering_bound_models": models,
                  "max_turns": maximum_turns, "max_tangent_frames": maximum_tangent_frames,
                  "first_provisional_tangent": first, "later_provisional_tangent": later}, indent=2) + "\n")
