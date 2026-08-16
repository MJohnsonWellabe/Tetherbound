# D50 — The Meadows is a long narrow corridor, and the walk is forty minutes

**Date:** 2026-08-16 · **Decided by:** `OW5A`, against the owner's directive of
the same day, `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5, and
`docs/MEADOWS_PROGRESSION_SPEC.md` §3

**Model note:** `OW5` is tagged `model: fable` and §5 says "START WITH FABLE".
The owner has directed that fable-tagged items run at **opus** for now because
he has no Fable usage left. This ran at opus. It did not run at its tagged tier.

## The decision

The Meadows is **8192 m long × 1536 m wide** — `region_size` 256,
`vertex_spacing` 2.0, so 512 m per region, **16 × 3 = 48 regions**. Bounds
`x ∈ [−768, +768]`, `z ∈ [−512, +7680]`; the long axis is +Z, running south,
away from Grandpa's house.

The trail through it is **11,594 m**, which is **38.6 minutes** of walking at
`movement.json` `walk_speed` 5.0 and **3.86 in-game days** at `art.json`
`day_length_seconds` 600. Camping on the way is forced.

The full layout is `docs/MEADOWS_MACRO_LAYOUT.md`. This decision records the
footprint, the target and what they cost.

## What the owner asked for

The `OW5` backlog entry said "the whole area should be a big square". He
superseded that in conversation on 2026-08-16:

> the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square… like maybe
> it's five minutes of walking from side to side.

> a day from midnight to midnight should take about 10 minutes. a walk from the
> end of the meadows to the other end should take 40 minutes.

40 min × 5.0 m/s = 12,000 m of trail. 5 min × 5.0 m/s = 1,500 m of width,
rounded up to 1,536 = three whole regions.

## Why 8192 m of corridor and not 6144

6144 m was the starting proposal and it was tested rather than accepted. 12,000
m of trail over 6144 m of corridor is **tortuosity 1.95** — the trail has to
swing roughly ±500 m every 600 m of advance, which consumes the entire width.
The width would stop being "off the path in either direction" and become the
path.

8192 m gives **tortuosity 1.53**, and the authored spine's x range is
**−430 … +450**, leaving over 300 m of genuinely off-trail land on both flanks
for the whole length. That is the difference between the owner's directive
being implemented and being approximated.

## Why 2.0 m vertex spacing is safe, which was not obvious

`vertex_spacing` 2.0 halves the heightfield's resolution, and every blocker on
this map is a `_carve_depth` trench whose *walls* are the blocker. Two limits,
both already tested: the player's `floor_max_angle` is 45°, but
`riding_controller._apply_climb_limit` raises the ridden legendary's body to
**60°**, and `smoke_riding` / `smoke_boss` assert the spoke walls stay above
that. 60° is the number that matters, not 45.

`tools/_probe_corridor_footprint.gd` builds the piecewise-bilinear surface
Terrain3D actually reconstructs at each candidate spacing and walks transects
over *that*, rather than reading the analytic field — the field would report the
angle the config asks for, which was never in doubt.

Measured: **going from 1.0 m to 2.0 m costs 1–2 degrees of wall.** Steepest
angles drop from 70.6–81.5° to 69.5–80.3°. Every carve stays 15° or more past
the ridden limit, including the mill narrows whose `rim` is 3.4 m and therefore
under two samples wide. The carves survive; the footprint does not have to fight
them.

The condition attached: at 2.0 m spacing keep every carve's `rim` at
**≥ 2 × vertex_spacing**. Today's narrows at 3.4 m is the only one below that
and should go to 4.0 m when it is re-sited.

## What it costs

- **The bake.** Measured at **2584 µs/pixel** across both of
  `build_playground_terrain.gd`'s passes, validated against the known 512 m
  figure (262,144 px → 11.3 min, which is the repo's "12 min" and not its
  "5.5"). 48 regions is 4096 × 768 = 3,145,728 px → **~135 minutes** of one-shot
  offline bake. 6144 m would have been 102. Both are overnight work; neither is
  a reason to choose a shape.
- **Land to keep dense.** 12.58 km² against today's 0.262 km² — **48×**. This is
  the real price, and §5's rule ("only as large as the team can make
  meaningfully dense") is the thing most likely to be violated. The layout
  answers it with a budget: one authored beat every 150–250 m of spine, no
  segment over 250 m without one, checkable from data.
- **Two systems that must be rebuilt before this can land.** The scatter builds
  ~28,790 MultiMesh instances at load today; 48× is ~1.38 million, in GDScript,
  during the load screen. And `collision_mode` is FULL_GAME, building real
  collision across the entire terrain at startup. Both are covered in
  `MEADOWS_MACRO_LAYOUT.md` §8, and **streaming the scatter is a hard
  prerequisite** — a child item ahead of the trail work, not after it.

## What was rejected

- **A big square**, per the backlog's original wording. Superseded by the owner
  directly. A 12 km square is 144 km² and could not be made dense by anyone.
- **6144 × 1536**, the starting proposal. Tortuosity 1.95 (above).
- **`vertex_spacing` 1.0 at corridor scale.** 12,582,912 pixels → **542 minutes**
  of bake, four times the resolution nothing needed, for 1–2 degrees of carve
  wall that the measurement says is not needed either.
- **Moving the village to centre the world.** The bake currently centres its
  images on the world origin, which made re-centring look free. It is not:
  §0.6 says relocate shipped work rather than reconstruct it, and the cheapest
  relocation is none. Band 0 and the whole shipped village keep their exact
  current coordinates; the bake grows an authored two-axis extent instead.

## What this supersedes

`docs/decisions/D46` on its central claim. D46 decided the river divides the map
and that this costs one severed spoke — the storm road — because the 512 m disc
was *demonstrably full*: every bearing searched at 1°, every offset at 2.5 m,
and the best compliant chord left a far side 17 m deep. That reasoning was
correct and it was about the disc. In a 1,536 m-wide corridor a river crossing
the width divides the map completely and trivially, with a far side 3,400 m
deep and no search to run. **The storm road is recovered; all seven spokes
stand.** What D46 got right and is kept: the river is a river and not a dry
gorge, the crossing sits on a road at narrows where a mill and a bridge would
actually stand, and the dry upper gorge is a legitimate landform rather than an
accident.

## The honest remainder

The trail measures 11,594 m, not 12,000 — **38.6 minutes, not 40**. The
difference is 3.5%, it is in the authored waypoints rather than in the
footprint, and it can be closed by any of the loops in §3.2 becoming part of
the spine. It is recorded rather than rounded because the next person to
lengthen a band should know how much slack there is.

Two numbers in the load-time recommendation are **reasoned, not measured**: the
512 m dynamic collision radius (from `sprint_speed` 8.6, giving 59 seconds of
runway) and the claim that hoisting `playground_heightfield.gd`'s per-call
`_config.get(...)` lookups would meaningfully cut the bake. Both are `OW5B`'s to
measure before relying on.
