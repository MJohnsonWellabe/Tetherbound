"""The blind critique's fix list for Veridian Stag candidate c, as geometry.

    blender --background --python tools/art_pipeline/blender/fix_veridian_c.py \
            -- <model.glb> --out <fixed.glb>

Round 1's critique ranked c first and ruled it mesh-editable, on the grounds
that everything hard to win in a re-roll is already right: "by a clear margin
the best deer anatomy ... best head in the set ... best mantle where it
exists ... thickest, least fragile antler geometry ... cleanest leg
separation." Regenerating would gamble all of that to fix one part.

Four edits, in the critique's own priority order:

  1. **The rack.** The decisive failure. Measured against the concept: limb
     thickness 0.24 vs 0.51 (fraction surviving a 6px erosion), profile rack
     span 0.96x body length vs 1.17x, and forward reach PAST THE MUZZLE of
     -0.03 body-lengths vs +0.12 — i.e. the rack sweeps backward only, "which
     turns a crown into a windblown crest". Both halves are fixed here:
     thicken the limbs, and bend the rack progressively forward so the tips
     cradle the head instead of trailing off the back of it.
  2. **The yaw.** The model sits ~26 deg off-axis in its own space, so its
     "front" render is a three-quarter. Zeroed before anything else, because
     every other edit below is expressed in body-axis terms.
  3. **The mantle.** "A collar, not a bib" — it reads front-on but in profile
     it is a band behind the jaw with the brisket left bare. Pushed forward
     off the chest so it has depth from the side.
  4. **The whip tail.** Too thin to skin, and — the reason it is worth doing
     at all — too thin to survive cleanup_mesh.py's voxel remesh, which ate
     Ripplet's whiskers at this same stage. Thickened so it comes out the
     other side as a vine rather than as nothing.

## Two techniques worth naming

**Thickening pushes away from the local medial axis, not along normals.**
The obvious way to fatten a rod is to displace along vertex normals. This
mesh is a soup of 557 disconnected shells, many of them open, so "outward"
per normal is not reliably outward — some shells would thin instead of
thicken and the rack would come apart. Instead, for each vertex, the centroid
of its neighbours within a small radius lies ON the rod's axis, so
`p - centroid` points radially outward by construction, whichever way the
shell's normals happen to face. Orientation-free, which is what a shell soup
needs.

**The rack bends rather than rotates.** The rotation is weighted by height
above the pedicle, so the base stays welded to the skull while the tips swing
furthest. A rigid rotation would have traded a backward rack for a forward
one; the concept has both, tines forward past the nose AND back past the
shoulder, and a progressive bend plus a fore-aft spread gives that.

Deliberately NOT done: rebuilding the rack's branching. The critique offered
"or replaced outright" as an option — modelling a new rack from scratch is
sculpting, and a correctly-massed, correctly-swept version of the generator's
own branching reads better than clumsy hand-authored tines.
"""

import math
import pathlib
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

## --- The rack -------------------------------------------------------------
## Everything above this fraction of height is rack, minus the skull sphere.
ANTLER_Z = 0.75
## Skull core, protected from the rack edits so the head is not inflated.
SKULL_BAND = (0.63, 0.74)
SKULL_RADIUS = 0.17          # of overall height

## Limb thickening, as a fraction of height. The concept's limbs are ~2x the
## candidate's; this is the radial gain, applied to every rack surface point.
ANTLER_THICKEN = 0.013
## Radius of the neighbourhood whose centroid approximates the local rod axis.
## Must exceed the rod's own radius or the centroid sits on the surface.
MEDIAL_RADIUS = 0.045

## Forward bend at the tips, degrees, falling to zero at the pedicle.
ANTLER_SWEEP = 30.0
## Fore-aft spread about the pedicle, so bending forward does not cost the
## backward reach past the shoulder.
ANTLER_SPREAD = 1.22

## --- The mantle -----------------------------------------------------------
MANTLE_Z = (0.42, 0.63)
## Forward push at the strongest point, as a fraction of body length.
MANTLE_PUSH = 0.075
## Sideways gain, so the bib has volume rather than being a displaced sheet.
MANTLE_WIDEN = 1.10

## --- The tail -------------------------------------------------------------
TAIL_Z = (0.38, 0.70)
TAIL_REAR = 0.75             # fraction of body length, from the front
TAIL_HALF_WIDTH = 0.20       # of overall width; the tail is on the centreline
TAIL_THICKEN = 0.011
## Guard rails: outside this range we have grabbed the rump, not the tail.
TAIL_PLAUSIBLE = (40, 3000)


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def smooth_step(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


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


def coordinates(body) -> np.ndarray:
    flat = np.empty(len(body.data.vertices) * 3, dtype=np.float64)
    body.data.vertices.foreach_get("co", flat)
    return flat.reshape(-1, 3)


def write_coordinates(body, points: np.ndarray) -> None:
    body.data.vertices.foreach_set("co", points.reshape(-1).astype(np.float32))
    body.data.update()


def align_to_axis(points: np.ndarray) -> tuple[np.ndarray, float]:
    """Rotate about Z so the body's long axis is Y, muzzle at -Y.

    The long axis comes from a PCA of the LOWER half only. The legs and barrel
    lie along the body; the rack does not — it is the widest thing on the
    creature and sweeps sideways, so including it turns the principal axis
    into the antler span and "aligns" the stag sideways.
    """
    low, high = points.min(axis=0), points.max(axis=0)
    size = high - low
    lower = points[points[:, 2] < low[2] + size[2] * 0.55][:, :2]
    centred = lower - lower.mean(axis=0)
    _, _, right = np.linalg.svd(centred, full_matrices=False)
    axis = right[0]

    # Headings here are measured from +Y toward +X, i.e. theta = atan2(x, y).
    # Under this matrix a vector at heading theta lands at theta - phi, so phi
    # is the heading itself, NOT its negation. Negating it doubles the error
    # instead of cancelling it, which is a silent failure: the model still
    # comes out "aligned", just to 2x the yaw it started with. Caught by
    # measuring the exported file's axis rather than trusting the print.
    phi = math.atan2(axis[0], axis[1])
    rotate = np.array([[math.cos(phi), -math.sin(phi)],
                       [math.sin(phi), math.cos(phi)]])
    out = points.copy()
    out[:, :2] = points[:, :2] @ rotate.T

    # Which end is the head? In the band just below the rack the only thing
    # present is the neck, and it is narrow in X — so the sign of its mean Y
    # names the head end without having to reason about the antlers at all.
    low, high = out.min(axis=0), out.max(axis=0)
    size = high - low
    neck = out[(out[:, 2] > low[2] + size[2] * 0.58)
               & (out[:, 2] < low[2] + size[2] * 0.68)]
    if len(neck) and neck[:, 1].mean() > (low[1] + high[1]) / 2:
        out[:, :2] = -out[:, :2]      # 180 deg about Z: head to -Y
        phi += math.pi

    # Measure the result instead of trusting the maths. The sign bug above
    # produced a model that was rotated, printed a confident angle, and was
    # twice as crooked as before — nothing downstream would have noticed.
    check = out[out[:, 2] < out[:, 2].min()
                + (out[:, 2].max() - out[:, 2].min()) * 0.55][:, :2]
    _, _, after = np.linalg.svd(check - check.mean(axis=0), full_matrices=False)
    residual = abs(math.degrees(math.atan2(after[0][0], after[0][1]))) % 180.0
    residual = min(residual, 180.0 - residual)
    if residual > 5.0:
        raise SystemExit(f"alignment failed: body axis still {residual:.1f} deg "
                         f"off Y after correcting by {math.degrees(phi) % 360:.1f}")
    return out, math.degrees(phi) % 360.0


def skull_centre(points: np.ndarray) -> np.ndarray:
    low, high = points.min(axis=0), points.max(axis=0)
    size = high - low
    band = points[(points[:, 2] > low[2] + size[2] * SKULL_BAND[0])
                  & (points[:, 2] < low[2] + size[2] * SKULL_BAND[1])
                  & (np.abs(points[:, 0]) < size[0] * 0.25)]
    return band.mean(axis=0) if len(band) else (low + high) / 2


def thicken(points: np.ndarray, mask: np.ndarray, gain: float) -> int:
    """Push masked vertices away from their own local medial axis.

    See the module docstring: normals are not trustworthy on a shell soup,
    but the centroid of a neighbourhood on a thin rod sits on that rod's
    axis, so the outward direction falls out of the geometry itself.
    """
    indices = np.nonzero(mask)[0]
    if len(indices) == 0:
        return 0
    subset = points[indices]

    tree = KDTree(len(subset))
    for i, point in enumerate(subset):
        tree.insert(Vector(point), i)
    tree.balance()

    moved = 0
    for i, point in enumerate(subset):
        neighbours = tree.find_range(Vector(point), MEDIAL_RADIUS)
        if len(neighbours) < 4:
            continue
        centre = np.mean([subset[j] for (_, j, _) in neighbours], axis=0)
        direction = point - centre
        length = np.linalg.norm(direction)
        if length < 1e-9:
            continue
        points[indices[i]] = point + direction / length * gain
        moved += 1
    return moved


def fix_rack(points: np.ndarray) -> tuple[int, int]:
    low, high = points.min(axis=0), points.max(axis=0)
    size = high - low
    centre = skull_centre(points)

    above = points[:, 2] > low[2] + size[2] * ANTLER_Z
    off_skull = np.linalg.norm(points - centre, axis=1) > size[2] * SKULL_RADIUS
    rack = above & off_skull
    if rack.sum() < 200:
        print("  rack: not located; edit skipped")
        return 0, 0

    thickened = thicken(points, rack, size[2] * ANTLER_THICKEN)

    # The pedicle: the base of the rack, where it leaves the skull. Bending
    # about this point keeps the attachment welded while the tips travel.
    base_z = points[rack][:, 2].min()
    pedicle = np.array([0.0, points[rack][points[rack][:, 2]
                                         < base_z + size[2] * 0.04][:, 1].mean(),
                        base_z])
    top_z = points[rack][:, 2].max()
    span = max(top_z - pedicle[2], 1e-6)

    indices = np.nonzero(rack)[0]
    local = points[indices] - pedicle
    weight = smooth_step(local[:, 2] / span)[:, None]

    # Fore-aft spread first, so the bend acts on a rack that already reaches.
    local[:, 1] *= 1.0 + (ANTLER_SPREAD - 1.0) * weight[:, 0]

    # Then bend forward. Positive rotation about X carries geometry above the
    # pivot toward -Y, which is the muzzle end after align_to_axis.
    angle = math.radians(ANTLER_SWEEP) * weight[:, 0]
    cos, sin = np.cos(angle), np.sin(angle)
    y, z = local[:, 1].copy(), local[:, 2].copy()
    local[:, 1] = y * cos - z * sin
    local[:, 2] = y * sin + z * cos

    points[indices] = local + pedicle
    return thickened, int(rack.sum())


def fix_mantle(points: np.ndarray) -> int:
    """Give the leaf ruff depth in profile by pushing it off the brisket."""
    low, high = points.min(axis=0), points.max(axis=0)
    size = high - low
    mid_y = (low[1] + high[1]) / 2

    band = ((points[:, 2] > low[2] + size[2] * MANTLE_Z[0])
            & (points[:, 2] < low[2] + size[2] * MANTLE_Z[1])
            & (points[:, 1] < mid_y))
    if band.sum() < 100:
        print("  mantle: not located; edit skipped")
        return 0

    indices = np.nonzero(band)[0]
    subset = points[indices]
    # Strongest at the front and at the bottom of the band — that is the
    # brisket the critique found bare, not the neck, which already reads.
    forward = smooth_step((mid_y - subset[:, 1]) / (mid_y - low[1] + 1e-9))
    height = smooth_step(1.0 - (subset[:, 2] - (low[2] + size[2] * MANTLE_Z[0]))
                         / (size[2] * (MANTLE_Z[1] - MANTLE_Z[0])))
    weight = forward * (0.45 + 0.55 * height)

    subset[:, 1] -= weight * size[1] * MANTLE_PUSH
    subset[:, 0] *= 1.0 + (MANTLE_WIDEN - 1.0) * weight
    points[indices] = subset
    return int(band.sum())


def fix_tail(points: np.ndarray) -> int:
    low, high = points.min(axis=0), points.max(axis=0)
    size = high - low

    tail = ((points[:, 2] > low[2] + size[2] * TAIL_Z[0])
            & (points[:, 2] < low[2] + size[2] * TAIL_Z[1])
            & (points[:, 1] > low[1] + size[1] * TAIL_REAR)
            & (np.abs(points[:, 0]) < size[0] * TAIL_HALF_WIDTH))
    count = int(tail.sum())
    if not TAIL_PLAUSIBLE[0] <= count <= TAIL_PLAUSIBLE[1]:
        # Too few and there is no tail here; too many and this is the rump,
        # which must not be inflated. Either way, do nothing and say so.
        print(f"  tail: {count} verts is outside {TAIL_PLAUSIBLE}; edit skipped")
        return 0
    return thicken(points, tail, size[2] * TAIL_THICKEN)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... fix_veridian_c.py -- <model.glb> --out <fixed.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("fixed.glb"))).resolve()

    body = load_single_mesh(model)
    points = coordinates(body)

    points, yaw = align_to_axis(points)
    print(f"  yaw: corrected by {yaw:.1f} deg, muzzle now at -Y")

    thickened, rack = fix_rack(points)
    print(f"  rack: {rack} verts, {thickened} thickened, "
          f"spread {ANTLER_SPREAD}x and bent {ANTLER_SWEEP} deg forward")
    print(f"  mantle: {fix_mantle(points)} verts pushed off the brisket")
    print(f"  tail: {fix_tail(points)} verts thickened")

    write_coordinates(body, points)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
