"""Replace a generated body's head with a separately generated one.

    blender --background --python tools/art_pipeline/blender/graft_head.py \
            -- <body.glb> --head <bust.glb> --out <grafted.glb> \
            [--head-fraction 0.20] [--head-yaw 0] [--overlap 0.35] [--drop 0.0]

## Why this exists

Nine humanoid candidates, three characters, three rounds of prompt work, and
the blind critic's verdict never moved: "there is no face on any of the three
... a featureless ovoid with hair over it". Its judgement on the best body in
the set was that the body is a keeper and the head is not, and that no volume
edit saves it, because there is no brow, socket, nose or mouth to edit.

The cause is not the prompt — it has demanded sockets and lids in capitals
since round 2 — it is resolution allocation. At a 30k budget spread over a
standing figure, an eye socket is smaller than the triangles available to
describe it. Generating the head ALONE spends that whole budget on the head,
and the same generator that produced nine blank ovoids produces brows, lids,
a nose with nostrils and a modelled mouth on the first attempt.

So each character is made twice — once for the body, once for the head — and
this script joins them.

## How the join survives being crude

It does not stitch. It cuts both meshes at their own neck, scales the head to
the concept's head-to-body ratio, drops it into the body's neck stump so the
two volumes INTERPENETRATE, and joins them as loose parts. cleanup_mesh.py's
voxel remesh then turns any overlapping solid into one manifold surface,
which is the same mechanism that already welds these generators' 500-shell
output into a single skin. Overlap is doing the work that careful topology
would otherwise have to, and overlap is robust to being slightly wrong.

## The neck is found, not assumed

Both cuts land on the narrowest horizontal cross-section between shoulder and
skull, measured by scanning slabs — on a humanoid that minimum IS the neck.
Assuming a fixed height fraction instead would work on one character and
quietly cut through the jaw on the next.

## The head is scaled to the concept, not to the body it replaces

The critic measured the winning body's head at 18.0% of figure height against
the concept's 20.0%, i.e. ~10% undersized — one of the three fixes it asked
for. Scaling the new head to `--head-fraction` of the body's total height
fixes that in the same operation as the graft, rather than grafting the fault
back in.
"""

import math
import pathlib
import sys

import bmesh
import bpy
import numpy as np

## The concept sheet's head-to-figure ratio, crown to chin, hair included.
## Sheet 04 states 6.25 heads; the critic measured the drawing at 20.0%.
HEAD_FRACTION = 0.20

## How far the head is pushed down into the body's stump, as a fraction of
## head height. Enough that the two solids share volume for the remesh to
## fuse; small enough not to bury the chin in the collar.
OVERLAP = 0.35

## Where to scan for a neck, as fractions of each mesh's own height.
BODY_NECK_BAND = (0.55, 0.92)
BUST_NECK_BAND = (0.10, 0.75)

## Slabs used to profile the cross-section while hunting for the neck.
SLABS = 60


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load_joined(path: pathlib.Path, name: str) -> bpy.types.Object:
    """Import one GLB and return it as a single object, transforms applied."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    fresh = [o for o in set(bpy.data.objects) - before if o.type == "MESH"]
    if not fresh:
        raise SystemExit(f"no mesh in {path}")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in fresh:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = fresh[0]
    if len(fresh) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def delete_where(obj, doomed) -> None:
    """Delete the vertices of `obj` whose coordinate satisfies `doomed`.

    Done through bmesh rather than `bpy.ops.mesh.delete`, because the operator
    route deletes the whole mesh here regardless of what the per-vertex select
    flags say — set them in Object mode, switch to Edit mode, and every vertex
    comes back selected. bmesh takes an explicit geometry list and cannot be
    talked out of it, which is also how the other fix scripts in this folder
    remove geometry.
    """
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    mesh.verts.ensure_lookup_table()
    victims = [vertex for vertex in mesh.verts if doomed(vertex.co)]
    if victims:
        bmesh.ops.delete(mesh, geom=victims, context="VERTS")
    mesh.to_mesh(obj.data)
    mesh.free()
    obj.data.update()


def coordinates(obj) -> np.ndarray:
    flat = np.empty(len(obj.data.vertices) * 3, dtype=np.float64)
    obj.data.vertices.foreach_get("co", flat)
    return flat.reshape(-1, 3)


def write_coordinates(obj, points: np.ndarray) -> None:
    obj.data.vertices.foreach_set("co", points.reshape(-1).astype(np.float32))
    obj.data.update()


def find_neck(points: np.ndarray, band: tuple[float, float]) -> float:
    """The narrowest horizontal cross-section in the band — i.e. the neck.

    Width is the X extent of a slab, not its vertex count: a dense hair clump
    and a wide pair of shoulders can carry similar vertex counts, but nothing
    on a humanoid between the shoulders and the skull is narrower across than
    the neck.
    """
    low, high = points[:, 2].min(), points[:, 2].max()
    height = high - low
    best_z, best_width = None, math.inf
    for index in range(SLABS):
        lower = band[0] + (band[1] - band[0]) * index / SLABS
        upper = band[0] + (band[1] - band[0]) * (index + 1) / SLABS
        slab = points[(points[:, 2] >= low + height * lower)
                      & (points[:, 2] < low + height * upper)]
        if len(slab) < 20:
            continue
        width = slab[:, 0].max() - slab[:, 0].min()
        if width < best_width:
            best_width, best_z = width, low + height * (lower + upper) / 2
    if best_z is None:
        raise SystemExit(f"no neck found in band {band}")
    return best_z


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... graft_head.py -- <body.glb> --head <bust.glb> "
                         "--out <grafted.glb>")
    body_path = pathlib.Path(args[0]).resolve()
    bust_path = pathlib.Path(option(args, "--head")).resolve()
    out = pathlib.Path(option(args, "--out", body_path.with_name("grafted.glb"))).resolve()
    fraction = float(option(args, "--head-fraction", HEAD_FRACTION))
    overlap = float(option(args, "--overlap", OVERLAP))
    drop = float(option(args, "--drop", 0.0))
    yaw = math.radians(float(option(args, "--head-yaw", 0.0)))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    body = load_joined(body_path, "body")
    bust = load_joined(bust_path, "bust")

    body_points = coordinates(body)
    body_low, body_high = body_points[:, 2].min(), body_points[:, 2].max()
    body_height = body_high - body_low
    neck_z = find_neck(body_points, BODY_NECK_BAND)
    old_head = body_high - neck_z
    print(f"  body: height {body_height:.3f}, neck at "
          f"{(neck_z - body_low) / body_height:.3f} of height, "
          f"old head {old_head / body_height:.3f} of height")

    bust_points = coordinates(bust)
    if yaw:
        cos, sin = math.cos(yaw), math.sin(yaw)
        x, y = bust_points[:, 0].copy(), bust_points[:, 1].copy()
        bust_points[:, 0] = x * cos - y * sin
        bust_points[:, 1] = x * sin + y * cos
    bust_neck_z = find_neck(bust_points, BUST_NECK_BAND)
    bust_head = bust_points[:, 2].max() - bust_neck_z
    print(f"  bust: neck at {bust_neck_z:.3f}, head height {bust_head:.3f}")

    # Scale to the CONCEPT's ratio rather than to the head being replaced —
    # the head being replaced is the one the critique measured as undersized.
    target_head = body_height * fraction
    scale = target_head / bust_head
    print(f"  head scaled {scale:.3f}x to {fraction:.2f} of body height")

    # Neck centre in plan, so the head lands on the spine rather than beside it.
    collar = bust_points[(bust_points[:, 2] > bust_neck_z - bust_head * 0.05)
                         & (bust_points[:, 2] < bust_neck_z + bust_head * 0.05)]
    bust_centre = collar[:, :2].mean(axis=0) if len(collar) else bust_points[:, :2].mean(axis=0)
    body_collar = body_points[(body_points[:, 2] > neck_z - old_head * 0.25)
                              & (body_points[:, 2] <= neck_z)]
    body_centre = (body_collar[:, :2].mean(axis=0) if len(body_collar)
                   else body_points[:, :2].mean(axis=0))

    # Transform every bust vertex first and cut afterwards. Doing it in this
    # order keeps one affine map over the whole mesh instead of a partial one
    # over a subset, so the cut plane can be stated in final world terms and
    # there is no index bookkeeping between a filtered array and the mesh.
    bust_points[:, :2] = (bust_points[:, :2] - bust_centre) * scale + body_centre
    # --head-drop sinks the whole head DOWN into the collar, in head-heights.
    #
    # `overlap` cannot do this and it was the first thing tried: it moves the
    # CUT, not the head, so raising it keeps more of the bust's own neck and
    # makes the problem worse, while negative values lift the head clean off
    # the shoulders. What was actually wrong on the Warden is that the body's
    # neck stump and the bust's neck stack, and the owner's word for the result
    # was "comically long". This translates the placed head down so the jaw
    # meets the collar, which is the only lever that shortens the visible neck
    # without touching either mesh.
    bust_points[:, 2] = ((bust_points[:, 2] - bust_neck_z) * scale + neck_z
                         - target_head * drop)
    write_coordinates(bust, bust_points)

    # Everything above the cut is head plus a collar of neck that reaches down
    # into the body's stump by `overlap` head-heights — that shared volume is
    # what the voxel remesh fuses.
    cut_z = neck_z - target_head * (overlap + drop)
    if (bust_points[:, 2] > cut_z).sum() < 100:
        raise SystemExit("head cut left almost nothing; check --overlap")
    delete_where(bust, lambda co: co.z <= cut_z)
    print(f"  bust trimmed to {len(bust.data.vertices)} verts above the cut")

    # Now take the body's own head off, leaving the stump the new one sits in.
    delete_where(body, lambda co: co.z > neck_z)
    print(f"  body head removed, {len(body.data.vertices)} verts remain")

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bust.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)
    print(f"\n-> {out}  (run cleanup_mesh.py next; the remesh does the welding)")


if __name__ == "__main__":
    main()
