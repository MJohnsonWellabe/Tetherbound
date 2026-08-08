"""The §11 cleanup pass: make a generated mesh manifold, sane, and in budget.

    blender --background --python tools/art_pipeline/blender/cleanup_mesh.py \
            -- <model.glb> --out <clean.glb> [--target-tris 28000]

Generated meshes arrive as triangle soup: measured on this project's first
live candidates, ~55k triangles with thousands of duplicate vertices,
non-manifold edges, and debris islands (see inspect_glb.py's reports). Two
downstream steps choke on that:

  - Blender's bone-heat automatic weighting fails outright — "failed to find
    solution for one or more bones" — and quietly leaves every vertex
    unweighted, which reads as the whole surface tearing on the first frame
    of animation. Reproduced on candidate b before this script existed.
  - The 30k triangle budget (inspect_glb.BUDGET_TRIANGLES) is blown ~2x.

Order of operations, and why:

  1. Merge by distance. Kills the duplicate verts that break bone heat.
  2. Delete debris islands (< 0.5% of vertices). A floating speck the
     auto-weighter cannot reach is another "no solution" source.
  3. Voxel remesh at a resolution derived from the body size. Produces ONE
     closed manifold surface — the strongest possible guarantee for bone
     heat — at the cost of destroying UVs, which these preview meshes do not
     have yet. Texturing happens AFTER cleanup (Meshy retexture re-unwraps),
     so nothing of value is lost. Do NOT run this on an already-textured
     model.
  4. Smooth-corrective pass: voxel remesh leaves a faint lego-surface; one
     gentle smooth restores the sculpt read without melting edges.
  5. Decimate to the triangle target, shade smooth, normalise transforms.

The result is deliberately still a triangle mesh, not retopologised quads.
For a hero asset §11 wants proper edge flow at the joints; that is a later,
manual pass. This gets the mesh through texturing, rigging and the visual
gate without lying about being production topology.
"""

import math
import pathlib
import sys

import bmesh
import bpy
from mathutils import Vector

MERGE_DISTANCE = 0.0008          # metres at normalised scale; welds seams, not features
DEBRIS_FRACTION = 0.005          # match inspect_glb.py
VOXEL_DETAIL_DIVISOR = 220.0     # voxel size = longest axis / this; ~220 keeps toes
SMOOTH_ITERATIONS = 2
DEFAULT_TARGET_TRIS = 28_000     # just under inspect_glb.BUDGET_TRIANGLES


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix.lower() in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        raise SystemExit(f"cleanup_mesh only takes glTF, got {path.suffix}")


def join_all() -> bpy.types.Object:
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
    return body


def longest_axis(obj: bpy.types.Object) -> float:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return max(high - low)


def merge_and_deburr(body: bpy.types.Object) -> tuple[int, int]:
    mesh = bmesh.new()
    mesh.from_mesh(body.data)

    before = len(mesh.verts)
    bmesh.ops.remove_doubles(mesh, verts=mesh.verts, dist=MERGE_DISTANCE)
    merged = before - len(mesh.verts)

    # Debris islands, found by flood fill, removed outright.
    mesh.verts.ensure_lookup_table()
    unvisited = set(v.index for v in mesh.verts)
    islands = []
    while unvisited:
        start = unvisited.pop()
        stack, members = [start], [start]
        while stack:
            index = stack.pop()
            for edge in mesh.verts[index].link_edges:
                other = edge.other_vert(mesh.verts[index]).index
                if other in unvisited:
                    unvisited.remove(other)
                    stack.append(other)
                    members.append(other)
        islands.append(members)

    total = len(mesh.verts)
    keep_threshold = max(total * DEBRIS_FRACTION, 4)
    doomed = [i for island in islands if len(island) < keep_threshold for i in island]
    if doomed:
        mesh.verts.ensure_lookup_table()
        bmesh.ops.delete(mesh, geom=[mesh.verts[i] for i in doomed], context="VERTS")

    mesh.to_mesh(body.data)
    mesh.free()
    return merged, len(doomed)


def voxel_remesh(body: bpy.types.Object) -> None:
    body.data.remesh_voxel_size = longest_axis(body) / VOXEL_DETAIL_DIVISOR
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.voxel_remesh()

    smooth = body.modifiers.new("smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = SMOOTH_ITERATIONS
    bpy.ops.object.modifier_apply(modifier=smooth.name)


def decimate_to(body: bpy.types.Object, target_tris: int) -> None:
    current = sum(len(p.vertices) - 2 for p in body.data.polygons)
    if current <= target_tris:
        return
    modifier = body.modifiers.new("decimate", "DECIMATE")
    modifier.ratio = target_tris / current
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... cleanup_mesh.py -- <model.glb> --out <clean.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("clean.glb"))).resolve()
    target = int(option(args, "--target-tris", DEFAULT_TARGET_TRIS))

    load(model)
    body = join_all()

    # The remesh destroys UVs, so a TEXTURED model in is a textured model
    # ruined. But the guard is on textures, not on UV layers: Meshy's preview
    # meshes ship a UV unwrap with no images bound to it, and that unwrap is
    # discarded at the texture stage anyway (retexture re-unwraps). Refusing
    # those blocked the exact input this script exists for.
    textured = any(
        node.type == "TEX_IMAGE" and node.image
        for material in bpy.data.materials if material.use_nodes
        for node in material.node_tree.nodes)
    if textured:
        raise SystemExit(f"{model.name} carries image textures — refusing to "
                         f"voxel-remesh a textured model. Run cleanup before texturing.")

    before_tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    merged, debris = merge_and_deburr(body)
    voxel_remesh(body)
    decimate_to(body, target)
    bpy.ops.object.shade_smooth()

    after_tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)

    print(f"\n{model.name}: {before_tris:,} tris -> {after_tris:,}")
    print(f"  {merged} duplicate verts merged, {debris} debris verts removed, "
          f"voxel-remeshed to one manifold surface")
    print(f"  -> {out}")


if __name__ == "__main__":
    main()
