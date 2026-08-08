"""Build a bird armature — two legs, three-segment wings, tail fan — skin it,
and author the six gameplay clips onto it.

    blender --background --python tools/art_pipeline/blender/rig_bird.py \
            -- <model.glb> --out <rigged.glb> [--report report.json] [--rig-only]

WHY THIS EXISTS. Four of the remaining wild species are birds and no rig fits
any of them:

  Reedwing   waterfowl. Short legs, long neck, a bill that projects further
             than a hawk's beak, and wings folded flat against the flanks.
  Pipwing    tiny round songbird. Almost no neck, almost no leg, and wings
             that do not break the body silhouette at all.
  Duskhush   owl. Head as wide as the torso sitting almost directly on it.
  Galecrest  large hawk. 3.6-4.2 m of wingspan against a 2.0 m body — the
             wings are two thirds of everything the mesh contains.

rig_quadruped refuses these correctly (they are not four-legged).
rig_glider is closer but is built for Galewisp specifically: it finds wings
by requiring vertices past 55% of the body's half-width, and SystemExits if
it finds none. A duck with folded wings has nothing out there — the widest
thing on it is its own chest — so rig_glider refuses every bird in the
roster except the hawk. HANDOFF.md §8's requirement for this file is exactly
that: "it must be general enough for a duck."

HOW THAT GENERALITY IS ACHIEVED. Nothing here is a fixed proportion of the
bounding box, because the bounding box of a hawk with 4 m of wing and the
bounding box of a fist-sized songbird share no useful ratio. Every landmark
is a measurement of the mesh's own shape:

  crotch      scan z upward and find the first slice where the two leg
              columns stop being separate and become one body. That single
              number is the duck/hawk difference — it IS leg length — and
              everything below it is leg, everything above it is bird.
  torso width the x-extent of a thin slab at the hips, between the crotch and
              mid-torso. Deliberately not the bounding box: on Galecrest the
              bounding box's width is wing, and on Duskhush it is head.
  neck        the narrowest horizontal slice between the shoulders and the
              crown. A duck has a deep minimum there, an owl a shallow one,
              and a songbird almost none — so a shallow minimum falls back to
              a proportion and SAYS SO rather than putting the head bone
              halfway down the chest.
  wing        the wing tip is the wing-band vertex FURTHEST FROM THE
              SHOULDER, not the one furthest out sideways. That one change is
              what makes the same code work folded and spread: on Galecrest
              the furthest point is 2 m out to the side, on Reedwing it is
              20 cm back along the flank, and in both cases it is the tip of
              the wing.

SKINNING. Automatic weights, on the CLEAN mesh, exactly like rig_quadruped
and rig_glider — and for the same reason: bone heat succeeds on the
voxel-remeshed manifold cleanup_mesh.py produces and is a lottery on Meshy's
retexture output. Do not re-solve that here. The textured mesh gets its
weights from `skin_transfer.py`, which copies them off this rig by nearest-
face interpolation:

    rig_bird.py     clean.glb    --out rigged_clean.glb     # this file
    skin_transfer.py rigged_clean.glb textured.glb --out pal_<species>.glb

Run inspect_glb.py on the result: skin_transfer exports with the exporter's
default animation mode rather than NLA_TRACKS, and the clips authored here
have to survive that round trip.

BONE CHANNEL SIGNS ARE MEASURED, NOT WRITTEN DOWN. Every rotation in this
file goes through a channel whose sign was found by posing the bone 12
degrees and looking at where the tip actually went. That is not caution for
its own sake. A pose bone's euler axes are its own, and Blender computes a
bone's roll from its head/tail direction, so the same euler tuple means
different things on a wing that points sideways and a wing that points
backwards along the flank — which is precisely the difference between two
birds in this roster. Hardcoded tuples work for the silhouette they were
tuned on and silently mirror or spin on the next one. (animate_quadruped.py's
faint is the cautionary case: it puts -78 degrees on the root bone's Y euler
and its comment says "keel over sideways", but the root bone is vertical, so
its local Y is world up and that number is a yaw. The creature spins on the
spot.)

PROVED ON. None of the four birds exists yet, so this was run end to end on
the three winged meshes the project has, and the clips were re-imported and
measured rather than eyeballed:

  ernie-the-duck.glb    0.87 m, legs 19% of height, wings 1.87x torso -> folded
  ollie-the-songbird    0.86 m, legs not measurable (fell back), 2.00x -> folded
  pal_galewisp_lod0     2.08 m, legs 8%, wings 3.71x torso -> SPREAD

All three: 19 bones, one root, six clips, 0 unweighted vertices (the duck has
3 of 6953, from its own non-manifold geometry). Re-imported, the walk's two
feet travel fore and aft in antiphase (correlation -0.96 to -0.98), the body
bobs and sways, the attack winds up for 8 frames and strikes in 5, the faint
topples sideways and downwards instead of spinning, and the three looping
clips close to 0.000000 m at the seam.
"""

import json
import math
import pathlib
import sys

import bpy
from mathutils import Vector

# ---------------------------------------------------------------------------
# Landmark detection. TUNABLE, all of it — but see the module docstring: these
# are thresholds on measurements, not proportions of the model.
# ---------------------------------------------------------------------------

## Lowest fraction of total height searched for the two foot clusters. Has to
## reach the feet of a long-legged hawk without swallowing a songbird's belly.
LEG_BAND = 0.18

## Feet must sit inside this fraction of the body's length, front to back. A
## "foot" at either extreme is a drooping primary feather or a tail tip.
LEG_ZONE = (0.20, 0.80)

## How far up to scan for the crotch, and how large a gap between the two leg
## columns counts as "still two legs" — as a fraction of the distance between
## the feet, so it scales with the animal instead of with its bounding box.
CROTCH_SCAN_TOP = 0.60
CROTCH_SLICES = 48
CROTCH_MIN_GAP = 0.16

## Below this, the crotch measurement is not believed. A bird whose legs are
## under 7% of its standing height has legs a slice scan cannot resolve —
## Pipwing is a ball of feathers on two twigs, and the songbird stand-in
## measures 1.3%, which would put the hips on the floor and give the walk
## cycle two centimetre-long thigh bones. Fall back and say so.
MIN_LEG_FRACTION = 0.07
FALLBACK_LEG_FRACTION = 0.18

## The neck is the narrowest slice between the shoulders and the crown. If the
## narrowest is less than this much narrower than the widest, there is no neck
## worth finding (Pipwing, Duskhush) and the fallback below is used instead.
NECK_MIN_PINCH = 0.12
NECK_FALLBACK = 0.55        # of the way from crotch to crown

## Shoulders sit high on a bird's back — the wing roots are level with the top
## of the ribcage, not with the middle of the body like a mammal's.
SHOULDER_OF_TORSO = 0.74

## A vertex counts as wing if it is outside this multiple of the torso's
## half-width. Below 1.0 on purpose: a folded wing lies ON the flank, so it
## only just clears the torso silhouette.
WING_CLEARANCE = 0.88

## Wingspan over torso width. Above this the wings are spread and can be flown;
## below it they are folded and the ambient clips must not try to flap them.
## Measured on what the project has: the duck stand-in reads 1.87 and the
## songbird 2.00 — both of which are little held-out arms, not flight poses —
## while Galewisp's actual spread membranes read 3.71. A hawk in a flight pose
## is far past that again, so the line goes above the stand-ins.
WING_SPREAD_RATIO = 2.2

## Where along the visible leg the ankle sits — the backward-bending joint that
## reads as a bird's "knee". Measured from the ground up.
ANKLE_OF_LEG = 0.42

## Four separated ground clusters with a real gap between the front and rear
## pairs means a quadruped wandered in. Refuse rather than rig it.
QUADRUPED_GAP = 0.15


# ---------------------------------------------------------------------------
# Clip amplitudes. All TUNABLE. Degrees unless the name says otherwise.
# ---------------------------------------------------------------------------

FPS = 24

## name -> (frames, loops). Same six roles and the same six names as every
## other creature in the roster, because data/pals/species.json maps roles to
## clips by exact string and pal_animator.gd retargets nothing.
CLIPS = {
    "idle": (72, True),
    "walk": (32, True),
    "run": (18, True),
    "attack": (22, False),
    "hit": (12, False),
    "faint": (36, False),
}

## IDLE AMPLITUDE — the deliberate part of this file.
##
## HANDOFF.md §6: pals are owner-reported as "static posed and sliding around"
## in combat, and the best remaining lead is that Terrapup's idle moves bones
## by 0.088 against 1.53 for its walk — about 6% — while a creature in combat
## is in idle almost all of the time. An idle that subtle is indistinguishable
## from a frozen creature, and no amount of correct loop-flag plumbing fixes
## a clip that does not move.
##
## So this idle is authored at roughly HALF the walk cycle's bone motion, not
## a twentieth of it, and the script measures and prints both numbers at the
## end of every run so the ratio can never quietly regress again.
##
## The amplitude is spent where a bird actually spends it. A standing bird is
## not a breathing statue: it scans, and the scan is a head movement that
## carries the whole silhouette. 24 degrees of yaw on a head that is a third
## of Duskhush's mass moves more pixels than 6 degrees of tail sway ever will,
## and it is in character for every one of the four — a duck, a songbird, an
## owl and a hawk all do it. A once-per-cycle sharp look breaks the sine so it
## does not read as a mechanical oscillation either.
IDLE_HEAD_TURN = 24.0
IDLE_HEAD_NOD = 11.0
IDLE_NECK_NOD = 8.0
IDLE_SPINE_NOD = 4.5
IDLE_PELVIS_TURN = 3.5
IDLE_TAIL_NOD = 9.0
IDLE_TAIL_TURN = 7.0
IDLE_WING_LIFT = 9.0
IDLE_WING_SETTLE = 16.0     # the once-per-cycle shuffle, on top of the above
IDLE_BOB = 0.014            # of body height, on the root bone

WALK_SWING = 30.0           # hip swing, peak to centre
WALK_LEAN = 3.0
WALK_BOB = 0.018            # of body height
WALK_SPINE_NOD = 3.0
WALK_HEAD_THRUST = 13.0     # the fore/aft head bob every walking bird has
WALK_TAIL = 7.0
WALK_WING = 8.0
WALK_WADDLE = 11.0          # peak roll, before the leg-length scaling below

RUN_SWING = 46.0
RUN_LEAN = 13.0
RUN_BOB = 0.032
RUN_SPINE_NOD = 5.0
RUN_HEAD_THRUST = 9.0
RUN_TAIL = 10.0
RUN_WING = 26.0

## Ambient wing motion is scaled down when the wings are folded — a folded
## wing that swings 26 degrees in a walk cycle detaches from the body. The
## attack deliberately does NOT use this: flaring the wings is the threat
## display, and a bird flares folded wings hardest of all.
FOLDED_WING_GAIN = 0.35

## Leg length as a fraction of standing height, from "no visible leg" to
## "wading bird". Measured on the two stand-ins the harness has: the duck
## comes out at 0.19 and the songbird at 0.16, and a long-legged raptor sits
## near a third. The waddle interpolates across this range and never reaches
## zero, because even a striding bird rolls a little onto each foot.
SHORT_LEG_FRACTION = 0.12
LONG_LEG_FRACTION = 0.34
WADDLE_MIN = 3.0


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


# ---------------------------------------------------------------------------
# Load and normalise
# ---------------------------------------------------------------------------

def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix.lower() not in (".glb", ".gltf"):
        raise SystemExit(f"rig_bird only takes glTF, got {path.suffix}")
    bpy.ops.import_scene.gltf(filepath=str(path))


def drop_import_artifacts() -> None:
    """Remove the phantom sphere Blender invents, and any skeleton already here.

    THE PHANTOM. inspect_glb.drop_import_phantoms documents this at length and
    it is not repeated here: reading any GLB this project exported gives back
    an extra 42-vertex `Icosphere`, unskinned and unmaterialled, that is not in
    the file. Five production reports mistook it for a stray riding through the
    pipeline. It matters here because this script JOINS every mesh it finds,
    and a unit sphere at the origin joined into a creature is a body that
    reaches z = -1: the mesh is then recentred around a sphere it does not
    have, the leg band fills with sphere vertices, and the run that found this
    refused Galewisp as a quadruped because the sphere's equator looked like a
    second pair of feet 0.15 of a body length behind the first.

    THE OLD SKELETON. Re-rigging an already-rigged model is an ordinary thing
    to want — every creature in this roster gets rigged more than once — and
    the previous armature would otherwise be exported alongside the new one,
    giving the GLB two skeletons and Godot the wrong one.
    """
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if any(o.vertex_groups for o in meshes):
        for obj in meshes:
            if obj.vertex_groups or obj.data.materials:
                continue
            print(f"  ignoring Blender import phantom: {obj.name} "
                  f"({len(obj.data.vertices)} verts) — not present in the file")
            bpy.data.objects.remove(obj, do_unlink=True)
    for obj in [o for o in bpy.data.objects if o.type == "ARMATURE"]:
        print(f"  removing the model's existing armature '{obj.name}' — re-rigging")
        bpy.data.objects.remove(obj, do_unlink=True)
    # Whatever the old rig weighted is now meaningless, and automatic weights
    # would otherwise merge into groups named for bones that no longer exist.
    for obj in [o for o in bpy.data.objects if o.type == "MESH"]:
        obj.vertex_groups.clear()
        for modifier in [m for m in obj.modifiers if m.type == "ARMATURE"]:
            obj.modifiers.remove(modifier)


def purge_incoming_animation() -> None:
    """Drop every action and NLA track that arrived with the file.

    Not paranoia. The Plumberry stand-ins the harness is proved against carry
    390 clips each as rigid-part transform animation on eight separate mesh
    objects. Join those objects and the surviving object keeps its animation
    data; export afterwards and the six clips this script authors ship
    alongside a few hundred inherited ones, several of which drive the object
    origin — which the game forbids, because pal_body drives position itself.
    """
    dropped = 0
    for obj in bpy.data.objects:
        if obj.animation_data:
            obj.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
        dropped += 1
    if dropped:
        print(f"  dropped {dropped} inherited clip(s) from the source file")


def join_normalise_weld() -> bpy.types.Object:
    """One mesh, welded, standing on z=0, centred in x/y.

    Same three steps and the same reasoning as rig_quadruped.join_and_normalise:
    automatic weights bind one object cleanly, and Meshy's retexture stage
    hands back coincident vertices that make bone heat fail. Merging by
    distance is UV-safe because Blender stores UVs per face corner.
    """
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in the file")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        print(f"  joining {len(meshes)} mesh objects into one body")
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    # Unparent first, KEEPING the world transform. A Meshy export is one object
    # at the scene root and this is a no-op there, but the Plumberry stand-ins
    # the harness is proved against are rigged as a hierarchy of empties, so the
    # joined mesh inherits whichever empty the first part hung from. Everything
    # after this point sets `location` and reads `matrix_world`, and those two
    # only agree when there is no parent between them: recentring a mesh whose
    # parent carries a rotation moves it somewhere else entirely, and the only
    # symptom is that the measured height quietly stops matching inspect_glb's.
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
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

    low, high = point_bounds(world_points(body))
    body.location = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
    bpy.ops.object.transform_apply(location=True)
    return body


def world_points(obj) -> list[Vector]:
    matrix = obj.matrix_world
    return [matrix @ vertex.co for vertex in obj.data.vertices]


def point_bounds(points: list[Vector]) -> tuple[Vector, Vector]:
    """Bounds from the vertices themselves, not from `object.bound_box`.

    Two reasons, both of which bit this file during development. `bound_box`
    is an object-space box, so on a model assembled from parts it is measured
    per part and then rotated into world, which inflates it — the duck
    stand-in reads 0.958 m that way and 0.865 m by its actual vertices, a 10%
    error straight into every proportion below. And it is cached: reading it
    immediately after `transform_apply` returns the previous frame's numbers
    unless the depsgraph has been pushed, which is a 1% wobble that appears
    and disappears depending on what ran before.
    """
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for point in points:
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return low, high


def centroid(points: list[Vector]) -> Vector:
    return sum(points, Vector()) / len(points)


# ---------------------------------------------------------------------------
# Landmarks
# ---------------------------------------------------------------------------

def find_feet(pts, low, high, size, mid_x) -> dict[str, Vector]:
    """The two ground clusters, and a refusal if there are four of them."""
    band_top = low.z + size.z * LEG_BAND
    half_width = size.x / 2
    band = [p for p in pts if p.z <= band_top]
    if not band:
        raise SystemExit("no vertices in the lowest band — the mesh does not touch the ground")

    near = [p for p in band if abs(p.x - mid_x) < half_width * 0.45]
    if not near:
        # Everything low is out at the sides: drooping wing tips, no feet.
        raise SystemExit(
            "nothing near the centreline touches the ground — the lowest geometry is "
            "all lateral. This is a spread-winged pose with no visible legs; rig it "
            "standing, or lower LEG_BAND if the legs are simply very short.")

    sides: dict[bool, list[Vector]] = {True: [], False: []}
    for point in near:
        sides[point.x < mid_x].append(point)
    feet = {}
    for left, name in ((True, "foot_l"), (False, "foot_r")):
        if not sides[left]:
            raise SystemExit(f"no vertices in the {name} cluster — not a standing biped?")
        centre = centroid(sides[left])
        along = (centre.y - low.y) / max(size.y, 1e-6)
        if not (LEG_ZONE[0] < along < LEG_ZONE[1]):
            raise SystemExit(
                f"{name} sits at {along:.2f} of body length, outside the middle "
                f"{LEG_ZONE} — that is a wing tip or a tail feather on the floor, "
                f"not a foot. Refusing to rig a skeleton that is wrong by construction.")
        feet[name] = centre

    # A quadruped that wandered in. Not "are there four clusters" — a duck's
    # webbed feet are long enough front to back to look like four if you only
    # count quadrants — and not just "is there a gap across the body", either:
    # a bird with a tail that reaches the floor leaves exactly such a gap
    # behind its feet, and refusing it would be wrong. A quadruped is a front
    # PAIR and a rear PAIR, so both groups have to split left and right.
    stance = abs(feet["foot_l"].x - feet["foot_r"].x)
    ys = sorted(p.y for p in near)
    if len(ys) > 2 and stance > 1e-6:
        gap, divide = max(((b - a, (a + b) / 2) for a, b in zip(ys, ys[1:])))
        if gap / size.y > QUADRUPED_GAP:
            pairs = 0
            for group in ([p for p in near if p.y < divide],
                          [p for p in near if p.y > divide]):
                xs = sorted(p.x for p in group)
                if len(xs) > 2 and max(b - a for a, b in zip(xs, xs[1:])) > stance * 0.3:
                    pairs += 1
            if pairs == 2:
                raise SystemExit(
                    f"the ground contact is two PAIRS of feet {gap / size.y:.2f} of "
                    f"body length apart — this is a quadruped. Use rig_quadruped.py.")
    return feet


def find_crotch(pts, low, size, hip_y, feet: dict) -> tuple[float, bool]:
    """Height at which the two legs stop being separate and become one body.

    This is the single most important number in the file. It is leg length,
    and leg length is what separates the four birds this rig has to serve:
    Reedwing's legs are a fifth of it, Galecrest's a third, Pipwing's barely
    exist. Everything above it is bird and everything below it is leg, so the
    hips, the ankles, the toes, the torso slab and the waddle amplitude all
    hang off it.

    Measured by slicing upward and asking, of each slice, whether its vertices
    still fall into TWO COLUMNS with a gap between them near the midpoint of
    the two feet. The first version of this asked whether a fixed corridor
    around the model's centreline was empty, and it failed on the first duck
    it met: the corridor was sized off the bounding box's half-width, the
    bounding box's width was the bill and the wings, and the corridor came out
    wider than the whole stance. Sizing the test off the distance between the
    feet — the only length in the model that is actually about legs — fixes
    that, and incidentally handles a bird standing pigeon-toed or posed
    asymmetrically, which the stand-ins are.

    Returns (z, measured). `measured` is False when no slice was ever split,
    which is a real answer for a bird whose legs are buried in its plumage,
    and the caller must be told rather than handed a silent guess.
    """
    top = low.z + size.z * CROTCH_SCAN_TOP
    step = (top - low.z) / CROTCH_SLICES
    zone = [p for p in pts if abs(p.y - hip_y) < size.y * 0.32]
    stance = abs(feet["foot_l"].x - feet["foot_r"].x)
    split_x = (feet["foot_l"].x + feet["foot_r"].x) / 2
    fallback = (low.z + size.z * FALLBACK_LEG_FRACTION, False)
    floor = low.z + size.z * MIN_LEG_FRACTION
    if stance < 1e-6:
        return fallback

    gapped_until = None
    for index in range(CROTCH_SLICES):
        za = low.z + step * index
        xs = sorted(p.x for p in zone if za <= p.z < za + step)
        if len(xs) < 8:
            continue    # too thin to judge; keep climbing
        gap, middle = max(((b - a, (a + b) / 2) for a, b in zip(xs, xs[1:])),
                          default=(0.0, split_x))
        split = gap > stance * CROTCH_MIN_GAP and abs(middle - split_x) < stance * 0.5
        if split:
            gapped_until = za + step
        elif gapped_until is not None:
            break
    if gapped_until is None or gapped_until < floor:
        return fallback
    return gapped_until, True


def torso_half_width(pts, crotch_z, top_z, mid_x, hip_y, size) -> float:
    """Half-width of the body at the hips: how far out from the centreline the
    mesh runs BEFORE the first gap of air.

    Explicitly NOT half of the bounding box. On Galecrest the bounding box's
    width is 4 m of wing; on Duskhush it is the head; on Pipwing it is a tail
    feather. Every one of those would put the shoulder joints outside the
    animal, and this number is also the denominator of the folded/spread test,
    so getting it wrong gets the wing configuration wrong too.

    Taking the widest point of a hip slab is not enough either, which is how
    this was written first. Galewisp's wings droop almost to the floor, so
    they pass straight through any slab drawn at hip height and the "torso"
    came out 0.87 m wide on a creature with a 0.16 m body — reported as a
    1.19x wingspan on a mesh whose wings are two thirds of its bounding box,
    and therefore rigged as if they were folded.

    So walk outwards from the centreline instead and stop at the first real
    gap. A spread wing is separated from the ribcage by air at hip height; a
    folded wing lying on the flank is not, and correctly measures as part of
    the torso. "Real" is judged against the row's own median vertex spacing
    rather than against any fraction of the model, because the same absolute
    threshold that finds a duck's flank splits a hawk's ribcage in half.

    The walk has to happen ROW BY ROW, in thin horizontal slices. Doing it on
    one tall slab does not work and the failure is silent: Galewisp's wings
    are close to the body high up and far from it low down, so flattening
    three quarters of a metre of height into one list of x values fills the
    gap in from the neighbouring rows. Measured, the largest gap in the
    flattened list is 7 mm on a model whose wings clear the ribcage by 40 cm.
    Each row keeps its own gap; the median of the rows' edges is the torso.
    """
    rows = 12
    z0 = crotch_z
    z1 = crotch_z + (top_z - crotch_z) * 0.40
    step = (z1 - z0) / rows
    near_hips = [p for p in pts if abs(p.y - hip_y) < size.y * 0.16]
    if len(near_hips) < 16 * rows:
        near_hips = pts

    edges = []
    for index in range(rows):
        za = z0 + step * index
        row = [p for p in near_hips if za <= p.z < za + step]
        for left in (True, False):
            offsets = sorted(abs(p.x - mid_x) for p in row if (p.x < mid_x) == left)
            if len(offsets) < 8:
                continue
            steps = sorted(b - a for a, b in zip(offsets, offsets[1:]))
            spacing = steps[len(steps) // 2]
            limit = max(spacing * 6.0, size.x * 0.01)
            edge = offsets[0]
            for near_, far in zip(offsets, offsets[1:]):
                if far - near_ > limit:
                    break
                edge = far
            edges.append(edge)
    if not edges:
        slab = [p for p in pts if z0 <= p.z <= z1] or pts
        return max(abs(p.x - mid_x) for p in slab)
    edges.sort()
    return edges[len(edges) // 2]


def find_neck(pts, crotch_z, top_z, mid_x, torso_half) -> tuple[float, bool]:
    """Height of the narrowest horizontal slice between shoulders and crown.

    A duck pinches hard there, an owl barely, a songbird not at all. Returns
    (z, measured); an unmeasured neck falls back to a proportion and the
    caller prints it, because "we could not find a neck" is a true and useful
    thing to know about a mesh and a silently mislocated head bone is not.
    """
    z0 = crotch_z + (top_z - crotch_z) * 0.30
    z1 = top_z
    slices = 20
    step = (z1 - z0) / slices
    widths: list[tuple[float, float]] = []
    for index in range(slices):
        za = z0 + step * index
        band = [p for p in pts if za <= p.z < za + step and abs(p.x - mid_x) < torso_half * 2.0]
        if len(band) < 8:
            continue
        widths.append((za + step / 2, max(abs(p.x - mid_x) for p in band)))
    if len(widths) < 5:
        return z0 + (z1 - z0) * NECK_FALLBACK, False

    # Ignore the extreme ends: the bottom slice is chest and the top slice is
    # the crown, and both are narrow for reasons that are not a neck.
    inner = widths[1:-1]
    narrowest = min(inner, key=lambda w: w[1])
    widest = max(inner, key=lambda w: w[1])
    if widest[1] <= 1e-9 or (widest[1] - narrowest[1]) / widest[1] < NECK_MIN_PINCH:
        return z0 + (z1 - z0) * NECK_FALLBACK, False
    return narrowest[0], True


def find_wing(pts, side_left, crotch_z, top_z, mid_x, hip_y, size,
              torso_half, shoulder: Vector) -> dict[str, Vector] | None:
    """Shoulder-relative wing landmarks, or None if this side has no wing.

    THE TIP IS THE FURTHEST POINT FROM THE SHOULDER, not the furthest point
    out sideways. That is the whole trick, and it is what rig_glider gets
    wrong for anything but Galewisp. On a spread hawk the furthest point from
    the shoulder is 2 m out to the side; on a folded duck it is 20 cm back
    along the flank; on a songbird it is a few centimetres back and down. All
    three are the tip of the wing, and the elbow and wrist then fall out as
    fractions of that same distance rather than as fractions of the model.
    """
    clearance = torso_half * WING_CLEARANCE
    band = [p for p in pts
            if p.z > crotch_z
            and p.z < top_z - (top_z - crotch_z) * 0.05
            and p.y < hip_y + size.y * 0.30           # not the tail fan
            and (p.x < mid_x) == side_left
            and abs(p.x - mid_x) > clearance]
    if len(band) < 12:
        return None

    reach = [( (p - shoulder).length, p) for p in band]
    span = max(d for d, _ in reach)
    if span < 1e-6:
        return None
    tip = max(reach, key=lambda item: item[0])[1]

    def ring(lo: float, hi: float, fallback: float) -> Vector:
        found = [p for d, p in reach if span * lo <= d <= span * hi]
        # An empty ring is normal on a stubby folded wing; slide along the
        # shoulder->tip line instead of failing, so a chibi duck still gets a
        # three-bone wing that folds in the right place.
        return centroid(found) if found else shoulder.lerp(tip, fallback)

    return {
        "elbow": ring(0.22, 0.48, 0.33),
        "wrist": ring(0.52, 0.80, 0.68),
        "tip": tip,
        "span": span,
        "lateral": max(abs(p.x - mid_x) for p in band),
    }


def measure(body) -> dict:
    """Every landmark the armature is built from, as one dict."""
    pts = world_points(body)
    low, high = point_bounds(pts)
    size = high - low
    mid_x = (low.x + high.x) / 2

    feet = find_feet(pts, low, high, size, mid_x)
    hip_y = (feet["foot_l"].y + feet["foot_r"].y) / 2

    crotch_z, crotch_measured = find_crotch(pts, low, size, hip_y, feet)
    torso_half = torso_half_width(pts, crotch_z, high.z, mid_x, hip_y, size)
    neck_z, neck_measured = find_neck(pts, crotch_z, high.z, mid_x, torso_half)
    shoulder_z = crotch_z + (neck_z - crotch_z) * SHOULDER_OF_TORSO

    chest_slab = [p for p in pts
                  if abs(p.z - shoulder_z) < (neck_z - crotch_z) * 0.15
                  and abs(p.x - mid_x) < torso_half]
    chest_y = centroid(chest_slab).y if chest_slab else hip_y - size.y * 0.10

    # Head: everything above the neck pinch, near the centreline. The beak is
    # its front extreme, which is the bill on Reedwing and barely a bump on
    # Duskhush — both correct, both the same measurement.
    head_pts = [p for p in pts if p.z > neck_z and abs(p.x - mid_x) < torso_half * 1.6]
    if len(head_pts) < 12:
        head_pts = [p for p in pts if p.z > neck_z] or pts
    head_centre = centroid(head_pts)
    beak = min(head_pts, key=lambda p: p.y)

    # Tail: rear extreme measured near the centreline, so a spread wing that
    # sweeps backwards cannot be mistaken for a tail feather.
    tail_pts = [p for p in pts
                if abs(p.x - mid_x) < torso_half * 0.9
                and crotch_z - (neck_z - crotch_z) * 0.25 < p.z < shoulder_z]
    tail_end_y = max(p.y for p in tail_pts) if tail_pts else high.y

    shoulders = {
        "l": Vector((mid_x - torso_half * 0.85, chest_y, shoulder_z)),
        "r": Vector((mid_x + torso_half * 0.85, chest_y, shoulder_z)),
    }
    wings = {side: find_wing(pts, side == "l", crotch_z, high.z, mid_x, hip_y,
                             size, torso_half, shoulders[side])
             for side in ("l", "r")}

    leg_length = crotch_z - low.z
    span = 0.0
    for wing in wings.values():
        if wing:
            span = max(span, wing["lateral"])
    spread_ratio = span / max(torso_half, 1e-6)

    return {
        "low": low, "high": high, "size": size, "mid_x": mid_x,
        "feet": feet, "hip_y": hip_y,
        "crotch_z": crotch_z, "crotch_measured": crotch_measured,
        "torso_half": torso_half,
        "neck_z": neck_z, "neck_measured": neck_measured,
        "shoulder_z": shoulder_z, "chest_y": chest_y,
        "head_centre": head_centre, "beak": beak,
        "tail_end_y": tail_end_y,
        "shoulders": shoulders, "wings": wings,
        "leg_length": leg_length,
        "leg_fraction": leg_length / max(size.z, 1e-6),
        "spread_ratio": spread_ratio,
        "wings_folded": spread_ratio < WING_SPREAD_RATIO,
    }


# ---------------------------------------------------------------------------
# Armature
# ---------------------------------------------------------------------------

def build_armature(body, m: dict) -> bpy.types.Object:
    """19 bones: root, pelvis, spine, neck, head, two tail, 3x2 leg, 3x2 wing.

    Names are chosen to overlap animate_quadruped.py's glider layout
    (leg_upper_*, leg_lower_*, wing_upper_*, wing_tip_*) so that script still
    produces something sane if it is ever pointed at a bird. The bones it does
    not know about — wing_fore_*, foot_* — simply stay at rest there.

    Three bones per wing rather than the glider's two because a bird's wing
    folds at two joints, and a two-bone wing can only ever be a straight
    paddle that rotates. Reedwing folded and Galecrest spread are the same
    limb in two configurations, and the elbow/wrist pair is what lets one
    skeleton hold both.

    Three bones per leg because a bird's visible leg is not a mammal's: the
    joint that reads as a backward-bending knee is the ankle, and the segment
    below it is the foot. A two-bone leg puts the fold in the wrong place and
    the walk cycle reads as a person in a bird suit.
    """
    low, high, size = m["low"], m["high"], m["size"]
    crotch_z, neck_z = m["crotch_z"], m["neck_z"]
    torso_h = max(neck_z - crotch_z, size.z * 0.05)

    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.view_layer.objects.active
    rig.name = "Armature"
    edit = rig.data.edit_bones
    for bone in list(edit):
        edit.remove(bone)

    def add(name, head, tail, parent=None, connect=False):
        bone = edit.new(name)
        bone.head, bone.tail = Vector(head), Vector(tail)
        if parent:
            bone.parent = edit[parent]
            bone.use_connect = connect
        return bone

    hip_y = m["hip_y"]
    pelvis = Vector((0, hip_y, crotch_z))
    chest = Vector((0, m["chest_y"], m["shoulder_z"]))
    mid_spine = pelvis.lerp(chest, 0.5)

    # root is placed exactly vertical on purpose: the faint clip slides the
    # whole body along this bone's local Y, and that is only "up" while the
    # bone points up.
    add("root", (0, hip_y, low.z), (0, hip_y, low.z + size.z * 0.12))
    add("pelvis", pelvis, mid_spine, "root")
    add("spine", mid_spine, chest, "pelvis", connect=True)

    neck_base = Vector((0, m["chest_y"] - size.y * 0.02, neck_z))
    head_base = neck_base
    head_tip = Vector((0, m["beak"].y + size.y * 0.01,
                       m["head_centre"].z + (m["beak"].z - m["head_centre"].z) * 0.5))
    add("neck", chest, neck_base, "spine", connect=True)
    add("head", head_base, head_tip, "neck", connect=True)

    # Tail: two bones so the fan can lag the base. Angled slightly down at the
    # tip, which is where a standing bird's tail sits and which also stops the
    # bone being exactly horizontal — a degenerate direction for the turn
    # channel measured below.
    tail_mid = Vector((0, hip_y + (m["tail_end_y"] - hip_y) * 0.45, crotch_z + torso_h * 0.10))
    tail_tip = Vector((0, m["tail_end_y"] - size.y * 0.02, crotch_z - torso_h * 0.05))
    add("tail_1", pelvis, tail_mid, "pelvis")
    add("tail_2", tail_mid, tail_tip, "tail_1", connect=True)

    ankle_z = low.z + m["leg_length"] * ANKLE_OF_LEG
    for side in ("l", "r"):
        foot = m["feet"][f"foot_{side}"]
        hip = Vector((foot.x, hip_y, crotch_z))
        knee = Vector((foot.x, foot.y + size.y * 0.02, crotch_z - m["leg_length"] * 0.30))
        ankle = Vector((foot.x, foot.y + size.y * 0.02, ankle_z))
        toe = Vector((foot.x, foot.y - size.y * 0.05, low.z))
        add(f"leg_upper_{side}", hip, knee, "pelvis")
        add(f"leg_lower_{side}", knee, ankle, f"leg_upper_{side}", connect=True)
        add(f"foot_{side}", ankle, toe, f"leg_lower_{side}", connect=True)

        shoulder = m["shoulders"][side]
        wing = m["wings"][side]
        if wing is None:
            # No geometry clears the torso on this side. Do not refuse — this
            # is Pipwing, a ball of feathers with its wings inside its own
            # silhouette, and it still has to flap. Lay the wing along the
            # flank from the shoulder to the hip, which is where it is.
            sign = -1.0 if side == "l" else 1.0
            flank_x = m["mid_x"] + sign * m["torso_half"] * 0.95
            elbow = Vector((flank_x, m["chest_y"] + size.y * 0.10, m["shoulder_z"] - torso_h * 0.12))
            wrist = Vector((flank_x, hip_y + size.y * 0.02, m["shoulder_z"] - torso_h * 0.26))
            tip = Vector((flank_x, hip_y + size.y * 0.14, m["shoulder_z"] - torso_h * 0.38))
        else:
            elbow, wrist, tip = wing["elbow"], wing["wrist"], wing["tip"]
        add(f"wing_upper_{side}", shoulder, elbow, "spine")
        add(f"wing_fore_{side}", elbow, wrist, f"wing_upper_{side}", connect=True)
        add(f"wing_tip_{side}", wrist, tip, f"wing_fore_{side}", connect=True)

    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def skin(body, rig) -> None:
    """Automatic weights on the clean mesh — see the module docstring on why
    the textured mesh goes through skin_transfer.py instead."""
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def strip_scene(body, rig) -> None:
    """Delete everything that is not the body or the new rig.

    The joined mesh leaves its old parent hierarchy behind, and on the
    Plumberry stand-ins that is a tree of thirty empties — sockets, an
    `arm_l`, a `root` that is not this rig's root. Exporting with
    `select_all(SELECT)` shipped the whole tree as extra glTF nodes, so the
    file had two things called root and a scene root named after the source
    pack. Godot would load it, but pal_body would be fitting a scene with
    named nodes nobody meant to ship.
    """
    keep = {body, rig}
    for obj in list(bpy.data.objects):
        if obj not in keep:
            bpy.data.objects.remove(obj, do_unlink=True)


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


# ---------------------------------------------------------------------------
# Channel signs, measured
# ---------------------------------------------------------------------------

## bone -> {"x": (sign, quality), "z": (sign, quality)}. Filled by
## measure_channels(); `quality` is |cos| between what the channel does and
## what it is being asked to do, so a degenerate pairing can be reported.
CHANNELS: dict[str, dict[str, tuple[float, float]]] = {}
FOLDED = False


def measure_channels(rig: bpy.types.Object, folded: bool) -> None:
    """Pose each bone 12 degrees and look at where its tip actually went.

    See the module docstring. The intent behind each channel is expressed as a
    rotation about a WORLD axis, and the world direction a bone's tip travels
    under such a rotation is `axis x (tail - head)` — which is exact, needs no
    knowledge of Blender's roll convention, and stays correct when the same
    bone points sideways on one bird and backwards on the next.

      nod   rotation about world +X, so the tip travels along `X x (tail-head)`.
            On the spine chain that is a nod; on a vertical root it is a
            forward lean; on a leg it swings the foot backwards, so the leg
            wrapper passes -forward.
      turn  the tip travels towards world +X, the bird's right. Expressed as a
            direction rather than as a rotation about world +Z on purpose:
            `Z x (tail-head)` vanishes for any vertical bone, and the root and
            both shins ARE vertical, so that formulation measured a sign off
            floating-point noise and reported a conditioning of 0.00. Every
            non-wing bone in this rig is built in the sagittal plane, so its
            axis is perpendicular to world X and this target is never
            degenerate. It is also what makes the faint work: on the vertical
            root, "tip travels towards +X" is the body toppling sideways.
      lift  wings only: the tip rises.
      swing wings only: the tip travels forward if the wings are spread, and
            away from the body if they are folded. Those are the same motion
            in the wing's own frame — the in-plane swing — and they are what
            "open the wing" means in each configuration. A folded wing swung
            forward would fold further into the body; a spread wing swung
            outward has nowhere to go.
    """
    global CHANNELS, FOLDED
    FOLDED = folded
    CHANNELS = {}

    bpy.ops.object.mode_set(mode="OBJECT")
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0.0, 0.0, 0.0)
        bone.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()

    world = rig.matrix_world
    rest = {b.name: (world @ b.tail).copy() for b in rig.pose.bones}
    probe = math.radians(12.0)

    for bone in rig.pose.bones:
        head = world @ bone.head
        arm = rest[bone.name] - head
        is_wing = bone.name.startswith("wing_")
        if is_wing:
            up = Vector((0.0, 0.0, 1.0))
            targets = {"x": (up - arm.normalized() * up.dot(arm.normalized()))}
            if folded:
                outward = Vector((-1.0, 0.0, 0.0)) if bone.name.endswith("l") \
                    else Vector((1.0, 0.0, 0.0))
            else:
                outward = Vector((0.0, -1.0, 0.0))
            targets["z"] = outward - arm.normalized() * outward.dot(arm.normalized())
        else:
            targets = {
                "x": Vector((1.0, 0.0, 0.0)).cross(arm),
                "z": Vector((1.0, 0.0, 0.0)),
            }

        measured = {}
        for label, index in (("x", 0), ("z", 2)):
            bone.rotation_euler = tuple(probe if i == index else 0.0 for i in range(3))
            bpy.context.view_layer.update()
            delta = (world @ bone.tail) - rest[bone.name]
            bone.rotation_euler = (0.0, 0.0, 0.0)
            target = targets[label]
            if delta.length < 1e-9 or target.length < 1e-9:
                measured[label] = (1.0, 0.0)
                continue
            cosine = delta.normalized().dot(target.normalized())
            measured[label] = (1.0 if cosine >= 0.0 else -1.0, abs(cosine))
        CHANNELS[bone.name] = measured
    bpy.context.view_layer.update()

    # A channel is "weak" when the bone cannot travel in the direction the
    # clips ask it to, because the bone lies close to the rotation axis. It is
    # reported, not corrected: the sign is still right, the motion is just
    # partly off-axis, and the honest fix is a better rest pose on the mesh
    # rather than a fudge factor here. The usual cause is a wing bone hanging
    # near-vertical, where "lift the tip" and "open the wing" are the same
    # motion — both stand-ins do this, because their wings are chibi arms.
    weak = [f"{name}.{label}={data[label][1]:.2f}"
            for name, data in CHANNELS.items()
            for label in ("x", "z")
            if data[label][1] < 0.45]
    if weak:
        print("  bones whose rest direction limits a channel (|cos| below 0.45; "
              "motion is partly off-axis, signs are still correct): "
              + ", ".join(weak))


def key(rig, name: str, frame: int, nod: float = 0.0, turn: float = 0.0,
        slide: float = None) -> None:
    """One keyframe, in the measured channels. Angles in degrees."""
    bone = rig.pose.bones.get(name)
    if bone is None:
        return
    signs = CHANNELS.get(name, {"x": (1.0, 1.0), "z": (1.0, 1.0)})
    bone.rotation_mode = "XYZ"
    # Always keyed, even when both angles are zero. Skipping the zero case is
    # tempting and wrong: a cycle whose value happens to be zero at the last
    # sample would then have no closing keyframe, and the curve would hold its
    # previous value across the loop seam.
    bone.rotation_euler = (math.radians(nod * signs["x"][0]), 0.0,
                           math.radians(turn * signs["z"][0]))
    bone.keyframe_insert("rotation_euler", frame=frame)
    if slide is not None:
        # Only ever used on `root`, which build_armature places vertically, so
        # the bone's local Y is world up.
        bone.location = (0.0, slide, 0.0)
        bone.keyframe_insert("location", frame=frame)


def leg_key(rig, name: str, frame: int, forward: float = 0.0, splay: float = 0.0) -> None:
    """Positive `forward` swings the foot towards the front of the bird."""
    key(rig, name, frame, nod=-forward, turn=splay)


def wing_key(rig, side: str, segment: str, frame: int,
             lift: float = 0.0, swing: float = 0.0) -> None:
    """Positive `lift` raises the tip; positive `swing` opens the wing."""
    name = f"wing_{segment}_{side}"
    bone = rig.pose.bones.get(name)
    if bone is None:
        return
    signs = CHANNELS.get(name, {"x": (1.0, 1.0), "z": (1.0, 1.0)})
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = (math.radians(lift * signs["x"][0]), 0.0,
                           math.radians(swing * signs["z"][0]))
    bone.keyframe_insert("rotation_euler", frame=frame)


def clear_pose(rig) -> None:
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0.0, 0.0, 0.0)
        bone.location = (0.0, 0.0, 0.0)


# ---------------------------------------------------------------------------
# The six clips
# ---------------------------------------------------------------------------

SIDES = ("l", "r")
SPINE_CHAIN = ("pelvis", "spine", "neck", "head", "tail_1", "tail_2")


def wing_gain(prop: dict) -> float:
    """Ambient wing amplitude. Folded wings shuffle; spread wings fly."""
    return FOLDED_WING_GAIN if prop["wings_folded"] else 1.0


def waddle_amount(prop: dict) -> float:
    """Short legs waddle, long legs stride — measured, not chosen per species.

    This is the one place the walk cycle changes shape between the four birds,
    and it is the right one: the side-to-side roll of a duck is a consequence
    of having to put its centre of mass over a foot that is barely below its
    body, and a hawk on long legs does not have that problem.
    """
    span = LONG_LEG_FRACTION - SHORT_LEG_FRACTION
    reach = (prop["leg_fraction"] - SHORT_LEG_FRACTION) / span
    reach = min(max(reach, 0.0), 1.0)
    return WADDLE_MIN + (WALK_WADDLE - WADDLE_MIN) * (1.0 - reach)


def author_idle(rig, frames: int, prop: dict) -> None:
    """A standing bird scanning its surroundings. See IDLE_HEAD_TURN above for
    why this is loud compared with the rest of the roster's idles."""
    gain = wing_gain(prop)
    height = prop["size"].z
    for frame in range(0, frames + 1, 4):
        t = frame / frames * 2 * math.pi
        # The scan: a slow sweep with one sharper look per cycle. sin(t) alone
        # reads as clockwork; the third harmonic gives it a beat.
        scan = 0.72 * math.sin(t) + 0.28 * math.sin(3 * t + 0.6)
        breathe = math.sin(2 * t)

        key(rig, "root", frame, slide=IDLE_BOB * height * breathe)
        key(rig, "pelvis", frame, turn=IDLE_PELVIS_TURN * math.sin(t + 0.9))
        key(rig, "spine", frame, nod=IDLE_SPINE_NOD * breathe)
        key(rig, "neck", frame,
            nod=IDLE_NECK_NOD * math.sin(2 * t + 0.4), turn=-IDLE_HEAD_TURN * 0.25 * scan)
        key(rig, "head", frame,
            nod=IDLE_HEAD_NOD * math.sin(3 * t + 1.1), turn=IDLE_HEAD_TURN * scan)
        key(rig, "tail_1", frame,
            nod=IDLE_TAIL_NOD * math.sin(t + 2.0), turn=IDLE_TAIL_TURN * math.sin(t + 0.3))
        key(rig, "tail_2", frame,
            nod=IDLE_TAIL_NOD * 0.7 * math.sin(t + 2.6), turn=IDLE_TAIL_TURN * 0.8 * math.sin(t + 0.9))

        for side in SIDES:
            phase = 0.0 if side == "l" else 0.5
            settle = IDLE_WING_SETTLE * max(0.0, math.sin(t - phase)) ** 3
            lift = gain * (IDLE_WING_LIFT * math.sin(2 * t + phase) + settle)
            wing_key(rig, side, "upper", frame, lift=lift, swing=gain * settle * 0.5)
            wing_key(rig, side, "fore", frame, lift=lift * 0.7)
            wing_key(rig, side, "tip", frame, lift=lift * 0.5)
        for side in SIDES:
            # A perched bird shifts its weight; the loaded leg straightens.
            shift = 2.5 * math.sin(t + (0.0 if side == "l" else math.pi))
            leg_key(rig, f"leg_upper_{side}", frame, forward=shift)
            leg_key(rig, f"leg_lower_{side}", frame, forward=-shift * 0.6)


def author_gait(rig, frames: int, prop: dict, swing: float, lean: float,
                bob: float, spine_nod: float, thrust: float, tail: float,
                wing: float, waddle: float) -> None:
    """A biped bird's gait: alternating legs, a waddle at step frequency, a
    body bob at twice it, and a fore/aft head bob.

    Deliberately not animate_quadruped's cycle. That one puts diagonal leg
    pairs on opposite phases and rolls a long spine; a bird has one pair of
    legs under a rigid trunk, and everything that makes a walking bird
    recognisable happens above the hips: the head thrust, the tail counter-
    sway, the roll onto each foot. Copying the quadruped gives a creature
    that shuffles its feet while its body slides — which is the exact
    complaint HANDOFF.md §6 records.
    """
    gain = wing_gain(prop)
    height = prop["size"].z
    step = max(2, frames // 10)
    frame_list = list(range(0, frames + 1, step))
    if frame_list[-1] != frames:
        frame_list.append(frames)

    for frame in frame_list:
        t = frame / frames * 2 * math.pi
        for side in SIDES:
            phase = 0.0 if side == "l" else math.pi
            hip = swing * math.sin(t + phase)
            # The tibiotarsus tucks on the recovery stroke so the foot clears
            # the ground; it does not fold on the stance stroke, which is what
            # separates a gait from a pair of pendulums.
            tuck = -swing * 0.55 * max(0.0, math.sin(t + phase - math.pi / 2))
            # The toes stay near level through the whole cycle. A bird's foot
            # is a flat plate and reads badly if it points where the shin does.
            ankle = -(hip + tuck) * 0.55
            leg_key(rig, f"leg_upper_{side}", frame, forward=hip)
            leg_key(rig, f"leg_lower_{side}", frame, forward=tuck)
            leg_key(rig, f"foot_{side}", frame, forward=ankle)

        key(rig, "root", frame,
            nod=lean * 0.35,
            turn=waddle * math.sin(t),                    # the waddle, 1x step
            slide=bob * height * math.sin(2 * t))         # the bob, 2x step
        key(rig, "pelvis", frame,
            nod=lean * 0.4 + spine_nod * 0.5 * math.sin(2 * t),
            turn=-waddle * 0.4 * math.sin(t))
        key(rig, "spine", frame, nod=lean * 0.6 + spine_nod * math.sin(2 * t + 0.5))
        # Head bob: the neck extends and retracts once per step and the head
        # counter-rotates to stay aimed level. With rotation only this is an
        # approximation of the fore/aft translation a real bird uses, and it
        # is the single most bird-like thing in the clip.
        key(rig, "neck", frame,
            nod=thrust * math.sin(t) - lean * 0.7,
            turn=-waddle * 0.5 * math.sin(t))
        key(rig, "head", frame,
            nod=-thrust * 0.75 * math.sin(t) - lean * 0.4,
            turn=waddle * 0.3 * math.sin(t))
        key(rig, "tail_1", frame,
            nod=tail * 0.6 * math.sin(2 * t), turn=-tail * math.sin(t))
        key(rig, "tail_2", frame,
            nod=tail * 0.4 * math.sin(2 * t + 0.6), turn=-tail * 0.8 * math.sin(t + 0.5))

        for side in SIDES:
            # The wings counterbalance the legs, so they lead the leg on the
            # same side by half a cycle.
            phase = math.pi if side == "l" else 0.0
            lift = gain * wing * math.sin(t + phase)
            open_bias = gain * wing * 0.45 if wing > 15.0 else 0.0
            wing_key(rig, side, "upper", frame, lift=lift, swing=open_bias)
            wing_key(rig, side, "fore", frame, lift=lift * 0.8, swing=open_bias * 0.7)
            wing_key(rig, side, "tip", frame, lift=lift * 0.6, swing=open_bias * 0.5)


def author_attack(rig, frames: int, prop: dict) -> None:
    """Flare, then drive the beak forward.

    One shape for all four birds, because it is the one all four share: a
    threatened or attacking bird throws its wings open and its head back, then
    stabs. It reads as a bill jab on Reedwing, a talon strike on Galecrest and
    a peck on Pipwing without any of them needing their own clip.

    The wing flare ignores FOLDED_WING_GAIN on purpose — a folded wing opening
    is a bigger silhouette change than a spread wing sweeping, and the flare
    is the whole point of the pose.
    """
    flare = 34.0 if prop["wings_folded"] else 26.0
    hold = 8      # anticipation peak
    strike = 13   # contact
    settle = min(frames - 2, 17)

    for name in SPINE_CHAIN + ("root",):
        key(rig, name, 0, nod=0.0, turn=0.0)
    for side in SIDES:
        for segment in ("upper", "fore", "tip"):
            wing_key(rig, side, segment, 0)
        leg_key(rig, f"leg_upper_{side}", 0)

    # Anticipation: sit back, neck coiled, wings thrown open and up.
    key(rig, "root", hold, nod=-9.0)
    key(rig, "pelvis", hold, nod=-13.0)
    key(rig, "spine", hold, nod=-15.0)
    key(rig, "neck", hold, nod=-22.0)
    key(rig, "head", hold, nod=-14.0)
    key(rig, "tail_1", hold, nod=-16.0)
    for side in SIDES:
        wing_key(rig, side, "upper", hold, lift=flare, swing=flare * 1.5)
        wing_key(rig, side, "fore", hold, lift=flare * 0.7, swing=flare * 1.2)
        wing_key(rig, side, "tip", hold, lift=flare * 0.5, swing=flare * 0.9)
        leg_key(rig, f"leg_upper_{side}", hold, forward=-10.0)

    # Strike: a third of the time the wind-up took. Beak leads, wings sweep
    # down and forward, body drives over the feet.
    key(rig, "root", strike, nod=11.0)
    key(rig, "pelvis", strike, nod=14.0)
    key(rig, "spine", strike, nod=20.0)
    key(rig, "neck", strike, nod=26.0)
    key(rig, "head", strike, nod=18.0)
    key(rig, "tail_1", strike, nod=14.0)
    for side in SIDES:
        wing_key(rig, side, "upper", strike, lift=-flare * 0.8, swing=flare * 0.5)
        wing_key(rig, side, "fore", strike, lift=-flare * 0.6, swing=flare * 0.4)
        wing_key(rig, side, "tip", strike, lift=-flare * 0.4, swing=flare * 0.3)
        leg_key(rig, f"leg_upper_{side}", strike, forward=14.0)

    key(rig, "spine", settle, nod=6.0)
    key(rig, "neck", settle, nod=8.0)

    for name in SPINE_CHAIN + ("root",):
        key(rig, name, frames, nod=0.0, turn=0.0)
    for side in SIDES:
        for segment in ("upper", "fore", "tip"):
            wing_key(rig, side, segment, frames)
        leg_key(rig, f"leg_upper_{side}", frames)


def author_hit(rig, frames: int, prop: dict) -> None:
    """Startle. Birds do not absorb a hit, they flinch and half-open."""
    flare = 24.0
    for name in SPINE_CHAIN + ("root",):
        key(rig, name, 0, nod=0.0, turn=0.0)
    for side in SIDES:
        for segment in ("upper", "fore", "tip"):
            wing_key(rig, side, segment, 0)

    key(rig, "root", 3, nod=-7.0, turn=4.0)
    key(rig, "pelvis", 3, nod=-9.0, turn=5.0)
    key(rig, "spine", 3, nod=-14.0, turn=6.0)
    key(rig, "neck", 3, nod=-20.0, turn=8.0)
    key(rig, "head", 3, nod=-22.0, turn=10.0)
    key(rig, "tail_1", 3, nod=-14.0, turn=-8.0)
    for side in SIDES:
        wing_key(rig, side, "upper", 3, lift=flare, swing=flare * 0.8)
        wing_key(rig, side, "fore", 3, lift=flare * 0.7, swing=flare * 0.6)
        wing_key(rig, side, "tip", 3, lift=flare * 0.5, swing=flare * 0.4)

    for name in SPINE_CHAIN + ("root",):
        key(rig, name, frames, nod=0.0, turn=0.0)
    for side in SIDES:
        for segment in ("upper", "fore", "tip"):
            wing_key(rig, side, segment, frames)


def author_faint(rig, frames: int, prop: dict) -> None:
    """Legs give way, body sinks, then topples sideways with the wings sprawled.

    The topple is on `root`'s turn channel, which measure_channels resolved to
    a rotation about world +Z... no: to the channel whose tip motion follows
    `Z x (tail - head)`, and root is vertical, so that channel leans the whole
    body sideways. Doing this by hand as a Y-euler is what makes
    animate_quadruped's faint spin on the spot instead of falling over.
    """
    ## The end pose is tuned so the head finishes NEAR THE GROUND, not through
    ## it. Every term here lowers the head — the topple, the sink on the root,
    ## and the neck and spine drooping forward — and the first version stacked
    ## them to 1.00 m of drop on a 0.87 m creature, which buries the head 20 cm
    ## under the floor. Measured on all three test meshes after retuning, the
    ## head lands within a tenth of a body height of z = 0.
    height = prop["size"].z
    key(rig, "root", 0, nod=0.0, turn=0.0, slide=0.0)
    key(rig, "root", 12, nod=4.0, turn=-20.0, slide=-0.03 * height)
    key(rig, "root", frames, nod=6.0, turn=-70.0, slide=-0.09 * height)

    key(rig, "pelvis", 0, nod=0.0)
    key(rig, "pelvis", frames, nod=9.0)
    key(rig, "spine", 8, nod=-8.0)
    key(rig, "spine", frames, nod=7.0)
    key(rig, "neck", 8, nod=-12.0)
    key(rig, "neck", frames, nod=16.0)
    key(rig, "head", 8, nod=-10.0)
    key(rig, "head", frames, nod=12.0, turn=-14.0)
    key(rig, "tail_1", frames, nod=12.0, turn=10.0)
    key(rig, "tail_2", frames, nod=8.0, turn=14.0)

    for side in SIDES:
        leg_key(rig, f"leg_upper_{side}", 0)
        leg_key(rig, f"leg_upper_{side}", frames, forward=32.0, splay=8.0)
        leg_key(rig, f"leg_lower_{side}", frames, forward=-48.0)
        leg_key(rig, f"foot_{side}", frames, forward=22.0)

        # The body falls towards -x, so the LEFT wing ends up underneath it and
        # the right wing on top. Splaying both equally is what a symmetric
        # authoring gives you and it drives the down-side wing tip nearly a
        # metre through the floor on Galewisp — measured. The buried wing tucks
        # in; only the free one sprawls.
        buried = side == "l"
        end_lift = 4.0 if buried else -16.0
        end_swing = -12.0 if buried else 30.0
        for segment, scale in (("upper", 1.0), ("fore", 0.8), ("tip", 0.6)):
            wing_key(rig, side, segment, 0)
            wing_key(rig, side, segment, 14,
                     lift=14.0 * scale, swing=(0.0 if buried else 22.0) * scale)
            wing_key(rig, side, segment, frames,
                     lift=end_lift * scale, swing=end_swing * scale)


AUTHORS = {
    "idle": author_idle,
    "attack": author_attack,
    "hit": author_hit,
    "faint": author_faint,
}


# ---------------------------------------------------------------------------
# Baking, loop flags and measurement
# ---------------------------------------------------------------------------

def close_loop(action) -> list[str]:
    """Force a looping action's last keyframe to equal its first.

    Every cycle here is built from functions of t = frame/frames * 2*pi, so
    the ends already match to floating point. This runs anyway, and reports
    how many curves it had to correct, because that count is a self-check on
    the authoring: anything non-zero means a clip picked up a term that is not
    periodic and would pop once per loop.
    """
    corrected = []
    for curve in action.fcurves:
        points = curve.keyframe_points
        if len(points) < 2:
            continue
        first, last = points[0], points[-1]
        if abs(first.co[1] - last.co[1]) > 1e-5:
            last.co[1] = first.co[1]
            last.handle_left[1] = first.co[1]
            last.handle_right[1] = first.co[1]
            parts = curve.data_path.split('"')
            bone = parts[1] if len(parts) > 1 else curve.data_path
            corrected.append(f"{bone}[{curve.array_index}]")
    if corrected:
        action.fcurves.update()
    return corrected


def set_loop_flag(action, looping: bool) -> None:
    """Mark the action as cyclic.

    Honest note on what this does and does not achieve. glTF has no loop flag;
    Godot's importer only infers one from a clip name ending in `-loop`, and
    these clips cannot use that suffix because data/pals/species.json maps
    roles to clip names by exact string. pal_animator.gd therefore sets
    `loop_mode` at runtime, which HANDOFF.md §6 already confirms is happening.

    So the flag that survives to the game is not a bit in the file, it is the
    property that makes the runtime flag look right: the first and last poses
    of a looping clip must be the same pose, or LOOP_LINEAR interpolates from
    one to the other and the creature jerks once per cycle. close_loop()
    guarantees that. `use_cyclic` below is for anyone who opens the .blend or
    re-imports the GLB in Blender, where the flag is real.
    """
    if hasattr(action, "use_cyclic"):
        action.use_cyclic = looping
    if not looping:
        # A one-shot must hold its final pose while pal_animator's `_hold`
        # timer runs out; constant extrapolation is what does that.
        for curve in action.fcurves:
            curve.extrapolation = "CONSTANT"


def motion_metric(rig, action, frames: int) -> float:
    """Peak total distance, in metres, that the bone tips travel from rest.

    Defined here so it can be quoted: sample the clip every two frames, and at
    each sample sum the world-space displacement of every bone's tip from its
    rest position; the metric is the largest such sum. It is a proxy for "how
    much of the creature moves", and it exists because HANDOFF.md §6's best
    lead on the combat animation bug is a single pair of numbers of roughly
    this kind (Terrapup: 0.088 idle against 1.53 walk) and there was no way to
    reproduce them without a definition.
    """
    scene = bpy.context.scene
    # Mute the strips stashed by earlier clips. Without this the NLA stack
    # keeps posing every bone the clip under test does not touch — `hit` never
    # keys the legs, so it was being measured with `run`'s legs underneath it —
    # and the "rest" baseline is not rest either. Both make the numbers larger
    # than the clip, which is the one direction this measurement must not err.
    tracks = list(rig.animation_data.nla_tracks)
    muted = [track.mute for track in tracks]
    for track in tracks:
        track.mute = True

    previous = rig.animation_data.action
    rig.animation_data.action = None
    clear_pose(rig)
    bpy.context.view_layer.update()
    rest = {b.name: (rig.matrix_world @ b.tail).copy() for b in rig.pose.bones}

    rig.animation_data.action = action
    peak = 0.0
    for frame in range(0, frames + 1, 2):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        total = sum(((rig.matrix_world @ b.tail) - rest[b.name]).length
                    for b in rig.pose.bones)
        peak = max(peak, total)
    scene.frame_set(0)
    rig.animation_data.action = previous
    for track, was in zip(tracks, muted):
        track.mute = was
    clear_pose(rig)
    bpy.context.view_layer.update()
    return peak


def author_all(rig, prop: dict) -> dict:
    """The six clips, stashed as NLA strips so the exporter writes all of them."""
    rig.animation_data_create()
    metrics = {}
    for name, (frames, looping) in CLIPS.items():
        clear_pose(rig)
        action = bpy.data.actions.new(name)
        rig.animation_data.action = action

        if name == "walk":
            author_gait(rig, frames, prop, swing=WALK_SWING, lean=WALK_LEAN,
                        bob=WALK_BOB, spine_nod=WALK_SPINE_NOD,
                        thrust=WALK_HEAD_THRUST, tail=WALK_TAIL, wing=WALK_WING,
                        waddle=waddle_amount(prop))
        elif name == "run":
            author_gait(rig, frames, prop, swing=RUN_SWING, lean=RUN_LEAN,
                        bob=RUN_BOB, spine_nod=RUN_SPINE_NOD,
                        thrust=RUN_HEAD_THRUST, tail=RUN_TAIL, wing=RUN_WING,
                        waddle=waddle_amount(prop) * 0.35)
        else:
            AUTHORS[name](rig, frames, prop)

        corrected = close_loop(action) if looping else []
        set_loop_flag(action, looping)
        metrics[name] = round(motion_metric(rig, action, frames), 4)

        action.use_fake_user = True
        rig.animation_data.action = None
        track = rig.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, 1, action)
        print(f"  {name}: {frames} frames, {len(action.fcurves)} curves, "
              f"motion {metrics[name]:.3f}"
              + ("" if looping else ", one-shot"))
        if corrected:
            print(f"    NOT PERIODIC, forced closed: {', '.join(corrected[:6])}"
                  + (" ..." if len(corrected) > 6 else ""))
    clear_pose(rig)
    return metrics


# ---------------------------------------------------------------------------

def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... rig_bird.py -- <model.glb> --out <rigged.glb> "
                         "[--report r.json] [--rig-only]")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("rigged.glb"))).resolve()
    report_path = option(args, "--report")
    rig_only = "--rig-only" in args

    load(model)
    drop_import_artifacts()
    purge_incoming_animation()
    body = join_normalise_weld()
    prop = measure(body)

    if not prop["crotch_measured"]:
        print(f"  LEG LENGTH NOT MEASURABLE — the two legs never separate into two "
              f"columns for long enough to believe. Hip height fell back to "
              f"{FALLBACK_LEG_FRACTION:.0%} of the model; check the rig before "
              f"animating, and lower CROTCH_MIN_GAP if the legs are simply close "
              f"together.")
    if not prop["neck_measured"]:
        print("  no neck pinch found (round-bodied bird) — head bone placed at "
              f"{NECK_FALLBACK:.0%} of the torso instead")
    print(f"  legs {prop['leg_fraction']:.0%} of height, "
          f"wingspan {prop['spread_ratio']:.2f}x torso width -> "
          f"{'FOLDED' if prop['wings_folded'] else 'SPREAD'} wings, "
          f"waddle {waddle_amount(prop):.1f} deg")

    rig = build_armature(body, prop)
    skin(body, rig)
    strip_scene(body, rig)
    measure_channels(rig, prop["wings_folded"])

    metrics = {}
    if not rig_only:
        bpy.context.scene.render.fps = FPS
        metrics = author_all(rig, prop)

    report = weight_report(body)
    report["bones"] = [b.name for b in rig.data.bones]
    report["proportions"] = {
        "height_m": round(prop["size"].z, 4),
        "leg_fraction": round(prop["leg_fraction"], 4),
        "leg_length_m": round(prop["leg_length"], 4),
        "crotch_measured": prop["crotch_measured"],
        "neck_measured": prop["neck_measured"],
        "torso_half_width_m": round(prop["torso_half"], 4),
        "wingspan_over_torso": round(prop["spread_ratio"], 3),
        "wings_folded": prop["wings_folded"],
        "waddle_deg": round(waddle_amount(prop), 2),
    }
    # Landmark heights as fractions of the model, which is the form in which a
    # wrong one is obvious: a neck at 0.35 or a shoulder above the head is a
    # mesh this script has misread, and no amount of clean weighting saves it.
    height = max(prop["size"].z, 1e-6)
    base = prop["low"].z
    report["landmarks_of_height"] = {
        "crotch": round((prop["crotch_z"] - base) / height, 3),
        "shoulder": round((prop["shoulder_z"] - base) / height, 3),
        "neck": round((prop["neck_z"] - base) / height, 3),
        "head_centre": round((prop["head_centre"].z - base) / height, 3),
        "beak_forward_of_hips": round((prop["hip_y"] - prop["beak"].y) / height, 3),
        "tail_behind_hips": round((prop["tail_end_y"] - prop["hip_y"]) / height, 3),
    }
    report["clip_motion_peak_m"] = metrics
    report["channel_quality"] = {
        name: {label: round(data[label][1], 3) for label in ("x", "z")}
        for name, data in CHANNELS.items()
    }

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(out), export_format="GLB", use_selection=True,
        export_skins=True, export_animations=True,
        export_animation_mode="NLA_TRACKS", export_yup=True)
    if report_path:
        pathlib.Path(report_path).write_text(json.dumps(report, indent=2))

    bad = report["unweighted_vertices"]
    print(f"\nrigged {model.name} -> {out.name}")
    print(f"  {len(report['bones'])} bones, {report['total_vertices']} vertices, "
          f"{bad} unweighted")
    if metrics:
        idle, walk = metrics.get("idle", 0.0), metrics.get("walk", 0.0)
        ratio = idle / walk if walk else 0.0
        print(f"  idle motion {idle:.3f} against walk {walk:.3f} — {ratio:.0%}. "
              f"Terrapup's is 6% and reads as frozen (HANDOFF.md 6).")
        if ratio < 0.25:
            print("  IDLE IS TOO SUBTLE — raise the IDLE_* amplitudes before shipping.")
    if bad:
        print("  UNWEIGHTED VERTICES PRESENT — these will tear in animation. "
              "Inspect before using.")


if __name__ == "__main__":
    main()
