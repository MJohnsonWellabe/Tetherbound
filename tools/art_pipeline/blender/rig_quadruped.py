"""Build a quadruped armature for a generated creature and skin it.

    blender --background --python tools/art_pipeline/blender/rig_quadruped.py \
            -- <model.glb> --out <rigged.glb> [--report report.json]

Meshy's auto-rigging documents itself as humanoid-only, and Tetherbound's
roster is mostly quadrupeds, so the pipeline needs its own answer. This is it:
a deliberately simple skeleton — TETHERBOUND_3D_ART_PIPELINE.md §13's list for
quadrupeds (pelvis, spine, neck, head, four leg chains, tail) — placed from
the mesh's own geometry and skinned with Blender's automatic weights.

WHERE THE BONES COME FROM. Nothing here is hand-placed. The legs are found by
clustering the vertices of the lowest quarter of the body into four x/y
quadrants; each cluster's centroid column is a leg. The spine runs along the
body's long axis at mid-height; the head sits over the front overhang beyond
the front legs; the tail over the rear overhang. On a compact stylised
quadruped those heuristics land close enough for automatic weights to do the
rest. On anything else — a bird, a biped, a snake — they will land nonsense,
which is why the script measures and refuses rather than guessing (see
--min-leg-separation).

WHAT THIS IS NOT. Not a production rig for hero deformation: no IK, no twist
bones, no jaw or ear bones. §13 says auto-rigging is a starting point and the
weights get inspected at the joints; this replaces the auto-rigger, not the
inspection.
"""

import json
import math
import pathlib
import sys

import bpy
from mathutils import Vector

## Fraction of the body's height, from the ground up, whose vertices count as
## "leg" for the quadrant clustering. A quarter reaches the whole lower leg on
## a compact quadruped without pulling in the belly.
LEG_BAND = 0.25

## Legs must be at least this far apart, as a fraction of body length/width,
## for the quadrant clustering to be trusted. Below it the mesh probably is
## not a standing quadruped, and the script refuses instead of rigging it.
MIN_LEG_SEPARATION = 0.15


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix.lower() in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        raise SystemExit(f"rig_quadruped only takes glTF, got {path.suffix}")


def mesh_objects() -> list[bpy.types.Object]:
    return [o for o in bpy.data.objects if o.type == "MESH"]


def join_and_normalise() -> bpy.types.Object:
    """One mesh, standing on z=0, centred, facing -Y (glTF forward in Blender).

    Joined because automatic weights bind one object to one armature cleanly,
    and a generated creature has no meaningful per-part split anyway.
    """
    meshes = mesh_objects()
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

    weld(body)

    low, high = bounds(body)
    body.location = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
    bpy.ops.object.transform_apply(location=True)
    return body


def weld(body: bpy.types.Object) -> None:
    """Merge duplicate vertices before weighting — the UV-safe half of cleanup.

    Needed here and not only in cleanup_mesh.py because Meshy's RETEXTURE
    stage hands back a re-meshed surface: the cleaned 28k-triangle manifold
    went in, and the textured result came back with 1,614 duplicate vertices
    and 3,144 non-manifold edges. Those are exactly what makes bone-heat
    weighting fail, and the full cleanup cannot run again because a voxel
    remesh would destroy the textures this stage exists to keep.

    Merging by distance is safe on a textured mesh: Blender stores UVs per
    face corner, so welding coincident positions does not smear the unwrap.
    """
    import bmesh
    mesh = bmesh.new()
    mesh.from_mesh(body.data)
    before = len(mesh.verts)
    bmesh.ops.remove_doubles(mesh, verts=mesh.verts, dist=0.0008)
    welded = before - len(mesh.verts)
    mesh.to_mesh(body.data)
    mesh.free()
    if welded:
        print(f"  welded {welded} duplicate vertices before weighting")


def bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return low, high


def find_legs(body: bpy.types.Object) -> dict[str, Vector]:
    """Centroid column of each leg, from the lowest LEG_BAND of the mesh.

    Quadrants split on the mesh's own x/y midlines. The front of a glTF import
    is -Y, so smaller y is the front pair.
    """
    low, high = bounds(body)
    band_top = low.z + (high.z - low.z) * LEG_BAND
    mid_x = (low.x + high.x) / 2
    mid_y = (low.y + high.y) / 2

    quadrants: dict[str, list[Vector]] = {
        "front_l": [], "front_r": [], "rear_l": [], "rear_r": [],
    }
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z > band_top:
            continue
        front = point.y < mid_y
        left = point.x < mid_x
        key = ("front_" if front else "rear_") + ("l" if left else "r")
        quadrants[key].append(point)

    legs = {}
    for key, points in quadrants.items():
        if not points:
            raise SystemExit(f"no vertices in the {key} leg quadrant — "
                             f"this does not look like a standing quadruped")
        centre = sum(points, Vector()) / len(points)
        legs[key] = centre

    # Sanity: the pairs must actually be separated, or the "legs" are one blob.
    #
    # Measured against the span of the LEG BAND, not of the whole model. The
    # whole model's x-span is whatever the widest feature happens to be, and on
    # the legendary stag that is the antler rack — nearly three times the body's
    # width. Dividing a real leg separation by an antler span reported 0.15 and
    # refused to rig a mesh whose legs a reviewer had just called "the cleanest
    # leg separation of any candidate". The yardstick was wrong, not the mesh.
    band = [body.matrix_world @ vertex.co for vertex in body.data.vertices
            if (body.matrix_world @ vertex.co).z <= band_top]
    band_x = max(p.x for p in band) - min(p.x for p in band)
    band_y = max(p.y for p in band) - min(p.y for p in band)
    x_gap = abs(legs["front_l"].x - legs["front_r"].x) / max(band_x, 1e-6)
    y_gap = abs(legs["front_l"].y - legs["rear_l"].y) / max(band_y, 1e-6)
    if x_gap < MIN_LEG_SEPARATION or y_gap < MIN_LEG_SEPARATION:
        raise SystemExit(
            f"leg clusters are not separated (x {x_gap:.2f}, y {y_gap:.2f} of body; "
            f"need {MIN_LEG_SEPARATION}). Refusing to rig — the mesh is probably "
            f"not a standing quadruped, and automatic weights on a wrong skeleton "
            f"deform worse than no skeleton at all.")
    return legs


def build_armature(body: bpy.types.Object, legs: dict[str, Vector]) -> bpy.types.Object:
    low, high = bounds(body)
    size = high - low
    spine_z = low.z + size.z * 0.55          # mid-body, where a quadruped's spine sits
    front_y = (legs["front_l"].y + legs["front_r"].y) / 2
    rear_y = (legs["rear_l"].y + legs["rear_r"].y) / 2

    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.view_layer.objects.active
    rig.name = "Armature"
    edit = rig.data.edit_bones
    for bone in list(edit):
        edit.remove(bone)

    def add(name: str, head: Vector, tail: Vector, parent: str | None = None,
            connect: bool = False):
        bone = edit.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = edit[parent]
            bone.use_connect = connect
        return bone

    # Spine, rear to front, so the pelvis is the root of the chain — §13's list.
    pelvis = Vector((0, rear_y, spine_z))
    chest = Vector((0, front_y, spine_z))
    spine_mid = pelvis.lerp(chest, 0.5)
    add("root", Vector((0, (rear_y + front_y) / 2, 0)),
        Vector((0, (rear_y + front_y) / 2, size.z * 0.15)))
    add("pelvis", pelvis, spine_mid, "root")
    add("spine", spine_mid, chest, "pelvis", connect=True)

    # Head over the front overhang. On a huge-headed stylised creature the
    # overhang IS most of the head, so the neck bone stays short.
    muzzle_y = low.y
    head_base = Vector((0, front_y + (muzzle_y - front_y) * 0.35, spine_z + size.z * 0.12))
    head_tip = Vector((0, muzzle_y + size.y * 0.02, spine_z + size.z * 0.10))
    add("neck", chest, head_base, "spine", connect=True)
    add("head", head_base, head_tip, "neck", connect=True)

    # Tail over the rear overhang, two bones so a stone tip can lag the root.
    tail_root = Vector((0, rear_y + (high.y - rear_y) * 0.4, spine_z))
    tail_tip = Vector((0, high.y - size.y * 0.02, spine_z - size.z * 0.05))
    add("tail_1", pelvis, tail_root, "pelvis")
    add("tail_2", tail_root, tail_tip, "tail_1", connect=True)

    # Legs: hip/shoulder at spine height above the cluster, knee at the
    # cluster's own centroid height, foot to the ground.
    for key, column in legs.items():
        prefix = "front" if key.startswith("front") else "rear"
        side = key[-1]
        attach = "spine" if prefix == "front" else "pelvis"
        top = Vector((column.x, column.y, spine_z))
        mid = Vector((column.x, column.y, column.z))
        toe = Vector((column.x, column.y - size.y * 0.04, low.z))
        upper = f"{prefix}_upper_{side}"
        lower = f"{prefix}_lower_{side}"
        add(upper, top, mid, attach)
        add(lower, mid, toe, upper, connect=True)

    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def skin(body: bpy.types.Object, rig: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def weight_report(body: bpy.types.Object) -> dict:
    """How many vertices each bone owns, and how many nobody owns.

    Unweighted vertices are the failure automatic weights produces silently:
    they stay pinned in bind pose while the body moves, which reads as the
    surface tearing. Counted here so the caller can reject before anyone
    animates.
    """
    totals = {g.name: 0 for g in body.vertex_groups}
    unweighted = 0
    for vert in body.data.vertices:
        weight = 0.0
        for group in vert.groups:
            totals[body.vertex_groups[group.group].name] = \
                totals.get(body.vertex_groups[group.group].name, 0) + 1
            weight += group.weight
        if weight < 1e-4:
            unweighted += 1
    return {"per_bone": totals, "unweighted_vertices": unweighted,
            "total_vertices": len(body.data.vertices)}


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... rig_quadruped.py -- <model.glb> --out <rigged.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("rigged.glb"))).resolve()
    report_path = option(args, "--report")

    load(model)
    body = join_and_normalise()
    legs = find_legs(body)
    rig = build_armature(body, legs)
    skin(body, rig)

    report = weight_report(body)
    report["bones"] = [b.name for b in rig.data.bones]
    report["legs_found_at"] = {k: [round(c, 4) for c in v] for k, v in legs.items()}

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
        print("  UNWEIGHTED VERTICES PRESENT — these will tear in animation. "
              "Inspect before using.")


if __name__ == "__main__":
    main()
