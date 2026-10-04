"""Read-only, engine-free record/source audit. This does not execute GDScript."""
import hashlib
import json
import math
import re
import struct
from pathlib import Path

PACKET = Path(__file__).resolve().parent
WORKSPACE = PACKET.parents[4]
PROBE = "tools/_probe_scatter_tree_prompt_height.gd"
OLD_TARGET = (45.44735, -0.188587, -62.50097)
NEW_TARGET = (98.15209197998047, 5.79111909866333, -35.932098388671875)
OLD_LINE = b"const TARGET := Vector3(45.44735, -0.188587, -62.50097)\n"
NEW_LINES = (
    b"# bf0f38b203 removed trees#320. Pin kept trees#886, the closest non-smaller\n"
    b"# CommonTree_2 in this region by scale (1.598110499382019 -> 1.6529272198677063).\n"
    b"const TARGET := Vector3(98.15209197998047, 5.79111909866333, -35.932098388671875)\n"
)
checks = []


def check(name, passed):
    checks.append({"name": name, "pass": bool(passed)})
    if not passed:
        raise AssertionError(name)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def parse_region(data):
    """Exact scatter_bake.gd v1 layout; includes kept AND drained records."""
    at = 0

    def take(fmt):
        nonlocal at
        count = struct.calcsize("<" + fmt)
        if at + count > len(data):
            raise ValueError("truncated record")
        values = struct.unpack_from("<" + fmt, data, at)
        at += count
        return values[0] if len(values) == 1 else values

    def string():
        nonlocal at
        count = take("I")
        if at + count > len(data):
            raise ValueError("truncated string")
        value = data[at:at + count].decode("utf8")
        at += count
        return value

    if take("I") != 0x53434154 or take("I") != 1:
        raise ValueError("unexpected header")
    models = [string() for _ in range(take("I"))]
    rows, layers = [], []
    for _ in range(take("I")):
        layer = string()
        kept, drained = take("I"), take("I")
        layers.append({"layer": layer, "kept": kept, "drained": drained})
        for index in range(kept + drained):
            order, model_index = take("I"), take("H")
            if model_index >= len(models):
                raise ValueError("invalid model index")
            position, yaw, scale = take("fff"), take("d"), take("d")
            has_normal = take("B")
            if has_normal not in (0, 1):
                raise ValueError("invalid normal flag")
            normal = take("fff") if has_normal else None
            if not all(math.isfinite(v) for v in (*position, yaw, scale, *(normal or ()))):
                raise ValueError("nonfinite placement")
            rows.append({"layer": layer, "state": "kept" if index < kept else "drained",
                         "order": order, "model": models[model_index],
                         "position": list(position), "yaw": yaw, "scale": scale,
                         "normal": list(normal) if normal is not None else None})
    if at != len(data):
        raise ValueError("trailing region bytes")
    return rows, layers


def matches(rows, target, kept_only=True):
    # The actual unchanged probe reads only production _read_region's kept output.
    return [row for row in rows
            if (not kept_only or row["state"] == "kept")
            and math.dist(row["position"], target) < 0.01]


manifest = json.loads((PACKET / "manifest.json").read_text("utf8"))
for relative, expected in manifest["files"].items():
    data = (PACKET / relative).read_bytes()
    check("sealed bytes " + relative, len(data) == expected["bytes"]
          and digest(data) == expected["sha256"])
for relative, expected in manifest["unchanged_production"].items():
    check("unchanged production " + relative,
          digest((WORKSPACE / relative).read_bytes()) == expected["sha256"])

old_bytes = (PACKET / "originals" / PROBE).read_bytes()
new_bytes = (PACKET / "proposal" / PROBE).read_bytes()
check("working proposal exact", (WORKSPACE / PROBE).read_bytes() == new_bytes)
check("old target occurs once", old_bytes.count(OLD_LINE) == 1)
check("only target and provenance comments changed",
      old_bytes.replace(OLD_LINE, NEW_LINES) == new_bytes)
check("entire original recovered by reversing target refresh",
      new_bytes.replace(NEW_LINES, OLD_LINE) == old_bytes)
check("ROOT failure used exact original probe",
      (PACKET / "root-failed" / PROBE).read_bytes() == old_bytes)
for label in ["probe-introduction", "pre-promotion", "current"]:
    binary = (PACKET / "records" / (label + ".bin")).read_bytes()
    rows, layers = parse_region(binary)
    check(label + " all records counted",
          len(rows) == sum(layer["kept"] + layer["drained"] for layer in layers))
    check(label + " expected count", len(rows) == manifest["record_counts"][label])
    if label == "current":
        current_rows = rows
        check("current old coordinate absent including drained",
              matches(rows, OLD_TARGET, False) == [])
    else:
        hits = matches(rows, OLD_TARGET)
        check(label + " old fixture unique kept record", len(hits) == 1)
        check(label + " original full identity", hits[0] == manifest["original_record"])
check("ROOT failed bake equals current immutable records",
      (PACKET / "root-failed/region_0_-1.bin").read_bytes()
      == (PACKET / "records/current.bin").read_bytes())
selected = matches(current_rows, NEW_TARGET)
check("replacement unique at unchanged .01m tolerance", len(selected) == 1)
selected = selected[0]
original = manifest["original_record"]
check("replacement full frozen identity", selected == manifest["replacement_record"])
check("replacement is kept trees#886",
      selected["state"] == "kept" and selected["layer"] == "trees" and selected["order"] == 886)
check("same original model and layer",
      selected["model"] == original["model"] and selected["layer"] == original["layer"])
check("same world-up collider orientation", selected["normal"] is original["normal"] is None)
check("scale never reduced", selected["scale"] >= original["scale"])
eligible = [row for row in current_rows if row["state"] == "kept"
            and row["layer"] == original["layer"] and row["model"] == original["model"]
            and row["normal"] == original["normal"] and row["scale"] >= original["scale"]]
ranked = sorted(eligible, key=lambda row: (row["scale"] - original["scale"], row["order"]))
check("closest non-smaller same-model scale in this region", ranked[0] == selected)
check("scale growth below four percent", selected["scale"] / original["scale"] < 1.04)
config = json.loads((PACKET / "production/data/config/vegetation.json").read_text("utf8"))
layer = config["layers"]["trees"]
check("same collidable tree layer", layer["collides"] is True and selected["model"] in layer["models"])
check("current source collision radius pinned", layer["collision_radius"] == 0.435)
original_config = json.loads((PACKET / "records/probe-introduction-vegetation.json").read_text("utf8"))
check("original and current layer cylinder radius agree",
      original_config["layers"]["trees"]["collision_radius"] == layer["collision_radius"])
def function(data, name):
    text = data.decode("utf8")
    start = text.index("func " + name + "(")
    end = re.search(r"(?m)^(?:static )?func ", text[start + 1:])
    return text[start:start + 1 + end.start()] if end else text[start:]
old_cylinder = function((PACKET / "records/probe-introduction-vegetation.gd").read_bytes(), "_make_collision_shape")
new_cylinder = function((PACKET / "production/scripts/world/vegetation.gd").read_bytes(), "_make_collision_shape")
check("current optional canopy defaults empty", "canopy: Dictionary = {}" in new_cylinder.splitlines()[0])
canopy_start = new_cylinder.index("\tif not canopy.is_empty():")
canopy_end = new_cylinder.index("\treturn node", canopy_start)
new_cylinder_without_unused_canopy = new_cylinder[:canopy_start] + new_cylinder[canopy_end:]
check("original trunk body equals current trunk body with unused canopy omitted",
      old_cylinder.split("\n", 1)[1] == new_cylinder_without_unused_canopy.split("\n", 1)[1])
check("production cylinder radius and height cannot shrink",
      layer["collision_radius"] * selected["scale"] >= layer["collision_radius"] * original["scale"]
      and 4.0 * selected["scale"] >= 4.0 * original["scale"])
source = new_bytes.decode("utf8")
for name, pattern in {
    "missing exact-record refusal": 'print("FAIL exact shipped placement absent")\n\t\tquit(1)\n\t\treturn',
    "real joypad input": "var event := InputEventJoypadMotion.new()",
    "actual trunk contact": "_player.get_slide_collision(index).get_collider() == trunk",
    "actual production cylinder": "veg._make_collision_shape(placement, float(config.collision_radius))",
    "30 settle frames": "for frame in 30: await physics_frame",
    "180 approach frames": "for frame in 180:",
    "actual offer": "_prompt.interaction_offer(_player.global_position)",
    "exact prompt activation": "_activated = provider == _prompt",
    "arbiter winner": "_arbiter.winning_provider() == _prompt",
    "grounded success": "and _player.is_on_floor()",
    "touched success": "and touched and int(_player.get(\"_unstick_count\")) == 0",
    "unchanged interact frame limits": "for frame in 3: await physics_frame",
    "release frame limits": "for frame in 5: await physics_frame",
    "no campaign receipt": '" no campaign receipt claimed"',
    "metadata-only branch preserved": 'OS.get_cmdline_user_args().has("--metadata-only")',
}.items():
    check(name, pattern in source)
log = (PACKET / "prior-failure/smoke.log").read_text("utf8", errors="replace")
check("actual failure before fixture", "FAIL exact shipped placement absent" in log
      and all(marker not in log for marker in ["EXACT BAKED placement=", "PHYSICAL tree-contact", "RESULT exact physical"]))
for label, data in {
    "truncated current record": (PACKET / "records/current.bin").read_bytes()[:-1],
    "trailing current data": (PACKET / "records/current.bin").read_bytes() + b"\x00",
    "bad magic": b"\x00\x00\x00\x00" + (PACKET / "records/current.bin").read_bytes()[4:],
}.items():
    try:
        parse_region(data)
    except (ValueError, struct.error):
        check(label + " rejected", True)
    else:
        check(label + " rejected", False)
result = {"classification": "AUTHOR SOURCE AND IMMUTABLE RECORD AUDIT ONLY; NATIVE/PARSER UNRUN; F17#4 OPEN",
          "checks": checks, "passed": len(checks),
          "same_model_non_smaller_candidates_in_current_region": len(eligible),
          "original_record": original, "replacement_record": selected}
print(json.dumps(result, indent=2) + "\n")
