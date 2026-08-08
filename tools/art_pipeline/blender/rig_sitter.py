"""Build an upright-sitter armature — hind legs, held forepaws, big tail.

    blender --background --python tools/art_pipeline/blender/rig_sitter.py \
            -- <model.glb> --out <rigged.glb> [--report report.json]

Ripplet's posture: kangaroo-sit on two hind legs, small forepaws held in
front of the chest, and a tail fan that is nearly torso-sized. Neither
existing rig fits. rig_quadruped needs four ground-contact clusters and the
forepaws never touch the ground; rig_glider finds wings at the LATERAL
extremes, and on this creature the lateral extremes are the ear frills —
it would happily put wing bones in the ears.

So the sitter finds: legs in the lowest band near the midline (glider rule);
ARMS as the forward protrusion at chest height — vertices in the front
quarter of the body between 35% and 65% of height, split left/right; and a
two-bone tail over the rear overhang, measured with feet taken from the
middle band of length because the tail paddle itself touches the ground
behind them (the lesson fix_ripplet_c.py learned).
"""

import json
import math
import pathlib
import sys

import bpy
from mathutils import Vector

LEG_BAND = 0.20
ARM_Z = (0.35, 0.65)       # arms live in this height band
ARM_Y = 0.30               # and in the front fraction of body length


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix.lower() in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        raise SystemExit(f"rig_sitter only takes glTF, got {path.suffix}")


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


def find_parts(body) -> dict[str, Vector]:
    low, high = bounds(body)
    size = high - low
    leg_top = low.z + size.z * LEG_BAND
    mid_x = (low.x + high.x) / 2
    arm_z0, arm_z1 = low.z + size.z * ARM_Z[0], low.z + size.z * ARM_Z[1]
    arm_y = low.y + size.y * ARM_Y

    legs: dict[bool, list[Vector]] = {True: [], False: []}
    arms: dict[bool, list[Vector]] = {True: [], False: []}
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z < leg_top and abs(point.x - mid_x) < size.x * 0.35 \
                and point.y < low.y + size.y * 0.68:
            legs[point.x < mid_x].append(point)
        if arm_z0 < point.z < arm_z1 and point.y < arm_y \
                and abs(point.x - mid_x) < size.x * 0.30:
            arms[point.x < mid_x].append(point)

    parts: dict[str, Vector] = {}
    for left, name in ((True, "leg_l"), (False, "leg_r")):
        if not legs[left]:
            raise SystemExit(f"no vertices in the {name} cluster — not a standing sitter?")
        parts[name] = sum(legs[left], Vector()) / len(legs[left])
    for left, name in ((True, "arm_l"), (False, "arm_r")):
        if not arms[left]:
            raise SystemExit(f"no vertices in the {name} cluster — forepaws not held "
                             f"forward? Widen ARM_Y/ARM_Z and rerun.")
        parts[name] = sum(arms[left], Vector()) / len(arms[left])
    return parts


def build_armature(body, parts) -> bpy.types.Object:
    low, high = bounds(body)
    size = high - low
    hip_y = (parts["leg_l"].y + parts["leg_r"].y) / 2
    hip_z = low.z + size.z * 0.38
    chest = Vector((0, hip_y - size.y * 0.10, low.z + size.z * 0.60))

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

    pelvis = Vector((0, hip_y, hip_z))
    add("root", Vector((0, hip_y, 0)), Vector((0, hip_y, size.z * 0.12)))
    add("pelvis", pelvis, pelvis.lerp(chest, 0.5), "root")
    add("spine", pelvis.lerp(chest, 0.5), chest, "pelvis", connect=True)

    head_base = Vector((0, low.y + size.y * 0.14, low.z + size.z * 0.78))
    head_tip = Vector((0, low.y + size.y * 0.02, low.z + size.z * 0.84))
    add("neck", chest, head_base, "spine", connect=True)
    add("head", head_base, head_tip, "neck", connect=True)

    # The tail fan is the creature's defining feature and gets two bones so a
    # sway can lag the root — the fan should read as trailing water.
    tail_root = Vector((0, hip_y + (high.y - hip_y) * 0.35, hip_z))
    tail_tip = Vector((0, high.y - size.y * 0.02, hip_z + size.z * 0.10))
    add("tail_1", pelvis, tail_root, "pelvis")
    add("tail_2", tail_root, tail_tip, "tail_1", connect=True)

    for side in ("l", "r"):
        leg = parts[f"leg_{side}"]
        top = Vector((leg.x, leg.y, hip_z))
        mid = Vector((leg.x, leg.y, leg.z))
        toe = Vector((leg.x, leg.y - size.y * 0.06, low.z))
        add(f"leg_upper_{side}", top, mid, "pelvis")
        add(f"leg_lower_{side}", mid, toe, f"leg_upper_{side}", connect=True)

        arm = parts[f"arm_{side}"]
        shoulder = Vector((arm.x * 0.4, chest.y, chest.z))
        add(f"arm_{side}", shoulder, Vector((arm.x, arm.y, arm.z)), "spine")

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
        raise SystemExit("usage: ... rig_sitter.py -- <model.glb> --out <rigged.glb>")
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
