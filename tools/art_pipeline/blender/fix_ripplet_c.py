"""The blind critique's fix list for Ripplet candidate c, applied as geometry.

    blender --background --python tools/art_pipeline/blender/fix_ripplet_c.py \
            -- <model.glb> --out <fixed.glb>

Round 1's critique chose c — best-lobed ear frills, the only readable crest
spike, the concept's head-heavy ratio — and ruled its faults mesh-editable:

  1. "Tail fan: undersized by roughly half... carried too low to read from
     the back." The concept's fan is torso-sized and curls UP; c's is a low
     paddle. Fix: scale ~1.7x about the tail root and rotate the carriage
     upward — the exact inverse of Terrapup's tail fix, which is why this is
     a separate file and not a flag on that one.
  2. "Inflate the thigh volumes" — the concept is a bottom-heavy pear and c,
     though the plumpest of the three, still tapers.
  3. A dangling whisker strand below the muzzle. NOT deleted here, after
     trying exactly that: the strand shares vertices with the chin, so the
     connectivity delete opened a hole in the head, and cleanup_mesh's voxel
     remesh answered the open surface by shelling the ENTIRE body double-
     walled — every render came back as crumpled foil. The remesh itself
     erases sub-voxel strands, verified on this very mesh, so the right
     amount of code for the whisker is none.

The scallop count (2 lobes vs the concept's 4-5) is left for texturing:
cutting new lobes into a fan is sculpting, and a painted scallop edge on a
big correctly-carried fan reads better than clumsy real ones.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

TAIL_SCALE = 1.7
TAIL_RAISE = 38.0          # degrees up about the root
TAIL_START = 0.20

THIGH_SCALE = 1.22
## The haunch band: lower-middle of the body, rear half.
THIGH_Z = (0.10, 0.45)     # fractions of height
THIGH_RADIUS = 0.16        # of body length, per-side falloff sphere

## Whisker debris: thin geometry below the muzzle tip, within this radius of
## the chin, gets removed as loose parts.
WHISKER_RADIUS = 0.10


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load_single_mesh(path: pathlib.Path) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
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


def bounds(obj) -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return low, high


def smooth_step(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def fix_tail(body) -> int:
    """Scale the rear overhang up and rotate it upward about the root."""
    low, high = bounds(body)
    size = high - low
    band_top = low.z + size.z * 0.30
    mid_y = (low.y + high.y) / 2

    # Feet are found in the body's MIDDLE band of length, not by "rearmost
    # ground contact" — this creature's tail paddle itself rests on the
    # ground at the very back, so the rearmost contact IS the tail tip and
    # that heuristic concluded there was no tail to edit (0 vertices, on a
    # creature whose tail is its defining feature).
    rear_foot_y = max((body.matrix_world @ v.co).y for v in body.data.vertices
                      if (body.matrix_world @ v.co).z < band_top
                      and mid_y < (body.matrix_world @ v.co).y < low.y + size.y * 0.68)
    overhang = high.y - rear_foot_y
    if overhang < size.y * 0.03:
        print("  no rear overhang; tail edit skipped")
        return 0
    root_y = rear_foot_y + overhang * TAIL_START
    root_z = low.z + size.z * 0.35     # the tail roots low on a sitter
    pivot = Vector((0.0, root_y, root_z))

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.y <= root_y:
            continue
        weight = smooth_step((point.y - root_y) / (high.y - root_y + 1e-9))
        # Up, not down: positive rotation about X lifts +Y geometry.
        rotation = Matrix.Rotation(math.radians(TAIL_RAISE) * weight, 4, "X")
        point = pivot + rotation @ (point - pivot)
        point = pivot + (point - pivot) * (1.0 + (TAIL_SCALE - 1.0) * weight)
        vert.co = body.matrix_world.inverted() @ point
        touched += 1
    return touched


def inflate_thighs(body) -> int:
    low, high = bounds(body)
    size = high - low
    z0, z1 = low.z + size.z * THIGH_Z[0], low.z + size.z * THIGH_Z[1]
    mid_x = (low.x + high.x) / 2
    mid_y = (low.y + high.y) / 2
    radius = max(size) * THIGH_RADIUS

    sides: dict[bool, list[Vector]] = {True: [], False: []}
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if z0 < point.z < z1 and point.y > mid_y:
            sides[point.x < mid_x].append(point)
    if not sides[True] or not sides[False]:
        print("  could not find haunches; thigh edit skipped")
        return 0
    centres = [sum(side, Vector()) / len(side) for side in sides.values()]

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        for centre in centres:
            distance = (point - centre).length
            if distance > radius:
                continue
            weight = smooth_step(1.0 - distance / radius)
            factor = 1.0 + (THIGH_SCALE - 1.0) * weight
            # Outward from the body's own core axis, so the pear widens
            # instead of the whole rump translating.
            axis = Vector((mid_x, point.y, point.z))
            point = axis + (point - axis) * factor
            vert.co = body.matrix_world.inverted() @ point
            touched += 1
            break
    return touched


def delete_whisker_debris(body) -> int:
    """Remove small disconnected fragments near the chin.

    The critique found "a whisker strand drooping from the muzzle straight
    down past the chin". Deleted by connectivity: components whose vertex
    count is tiny AND whose centroid sits in the chin sphere. Deleting by
    position alone would bite the chin itself.
    """
    import bmesh
    low, high = bounds(body)
    size = high - low
    # The muzzle tip: foremost point of the upper half.
    tip = min((body.matrix_world @ v.co for v in body.data.vertices
               if (body.matrix_world @ v.co).z > low.z + size.z * 0.5),
              key=lambda p: p.y)
    chin = Vector((tip.x, tip.y + size.y * 0.02, tip.z - size.z * 0.10))
    radius = max(size) * WHISKER_RADIUS

    mesh = bmesh.new()
    mesh.from_mesh(body.data)
    mesh.verts.ensure_lookup_table()
    matrix = body.matrix_world

    unvisited = set(v.index for v in mesh.verts)
    doomed: list[int] = []
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
        if len(members) < len(mesh.verts) * 0.02:
            centroid = sum((matrix @ mesh.verts[i].co for i in members), Vector()) / len(members)
            if (centroid - chin).length < radius:
                doomed.extend(members)

    if doomed:
        bmesh.ops.delete(mesh, geom=[mesh.verts[i] for i in doomed], context="VERTS")
        mesh.to_mesh(body.data)
    mesh.free()
    return len(doomed)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... fix_ripplet_c.py -- <model.glb> --out <fixed.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("fixed.glb"))).resolve()

    body = load_single_mesh(model)
    print(f"  tail: {fix_tail(body)} verts, {TAIL_SCALE}x and {TAIL_RAISE} deg up")
    print(f"  thighs: {inflate_thighs(body)} verts, {THIGH_SCALE}x outward")
    # Whisker deliberately untouched — see the module docstring.

    body.data.update()
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
