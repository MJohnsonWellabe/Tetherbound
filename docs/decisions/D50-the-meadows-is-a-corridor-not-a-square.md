# D50 — The Meadows is a long narrow corridor, and the walk is forty minutes

**Date:** 2026-08-16 · **Decided by:** `OW5A`, against the owner's directive of
the same day, `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5, and
`docs/MEADOWS_PROGRESSION_SPEC.md` §3

**Model note:** `OW5` is tagged `model: fable` and §5 says "START WITH FABLE".
The owner has directed that fable-tagged items run at **opus** for now because
he has no Fable usage left. This ran at opus. It did not run at its tagged tier.

**Revised 2026-08-16 (second commit on `ralph/OW5A`), after a blind review.**
The first version of this decision specified a footprint that **was not
region-aligned**: 8192 × 1536 m centred on the origin, which puts its long
edges at x = ±768 while Terrain3D's region lattice at `region_size` 256 and
`vertex_spacing` 2.0 falls every 512 m. The width is now **2048 m** and the
region count **64, not 48**. Every figure downstream has been recomputed here
and in `docs/MEADOWS_MACRO_LAYOUT.md`. The trail, the bands and the 40-minute
target are unchanged.

## The decision

The Meadows is **8192 m long × 2048 m wide** — `region_size` 256,
`vertex_spacing` 2.0, so 512 m per region, **16 × 4 = 64 regions**. Bounds
**`x ∈ [−1024, +1024]`, `z ∈ [−512, +7680]`**; the long axis is +Z, running
south, away from Grandpa's house.

Every bound is an exact multiple of the 512 m region pitch: x at ±2, z at −1
and +15. That sentence is load-bearing and is why this decision was revised.

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

40 min × 5.0 m/s = 12,000 m of trail. 5 min × 5.0 m/s = 1,500 m of width — but
1,536 (the obvious rounding) is not region-aligned in any centred placement, so
the width goes to the next aligned value up, **2,048 m = 6 min 49 s side to
side**. Over the owner's "maybe five minutes" rather than under it, which is the
right direction to err: the flanks are where "off the path in either direction"
lives.

## Why the width had to be 2048 and not 1024 or an offset 1536

Terrain3D's regions sit on an integer lattice — a region's origin is
`region_location × region_size × vertex_spacing`, here a **512 m grid**. Both
bounds must land on it or the outermost regions are partly written and the rest
bakes as flat default terrain. 1,536 m centred on zero runs −768 … +768 and
neither bound qualifies, leaving 256 m of unfilled ground along each long edge
for 8 km — exactly where `D51` puts the boundary the player walks up to.

Three aligned candidates, decided against two measured facts: the authored
spine's x range is **−430 … +450**, and the seven spokes' blockers reach out to
**x = ±700 … ±740**.

| option | width | regions | flank past spine | spoke blockers |
|---|---|---|---|---|
| `x ∈ [−512, +512]` | 1024 | 32 | 62–82 m | outside the world |
| `x ∈ [−512, +1024]` (offset) | 1536 | 48 | 82 m west | outside the world |
| offset, spine shifted +256 m east | 1536 | 48 | 318–338 m | 38–68 m inside |
| **`x ∈ [−1024, +1024]`** | **2048** | **64** | **574–594 m** | **284–324 m inside** |

**1024 m is rejected by this decision's own argument against a 6144 m length.**
That argument was: a trail whose swings consume the whole width turns the width
*into* the trail. At ±768 the spine used 56–59% of the half-width; at ±512 it
uses **84–88%**, the ten regional loops have nowhere to leave the spine to, and
all six lateral spoke blockers fall outside the world. The same objection, the
same answer.

**The offset 1536 m placement is rejected** because it also puts the western
spokes outside, and shifting the spine east to compensate costs a full
re-authoring pass and still lands the blockers 38–68 m from the edge — the
precise defect the wider footprint exists to fix.

**2048 m is not only alignment.** At ±1024 the six lateral blockers stand
**284–324 m** inside the boundary, so `MEADOWS_MACRO_LAYOUT.md` §7's requirement
— land visibly continuing past every severed spoke — becomes true as written
rather than aspirational. At ±768 they stood **28–68 m** inside it, which is
inside the edge dressing. The alignment fix and the spoke fix are one fix.

## Why 8192 m of corridor and not 6144

6144 m was the starting proposal and it was tested rather than accepted.

*(Corrected: the first version of this decision compared 1.95 against 1.53, two
tortuosity figures computed on different bases — 1.95 was the 12,000 m *target*
trail over corridor length, 1.53 the 11,594 m *authored* trail over spine
z-advance. On a consistent basis, with the authored trail: **1.89 vs 1.42**
against corridor length, or 2.10 vs 1.53 against spine advance. The conclusion
survives; the numbers quoted as evidence did not.)*

At 6144 m the trail has to double back through most of its own length — swinging
roughly ±500 m every 600 m of advance, which consumes the entire width. The
width would stop being "off the path in either direction" and become the path.

8192 m gives **tortuosity 1.42**, and the authored spine's x range is
**−430 … +450**, leaving **574–594 m** of genuinely off-trail land on both
flanks for the whole length. That is the difference between the owner's
directive being implemented and being approximated.

## Why 2.0 m vertex spacing is *probably* safe, on a margin of ~5°

`vertex_spacing` 2.0 halves the heightfield's resolution. Two limits, both
already tested: the player's `floor_max_angle` is 45°, but
`riding_controller._apply_climb_limit` raises the ridden legendary's body to
**60°**, and `smoke_riding` / `smoke_boss` assert the spoke walls stay above
that. 60° is the number that matters, not 45.

**First, a false premise in the original version.** It said "every blocker on
this map is a `_carve_depth` trench". Checked against `terrain_playground.json`:
only **three of seven spokes carry a carve** (`river_gorge`, `storm_road`,
`cliff_road`). `mountain_trail` and `high_pass` are rockslides — props over a
buried collision barrier — `stone_gate` is a built sealed gate, `blighted_road`
a sealed road. Plus two non-spoke carves: the `south_bridge` gully and the
river's own course. So `vertex_spacing` governs **five** blockers, not eleven,
and the four prop/built blockers are completely indifferent to it. That is a
real reduction in exposure and it should be stated that way round.

**Second, the original version reported the wrong statistic.**
`tools/_probe_corridor_footprint.gd` builds the piecewise-bilinear surface
Terrain3D actually reconstructs at each candidate spacing and walks transects
over *that*, which is the right method. But the figure quoted — 69.5–81.5°,
"every carve stays 15° or more past the ridden limit" — is `max_deg`, **the
single steepest 0.1 m finite difference on a 48–68 m transect**. Whether a body
climbs out is decided by the *shallowest sustained line*, not the steepest 10 cm,
and a smoothstepped wall's peak gradient exceeds its mean by 1.5× by
construction. The probe already computes a better proxy, `blocked_60` — the
longest unbroken ≥60° run — and the original version ignored it.

**Third, the repo already recorded the right number three times, and it is ~65°,
not ~80°.** `severed_spokes.gd:24` says spoke carves are "57–66 degree walls";
`tests/smoke_riding.gd:163` pins `SHALLOWEST_SPOKE_WALL_DEG := 65.0`;
`ralph/DONE.md:16` records the shipped `storm_road` at **65.6°**. Computed
straight from the config, the mean wall is `atan(depth / rim)`:

| carve | depth / rim | mean wall | margin over 60° |
|---|---|---|---|
| `river_gorge` | 16 / 7 | 66.4° | +6.4° |
| `cliff_road` | 9 / 4 | 66.0° | +6.0° |
| `storm_road` | 11 / 5 | **65.6°** | **+5.6°** |
| `south_bridge` gully | 11 / 3.4 | 72.8° | +12.8° |

65.6 reproduces `smoke_riding`'s constant and `DONE.md`'s shipped figure exactly.
**So the real margin is ~5°, not ~15°.** The probe's 1–2° of loss going 1.0 → 2.0
was measured on the peak; the loss on the mean is unmeasured, and if it is the
same 1–2° the margin on `storm_road` falls to 3.6–4.6°. The probe's own
phase-dependence caveat — a few degrees either way depending on where the sample
lines fall — is a band as wide as the whole remaining margin.

**The honest position: 2.0 m spacing is probably safe, with single-digit degrees
of margin, and has not been measured on the statistic that decides it.** That is
a condition on `OW5B`, not a reason to choose 1.0 m — which would cost 723
minutes of bake for a resolution nothing else needs.

Conditions attached, and they are what `OW5B` is held to:

- Report **`blocked_60` against carve depth**, at the now-fixed origin. `max_deg`
  is diagnostics and must never appear in a pass/fail sentence.
- Keep every carve's mean wall `atan(depth / rim)` at **≥ 65°** — the number
  `smoke_riding.gd` already asserts and the shipped `storm_road` already holds.
- Keep every carve's `rim` at **≥ 2 × vertex_spacing** (4.0 m). Necessary, not
  sufficient. `cliff_road` sits exactly at 4.0; the `south_bridge` gully is at
  **3.4, below the floor**, and should go to 4.0 when the crossing is re-sited —
  which costs nothing, as the prefab's 18.4 m span clears a 15.2 m gap.
- Widen **before** the bake. A rim change afterwards costs another three hours.

## What it costs

- **The bake, with its anchor withdrawn.** Measured at **2584 µs/pixel** across
  both of `build_playground_terrain.gd`'s passes. The original version claimed
  this was "validated against the known 512 m figure… which is the repo's '12
  min'". **There is no 12-minute figure anywhere in this tree.** The only
  recorded bake times are `ralph/DONE.md:2752`'s **~5.5 min** and
  `D45`/`meadow_healing.gd`'s **~15 min** — which disagree with each other by
  2.7× and with the probe's 11.3 by 2.05× and 0.75×, and which are whole-bake
  wall-clock times against the probe's field-work-only figure. **The unit cost
  is unvalidated**, and every projection carries that. On it: 64 regions is
  4096 × 1024 = 4,194,304 px → **~181 minutes** of one-shot offline bake. It is
  overnight work either way and is not a reason to choose a shape. `OW5B` should
  time a **single-region bake** first and anchor the number for the price of a
  coffee.
- **Land to keep dense.** 16.78 km² against today's 0.262 km² — **exactly 64×**,
  the same 64 as the region count. This is the real price, and §5's rule ("only
  as large as the team can make meaningfully dense") is the thing most likely to
  be violated. The layout answers it with a budget: one authored beat every
  150–250 m of spine, no segment over 250 m without one, checkable from data —
  and the budget is **per metre of route, not per square metre of world**, which
  is what keeps it bounded when the width grows.
- **Three systems that must be rebuilt before this can land.** The scatter
  builds ~**23.7 k** MultiMesh instances at load today (the original version's
  "28,790" has no source in this tree; the repo's own recorded snapshots run
  23,452–25,946 and the blind review measured 23,707); 64× is ~**1.52 million**,
  in GDScript, during the load screen. `collision_mode` is FULL_GAME, building
  real collision across the entire terrain at startup. And — **missing from the
  original version entirely** — the **map system**: `map_baker.gd` `HALF_SPAN`,
  `minimap.gd` `WORLD_HALF` and `map_state.gd`'s `GRID`/`CELL`/`ORIGIN` all
  hard-code a ±256 m world, `map_state`'s grid is **persisted to the save file**
  so changing it is a save-format change touching `D27` and `D33`, and
  `map_baker.bake()` walks a resolution² grid calling `height_at`,
  `slope_degrees_at` and `path_factor` per pixel **on the player's first
  launch, on their hardware**. All three are covered in
  `MEADOWS_MACRO_LAYOUT.md` §8, and **streaming the scatter and fixing the map
  bake are hard prerequisites** — child items ahead of the trail work, not after
  it.

## What was rejected

- **A big square**, per the backlog's original wording. Superseded by the owner
  directly. A 12 km square is 144 km² and could not be made dense by anyone.
- **6144 m of length**, the starting proposal. Tortuosity 1.89 (above).
- **8192 × 1536**, this decision's own first answer. Not region-aligned; see the
  top of this file.
- **8192 × 1024** (32 regions, 90 min of bake) and the **offset 1536 m**
  placement. Both aligned, both rejected on the spine and spoke geometry above.
- **`vertex_spacing` 1.0 at corridor scale.** 16,777,216 pixels → **723 minutes**
  of bake, four times the resolution nothing needed, to recover 1–2 degrees on a
  ~5° margin — which is worth having, but not at 12 hours a bake and not before
  the margin has been measured on the right statistic.
- **Moving the village to centre the world.** The bake currently centres its
  images on the world origin, which made re-centring look free. It is not:
  §0.6 says relocate shipped work rather than reconstruct it, and the cheapest
  relocation is none. Band 0 and the whole shipped village keep their exact
  current coordinates; the bake grows an authored two-axis extent instead.

## What this supersedes

`docs/decisions/D46` on its central claim — **prospectively, not yet in fact.**

D46 decided the river divides the map and that this costs one severed spoke —
the storm road — because the 512 m disc was *demonstrably full*: every bearing
searched at 1°, every offset at 2.5 m, and the best compliant chord left a far
side 17 m deep. That reasoning was correct and it was about the disc. In a
2,048 m-wide corridor a river crossing the width divides the map completely and
trivially, with a far side 3,400 m deep and no search to run.

**The tense matters and the first version of this decision got it wrong.** It
said flatly "the storm road is recovered; all seven spokes stand." **The shipped
game has a severed storm road**: `scripts/world/rift_collapse.gd` is built
against it, `tests/smoke_riding.gd` and `tests/smoke_boss.gd` assert against its
walls, and `ralph/DONE.md:16` records it as delivered with 65.6° walls. Nothing
in `OW5A` has moved a metre of terrain.

Stated correctly:

> **Conditional on `OW5B`, `OW5C` and `OW5D` all landing** — the corridor baked,
> the spokes re-sited laterally, the river re-authored across the width — the
> storm road is recovered and all seven spokes stand, at (0,7000) → (0,7620)
> past the stronghold. **Until then D46 describes the world as it runs**, and
> D46's cost is still being paid.

If the corridor is abandoned or narrowed below the point where a lateral river
divides the map, this supersession lapses and D46 stands unmodified.

What D46 got right and is kept either way: the river is a river and not a dry
gorge, the crossing sits on a road at narrows where a mill and a bridge would
actually stand, and the dry upper gorge is a legitimate landform rather than an
accident.

## The honest remainder

The trail measures 11,594 m, not 12,000 — **38.6 minutes, not 40**. (Verified
independently: all six band polylines recompute to 11,593.6 m.) The difference
is 3.5%, it is in the authored waypoints rather than in the footprint, and it
can be closed by any of the loops in §3.2 becoming part of the spine. It is
recorded rather than rounded because the next person to lengthen a band should
know how much slack there is.

**The forty minutes only holds for a walker, and the first version said
otherwise.** It claimed the stamina cycle buys "8.3 s of sprint per 5 s of
recovery, so the sustained rate is much nearer the walk". The recovery is not 5
s: `movement.json` has `regen_delay` **1.1** and `regen_per_second` 18, so a
full meter takes 1.1 + 100/18 = **6.67 s**. The cycle is 8.33 s at 8.6 m/s and
6.67 s at 5.0 → **7.00 m/s sustained**, which is 60% of the way from the walk to
the sprint, not "much nearer the walk". It is also the *optimal* cycle — the
average is monotonically increasing in how full the meter is allowed to get, so
a short-cycling sprinter does worse, at 6.20 m/s.

**At 7.00 m/s the trail is 27.6 minutes — 31% under the directive**, reachable
by any player who holds sprint and releases it when the bar empties. The owner's
wording is "a **walk** from the end of the meadows to the other end should take
40 minutes", which this layout meets. Whether forty is meant as a floor for any
playstyle is an owner question; if it is, the trail needs **16,800 m**, 45%
longer, and that is a different world and a different decision. Recorded, not
taken.

Three numbers in the load-time recommendation are **reasoned, not measured**:
the 512 m dynamic collision radius (from `sprint_speed` 8.6, giving 59 seconds
of runway), the claim that hoisting `playground_heightfield.gd`'s per-call
`_config.get(...)` lookups would meaningfully cut the bake, and the
`GRID_X` 512 / `GRID_Z` 128 / `CELL` 16.0 fog grid in §8.6. All three are
`OW5B`'s to measure before relying on.

**And one claim is withdrawn rather than qualified.** The first version said the
bake's cost "scales with pixel count and nothing else", from a two-tile probe
where the busy tile and the far-field tile came within 2.4% of each other. That
experiment cannot support the claim: `playground_heightfield.gd::path_factor`
calls `road_polylines()`, which rebuilds the whole road set from JSON on **every
call** with no cache and no distance rejection, so **both tiles paid the same
full 47-segment scan** — the far-field tile was never a low-content tile. A
sibling lane was fixing that cache on `ralph/PERF1`; checked against
`origin/main` at `5c7ec165`, **it has not landed**. If it does, the conclusion
may become true again, but it must be re-measured with content varied rather
than assumed. This matters because `MEADOWS_MACRO_LAYOUT.md` §11 proposes
unioning 81 more spine segments and ten loops into that same inner loop.
