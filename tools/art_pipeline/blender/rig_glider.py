"""Build a biped-glider armature — two legs, wing-forelimbs, tail — and skin it.

    blender --background --python tools/art_pipeline/blender/rig_glider.py \
            -- <model.glb> --out <rigged.glb> [--report report.json]

Galewisp's shape: it STANDS on two legs under the body's centre, its forelimbs
are wings that spread sideways, and its feathered tail trails behind. Run
rig_quadruped.py on that and the quadrant clustering files the wing tips as
front legs — a skeleton that is wrong before the first weight is painted,
which is exactly the case rig_quadruped's separation guard exists to refuse.

So the glider gets its own placement rules, same philosophy (bones from the
mesh's own geometry, automatic weights, refuse rather than guess):

  legs   the lowest LEG_BAND of vertices, clustered left/right of the
         midline. Both clusters must sit in the body's middle third along Y —
         a "leg" at the front or back extreme is probably a drooping wing tip
         or tail feather, and the script says so instead of rigging it.
  wings  the lateral extremes: vertices beyond WING_REACH of the half-width,
         split left/right. Two bones per wing, shoulder->mid-span->tip, so a
         fold and a flap read differently.
  spine  short, over the leg line; head over the front overhang; two tail
         bones over the rear overhang, which on this creature is long.
"""

import json
import math
import pathlib
import sys

import bpy
from mathutils import Vector

LEG_BAND = 0.22

## How far out from the centreline, as a fraction of the body's half-width,
## a vertex must sit to count as wing. Past 0.55 the torso cannot reach it.
WING_REACH = 0.55

## The middle-third test for leg clusters, as fractions of body length.
LEG_ZONE = (0.25, 0.75)


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix.lower() in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        raise SystemExit(f"rig_glider only takes glTF, got {path.suffix}")


def join_normalise_weld() -> bpy.types.Object:
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in the file")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Same UV-safe weld as rig_quadruped, for the same bone-heat reason.
    import bmesh
    mesh = bmesh.new()
    mesh.from_mesh(body.data)
    before = len(mesh.verts)
    bmesh.ops.remove_doubles(mesh, verts=mesh.verts, dist=0.0008)
    if before - len(mesh.verts):
        print(f"  welded {before - len(mesh.verts)} duplicate vertices")
    mesh.to_mesh(body.data)
    mesh.free()

    low, high = bounds(body)
    body.location = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
    bpy.ops.object.transform_apply(location=True)
    return body


def bounds(obj) -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return low, high


def cluster(points: list[Vector]) -> Vector:
    return sum(points, Vector()) / len(points)


def find_parts(body) -> dict[str, Vector]:
    low, high = bounds(body)
    size = high - low
    leg_top = low.z + size.z * LEG_BAND
    half_width = size.x / 2
    mid_x = (low.x + high.x) / 2

    legs: dict[bool, list[Vector]] = {True: [], False: []}
    wings: dict[bool, list[Vector]] = {True: [], False: []}
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z < leg_top and abs(point.x - mid_x) < half_width * 0.45:
            legs[point.x < mid_x].append(point)
        if abs(point.x - mid_x) > half_width * WING_REACH:
            wings[point.x < mid_x].append(point)

    parts: dict[str, Vector] = {}
    for left, name in ((True, "leg_l"), (False, "leg_r")):
        if not legs[left]:
            raise SystemExit(f"no vertices in the {name} cluster — not a standing biped?")
        centre = cluster(legs[left])
        along = (centre.y - low.y) / max(size.y, 1e-6)
        if not (LEG_ZONE[0] < along < LEG_ZONE[1]):
            raise SystemExit(
                f"{name} cluster sits at {along:.2f} of body length, outside the "
                f"middle {LEG_ZONE} — probably a wing tip or tail feather. "
                f"Refusing to rig a skeleton that is wrong by construction.")
        parts[name] = centre
    for left, name in ((True, "wing_l"), (False, "wing_r")):
        if not wings[left]:
            raise SystemExit(f"no vertices beyond {WING_REACH:.0%} half-width for {name} — "
                             f"wings folded flat? Lower WING_REACH and rerun.")
        parts[name] = cluster(wings[left])
        parts[name + "_tip"] = max(wings[left], key=lambda p: abs(p.x - mid_x))
    return parts


def build_armature(body, parts) -> bpy.types.Object:
    low, high = bounds(body)
    size = high - low
    spine_z = low.z + size.z * 0.55
    hip_y = (parts["leg_l"].y + parts["leg_r"].y) / 2

    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.view_layer.objects.active
    rig.name = "Armature"
    edit = rig.data.edit_bones
    for bone in list(edit):
        edit.remove(bone)

    def add(name, head, tail, parent=None, connect=False):
        bone = edit.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = edit[parent]
            bone.use_connect = connect
        return bone

    pelvis = Vector((0, hip_y, spine_z))
    chest = Vector((0, hip_y - size.y * 0.18, spine_z + size.z * 0.05))
    add("root", Vector((0, hip_y, 0)), Vector((0, hip_y, size.z * 0.15)))
    add("pelvis", pelvis, pelvis.lerp(chest, 0.5), "root")
    add("spine", pelvis.lerp(chest, 0.5), chest, "pelvis", connect=True)

    head_base = Vector((0, low.y + size.y * 0.16, spine_z + size.z * 0.22))
    head_tip = Vector((0, low.y + size.y * 0.02, spine_z + size.z * 0.26))
    add("neck", chest, head_base, "spine", connect=True)
    add("head", head_base, head_tip, "neck", connect=True)

    tail_root = Vector((0, hip_y + (high.y - hip_y) * 0.35, spine_z))
    tail_tip = Vector((0, high.y - size.y * 0.02, spine_z - size.z * 0.08))
    add("tail_1", pelvis, tail_root, "pelvis")
    add("tail_2", tail_root, tail_tip, "tail_1", connect=True)

    for side in ("l", "r"):
        leg = parts[f"leg_{side}"]
        top = Vector((leg.x, leg.y, spine_z))
        mid = Vector((leg.x, leg.y, leg.z))
        toe = Vector((leg.x, leg.y - size.y * 0.05, low.z))
        add(f"leg_upper_{side}", top, mid, "pelvis")
        add(f"leg_lower_{side}", mid, toe, f"leg_upper_{side}", connect=True)

        wing = parts[f"wing_{side}"]
        tip = parts[f"wing_{side}_tip"]
        shoulder = Vector((wing.x * 0.25, chest.y, spine_z + size.z * 0.08))
        mid_span = Vector((wing.x, wing.y, wing.z))
        add(f"wing_upper_{side}", shoulder, mid_span, "spine")
        add(f"wing_tip_{side}", mid_span, Vector((tip.x, tip.y, tip.z)),
            f"wing_upper_{side}", connect=True)

    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def skin(body, rig) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def weight_report(body) -> dict:
    totals = {g.name: 0 for g in body.vertex_groups}
    unweighted = 0
    for vert in body.data.vertices:
        weight = 0.0
        for group in vert.groups:
            totals[body.vertex_groups[group.group].name] += 1
            weight += group.weight
        if weight < 1e-4:
            unweighted += 1
    return {"per_bone": totals, "unweighted_vertices": unweighted,
            "total_vertices": len(body.data.vertices)}


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... rig_glider.py -- <model.glb> --out <rigged.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("rigged.glb"))).resolve()
    report_path = option(args, "--report")

    load(model)
    body = join_normalise_weld()
    parts = find_parts(body)
    rig = build_armature(body, parts)
    skin(body, rig)

    report = weight_report(body)
    report["bones"] = [b.name for b in rig.data.bones]

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              use_selection=True, export_yup=True,
                              export_skins=True, export_animations=True)
    if report_path:
        pathlib.Path(report_path).write_text(json.dumps(report, indent=2))

    bad = report["unweighted_vertices"]
    print(f"\nrigged {model.name} -> {out.name}")
    print(f"  {len(report['bones'])} bones, {report['total_vertices']} vertices, "
          f"{bad} unweighted")
    if bad:
        print("  UNWEIGHTED VERTICES PRESENT — inspect before using.")


if __name__ == "__main__":
    main()
