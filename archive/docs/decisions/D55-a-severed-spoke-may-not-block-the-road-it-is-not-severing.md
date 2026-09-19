# D55 — A severed spoke may not block the road it is not severing, and authored routes get surveyed before they are walked

**Date:** 2026-08-17 · **Decided by:** `SPINE-WEDGE`, against
`OW5-walk`'s corridor measurements, `docs/decisions/D50` §4–5 and
`docs/CURRENT_STATE.md`'s `OW5C`/`OF15` slope constraint

## What was asked, and what turned out to be true

`OW5-walk` walked the corridor's 11,316.6 m spine with a real body for the
first time and reported six places it stopped. Four were handed to this item as
**terrain wedges**, each named `Terrain` with a contact normal of 4.6–17° from
up — angles well inside the player's 45° `floor_max_angle`, which is what made
them read as one strange terrain defect worth chasing to a single mechanism.

Two of the four are not terrain at all, and a third is not a wedge.

| site | trail lost | what `OW5-walk` reported | what it is |
|---|---|---|---|
| stronghold gate approach (−34, 7513) | 57.6 m | `Terrain`, 12–17°, `on_floor=false`, **zero colliders** | the `storm_road` spoke's collapsed-bridge **carve**, and its `CarveFailsafe` teleporting the body back to the road's end, six times |
| South Bridge (5.5, −13.0, 1333.7) | 26.9 m | `Terrain`, 16° | the crossing gully's **75.9° wall** — the third collision in the same list, which was reported and not read |
| (336.3, 5.7, 3749.8) | 17.0 m | `Terrain`, **4.6°, nearly flat** | `TetherRelay/Compound/@StaticBody3D@1679`, a **90° wall** |
| (−417.0, −3.1, 2465.9) | 5.1 m | `Terrain`, 11.6° | `BurrowWarrens/@StaticBody3D@3323`, a **90° wall** |

They were not one defect. They were **two**, plus a measurement error that made
all four look like the same one.

## The measurement error, because it will happen again

`get_slide_collision()` on a body that has **already come to rest** names the
floor, not the wall.

`move_and_slide()` reports the collisions it encountered *during that frame's
motion*. A body pressed flat against a wall has no motion left: after a few
frames the wall stops appearing in the list, and the only contact still being
generated is the ground under the capsule. Three of these four sites reported a
walkable-angle `Terrain` normal for exactly that reason. The 4.6° one — the site
that most suggested a subtle terrain bug, because nothing should stop a body on
nearly flat ground — was a body standing on flat ground with its nose against a
relay wall.

`WALL1`'s technique is right and this does not retract it: **name the collider,
never trust `is_on_wall()`'s boolean.** What has to change is the query. On a
stopped body, ask the physics server what is in the way:

```gdscript
var sweep := PhysicsTestMotionParameters3D.new()
sweep.from = player.global_transform
sweep.motion = heading * 0.5
sweep.max_collisions = 4
PhysicsServer3D.body_test_motion(player.get_rid(), sweep, out)
```

That named the relay in one run and the warrens in the next. It is now part of
`tools/_probe_ow5_walk.gd`'s wedge report, alongside the capsule's own overlap
set, the areas it is standing in, the input vector still being fed to it, and a
per-frame trace (`--trace=N`).

The same report also disposes of the stronghold's `on_floor=false` with **zero
colliders**, which read as the strangest symptom of the four. The trace shows
what it actually was:

```
3182   -21.16   -9.03  7527.93   vy -15.46   .  .  0 -      <- falling into the trench
3183   -33.99   -1.35  7513.46   step 19.343 .  .  0 -      <- teleported to the road end
[severed_spokes] player went over the edge at -21, -9, 7528 -- back to the road
```

The 90-frame wedge window expired three frames after a `CarveFailsafe`
recovery, with the body still 1.35 m above the ground it had been put back on.
Zero colliders because it was in mid-air, and mid-air because the world had just
moved it. Nothing was missing.

## Decision 1 — `storm_road`'s carve is shortened to 20/10

`spokes.routes[storm_road].blocker.carve` was `half_length` 55 + `end_fade` 18:
a **73 m reach each way, a 146 m trench laid across the corridor to sever a 3 m
road** (`paths.width`). The spine's own last leg, wp75 (20, 7480) → wp76
(0, 7560), crosses it at |u| 37.6–41.8 m — full 11 m depth, 65.6° walls. The
trench carries `failsafe: true`, so a body walking the authored trail fell in,
was returned to `road[4]` at (−33.99, 7513.46), walked back toward the gate and
fell in again. Six recoveries, 142 m of world-driven displacement, and the last
57.6 m of the corridor unwalkable.

It is now **`half_length` 20 + `end_fade` 10**, a 30 m reach.

- The road is still cut. Its own bearing, continued past `road[4]`, meets the
  trench at |u| ≈ 1.2 m — full depth. The blocker still blocks the thing it
  exists to block.
- **`depth` and `rim` are untouched**, so the wall stays at D50 §4–5's 65.6°,
  which is what `tests/smoke_riding.gd` asserts and what D50 analysed. This
  edit changes what the carve **cuts**, never how steep it is.
- The spine now passes 7.6 m clear of the zero-depth contour at its closest
  approach.
- It is the same edit `river_gorge` already took, for the same reason and in the
  same file: that carve's own `_comment_length` records 70/22 cut to 26/14
  because a 92 m reach was gouging the pond basin. A 40 m reach is the shipped
  precedent for a spoke blocker; 30 m is in family.

Only regions `(−1, 14)` and `(0, 14)` were re-baked — the whole of this carve's
footprint, and 2 of 64 regions, at ~143 s each rather than a 153-minute full
bake.

**Measured, both ways, by walking it** (`tools/_probe_ow5_walk.gd --mode=spine
--z_from=7350 --z_to=7600`):

| | before | after |
|---|---|---|
| trail lost at this site | **57.6 m** | **0 m** |
| `CarveFailsafe` recoveries | 6 | **0** |
| moved by the world | 142.0 m | **0.0 m** |
| body reaches | (−34.0, 7513.5) | **(3.0, 7548.4)**, 45.6 m further |

**Honest residual.** The body now walks to 12.0 m short of wp76 and stops
against `Stronghold/@StaticBody3D@3555` — the stronghold's own outer wall. That
is the *other* defect (below), not this one. And a player who leaves the trail
near the gate can still fall into the shortened trench and be recovered to the
storm road's end, from which a straight line to the gate re-enters it at
|u| ≈ 15.7 m. The trail no longer goes there; a player walking into a visible
ravine twice is the failsafe working, not a trap.

## Decision 2 — the invariant asserted in CI is narrow, and the survey is a tool

The second defect is that **the spine's waypoints were authored as the
coordinates of the things they lead to**, and the legs between them were never
surveyed against anything. `trail`'s own comment says so: *"Coordinates are the
layout's own authored intent, not yet surveyed against `height_at` — `OW5C`'s
own job, before content, is to probe every metre of this for slope beyond the
player's `floor_max_angle` before it is treated as final."* `docs/CURRENT_STATE.md`
states the same constraint as something `OW5C` inherited from `OF15`. It was
never done.

The result is that wp19 is the South Bridge carve's centre, wp30 is the Burrow
Warrens' site coordinate, wp42 is the Tether Relay's station coordinate, and
wp76 is inside the stronghold's wall. Fourteen trailhead signposts and four
named trainers stand on the trail for the same reason — the marker is placed at
the coordinate that is also the waypoint.

That is a trail-routing problem, it is `SPINE-LAYOUT`'s, and a CI test that
asserted "no authored route touches anything" would be red on 66
route/collider pairs on the day it landed. So the split is:

**Asserted in `tests/smoke_traversal.gd`, absolutely, with no exceptions:**
a severed spoke's blocker carve may not touch any authored route. A blocker
sized to sever one 3 m road has no business anywhere near another. This is
exact rather than sampled — Liang–Barsky clipping of each route segment against
each carve's rotated footprint, a few hundred microseconds for every route
against every carve, no world and no heightfield. It is green on this branch and
**verified failable**: restoring 55/18 makes it report `storm_road x spine
seg75`.

`crossings[]` carves are deliberately not asserted. A crossing exists to be
crossed, on its bridge, so a route through one is right when it is on the deck
and wrong when it is not; the one place that is currently wrong is printed as a
NOTE naming the offset (the spine enters the South Bridge gully 8.4 m off
the crossing's own road) rather than failed.

**Two tools, for authoring, not for CI:**

- `tools/_probe_spine_slope.gd` — every authored route against the analytic
  landform, naming the feature responsible for each unwalkable run. **No bake and
  no world**: `height_at` is a pure function of the config, which is what makes
  surveying a route before baking it possible at all. It found 12 unwalkable
  runs across the spine, the loops and the shortcuts in eight seconds.
- `tools/_probe_ow5_walk.gd --mode=clear` — the player's own capsule stood at
  every 2 m of every authored route, naming every structure it does not fit
  past. One boot, ~13 km, the full catalogue.

On sampling the heightfield at all: `_probe_ow5_walk.gd`'s header records that
three investigations of the phantom wall died doing exactly that, and it is
right. The distinction is that **diagnosing a stopped body is a physics
question** — an analytic height does not know what `move_and_slide` will do —
while **asserting that an authored route does not cross authored terrain is a
config question**, and the config is the only thing that can answer it. The
slope probe never decides whether a body passed; the walk does, and every claim
above was measured by walking.

## What this does not decide

- **The trail is not re-shaped.** Nothing under `trail` was touched.
- **The South Bridge approach, the Burrow Warrens, the Tether Relay, the
  stronghold wall, the signposts on the centreline and the trainers on the
  trail** are all one item and it is `SPINE-LAYOUT`'s. The full catalogue is in
  `ralph/NOTES.md` and is reproducible with `--mode=clear`.
- **The Old Mill Crossing** is `RIVER-GATE`'s and needs an owner decision, as
  `OW5-walk` said.
- **Whether `rock_form`'s terrace risers belong on an 8 m rise.** The spine
  crosses `rises.peaks[-380, 2488]` (radius 30, height 8 — a mound built by
  `OW5E` to roof the Burrow Warrens) at 68°, which an average slope of 15°
  cannot produce; the ribs and bedding planes authored for the 46 m rock
  hillsides are making sub-metre walls on a grassy mound. Recorded, not changed.
