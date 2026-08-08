"""Round-3 fix list for Terrapup, from the blind critique of the textured model.

    blender --background --python tools/art_pipeline/blender/fix2_terrapup.py \
            -- <textured.glb> --out <fixed.glb>

The critique's verdict on the first textured pass was close-but-not-yet, with
a priority list: (1) forepaws still ~half the concept's relative width even
after round 2's 1.6x, (2) no silhouette-breaking ruff — "the model reads as a
smooth toy bear cub", (3) muzzle narrowed and pointed, "raccoon/red panda"
against the concept's broad blunt badger muzzle, (4) tail high and thin with
a pebble rather than low and meaty with a faceted cap.

All four are geometry, and all four are applied HERE, to the textured mesh,
on purpose: UVs ride with the vertices, so volume edits stretch the existing
texture slightly instead of discarding it — where re-generating would throw
away a texture pass the same critique said was mostly right ("the palette,
stripe, eyes and stone back all land").

The ruff is the one experiment: noise-driven displacement along normals,
confined to a collar band behind the skull. It either reads as fur tufts
after texturing or it reads as lumps — the next blind round decides, and
reverting is rerunning this script with --no-ruff.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector, noise

## Additional paw scale on top of round 2's 1.6x. Compounded ~2.1x from the
## original mesh, which is the concept's front-to-hind ratio.
PAW_SCALE = 1.35
PAW_BAND = 0.30
PAW_RADIUS = 0.17

## Muzzle: broaden x, drop and enlarge the nose tip. The critique's words are
## "broaden the muzzle and enlarge/soften the nose".
MUZZLE_WIDEN = 1.25
MUZZLE_RADIUS = 0.14      # of body length, sphere around the muzzle tip

## Tail: a further drop past round 2's 50, and thickening.
TAIL_DROP = 18.0
TAIL_THICKEN = 1.3
TAIL_START = 0.25

## Ruff: displacement amplitude as a fraction of body length, and the noise
## frequency that decides tuft size. Modest on purpose — see module docstring.
RUFF_AMPLITUDE = 0.022
RUFF_FREQUENCY = 9.0


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


def world_points(body) -> list[tuple[int, Vector]]:
    matrix = body.matrix_world
    return [(v.index, matrix @ v.co) for v in body.data.vertices]


def write_back(body, moved: dict[int, Vector]) -> None:
    inverse = body.matrix_world.inverted()
    for index, point in moved.items():
        body.data.vertices[index].co = inverse @ point


def enlarge_front_paws(body) -> int:
    low, high = bounds(body)
    size = high - low
    radius = max(size) * PAW_RADIUS
    band_top = low.z + size.z * PAW_BAND
    mid_x = (low.x + high.x) / 2
    mid_y = (low.y + high.y) / 2

    sides: dict[bool, list[Vector]] = {True: [], False: []}
    for _, point in world_points(body):
        if point.z < low.z + size.z * 0.18 and point.y < mid_y:
            sides[point.x < mid_x].append(point)
    if not sides[True] or not sides[False]:
        raise SystemExit("could not find two front paws")
    centres = [sum(side, Vector()) / len(side) for side in sides.values()]

    moved: dict[int, Vector] = {}
    for index, point in world_points(body):
        if point.z > band_top:
            continue
        for centre in centres:
            flat = (Vector((point.x, point.y, 0)) - Vector((centre.x, centre.y, 0))).length
            if flat > radius:
                continue
            weight = smooth_step(1.0 - flat / radius)
            weight *= smooth_step((band_top - point.z) / (band_top - low.z + 1e-9))
            factor = 1.0 + (PAW_SCALE - 1.0) * weight
            point = point.copy()
            point.x = centre.x + (point.x - centre.x) * factor
            point.y = centre.y + (point.y - centre.y) * factor
            point.z = low.z + (point.z - low.z) * (1.0 + (PAW_SCALE - 1.0) * 0.3 * weight)
            moved[index] = point
            break
    write_back(body, moved)
    return len(moved)


def broaden_muzzle(body) -> int:
    """Widen everything within a sphere of the muzzle tip; pull the tip's
    centreline out a touch so the profile blunts instead of staying a wedge."""
    low, high = bounds(body)
    size = high - low
    # The muzzle tip: the foremost point in the head band (upper half, front).
    head_band = low.z + size.z * 0.5
    tip = min((p for _, p in world_points(body) if p.z > head_band),
              key=lambda p: p.y)
    radius = max(size) * MUZZLE_RADIUS

    moved: dict[int, Vector] = {}
    for index, point in world_points(body):
        distance = (point - tip).length
        if distance > radius:
            continue
        weight = smooth_step(1.0 - distance / radius)
        point = point.copy()
        point.x = tip.x + (point.x - tip.x) * (1.0 + (MUZZLE_WIDEN - 1.0) * weight)
        # Blunt the wedge: the closer to the tip, the more the point is pulled
        # forward-and-down toward a rounded nose mass.
        point.y -= size.y * 0.012 * weight
        point.z -= size.z * 0.015 * weight
        moved[index] = point
    write_back(body, moved)
    return len(moved)


def fix_tail(body) -> int:
    low, high = bounds(body)
    size = high - low
    band_top = low.z + size.z * 0.25
    mid_y = (low.y + high.y) / 2

    rear_paw_y = max(p.y for _, p in world_points(body)
                     if p.z < band_top and p.y > mid_y)
    overhang = high.y - rear_paw_y
    if overhang < size.y * 0.03:
        print("  no rear overhang; tail edit skipped")
        return 0
    root_y = rear_paw_y + overhang * TAIL_START
    root_z = low.z + size.z * 0.55
    pivot = Vector((0.0, root_y, root_z))

    moved: dict[int, Vector] = {}
    for index, point in world_points(body):
        if point.y <= root_y:
            continue
        weight = smooth_step((point.y - root_y) / (high.y - root_y + 1e-9))
        rotation = Matrix.Rotation(math.radians(-TAIL_DROP) * weight, 4, "X")
        point = pivot + rotation @ (point - pivot)
        # Thicken about the tail's own axis, most at the tip where the stone
        # cap lives.
        axis = Vector((0.0, point.y, root_z))
        point = axis + (point - axis) * (1.0 + (TAIL_THICKEN - 1.0) * weight)
        moved[index] = point
    write_back(body, moved)
    return len(moved)


def raise_ruff(body) -> int:
    """Noise displacement along normals in a collar band behind the skull."""
    low, high = bounds(body)
    size = high - low
    # The collar: upper body, from behind the head to the shoulder line.
    band_front = low.y + size.y * 0.18
    band_back = low.y + size.y * 0.42
    band_floor = low.z + size.z * 0.55
    amplitude = max(size) * RUFF_AMPLITUDE

    # Vertex normals, straight off the vertices. (calc_normals_split was
    # removed in Blender 4.1; per-vertex averaged normals are enough for a
    # displacement whose whole point is soft tufting.)
    rotation = body.matrix_world.to_3x3()
    moved: dict[int, Vector] = {}
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if not (band_front < point.y < band_back and point.z > band_floor):
            continue
        across = smooth_step(1.0 - abs(point.y - (band_front + band_back) / 2)
                             / ((band_back - band_front) / 2))
        tuft = noise.noise(point * RUFF_FREQUENCY / max(size))
        tuft = max(0.0, tuft)          # outward only; dents read as mange
        normal = rotation @ vert.normal
        if normal.length < 1e-6:
            continue
        moved[vert.index] = point + normal.normalized() * amplitude * tuft * across
    write_back(body, moved)
    return len(moved)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... fix2_terrapup.py -- <textured.glb> --out <fixed.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("fixed2.glb"))).resolve()
    with_ruff = "--no-ruff" not in args

    body = load_single_mesh(model)
    print(f"  paws: {enlarge_front_paws(body)} verts, +{PAW_SCALE}x (compounds round 2)")
    print(f"  muzzle: {broaden_muzzle(body)} verts, {MUZZLE_WIDEN}x wider, blunted")
    print(f"  tail: {fix_tail(body)} verts, -{TAIL_DROP} deg, {TAIL_THICKEN}x thicker")
    if with_ruff:
        print(f"  ruff: {raise_ruff(body)} verts displaced (the experiment; "
              f"--no-ruff reverts)")

    body.data.update()
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              use_selection=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
