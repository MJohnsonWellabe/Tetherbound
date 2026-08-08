"""Report what is actually wrong with a generated mesh, as JSON.

    blender --background --python tools/art_pipeline/blender/inspect_glb.py \
            -- <model.glb|.fbx> [--out report.json]

TETHERBOUND_3D_ART_PIPELINE.md section 11 lists what to check on a candidate
before committing to it: non-manifold geometry, duplicate and interior
geometry, flipped normals, stretched UVs, excessive material slots, extreme
polygon density, microscopic disconnected components, topology around
deformation zones, symmetry, and scale.

Reading that list off a screenshot is how a candidate with 400 loose vertices
and inverted normals gets picked because its silhouette was nice. So this
measures it instead, and prints numbers a scorecard can hold.

WHAT IT DOES NOT DO. It never says a mesh is good. Every number here is
necessary and none is sufficient — a watertight, correctly-scaled, cleanly
unwrapped model of the wrong animal fails the only gate that matters
(section 10, and the owner's own eyes). Use this to reject, not to accept.
"""

import json
import math
import pathlib
import sys

import bmesh
import bpy
from mathutils import Vector

## A component holding fewer than this share of the model's vertices is debris
## — a stray floating tri from a marching-cubes pass, not a body part. Reported
## separately so it can be deleted without anyone wondering what it was.
DEBRIS_FRACTION = 0.005

## Above this, a UV triangle is stretched enough to smear a texture visibly at
## gameplay distance. Ratio of UV area to 3D area, normalised against the mesh
## median, so it does not care what resolution anyone textures at.
UV_STRETCH_RATIO = 4.0

## Tetherbound budgets. Not hard limits — a hero asset may exceed them and say
## why in its production report — but crossing one silently is how a roster
## arrives at 2 million triangles.
BUDGET_TRIANGLES = 30_000
BUDGET_MATERIALS = 4


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def load(path: pathlib.Path) -> None:
    suffix = path.suffix.lower()
    if suffix in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    else:
        raise SystemExit(f"unsupported model format: {path.suffix}")


def mesh_objects() -> list[bpy.types.Object]:
    return [o for o in bpy.data.objects if o.type == "MESH"]


def world_bounds(objects: list[bpy.types.Object]) -> dict:
    """Size in metres, as the renderer would draw it.

    Object-space bounds are meaningless on a generated asset: they arrive
    scaled by anything, parented to anything, and pal_body._fit() has already
    been burned once by trusting a bind-pose box. So compose the world matrix.
    """
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for obj in objects:
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
    size = high - low
    return {
        "min": [round(v, 4) for v in low],
        "max": [round(v, 4) for v in high],
        "size": [round(v, 4) for v in size],
        "height_m": round(size.z, 4),
        "longest_axis_m": round(max(size), 4),
        "sits_on_origin": abs(low.z) < 0.02,
        "centred_on_origin": abs(low.x + high.x) < 0.05 and abs(low.y + high.y) < 0.05,
    }


def topology(obj: bpy.types.Object) -> dict:
    """Per-mesh geometry health, measured on an evaluated copy."""
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    mesh.faces.ensure_lookup_table()
    mesh.verts.ensure_lookup_table()

    non_manifold = sum(1 for e in mesh.edges if not e.is_manifold)
    boundary = sum(1 for e in mesh.edges if e.is_boundary)
    ngons = sum(1 for f in mesh.faces if len(f.verts) > 4)
    tris = sum(1 for f in mesh.faces if len(f.verts) == 3)
    quads = sum(1 for f in mesh.faces if len(f.verts) == 4)
    loose_verts = sum(1 for v in mesh.verts if not v.link_edges)

    # Duplicate vertices, the classic generator artefact: two coincident points
    # that look welded and split under deformation.
    seen: dict[tuple, int] = {}
    doubles = 0
    for vert in mesh.verts:
        key = (round(vert.co.x, 5), round(vert.co.y, 5), round(vert.co.z, 5))
        if key in seen:
            doubles += 1
        seen[key] = 1

    components = connected_components(mesh)
    total_verts = len(mesh.verts)
    debris = [c for c in components if c < max(total_verts * DEBRIS_FRACTION, 4)]

    result = {
        "name": obj.name,
        "vertices": total_verts,
        "edges": len(mesh.edges),
        "faces": len(mesh.faces),
        "triangles": sum(len(f.verts) - 2 for f in mesh.faces),
        "tris": tris,
        "quads": quads,
        "ngons": ngons,
        "quad_fraction": round(quads / len(mesh.faces), 3) if mesh.faces else 0.0,
        "non_manifold_edges": non_manifold,
        "boundary_edges": boundary,
        "loose_vertices": loose_verts,
        "duplicate_vertices": doubles,
        "components": len(components),
        "debris_components": len(debris),
        "flipped_normals": flipped_normals(mesh),
        "uv_layers": len(obj.data.uv_layers),
        "stretched_uv_faces": stretched_uvs(mesh),
        "materials": [s.material.name for s in obj.material_slots if s.material],
        "shape_keys": len(obj.data.shape_keys.key_blocks) if obj.data.shape_keys else 0,
        "vertex_groups": len(obj.vertex_groups),
    }
    mesh.free()
    return result


def connected_components(mesh: bmesh.types.BMesh) -> list[int]:
    """Vertex count of each island, largest first."""
    unvisited = set(v.index for v in mesh.verts)
    sizes = []
    while unvisited:
        start = unvisited.pop()
        stack, size = [start], 1
        while stack:
            index = stack.pop()
            for edge in mesh.verts[index].link_edges:
                other = edge.other_vert(mesh.verts[index]).index
                if other in unvisited:
                    unvisited.remove(other)
                    stack.append(other)
                    size += 1
        sizes.append(size)
    return sorted(sizes, reverse=True)


def flipped_normals(mesh: bmesh.types.BMesh) -> int:
    """Faces pointing inward, by comparing to the direction away from the centroid.

    Approximate on purpose. An exact answer needs a closed surface, and a
    generated mesh often is not one — which is itself worth knowing, and is
    reported as `non_manifold_edges`. This catches the case that matters: a
    whole region inverted, which renders as a hole under backface culling.
    """
    if not mesh.faces:
        return 0
    centre = sum((v.co for v in mesh.verts), Vector()) / len(mesh.verts)
    flipped = 0
    for face in mesh.faces:
        outward = (face.calc_center_median() - centre)
        if outward.length > 1e-6 and face.normal.dot(outward.normalized()) < -0.5:
            flipped += 1
    return flipped


def stretched_uvs(mesh: bmesh.types.BMesh) -> int:
    """Faces whose texel density is far off the mesh median."""
    layer = mesh.loops.layers.uv.active
    if layer is None:
        return 0
    ratios = []
    for face in mesh.faces:
        area = face.calc_area()
        if area < 1e-9:
            continue
        uvs = [loop[layer].uv for loop in face.loops]
        uv_area = 0.0
        for i in range(1, len(uvs) - 1):
            a, b, c = uvs[0], uvs[i], uvs[i + 1]
            uv_area += abs((b - a).cross(c - a)) / 2.0
        ratios.append(uv_area / area)
    if not ratios:
        return 0
    ratios.sort()
    median = ratios[len(ratios) // 2]
    if median < 1e-9:
        return len(ratios)
    return sum(1 for r in ratios
               if r > median * UV_STRETCH_RATIO or r * UV_STRETCH_RATIO < median)


def armatures() -> list[dict]:
    """Every skeleton, its bones, and whether anything is actually skinned to it."""
    found = []
    for obj in bpy.data.objects:
        if obj.type != "ARMATURE":
            continue
        bones = [b.name for b in obj.data.bones]
        skinned = [m.id_data.name for m in bpy.data.objects
                   if m.type == "MESH"
                   for mod in m.modifiers
                   if mod.type == "ARMATURE" and mod.object == obj]
        found.append({
            "name": obj.name,
            "bones": len(bones),
            "bone_names": bones,
            "roots": [b.name for b in obj.data.bones if b.parent is None],
            "skinned_meshes": skinned,
            "max_depth": max((bone_depth(b) for b in obj.data.bones), default=0),
        })
    return found


def bone_depth(bone) -> int:
    depth = 0
    while bone.parent is not None:
        bone, depth = bone.parent, depth + 1
    return depth


def animations() -> list[dict]:
    return [{
        "name": action.name,
        "frames": [round(action.frame_range[0], 1), round(action.frame_range[1], 1)],
        "channels": len(action.fcurves),
    } for action in bpy.data.actions]


def materials() -> list[dict]:
    found = []
    for material in bpy.data.materials:
        images = [n.image.name for n in material.node_tree.nodes
                  if n.type == "TEX_IMAGE" and n.image] if material.use_nodes else []
        found.append({
            "name": material.name,
            "textures": images,
            "textured": bool(images),
        })
    return found


def verdicts(report: dict) -> list[str]:
    """Plain statements of what is wrong. Empty is not a pass — see the docstring."""
    problems = []
    meshes = report["meshes"]
    total_tris = sum(m["triangles"] for m in meshes)

    if total_tris > BUDGET_TRIANGLES:
        problems.append(
            f"{total_tris:,} triangles, over the {BUDGET_TRIANGLES:,} budget — "
            f"needs a decimate or retopology pass")
    if len(report["materials"]) > BUDGET_MATERIALS:
        problems.append(
            f"{len(report['materials'])} materials, over the {BUDGET_MATERIALS} budget")
    if not any(m["textured"] for m in report["materials"]):
        problems.append(
            "no material carries a texture — this is the exact defect two blind "
            "reviews named on the existing roster (docs/reviews/MA-01, MA-02)")

    for mesh in meshes:
        if mesh["non_manifold_edges"]:
            problems.append(f"{mesh['name']}: {mesh['non_manifold_edges']} non-manifold edges")
        if mesh["duplicate_vertices"]:
            problems.append(f"{mesh['name']}: {mesh['duplicate_vertices']} duplicate vertices "
                            f"— will split under deformation")
        if mesh["loose_vertices"]:
            problems.append(f"{mesh['name']}: {mesh['loose_vertices']} loose vertices")
        if mesh["debris_components"]:
            problems.append(f"{mesh['name']}: {mesh['debris_components']} microscopic "
                            f"disconnected components")
        if mesh["flipped_normals"]:
            problems.append(f"{mesh['name']}: ~{mesh['flipped_normals']} inward-facing faces")
        if not mesh["uv_layers"]:
            problems.append(f"{mesh['name']}: no UV layer — cannot be textured")
        elif mesh["stretched_uv_faces"]:
            problems.append(f"{mesh['name']}: {mesh['stretched_uv_faces']} faces with texel "
                            f"density {UV_STRETCH_RATIO}x off the median")
        if mesh["quad_fraction"] < 0.5 and mesh["triangles"] > 2000:
            problems.append(f"{mesh['name']}: {mesh['quad_fraction']:.0%} quads — generator "
                            f"triangle soup, poor for deformation")

    bounds = report["bounds"]
    if not bounds["sits_on_origin"]:
        problems.append(f"does not stand on the origin (lowest point z={bounds['min'][2]})")
    if not bounds["centred_on_origin"]:
        problems.append("not centred on the origin in x/y")

    # No armature is only a defect if nothing is animated. Not every animated
    # model is skinned: the Plumberry creatures already in the build carry no
    # skeleton at all and animate their rigid parts by transform node, which is
    # exactly why they imported into Godot with no retargeting. Calling that
    # "cannot animate" would condemn a working asset for the reason it works.
    if not report["armatures"] and not report["animations"]:
        problems.append("no armature and no clips — nothing here can move")
    elif not report["armatures"]:
        problems.append(
            f"no armature, but {len(report['animations'])} clips — rigid-part animation. "
            f"Fine for a prop or a hard-surface creature; a deforming quadruped needs a "
            f"skeleton")
    for rig in report["armatures"]:
        if not rig["skinned_meshes"]:
            problems.append(f"armature '{rig['name']}' has no mesh skinned to it")
        if len(rig["roots"]) > 1:
            problems.append(f"armature '{rig['name']}' has {len(rig['roots'])} root bones")

    if not report["animations"] and report["armatures"]:
        problems.append("rigged but no animation clips")

    return problems


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... inspect_glb.py -- <model> [--out report.json]")

    model = pathlib.Path(args[0]).resolve()
    if not model.exists():
        raise SystemExit(f"no such model: {model}")
    out = pathlib.Path(args[args.index("--out") + 1]) if "--out" in args else None

    clear_scene()
    load(model)

    meshes = mesh_objects()
    if not meshes:
        raise SystemExit(f"{model.name} contains no mesh")

    report = {
        "model": str(model),
        "bounds": world_bounds(meshes),
        "meshes": [topology(o) for o in meshes],
        "materials": materials(),
        "armatures": armatures(),
        "animations": animations(),
    }
    report["totals"] = {
        "meshes": len(report["meshes"]),
        "triangles": sum(m["triangles"] for m in report["meshes"]),
        "vertices": sum(m["vertices"] for m in report["meshes"]),
        "materials": len(report["materials"]),
        "animations": len(report["animations"]),
    }
    report["problems"] = verdicts(report)

    text = json.dumps(report, indent=2)
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
        print(f"wrote {out}")

    totals = report["totals"]
    print(f"\n{model.name}")
    print(f"  {totals['triangles']:,} tris, {totals['meshes']} mesh(es), "
          f"{totals['materials']} material(s), {totals['animations']} clip(s)")
    print(f"  {report['bounds']['height_m']}m tall")
    if report["problems"]:
        print(f"  {len(report['problems'])} problem(s):")
        for problem in report["problems"]:
            print(f"    - {problem}")
    else:
        print("  no measured problems (which is not the same as good — see the docstring)")


if __name__ == "__main__":
    main()
