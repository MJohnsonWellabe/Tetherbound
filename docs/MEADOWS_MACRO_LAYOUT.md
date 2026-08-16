# MEADOWS MACRO LAYOUT — the corridor

**`OW5A`, 2026-08-16.** The authored top-down map plan
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 asks for before terrain
production begins. This document decides the **shape**. It moves no terrain and
writes no gameplay code — `OW5B`/`OW5C`/`OW5D` do that.

**Model note, recorded honestly:** `OW5` is tagged `model: fable` and §5 says
"START WITH FABLE". The owner has directed that fable-tagged items run at
**opus** for now because he has no Fable usage left. This document was written
at opus. It did not run at its tagged tier and nothing here should be read as
having had a Fable pass.

Companion decisions: `docs/decisions/D50` (the footprint and the 40-minute
target) and `docs/decisions/D51` (the edge grammar that replaces the radial
perimeter).

**Revision 2, 2026-08-16 (second commit on `ralph/OW5A`).** A blind review of
revision 1 found five things wrong and several smaller ones. All are corrected
in place. The largest: **revision 1's footprint was not region-aligned** and has
been replaced — the corridor is now **8192 × 2048 m, 64 regions**, not 8192 ×
1536 / 48. Every region, pixel, bake, memory and margin figure downstream of
that has been recomputed. The band table in §3 is *not* changed: it was checked
independently and all six polylines recompute to 11,593.6 m against the 11,594
stated. What changed around it is the land the trail sits in.

Where this document previously stated something the review disproved, the old
claim is left visible and marked, not deleted. A layout document that quietly
rewrites its own evidence is worth less than one that shows where it was wrong.

---

## 0. The directive being implemented

Owner, in the `OW5` backlog entry:

> The meadow needs to read as a long journey away from home ending at the
> stronghold. It's a long trail working progressively further from Grandpa's
> house. You can go off the trail for different tasks. It can wind and fork and
> whatever but this should be the general layout. Walking end to end should take
> several in game days so you have to camp along the way.

Owner, superseding that entry's "the whole area should be a big square", in
conversation 2026-08-16:

> the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square. it should be
> long as I've stated but can be significantly less wide. like maybe it's five
> minutes of walking from side to side.

> a day from midnight to midnight should take about 10 minutes. a walk from the
> end of the meadows to the other end should take 40 minutes.

Everything below is that, plus §5's quality bar and the spec's bands.

### The one place this and §5 have to be reconciled

§5 says *"Do not target map size for its own sake. Do not force a 10–20 minute
uninterrupted straight-line walk merely to create scale."* The owner has since
asked for forty. These are not actually in conflict, and the reconciliation is
the whole design of this document: **§5 forbids empty scale, not scale.** The
forty minutes is forty minutes of *trail* — winding, forking, and carrying an
authored beat every couple of hundred metres — not forty minutes of holding
forward. §5's density rule (§4 below) is what makes the difference, and the
narrow corridor is what makes the density affordable. Where the two are read as
disagreeing, the owner's later word wins; where §5 sets the quality bar for how
that length is filled, §5 wins.

---

## 1. Measurements, not estimates

Everything in this section was measured on this container by
`tools/_probe_corridor_footprint.gd` and `tools/_probe_terrain_streaming.gd`,
both committed alongside this document. **No full bake was run** — a 36-to-48
region bake is `OW5B`'s job and would have consumed this item's whole budget.
The unit costs below are measured; the totals are extrapolations and are
labelled as such.

### 1.1 The bake cost — measured per pixel, and unanchored

Measured per-pixel cost of `build_playground_terrain.gd`'s two passes
(colour+height, then control), on this container:

| tile | µs/pixel | colour pass | control pass |
|---|---|---|---|
| busy centre (village, river, rises all in range) | **2584** | 1270 | 1315 |
| far field at (900, 900), only the noise layers answer | **2523** | 1228 | 1295 |

#### The anchor problem — read this before quoting any total below

Revision 1 said the probe "validates against a known figure: 262,144 px × 2584
µs = 11.3 minutes, which is the repo's '12 min' number". **That was wrong and
the error was in the probe's own header.** There is no 12-minute bake figure
anywhere in this tree. Grepped, 2026-08-16, the complete set of recorded bake
times is:

- `ralph/DONE.md:2752` — "The bake is **~5.5 minutes** and everything geometric
  depends on it."
- `docs/decisions/D45:115`, `scripts/world/meadow_healing.gd:30` and
  `data/config/meadow_healing.json` — "**~15-minute** bake", the figure `SG46`
  was explicitly forbidden to re-run.

Those two disagree with each other by **2.7×**, and the probe's 11.3 min agrees
with neither: it is 2.05× the 5.5 and 0.75× the 15. Both recorded figures are
wall-clock times for a *whole bake* on unnamed hardware at unnamed dates; the
probe's figure is *field work only* on this container, excluding image
allocation, control-word packing, PNG/res encoding and disk. So the three are
not even measuring the same thing, and the 11.3 was never a validation.

**State plainly: the bake unit cost is unvalidated.** 2584 µs/px is a real
measurement of a real inner loop on this box, and it is the best number anyone
has, but nothing independent confirms it and every total below inherits that
uncertainty. Do not present any bake projection in this document as a schedule.
The first thing `OW5B` should produce is a **timed single-region bake** on the
new footprint — one region, ~65,536 px, a couple of minutes — which turns the
unit cost into an anchored one and costs almost nothing to obtain.

#### Projections, at 2584 µs/px, carrying that caveat

| footprint | regions | pixels | field work |
|---|---|---|---|
| current 512 m @ 1.0 (512×512) | 4 | 262,144 | 11.3 min |
| 6144 × 2048 @ 2.0 (3072×1024) | 48 | 3,145,728 | 135 min |
| 8192 × 1024 @ 2.0 (4096×512) | 32 | 2,097,152 | 90 min |
| **8192 × 2048 @ 2.0 (4096×1024)** | **64** | **4,194,304** | **181 min** |
| 8192 × 2048 @ 1.0 (8192×2048) | 64 | 16,777,216 | 723 min |

*(Revision 1's headline was "48 regions, 3,145,728 px, 135 min" for an 8192 ×
1536 footprint. That footprint is not region-aligned and does not exist; see
§1.3 and §2. The 135 min now belongs to a 6144 × 2048 alternative that §2
rejects for a different reason.)*

#### What the two-tile experiment can and cannot tell you

Revision 1 concluded from the 2.4% gap between the busy tile and the far-field
tile that **"bake cost scales with pixel count and nothing else."** That
conclusion does not follow from this experiment, and the review that found it
was right.

`playground_heightfield.gd::path_factor` (`:905`) opens with
`var routes: Array = road_polylines()`. `road_polylines()` (`:1116`) rebuilds
the entire road set from the config Dictionary on **every call** — allocating a
fresh `Array` and a fresh `PackedVector2Array` per line — and there is **no
cache and no distance rejection anywhere in the path**. It then measures the
point against every segment of every line. Today that is 13 lines / **47
segments**, paid in full at every pixel of both tiles, including the far-field
tile 1,270 m from the nearest road.

So the far-field tile is not a low-content tile. It is a tile that pays exactly
the same road scan as the busy one, and the experiment therefore **cannot
detect content scaling at all** — the two tiles were never differentiated in
the one term that scales with authored content. The 2.4% gap measures noise
evaluation variance between two locations, nothing more.

This matters immediately, because §11 proposes unioning `trail.bands[]` (the
§3.1 spine: **81 segments**) and `trail.loops[]` (ten more) into
`road_polylines()`. That is roughly **4× the segment count**, evaluated per
pixel, over **16× the pixels** — into an inner loop with no cache and no
rejection. Revision 1's "adding features to fill the corridor costs almost
nothing at bake time" is an unsupported claim about the exact change this
document asks for.

**Status of the fix.** A sibling lane was fixing the `road_polylines()` cache on
branch `ralph/PERF1`. Checked against `origin/main` at `5c7ec165` on 2026-08-16:
**it has not landed.** `road_polylines()` on `main` is byte-identical to the
version above, with no cache field and no `PERF1` marker. If and when it does
land, the "cost scales with pixel count" conclusion may become true again — but
it must be **re-measured with a probe that actually varies the content**, not
inherited. The corrected experiment is: hold the tile fixed and vary the number
of road segments in the config, or add a third tile with the roads removed.

Two consequences for `OW5B`, replacing revision 1's:

1. **Do not budget the corridor bake on the assumption that content is free.**
   Until the cache lands and the varying-content probe is run, treat the road
   term as scaling with (pixels × segments) and assume the §11 trail data
   multiplies it.
2. **There is a large, unclaimed optimisation available, and it is now two
   things.** The `road_polylines()` cache (or a bounding-box rejection per line)
   is the bigger one and is mechanical. Hoisting the per-call
   `_config.get(...)` lookups in `playground_heightfield.gd` into typed fields
   at `_init` is the smaller one and is also mechanical. Neither is measured;
   do not treat any multiplier as known. But three hours of one-shot bake is
   worth an hour of both, because `OW5B` will not run the bake once.

### 1.2 The carve-resolution question — the margin is ~5°, not ~15°

This was the measurement most likely to kill the footprint. It does not kill
it, but revision 1 reported it against the wrong statistic and made the margin
look three times larger than it is.

#### First, the false premise

Revision 1 opened "**every blocker on this map is a `_carve_depth` trench**".
That is not true, and it is checkable from `terrain_playground.json` in one
pass. Of the seven spokes, **three carry a carve and four do not**:

| spoke | blocker kind | carve? |
|---|---|---|
| `river_gorge` | `gorge` | **yes** — depth 16, rim 7 |
| `storm_road` | `collapsed_bridge` | **yes** — depth 11, rim 5 |
| `cliff_road` | `fallen_roadbed` | **yes** — depth 9, rim 4 |
| `mountain_trail` | `rockslide` | no — props + buried collision barrier |
| `high_pass` | `rockslide` | no — props + buried collision barrier |
| `stone_gate` | `sealed_gate` | no — a built, sealed gate |
| `blighted_road` | `sealed_road` | no — a sealed road |

Plus two non-spoke carves: the `south_bridge` gully (depth 11, rim 3.4) and the
river's own 18-point course (depths 10–18, rims 3.4–7).

`vertex_spacing` therefore governs the safety of **five** blockers, not eleven.
The four rockslide/gate/sealed-road blockers are props and collision volumes,
`severed_spokes.gd`'s own vocabulary, and are **completely unaffected by
heightfield resolution** — which is a real and previously unstated reduction in
the risk this section exists to price. Say it that way round rather than
overstating the exposure.

For the five that *are* carves, two limits, both real and both already tested:

- `scenes/player/player.tscn` `floor_max_angle` 0.7854 rad = **45°**.
- `scenes/creatures/creature.tscn` gives every creature **55°**, and
  `riding_controller._apply_climb_limit` raises the ridden legendary's body to
  **60°**. `tests/smoke_riding.gd` and `tests/smoke_boss.gd` both assert the
  spoke walls stay above that. **60°, not 45°, is the number a spoke wall has to
  clear**, or riding walks out of the Meadows and breaks D23's carve-out.

The probe builds the piecewise-bilinear surface Terrain3D would actually
reconstruct from samples at each candidate spacing and walks transects over
*that*, rather than reading the analytic field — reading the field would report
the angle the config asks for, which is the number that was never in doubt.

#### The statistic revision 1 used, and why it is the wrong one

The probe prints `max_deg`: the **single steepest 0.1 m finite difference**
found anywhere on a 48–68 m transect. Revision 1 tabulated it and told the
reader to "read the angle column". That is the wrong number for this question.

Whether a body climbs out of a trench is not decided by the steepest 10 cm of
it. It is decided by the **shallowest sustained line** out — the gentlest
continuous run from floor to rim. A character controller with
`floor_max_angle` walks up anything at or under its limit and is stopped only
where *every* route out exceeds it. A wall with one 81° pixel and an otherwise
58° face is not a wall.

`max_deg` on a smoothstepped trench is a **peak**, and it is guaranteed to
exceed the wall's mean gradient by construction: a smoothstep's derivative
peaks at 1.5× its mean. Reporting the peak against a limit that acts on the
mean overstates the margin by exactly that factor.

The probe already computes a better proxy, and revision 1 ignored it:
**`blocked_60`** — the longest *unbroken* run of ≥60° slope, measured in metres
of vertical rise, with the run reset to zero the moment the slope drops below
the limit (`_measure_transect`, `:114–136`). That is a sustained statistic. Its
verdict test (`blocked_60 < depth × 0.5` → "RIDDEN CREATURE CLIMBS OUT") is the
right shape of question.

#### Reconciling with the three figures the repo already recorded

Revision 1's 79–81° for the storm ravine is flatly contradicted by three
independent places in this repo, all of which say ~65°:

| source | figure | what it is |
|---|---|---|
| `scripts/world/severed_spokes.gd:24` | "11–16 m deep with **57–66 degree** walls" | the design range across all three spoke carves, including their tapering ends |
| `tests/smoke_riding.gd:163` | `SHALLOWEST_SPOKE_WALL_DEG := 65.0` | the asserted floor, with the comment "storm_road: 11 m over a 5 m rim" |
| `ralph/DONE.md:16` (`SG44`) | storm_road "a BAKED 11 m carve with **65.6°** walls" | as shipped |

They are not in conflict with the probe; they are measuring the mean and the
probe is measuring the peak. Computed straight from
`terrain_playground.json` — the wall's mean gradient is `atan(depth / rim)`:

| carve | depth | rim | mean wall | margin over ridden 60° |
|---|---|---|---|---|
| `river_gorge` | 16.0 | 7.0 | **66.4°** | +6.4° |
| `cliff_road` notch | 9.0 | 4.0 | **66.0°** | +6.0° |
| `storm_road` ravine | 11.0 | 5.0 | **65.6°** | **+5.6°** |
| `south_bridge` gully | 11.0 | 3.4 | 72.8° | +12.8° |
| river @ north gorge | 18.0 | 7.0 | 68.7° | +8.7° |

65.6° reproduces `smoke_riding`'s constant and `DONE.md`'s shipped figure
exactly. The peak for a smoothstep at that mean is `atan(1.5 × 11/5)` = **73.1°**
— already well above the 65.6 the repo quotes, and the probe's 79–81° is higher
still because a transect crossing at an angle to the carve axis, or one that
also clips a `rises` flank, reports a steeper apparent gradient than the carve
has. **That is a further reason not to read `max_deg`: it is not even a clean
measurement of the carve.**

**So the real margin over the ridden 60° limit is nearer 5° than 15°**, and it
is 5.6° on the shallowest one. Revision 1's "every carve stays 15° or more past
the ridden limit" is withdrawn.

#### What the resolution loss actually costs against a 5.6° margin

The probe's own finding — **1–2° of wall lost going from 1.0 m to 2.0 m
spacing** — is a measurement of the *peak*. The loss on the *mean*, which is
the number that matters, is **unmeasured**. But the mean cannot be immune: at
2.0 m spacing `storm_road`'s 5.0 m rim is **2.5 samples** of horizontal run and
`cliff_road`'s 4.0 m rim is **2.0 samples**. A wall reconstructed from two or
three samples cannot hold a profile shape; it becomes a straight ramp between
them, and its mean is whatever those samples happen to bracket.

If the mean loses even the same 1–2° the peak does, the margin on `storm_road`
goes from **5.6° to 3.6–4.6°**. And the probe's own second caveat — that
degradation is **phase-dependent** and swings by a few degrees depending on
where the sample lines fall relative to the trench — is a band **as wide as the
entire remaining margin.**

This does not kill 2.0 m spacing. It does mean the previous section's
conclusion ("the footprint decision does not have to fight the carves") was
bought with a statistic that was not measuring the risk. The honest position:

> **2.0 m spacing is probably safe on the three spoke carves and the gully, with
> single-digit degrees of margin, and it has not yet been measured on the
> statistic that decides it.** The failure mode is not subtle if it happens — a
> ridden legendary walks out of the Meadows and breaks `D23`'s carve-out — and
> it is caught by tests that already exist.

Retained caveats from revision 1, unchanged and still true:

- **Degradation is phase-dependent, not monotonic.** 2.5 m sometimes measures
  *better* than 2.0 m. That is grid phase, not a trend, and it means a carve
  that measures fine at one offset can measure worse after the world origin
  moves. `OW5B` must re-run this probe **after** the corridor's origin is
  fixed, not before — and the origin is now fixed, at `x ∈ [−1024, +1024]`,
  `z ∈ [−512, +7680]` (§2).
- The *vertical extent* of wall steeper than 60° shrinks, most at `cliff_road`
  (12.7 m at 1.0 m → 9.8 m at 2.0 m) and `river @ south broad` (8.3 m → 7.0 m).
- The probe's "verdict" column compares blocked extent against rim-to-floor
  depth over the whole transect, which for the north gorge includes
  `rises.peaks[0]`'s flank rather than the carve. It is only meaningful where
  transect depth ≈ carve depth.

#### The rules `OW5B` inherits from this, restated on the right statistic

1. **Report `blocked_60` against carve depth, not `max_deg`.** A carve passes
   when its longest unbroken ≥60° run covers essentially the whole climb out.
   `max_deg` may stay in the probe's output as diagnostics; it must not be the
   headline and must not appear in a pass/fail sentence.
2. **Keep every carve's mean wall `atan(depth / rim)` at ≥ 65°.** That is the
   number `smoke_riding.gd` already asserts and the number the shipped
   `storm_road` already holds. It is a data check, cheap, and it is what would
   silently drift when someone re-sites a carve.
3. **Keep every carve's `rim` at ≥ 2 × `vertex_spacing`** (≥ 4.0 m at 2.0 m
   spacing) — necessary, not sufficient. Today `cliff_road` sits exactly at
   4.0 and the `south_bridge` gully at **3.4, below the floor**. The gully
   should go to 4.0 when the crossing is re-sited, which costs nothing: the
   `south_bridge` prefab's 18.4 m span clears a 14 m gap and a 4.0 m rim makes
   that 15.2 m.
4. **Widen before you re-bake, not after.** Raising a `rim` after a 3-hour bake
   costs another 3-hour bake. `height_at` is analytic and reads the JSON live
   (`ralph/DONE.md:2752`), so every carve can be re-probed at the new origin
   without baking anything.
5. The tapering ends of a carve (`end_fade`) run **shallower than the full-depth
   mean** — that is where `severed_spokes.gd`'s "57" comes from, and 57° is
   *below* the ridden 60° limit. A carve's ends are not held by wall angle;
   they are held by `half_length + end_fade` reaching past navigable ground.
   That property is geometric, survives any spacing, and must be re-verified
   when each carve is re-sited into the corridor.

### 1.3 Three engineering defects the corridor exposes

All three are `OW5B`'s to fix; recorded here so they are not discovered at bake
time. **The first one invalidated revision 1's entire footprint** and is the
reason this document has a revision 2.

#### (a) Region alignment is about the origin, not the extent

Terrain3D places regions on an **integer lattice**. A region's world origin is

```
region_location (Vector2i) × region_size × vertex_spacing
```

At `region_size` 256 and `vertex_spacing` 2.0 that is a **512 m grid**, so
region boundaries fall at … −1024, −512, 0, +512, +1024 … and nowhere else.
A world's min *and* max bounds must both land on that lattice or the outermost
regions are only partly written, and the unwritten part bakes as flat default
terrain — the exact failure `build_playground_terrain.gd:44`'s guard exists to
prevent.

**Revision 1 of this document specified `x ∈ [−768, +768]`.** 768 is 1.5 × 512.
Neither bound is on the lattice. A 1536 m width centred on the origin straddles
**four** region columns (−2, −1, 0, +1) and fills only the middle 1536 m of the
2048 m those four columns cover, leaving **256 m of unfilled flat terrain along
each long edge for the full 8192 m of the corridor** — which is also, precisely,
where `D51` puts the boundary the player is meant to walk up to.

The corrected consequences, propagated through this document, `D50` and `D51`:
**64 regions, not 48. 4096 × 1024 px, not 4096 × 768. ~22 MB of region data,
not 17.** §2 chooses the aligned footprint and shows the working.

#### (b) The guard tests the wrong property, and the proposed fix does not fix it

`build_playground_terrain.gd:44` asserts `world_size % region_size != 0`, but a
region covers `region_size × vertex_spacing` **metres**. At spacing 2.0 that
check passes for `world_size = 6400` (6400 % 256 == 0) while 6400 / 512 = 12.5.

**Revision 1 proposed replacing it with `world_size % (region_size *
vertex_spacing)`. That does not catch the bug that actually bit.** 1536 % 512 ==
0, so the proposed check passes the very footprint it was written to reject. It
tests **extent**, and the defect is one of **origin**: a 1536 m extent is fine,
a 1536 m extent *centred on zero* is not.

The check must verify that **both bounds** fall on the region lattice:

```gdscript
# A region's origin is region_location * region_size * vertex_spacing, so the
# lattice pitch is that product in METRES. Extent alone is not enough:
# 1536 % 512 == 0, but a 1536m width centred on the origin runs -768..+768 and
# NEITHER bound is on the lattice. Checking both bounds subsumes the extent
# check -- if min and max are both multiples of the pitch, so is max - min.
var pitch := float(region_size) * vertex_spacing
for bound: float in [min_x, max_x, min_z, max_z]:
    if not is_zero_approx(fposmod(bound, pitch)):
        push_error(
            "world bound %.1f is not a multiple of the %.1fm region pitch; " % [bound, pitch]
            + "the outermost regions would be partly written and bake as flat gaps")
        quit(1)
        return
```

`fposmod`, not `%`: GDScript's `%` on a negative float operand does not return
a value in `[0, pitch)`, and every bound on the west and north sides of this
corridor is negative.

#### (c) The bake is square-only

`world_size` is one number, `size = world_size / spacing` is used for both axes,
and `import_images` places the maps with their **centre** at the passed origin
(`:142–149`, origin computed as `-0.5 * size * spacing`). A corridor needs an
explicit two-axis extent. The layout below is therefore specified as **authored
world bounds**, not as a centred square:

**`x ∈ [−1024, +1024]`, `z ∈ [−512, +7680]`.**

Both x bounds are ±2 × 512. Both z bounds are −1 × 512 and +15 × 512. Region
columns −2 … +1 (four) and rows −1 … +14 (sixteen). **64 regions, every one of
them fully written.**

---

## 2. The footprint

**8192 m long × 2048 m wide**, `region_size` 256, `vertex_spacing` **2.0** →
512 m per region → **16 × 4 = 64 regions**. Bounds **`x ∈ [−1024, +1024]`,
`z ∈ [−512, +7680]`**. Long axis is **+Z**, running south, away from home.

Both x bounds are exact multiples of the 512 m region pitch (±2), and both z
bounds are too (−1 and +15). §1.3(a) is why that sentence is the first one in
this section.

### The arithmetic, verified

`data/config/art.json` `day_length_seconds = 600`. `data/config/movement.json`
`walk_speed = 5.0`, `sprint_speed = 8.6`.

- 40 min at 5.0 m/s = **12,000 m of trail**. The authored spine in §3 measures
  **11,594 m** = **38.6 min walking** = **3.86 in-game days**. Camping is
  forced, which is what `camp` has been waiting for.
- 5 min side to side at 5.0 m/s = **1,500 m**. 1,536 would have been that
  rounded up — but 1,536 is not region-aligned in any centred placement, so the
  width goes to the next aligned value, **2,048 m** = **6 min 49 s** side to
  side. That is over the owner's "maybe five minutes", not under it, and it is
  the direction to err in: the flanks are where "off the path in either
  direction" lives.

#### The sprint duty cycle — corrected, and it does not say what revision 1 said

Revision 1 wrote that the stamina cycle buys "8.3 s of sprint per 5 s of
recovery, so the sustained rate is much nearer the walk." The 5 s is wrong and
so is the conclusion. From `movement.json` `stamina`:
`max` 100, `sprint_drain_per_second` 12, `regen_per_second` 18,
**`regen_delay` 1.1**, `exhausted_below` 10.

- Sprint 100 → 0: **8.33 s**, covering 71.7 m at 8.6 m/s.
- Recovery 0 → 100: `regen_delay` **1.1 s** plus 100/18 = 5.56 s = **6.67 s**,
  not 5, covering 33.3 m at walk speed.
- Cycle: 104.9 m in 15.0 s = **7.00 m/s sustained**.

7.00 is **60% of the way from the walk to the sprint**, not "much nearer the
walk". And it is the *ceiling*: `player_vitals.gd` latches exhaustion at 0 and
clears it only above `exhausted_below` 10, and running the algebra over every
partial-meter cycle shows the average is monotonically increasing in how full
you let the meter get — so full-meter cycling at 7.00 m/s is also the optimal
strategy, not just one of them. A short-cycle sprinter who resumes at 10
stamina averages 6.20 m/s and is worse off.

**At 7.00 m/s the 11,594 m trail is 27.6 minutes.** That is **31% under the
owner's forty**, and it is achievable by any player who holds sprint and
releases it when the bar empties — i.e. by every player, within an hour.

This is recorded rather than fixed, because fixing it is not a layout decision:

- The directive says "**a walk** from the end of the meadows to the other end
  should take 40 minutes." On its own terms the layout meets it — 38.6 min, 3.5%
  short (see `D50`'s honest remainder).
- If the forty minutes is meant as a floor for *any* playstyle, the trail needs
  40 × 60 × 7.00 = **16,800 m**, a 45% increase over the authored spine. That is
  a different world and a different decision, and this document does not take
  it. It is the first question in §12.
- Riding is a third rate again and is the *intended* fast return (spec §3 Band
  4), so it is not a defect that it is faster.

### Why 2048 m of width, and not the three other aligned options

The width had to move off 1,536 because 1,536 is unaligned in every centred
placement (§1.3a). Four candidates were on the table. The measurements that
decide between them are the spine's own x range, **−430 … +450** (from §3.1,
recomputed: Band 1 reaches −430 and +430, Band 2 −420 and +400, Band 3 −160 and
+350, Band 4 −420 and +450), and the seven spokes' blocker positions, which run
out to **x = ±700 … ±740** (§7).

| option | width | regions | flank past spine | spoke blockers | verdict |
|---|---|---|---|---|---|
| `x ∈ [−512, +512]` | 1024 | 32 | 62–82 m | **outside the world** | rejected |
| `x ∈ [−512, +1024]`, offset | 1536 | 48 | 82 m west | **outside the world** | rejected |
| same, with the spine shifted +256 | 1536 | 48 | 318–338 m | 38–68 m inside | rejected |
| **`x ∈ [−1024, +1024]`** | **2048** | **64** | **574–594 m** | **284–324 m inside** | **chosen** |

**Why not 1024 m** — §12 offered narrowing to 1,024 as a fallback and 1,024 *is*
aligned, so the review was right to ask whether that ends the discussion. It
does not, and the reason is **§2's own objection to a 6144 m length, applied to
the width**. That objection was: a trail whose swings consume the entire width
turns the width *into* the trail, and "off the path in either direction" stops
existing. At ±768 the spine's ±430–450 swing used 56–59% of the half-width. At
**±512 it uses 84–88%** — the trail would be pressed against both edges through
Bands 1, 2 and 4, and there is no room left for the ten regional loops in §3.2
to leave the spine at all, since most of them swing further out than it does.
It also puts **all six lateral spoke blockers outside the world**, so either the
spokes go or the width does. The same objection, the same answer.

**Why not the 1536 m offset placement** — `x ∈ [−512, +1024]` is aligned and
keeps 48 regions and every number revision 1 quoted, which makes it tempting.
It fails for a concrete reason: the spine already reaches x = −430 and the west
spokes end at x = −700, −720, −730. All three fall outside a −512 boundary.
Shifting the entire spine +256 m east to compensate re-authors every waypoint in
§3.1 and every "new" coordinate in §10.2 — and even then it lands the western
blockers **38–68 m** inside the boundary, which is the *precise defect* §7 was
flagged for. An option that costs a full re-authoring pass and does not fix the
defect is not an option.

**What 2048 costs, honestly.** 16.78 km² instead of 12.58 — **4.2 km² more land
to keep dense**, which is the price §5's rule ("only as large as the team can
make meaningfully dense") is most likely to be broken by. Plus 16 more regions,
46 more minutes of one-shot bake (181 vs 135), 5 MB more region data, 12 MB more
map memory and ~1 km more perimeter. §4 is how the density gets paid and §8 is
where the rest lands.

**What 2048 buys, which is not only alignment.** It is the reason §7's
"blockers stand ~300 m inside the boundary, so the ground genuinely continues"
becomes **true** rather than aspirational: at ±1024 the six lateral blockers sit
**284–324 m** inside the edge. At ±768 they sat **28–68 m** inside it, which is
inside the edge dressing itself. The alignment fix and the spoke fix are the
same fix.

### Why not the coordinator's 6144 m length

*(Corrected: revision 1 compared two tortuosity figures computed on different
bases and presented them as evidence against each other.)*

Tortuosity has to be quoted on one basis. Two are in play in this document:

- **trail ÷ corridor length** — how much walking the corridor's full extent buys.
- **trail ÷ spine z-advance** (7,576 m, from −40 to 7,536 of actual progress) —
  how much walking the *authored route's own* advance buys.

Revision 1 quoted **1.95** for 6144 (which is 12,000 ÷ 6144, the *target* trail
over corridor length) against **1.53** for 8192 (which is 11,594 ÷ 7,576, the
*authored* trail over spine advance). Different numerators, different
denominators, presented as a comparison.

On a consistent basis, with the authored 11,594 m trail:

| | trail ÷ corridor length | trail ÷ spine advance |
|---|---|---|
| 6144 m corridor | **1.89** | ~2.10 |
| **8192 m corridor** | **1.42** | **1.53** |

**The conclusion survives; the numbers quoted as evidence did not.** 1.89 still
means the trail has to double back through most of its own length, swinging
roughly ±500 m every 600 m of advance, which consumes the entire width and
turns the flanks into the path. 1.42 leaves the spine inside ±450 of a ±1024
corridor. The extra 2,048 m of length costs 46 more minutes of offline bake and
4.2 km² more land; §4 is how the second is paid.

### What this is, in area terms

8192 × 2048 = **16.78 km²**, against today's 512 × 512 = 0.262 km². **Exactly
64× the current world** — the same 64 as the region count, which is not a
coincidence and is a useful thing to hold: every per-region and per-area cost
in §8 multiplies by the same number.

---

## 2A. "The world must not feel like one long corridor"

`MQ2A` §5, in the sentence this document has to answer and revision 1 never
quoted:

> But the world must **not** feel like one long corridor.

That sits eleven lines above `D50`'s title, which is *"The Meadows is a long
narrow corridor"*. Not quoting it was the single most conspicuous omission in
revision 1. There is a defensible answer and it has to be made out loud.

**First, what the sentence is about.** Read it with the eight lines that
immediately follow it, which are the plan's own remedy:

> Each progression band should open into an explorable regional loop. Use:
> branching paths; reconnecting paths; overlooks; shortcuts; side valleys; small
> vertical loops; optional clearings; hidden pockets; alternate return routes;
> while preserving the understandable macro progression.

and the mental model it names two paragraphs later — *"a connected adventure
through several real places"*, not *"a road with content placed beside it."*

`MQ2A` §5 is not legislating a footprint. It never mentions dimensions, aspect
ratio or region counts; it defines the failure by **route topology and content
placement**, and it prescribes the cure in the same breath. "Corridor" there is
a synonym for *one way forward with scenery bolted to the sides*, which is a
property of how the trail branches, not of how wide the world is.

**Second, the shape question was settled above `MQ2A` anyway.** The owner, on
2026-08-16: *"the world should be long but can be narrow… it doesn't have to be
a giant square."* `CLAUDE.md` makes the owner's later word win, and `MQ2A`'s own
§0.3 subordinates it where it overlaps. So even a direct conflict would resolve
this way. But it is not a direct conflict, because of the paragraph above.

**Third, the actual answer — this layout satisfies every clause of the cure.**

| `MQ2A` §5 asks for | where it is |
|---|---|
| each band opens into an explorable regional loop | §3.2 — ten loops, two or three per band, every one leaves the spine and rejoins it |
| branching paths | seven lateral spokes (§7), each leaving the spine and running to the flank |
| reconnecting paths | every loop rejoins; the two shortcuts below |
| overlooks | quarry rim overlook (Band 2), wind ridge traverse (Band 4) |
| shortcuts / alternate return routes | quarry haul road (2.4 km → 600 m), river ferry landing |
| side valleys | pond valley (Band 1), Warren undertrail (Band 2) |
| small vertical loops | wind ridge traverse, watchtower spur |
| optional clearings, hidden pockets | §4's beat budget; the four authored camps |
| understandable macro progression preserved | five bands, one direction, one arrival |

And the geometry itself argues against the feel: **tortuosity 1.42** means that
for every metre of southward progress the player walks 1.42 m, so the heading is
changing more or less constantly. Band 1 crosses the corridor's full width
**twice** in its first 2.4 km. There is no point on the map where the trail runs
straight for more than a few hundred metres except the stronghold approach,
which is straight **on purpose** (§3, 1.16) because after eleven kilometres of
winding a direct final approach is the arrival.

**Fourth, the honest concession, because the answer is not free.** A corridor
*can* fail `MQ2A` §5 in a way a square cannot, because there is genuinely only
one axis of progress: if the loops are shallow and the beats are thin, the
player experiences a road. The two mitigations are §4's beat budget (no 250 m
spine window without a beat, checkable from data and specified as a test) and
the ten loops being *real roads* in the `road_polylines()` sense — painted soil,
path stones, vegetation held off — not suggestions. The **2,048 m width chosen
in §2 helps directly here**: at 1,536 m most of the §3.2 loops would have folded
back inside the spine's own ±450 swing envelope, which is a loop that never gets
off the trail, which is exactly the failure `MQ2A` §5 names.

**And it is falsifiable.** `MQ2B`'s playtest gate asks a blind tester "where did
you choose to leave the path" and "whether traversal felt empty". If the answer
to the first is "nowhere", this section is wrong and the width or the loops are
what change — not the length, which is the owner's.

---

## 3. The spine

Coordinates are world metres, `(x, z)`, in the existing frame. **Band 0 and the
whole of the shipped village do not move at all** — §0.6 says relocate shipped
work rather than reconstruct it, and the cheapest relocation is none. Grandpa's
house, the village square, the well, the workshop, the cottages, the junction
signpost, the road gate, the Practice Meadow and The Rise all keep their exact
current coordinates. Everything from the South Bridge southward moves.

| band | trail m | z from | z to | corridor advance | tortuosity |
|---|---|---|---|---|---|
| 0 — Homebound | 96 | −40 | −16 | — | — |
| 1 — Lower Meadows | 2,384 | −16 | 1,360 | 1,376 | 1.73 |
| 2 — Stone & Root | 2,653 | 1,360 | 3,180 | 1,820 | 1.46 |
| 3 — The River Lock | 2,372 | 3,180 | 4,760 | 1,580 | 1.50 |
| 4 — Upper Meadows / Ironwood | 3,436 | 4,760 | 7,000 | 2,240 | 1.53 |
| Stronghold approach | 651 | 7,000 | 7,560 | 560 | 1.16 |
| **total** | **11,594** | −40 | 7,560 | 7,576 | **1.53** |

Band 0's 96 m is not an error and not a failure of the 20–40 minute target: the
spec's Band 0 is waking up, Grandpa, the starter, the first catch and reaching
the village. It is dialogue and a first fight, not walking. Nothing about it
changes.

### 3.1 Waypoints

Authored polyline, band by band. These are the **spine**; the loops in §3.2
hang off them and are not counted in the 11,594 m.

**Band 0 — Homebound** (unchanged from today)
```
(-22,-16) (-4,-13) (10,-10) (18,-24) (30,-40) (22,-26) (27.5,-16)
```
House → village square → Practice Meadow → road gate. Existing
`paths.routes` and `flats` already describe this exactly.

**Band 1 — Lower Meadows** — farm paths, oak grove, starter stream, the pond,
the trainer circuit, ending at the South Bridge
```
(27.5,-16) (14,20) (8,90) (-40,180) (-120,270) (-230,330) (-360,400)
(-430,510) (-330,590) (-190,650) (-50,700) (90,760) (230,830) (360,910)
(430,1020) (330,1130) (180,1200) (30,1250) (-40,1310) (0,1360)
```
The western swing (x −430 at z 510) is the pond and the starter stream; the
eastern swing (x +430 at z 1020) is the oak grove and the trainer road. The
trail crosses the corridor twice, which is what gives Band 1 its 1.73 — the
highest on the map, and correct there: the first two thousand metres should
feel like wandering the fields around home, not marching.

**Band 2 — Stone & Root** — Old Quarry, ridge trails, abandoned ranger camp,
Burrow Warrens, deeper oak forest
```
(0,1360) (70,1450) (190,1540) (310,1660) (400,1800) (330,1950) (180,2050)
(20,2130) (-150,2210) (-310,2320) (-420,2470) (-330,2630) (-180,2730)
(-40,2840) (90,2960) (60,3090) (0,3180)
```
Quarry east at (400,1800); Warrens mouth west at (−420,2470). The band is a
single long S, so the two dungeons sit on opposite flanks and the ridge trail
between them is the connective tissue.

**Band 3 — The River Lock** — river approach, Tether Relay Station, Old Mill
Crossing, far bank
```
(0,3180) (-110,3290) (-160,3420) (-60,3520) (90,3600) (230,3670) (350,3760)
(280,3900) (130,3980) (-30,4060) (-150,4170) (-150,4235) (-100,4350)
(30,4460) (160,4570) (110,4690) (0,4760)
```
The river runs **across the corridor** at z ≈ 4,200 (see §5). The crossing is
the two waypoints at (−150,4170) → (−150,4235). The relay is the eastern lobe
at (350,3760), on the near bank, which is what makes it a place you must clear
before the gate opens rather than a detour past it.

The `blighted_road` spoke leaves this band's **near-bank** approach at
(−150, 4150) and runs due west, staying north of the river the whole way —
revision 1 sent it to (−720, 4250), across a river it cannot bridge. §7 has the
correction and the reasoning.

**Band 4 — Upper Meadows / Ironwood** — old-growth, wind ridge, high pasture,
ruined watchtower, three regional captains
```
(0,4760) (-140,4870) (-300,4990) (-420,5140) (-330,5310) (-170,5410)
(0,5490) (170,5590) (330,5700) (450,5860) (390,6040) (230,6140) (60,6230)
(-110,6340) (-280,6460) (-210,6620) (-70,6720) (80,6820) (40,6930) (0,7000)
```
Ironwood old-growth west at (−420,5140); Field Captain at (170,5590); wind
ridge climb east at (450,5860); high pasture at (60,6230); ruined watchtower
and Ridge Captain west at (−280,6460). Riverwatch Captain sits off-spine on
the Band 3/4 seam (§3.2).

**Stronghold approach**
```
(0,7000) (-80,7120) (-20,7250) (80,7370) (20,7480) (0,7560)
```
Deliberately the straightest band on the map (1.16). After eleven kilometres
of winding, the last six hundred metres reading as a direct approach is the
arrival.

### 3.2 The regional loops

§5 is explicit that the mental model is "a connected adventure through several
real places", not "a road with content placed beside it". Each band therefore
opens into a loop that leaves the spine and rejoins it. These are roads in the
`road_polylines()` sense — painted soil, vegetation held off, path stones,
verge fringe — not invisible suggestions.

| band | loop | leaves | rejoins | why you take it |
|---|---|---|---|---|
| 1 | **Pond circuit** | (−360,400) | (−190,650) | the mill, the ranger station, the water species, and the first place you would choose to camp |
| 1 | **Oak grove ring** | (230,830) | (330,1130) | Duskhush at night, the trainer circuit's second fight, wood at scale |
| 2 | **Quarry rim overlook** | (310,1660) | (330,1950) | the whole quarry floor read from above before you walk into it; the drained ground is visible as a shape |
| 2 | **Ranger camp spur** | (−150,2210) | (−310,2320) | the abandoned camp, and the first evidence Team Tether has been moving material |
| 2 | **Warren undertrail** | (−420,2470) | (−180,2730) | the dungeon's second mouth, so the Warrens are a through-route once cleared, not a cul-de-sac |
| 3 | **Relay approach loop** | (230,3670) | (130,3980) | the compound seen from its own picket line before you are inside it |
| 3 | **Near-bank river walk** | (−30,4060) | (−100,4350) *(gated)* | walks the near bank downstream, shows the far side you cannot reach yet, and dead-ends at the crossing you have to earn |
| 4 | **Wind ridge traverse** | (330,5700) | (230,6140) | the highest ground in the Meadows and the vista that shows the whole journey behind you |
| 4 | **High pasture loop** | (60,6230) | (−110,6340) | Meadowhart herd, the riding payoff, open ground after the old-growth |
| 4 | **Watchtower spur** | (−280,6460) | (−210,6620) | the ruin, the Ridge Captain, and the first clear sight of the stronghold |

Two more reconnects that are not loops but shortcuts, both one-way until
earned, both §5's "alternate return routes":

- **Quarry haul road** — (400,1800) back to (8,90), the old cart road the
  quarry's stone left on. Opens when the quarry is cleared. Turns a 2.4 km
  return into 600 m and is the first time the world rewards knowing it.
- **River ferry landing** — (−100,4350) to (90,760). Not a fast-travel menu; a
  boat that exists at one place and goes to one other place, unlocked with the
  crossing.

---

## 4. Interesting-decision density — the budget that makes 12 km legal

§5: *"Long stretches of simply holding forward through procedural scenery are a
failure even if the terrain is visually attractive."* This is the constraint
that the length has to buy its way past, so it gets a number.

**One authored beat every 150–250 m of spine.** At 5 m/s that is something
worth noticing or deciding every 30–50 seconds. Over 11,594 m that is **46–77
beats on the spine**, plus each loop carrying its own.

A beat is any of §5's list: a fork, a resource opportunity, creature behaviour,
a vista, environmental story, a ruined object, an alpha silhouette, an optional
path, a hidden cache, a landmark, a climbable rise, an NPC, a traversal
shortcut, a safe camp location, a combat risk, a gatherable cluster.

Two rules that follow, and they are the ones that will actually get broken:

- **No spine segment longer than 250 m may pass without a beat.** This is
  checkable from data and should become a test in `OW5C`/`OW5D`: walk
  `road_polylines()`, and for each 250 m window assert at least one entry from
  the beat sources (`harvest.json`, `spawns.json`, `props.json` clusters,
  `map_landmarks.json`, `trainers.json`, the fork points above) falls within
  40 m of it. A layout document nobody can fail is a layout document nobody
  follows.
- **Beats are not evenly spaced.** 250 m is the ceiling, not the target. Bands
  cluster: the quarry rim and the relay picket should be dense, and the wind
  ridge traverse should be sparse on purpose so the vista lands.

The corridor is what makes this affordable. 16.78 km² of narrow land has far
less interior than a square of the same length, and **1,150 m of the 2,048 m
width is flank** (§5/§6 — broken land, scarp, marsh, old-growth, ridge) rather
than fillable interior. The land that has to carry beats is roughly the 900 m
band the trail and its loops wander within, not the whole footprint.

**The wider corridor makes this harder, and the increase is real.** At 1,536 m
the fillable band was ~400 m; at 2,048 m it is ~900 m, because the ten regional
loops in §3.2 now have room to leave the spine properly instead of folding back
inside its own swing envelope. That is the point of the extra width — a loop
that never gets more than 80 m off the trail is not a loop — but it is also
more land that has to earn its beats. **The beat budget is per metre of route,
not per square metre of world**, which is what keeps it bounded: 11,594 m of
spine plus the loops, not 16.78 km² of ground. The flanks carry the edge
grammar and the "broken land or sea" the owner asked for, and they are
deliberately not beat-bearing.

---

## 5. Regional identity — five real places, one biome

Still Meadows. Never a second biome (`CLAUDE.md` hard rule; D23's carve-out).
Differentiated the way §5 asks — landform, vegetation structure, openness, path
geometry, water, rock exposure, elevation, ruins, human occupation.

**Band 1 — Lower Meadows.** Open, low relief (the existing `hills` layer,
amplitude 15), hedged field boundaries, wide soft-edged paths, the pond and the
starter stream. Human occupation is *lived in*: fences that are maintained, a
working mill, a ranger station with someone in it. Vegetation: scattered
standards and hedgerow, high sky. This is the band that must not change much,
because it is the shipped one.

**Band 2 — Stone & Root.** Rock exposure arrives. The `rock_form` layer that
today only dresses the rises becomes the band's signature: ribbed, terraced
grey stone breaking through the turf, quarried faces, spoil heaps. Paths
narrow and start to switchback. Vegetation goes from scattered to *closed* —
deeper oak, low canopy, less sky. Human occupation is *abandoned*: the quarry
is worked out, the ranger camp is empty, and D41's drained ground is the first
thing in the world that is visibly wrong.

**Band 3 — The River Lock.** Water is the whole identity. The corridor's width
is crossed by the river; the land is low, wet, reed-edged, with the gorge
walls as the only steep thing for a kilometre. Openness returns but at ground
level rather than upward — long sightlines along the bank, none across it.
Human occupation is *occupying*: the relay compound is lit, fenced, powered
and staffed, and it is the first place in the Meadows that Team Tether has
actually built rather than broken.

**Band 4 — Upper Meadows / Ironwood.** Elevation. The band climbs roughly 60 m
across its length, so the player is looking back down at where they came from
for the first time. Old-growth Ironwood is the densest vegetation on the map
and the wind ridge is the emptiest; the contrast between them is the band's
shape. Human occupation is *contested*: patrol camps, a ruined watchtower,
three captains, and a stronghold on the skyline that gets closer every time
the trail crests.

**Stronghold approach.** Everything narrows. Straight, walled, drained, dead.
The only band with no loop and no optional content, because that is the point.

Spec §13's wild species fall out of this directly: lower fields
(Bramblebun/Mudsnout/Pipwing) in Band 1, grove (Trailpup/Duskhush/Burrowback)
in Band 1's oak ring and Band 2, quarry/warrens (Burrowback/Mudsnout/Tuskroot)
in Band 2, river (Paddlenewt/Mosshell/Brooktail/Reedwing) in Band 3, upper
ridge (Galecrest/Meadowhart/stronger Trailpup) in Band 4.

### Camps

§5: not a chain of free hotels. Authored camp locations are **places you want
to stop**, not services. The trail's natural stopping points fall out of the
day arithmetic — 3.86 in-game days at 10 minutes each means roughly a night
every 3,000 m of trail — so four are authored, each a different kind:

| at | kind | what it is |
|---|---|---|
| (−330,590) | safe clearing | flat, sheltered, beside the pond. Nothing built. You bring your own fire. |
| (−150,2210) | abandoned ranger camp | a ring of stones, a collapsed lean-to, and someone's kit. Salvage, not shelter. |
| (−100,4350) | ruined camp | the far bank, burned by Team Tether. Story, and a reason not to sleep there. |
| (60,6230) | story camp | high pasture, the Meadowhart herd, and the last flat ground before the stronghold. |

None of them restores anything on its own. `scripts/build/camp.gd` stays the
only thing that makes a camp work, and the player still has to build it. What
these four provide is the *decision* — "is this where I stop tonight?" — which
is what makes the campfire mean anything after the first night.

---

## 6. The edge grammar

This replaces `scripts/world/world_perimeter.gd`'s **circular ring at `RADIUS`
235**, which cannot survive a corridor: it is one continuous ground-sampled
polyline of 40 segments × 18 spans, generated as a closed circle, with its
collision boxes derived from the same points. See `docs/decisions/D51` for the
decision; this section is the design.

Spec §1E is the rule and does not change: *a believable physical perimeter —
fieldstone walls, ranch fencing, hedgerows, terrain ridges, rivers, rock
formations, dense impassable growth, authored Team Tether barriers — with
invisible collision only supporting a visible boundary, never being the
boundary.*

### What it becomes

**Two long edges, authored as polylines rather than generated as a circle**, at
**`x = −1024` and `x = +1024`**, following the terrain the way the ring already
does.
The existing generator's *through-line* is kept exactly — a continuous earth
bank and fieldstone kerb running the whole length under every dressing style,
with a stone pier at each join, so at any distance the boundary reads as one
built line whose dressing changes. That property was hard-won and is the whole
reason the current perimeter works. Only its **shape** changes: an open
polyline with a style sequence, instead of a closed circle with a cycle.

The style sequence is per-band, and it is how the edge carries regional
identity instead of fighting it:

| band | west edge (x = −1024) | east edge (x = +1024) |
|---|---|---|
| 1 | hedgerow on bank, ranch fence at gaps | fieldstone wall, the village's own field boundary continued |
| 2 | quarried rock face — the same `rock_form` grammar, run as a scarp | dense impassable growth over a terrain ridge |
| 3 | **water** — the broad marsh the river drains into, reed-choked and unwadeable | rock formation and scree |
| 4 | old-growth Ironwood, impassable by density alone | terrain ridge climbing to the wind ridge's own shoulder |
| approach | authored Team Tether barrier | authored Team Tether barrier |

The owner's phrase was "broken land or sea off the path in either direction".
Both halves are used: **broken land** is Bands 2 and 4 (scarp, ridge,
impassable growth), **sea** is Band 3's marsh, and the transition between them
is the band boundary, so the edge changes when the place changes.

### The two short ends

Both are 2,048 m long now rather than 1,536.

- **North (z = −512), behind Grandpa's farm.** Fieldstone and hedge, the
  gentlest boundary on the map. It is the back of the home fields and should
  read as "nothing over there", not as a wall.
- **South (z = +7680), past the stronghold.** Team Tether barrier and the
  stronghold's own outer works. The player reaches this last, and by then a
  built wall is the correct answer.

### The rule that must not be lost

Collision follows the visible line and never precedes it. The current
implementation generates its collision boxes from the same polyline that
generates the bank — keep that. A corridor is **20.5 km** of perimeter
(2 × 8192 + 2 × 2048) against the ring's 1.48 km — **14×** — so this is also a
cost item: `OW5B` should build the edge **per region** and let it stream with
the terrain, not build 20.5 km of banks and MultiMesh at load. §8 covers that.

---

## 7. The seven severed spokes, re-sited

`terrain_playground.json` `spokes` (lines 657–1610). The design is in that
file's own `_comment_spokes` keys and it does not change: **a spoke is a road
that runs the full way out from the village square and then stops at something
the world can show, with land still visible past it. Never a wall built across
a bearing. The sign names where the road used to go and never says it is
closed.**

What changes is that the current blockers sit at 160–200 m from the origin,
inside the 235 m ring, on evenly-ish spread bearings. In a corridor, roads
leave **laterally across the broken land** and **at the far end**. Bearings are
no longer the organising idea; *where the corridor's edge is interesting* is.

| spoke | biome | blocker kind | leaves at | direction | ends at | margin to edge |
|---|---|---|---|---|---|---|
| `river_gorge` | water | gorge **(carve)** | (−360,400) | west, through the pond valley | (−700,470) | 324 m |
| `cliff_road` | air | fallen roadbed **(carve)** | (430,1020) | east, onto the oak grove's high shoulder | (720,1080) | 304 m |
| `mountain_trail` | fire | rockslide (props) | (400,1800) | east, up the quarry scarp | (740,1860) | 284 m |
| `stone_gate` | psychic | sealed gate (built) | (−420,2470) | west, past the Warrens | (−730,2510) | 294 m |
| `blighted_road` | dark | sealed road (built) | (−150,4150) | west, along the **near** bank's marsh edge | (−730,**4150**) | 294 m |
| `high_pass` | ice | rockslide (props) | (450,5860) | east, off the wind ridge | (740,5960) | 284 m |
| `storm_road` | electric | collapsed bridge **(carve)** | (0,7000) | **south, past the stronghold** | (0,7620) | 60 m — see below |

Six leave laterally, one at the far end. The far-end one is the storm road, and
that placement is deliberate: the last thing the player sees past the
stronghold should be a road going on, not the edge of a level.

**Only three of the seven are carves** (`river_gorge`, `storm_road`,
`cliff_road`), which is why §1.2's resolution question touches three spokes and
not seven. Revision 1's "every blocker on this map is a carve" was wrong;
`mountain_trail` and `high_pass` are rockslides — props over a buried continuous
collision barrier — `stone_gate` is a built sealed gate and `blighted_road` a
sealed road. All four are `severed_spokes.gd`'s own vocabulary and none of them
cares what `vertex_spacing` is.

### The margin claim, corrected

Revision 1 said the blockers sit "300+ m past" the boundary and the review was
right that the table then showed 28–68 m. **Both were describing real things and
neither was the blockers.** The 300+ m was the *spine's* flank margin — the
trail's own x range against a ±768 edge — and it got attached to the wrong
subject. Against a ±768 edge the blockers, which reach out to x = ±700…±740,
had **28–68 m**: inside the edge dressing itself, which is not "land visibly
continuing past the blocker", it is "the blocker is standing on the boundary".

§2's aligned width fixes it rather than papering over it. At **x = ±1024** the
six lateral blockers sit **284–324 m** inside the edge, the spine's own flanks
are **574–594 m**, and the sentence becomes true as written. **The alignment fix
and this fix are the same fix** — which is the main reason 2,048 m won over the
other two aligned candidates in §2, both of which put these blockers outside the
world entirely.

Do not move a blocker outward to save a region. The 284 m is the minimum and it
is the design's floor, not slack.

### The storm road's far end is answered by sky, not by ground

`storm_road` is the exception: its blocker at (0, 7620) has only **60 m** of
terrain before the south end at z = +7680. That is not a defect and it is not
to be fixed by extending the world. The storm road is the reconnection spoke,
and `scripts/world/rift_collapse.gd` (`SG44`, `ralph/DONE.md:16`) already
answers its "land visible past it" with **sky**: four ridge silhouettes and a
warm horizon glow at 380–460 m, outside the terrain, no collider, no spawn, no
prompt — measured at 70,645 m² of visible land-form after the collapse. That is
the shipped mechanism for this one spoke and it is the correct one; a far-end
blocker at the end of an 8 km corridor should read as *the world continuing
past the horizon*, not as sixty metres of grass. Recorded here so `OW5C` does
not "fix" it by pushing the south bound out.

### `blighted_road` was authored across the river

Revision 1 put `blighted_road` leaving at (−150, **4170**) and ending at
(−720, **4250**), while §3/§5 run the river **across the full width at
z ≈ 4,200**. The spoke therefore crossed the river. It could only ever have
meant one of two broken things: a road that bridges an impassable river 550 m
west of the one authored crossing, or a blocker stranded on the far bank that
the player cannot reach until after the Old Mill Crossing opens — at which point
a Band 3 severed spoke is being discovered in Band 4.

**Corrected above: it leaves and ends at z = 4,150, wholly on the near (north)
bank**, running due west along the bank rather than across it. This is better
than the original intent, not a compromise: the spoke's own line is "west, along
the marsh edge", `D51` puts Band 3's **west edge in the marsh the river drains
into**, and a sealed road ending at the marsh has exactly the property §7
requires — the ground visibly continues, as water and reed, and the reason you
cannot follow it is legible without a word of UI. `OW5C` must keep the whole
polyline north of the river course; the river's `end_fade` is 14 m, so hold at
least 30 m of clearance from the nearest course point.

---

## 8. Load-time and residency budget

Added to this item by the coordinator, from the owner's question: *does baking a
map this size break the game? Valheim's map is far larger and nobody sits
through a long load.* The answer is that the terrain is fine and two other
systems are not.

### 8.1 The terrain itself is cheap, and the intuition is wrong

A bigger baked map does **not** mean a longer load, for the terrain:

- **Baked region data is small.** `data/terrain/playground` is **1.4 MB for 4
  regions** — 350 KB per region. **64 regions is ~22 MB on disk.** That is
  nothing. (Revision 1 said 17 MB for 48 regions; same per-region figure, wrong
  region count — see §1.3a.)
- **Render cost does not scale with world size.** Terrain3D draws with a
  clipmap (`mesh_lods`, `mesh_size`, `cull_margin` on the node). The mesh drawn
  around the camera is the same mesh whether the world is 4 regions or 64.
- **Map memory is bounded and modest.** 64 regions × 3 maps × 256² × 4 bytes =
  **48 MB** of texture-array memory. Still fine on an Ally, and worth noting it
  is now within a factor of two of a figure that would need thinking about.

So the terrain is resident, small, and does not need streaming. **Say this
plainly to anyone who assumes otherwise.**

### 8.2 Collision is the first real cliff

`scripts/world/playground_world.gd:155` sets `collision_mode = 3` (FULL_GAME) —
real collision shapes across the entire terrain, built at load — and `:320`
sets `collision_shape_size` to `region_size`, so shape granularity scales with
the region.

The comment at `:147–160` is important and easy to misread: FULL_GAME was
chosen to fix a **lifecycle bug**, not because dynamic collision is wrong.
Setting `collision_mode` before the node entered the tree silently reverted it
to 1 (Dynamic/Game), which built collision only inside a 64 m bubble, and
everything looked correct until you walked a couple of hundred metres and fell
through the world.

At 4 regions FULL_GAME is cheap. At 64 it is 16× the shapes and 16× the memory,
all at startup, and at `vertex_spacing` 2.0 each region is 512 m so
`collision_shape_size` must rise to 512 to stay one-shape-per-region — 64
`HeightMapShape3D`s of 256² samples each, ≈ **16.8 MB of shape data plus
broadphase**, built during the load screen.

**Recommendation: dynamic collision, set correctly and asserted.**

`tools/_probe_terrain_streaming.gd` confirms against ClassDB that this build's
`Terrain3D` exposes **`collision_radius`** with `set_collision_radius` /
`get_collision_radius`. The 64 m bubble in the old comment was the *default*,
not a hard limit. So:

- `collision_mode = 1` (Dynamic/Game), `collision_radius = 512`,
  `collision_shape_size = 64`.
- 512 m of radius is **59 seconds at `sprint_speed` 8.6** and 102 s at walk.
  The player cannot outrun it by any margin that matters. 64 m shapes mean the
  incremental rebuild as the camera moves touches small shapes often rather
  than 512 m shapes rarely, which is the shape of hitch you want.
- **How to stop it silently reverting**, which is the actual failure that
  produced FULL_GAME: apply both properties in `_ready()` **after**
  `data_directory` is assigned and the node is in the tree — exactly where
  `collision_mode` is applied today — then **read both back and `push_error` on
  mismatch**, extending the guard that already exists for `collision_mode` to
  `collision_radius`. And add the test the original bug did not have: drive a
  body 600 m down the spine in `smoke_traversal` and assert it never leaves the
  ground. The old bug survived because every test happened inside the bubble.

Numbers above are reasoned from `sprint_speed` and the ClassDB surface, **not
measured** — the frame cost of a dynamic rebuild step at 64 vs 256 shape size
is unmeasured and is the thing `OW5B` must put a number on.

### 8.3 The scatter is the hard prerequisite

`scripts/world/vegetation.gd` `build()` instantiates every MultiMesh instance
for the whole world at startup.

**Revision 1 said "about 28,790 today" and that number has no source.** Grepped:
it appears nowhere in this tree except in revision 1 of this document and `D50`.
The figures the repo has actually recorded, each a snapshot of the full
`meadows_playground.tscn` scatter at a different content state, are
**23,452** (`ralph/DONE.md:10002`, the `SA1-lod` note), **23,762** (`:7206`),
**24,314** (`:7018`, `:7077`) and **25,946** (`:3631`). The blind review's own
measurement is **23,707**, which sits inside that spread. Take **~23.7 k** as
the working figure and the 23.4–25.9 k spread as its honest uncertainty; the
28,790 is withdrawn.

Over 0.262 km² that is ~90,400 instances per km². The corridor is **16.78 km²**,
i.e. **64×**. At the same density that is roughly **1.52 million instances**
(1.50 M–1.66 M across the recorded spread) **built during the load screen**, in
GDScript, with a per-instance `height_at` sample. Revision 1's 1.38 M inherited
both the wrong base and the wrong area.

This is not a tuning problem. **Streaming the scatter is a hard prerequisite
for the corridor, not a follow-up.** The corridor cannot land until it exists.

The file's own header (`:13–16`) already names the answer, and it is correct —
verified against the vendored addon rather than trusted:

`tools/_probe_terrain_streaming.gd` confirms **`Terrain3DInstancer` is a real,
script-reachable class on this build** (Terrain3D 1.0.2, `addons/terrain_3d/`),
exposing `add_transforms`, `add_multimesh`, `add_instances`, `append_region`,
`append_location`, `update_transforms`, `update_mmis`, `clear_by_region`,
`clear_by_location`, `clear_by_mesh`. `Terrain3DRegion` carries an `instances`
property with `get_instances`/`set_instances`/`save`, so instance data is
**stored per region and streams with the region**. And `Terrain3DMeshAsset`
exposes per-mesh `lod0_range` … `lod9_range`, `last_lod`, `last_shadow_lod`,
`shadow_impostor`, `fade_margin` and `density`.

**Recommendation: swap to `Terrain3DInstancer`, not per-region MultiMesh
build/unload.** Both would solve residency. The instancer additionally gives
per-instance LOD and impostors for free, which a hand-rolled MultiMesh path
would have to build, and it puts the instance data in the same region files the
terrain already streams — so there is one residency mechanism instead of two
that can disagree about which region is loaded. The header's claim that this is
"a swap of this file alone" is close to true: `scatter_rules.gd` is pure and
tested and does not change, and `vegetation.gd`'s public surface is `build()`
plus the drain/regrow bookkeeping.

Two things that swap will break and must be planned for, not discovered:

- **`_drained` / `_regrown`** (SG46) holds the exact placements
  `scatter_rules._thin_by_drain` removed, so healing puts back the same
  instances. Instancer indices are per region, so that bookkeeping becomes
  per-region too.
- **Collision.** MultiMesh draws but does not collide, and `vegetation.gd`
  already builds separate collision for the solid props. Whatever streams the
  instances must stream that collision with them, or trees become ghosts at
  range and solid up close.

### 8.4 What is resident at boot, for the recommended footprint

| system | resident at boot | streamed | note |
|---|---|---|---|
| terrain region data | ~22 MB, all 64 regions | — | small; loaded from `data_directory` |
| terrain map memory | ~48 MB texture arrays | — | fine on an Ally |
| terrain mesh | clipmap around camera | yes, by Terrain3D | independent of world size |
| **terrain collision** | **nothing** | **yes — `collision_mode` 1, `collision_radius` 512** | changed by this document; see §8.2 |
| **scatter** | **nothing** | **yes — `Terrain3DInstancer`, per region** | changed by this document; hard prerequisite |
| perimeter edge | nothing | yes, per region | 20.5 km of edge; see §6 |
| **the baked map texture** | **nothing at boot, but a one-shot bake on first launch** | **must become per-region or per-band** | **added in revision 2; see §8.6 — this is the second hard prerequisite** |
| **`MapState` fog grid** | one `PackedByteArray`, sized by the world | — | **save-format change; see §8.6** |
| structures (village, quarry, relay, stronghold) | all | — | a few dozen prefabs; cheap and they anchor the map |
| NPCs, trainers, harvest nodes, props | all | — | ~60 nodes total; cheap |
| creature spawns | all spawn *points*; bodies on demand | — | already how `spawns.json` works |

`PT-18` records that boot cost already rose sharply on the current 512 m world.
Nothing in this document reduces that; §8.2, §8.3 and §8.6 stop it from being
multiplied by 64.

### 8.6 The map system — the one that runs on the player's hardware

**Missing from revision 1 entirely**, in all three documents, and it is the only
item in this section whose cost is paid by the player rather than by an offline
bake. Three files hard-code the world's extent, and one of them writes it to the
save file.

| file | constant | value | what breaks |
|---|---|---|---|
| `scripts/world/map_baker.gd:36` | `HALF_SPAN` | `256.0` | the baked map texture covers only the middle 512 m of an 8 km corridor |
| `scripts/ui/minimap.gd:49` | `WORLD_HALF` | `256.0` | the minimap's player dot and its texture sampling both use it; wrong world → wrong position |
| `autoload/map_state.gd:28–30` | `GRID` 128, `CELL` 4.0, `ORIGIN` (−256, −256) | a 128×128 grid of 4 m cells over ±256 m | fog-of-war covers 0.26 km² of a 16.78 km² world — **and it is persisted** |

Each of the three carries a comment tying itself to `terrain_playground.json`'s
`world_size` 512, so none of them is an accident; they are three places one
number was copied to. §10's relocation table omitted all three.

**(a) `map_state`'s grid is in the save file, so this is a save-format change.**
`save_data()` writes `visited_b64` = `Marshalls.raw_to_base64(_visited)`, a
`GRID × GRID` = 16,384-byte array. `load_data()` is defensive — a
`visited_b64` of the wrong length is discarded with a `push_warning` and a fresh
fully-hidden grid is kept — so **an existing save does not crash, it silently
loses all map discovery.** That is the benign case.

The dangerous case is the one `load_data` cannot detect: **changing `CELL` or
`ORIGIN` while `GRID × GRID` stays the same length.** The byte array validates,
loads, and every cell now means a different piece of world. A player's explored
Meadows comes back as an arbitrary pattern of revealed squares somewhere else.
Any change here must therefore go through `D27`'s save format properly — a
version bump or an explicit grid descriptor in the payload, not a silent
constant edit — and `D33` ("one map database … a 128×128 cell grid over the
±256 m playground world") states the current geometry as part of its decision
and needs amending, not just the code.

**Sizing it, for `OW5B`/`OW5D` to argue with.** The grid must become
rectangular; a square grid over an 8192 × 2048 world wastes three quarters of
itself. At the current `CELL` 4.0 the corridor needs 2048 × 512 = **1,048,576
cells = 1 MB per save slot**, which is absurd for fog-of-war. At `CELL` 16.0 it
is 512 × 128 = **65,536 bytes**, four times today's file for 64 times the world,
with cells the size of a small clearing. The reveal radius (~45 m today) is
already three `CELL` 16 cells wide, so the fog's *edge* resolution barely
changes. **`CELL` 16.0, `GRID_X` 512, `GRID_Z` 128 is the recommendation**, and
it is a recommendation, not a measurement.

**(b) `map_baker.bake()` runs on the player's machine, on first launch.**
It walks a `resolution²` grid — 512² = 262,144 pixels by default — and per pixel
calls `ground_height_at`, then in a second pass `building_apron_factor` and
**`path_factor`**. Per §1.1, `path_factor` rebuilds `road_polylines()` from the
config Dictionary on every one of those calls with no cache and no distance
rejection. `bake_cached()` writes the result to `user://cache/map_meadows.png`
keyed on a hash of `terrain_playground.json`, and `playground_hud.gd:796`
(`_ensure_minimap_baked`) and `tab_map.gd:600` both call it lazily — so the
**first player to open the map after a fresh install pays the whole thing, on
an Ally, inside a frame budget.**

At 64× the world and the same metres-per-pixel, that is 8192 × 2048 =
**16.78 M pixels**. Even at four times coarser (2048 × 512 = 1.05 M px) it is
4× today's pixel count with a road scan that has grown from 47 segments to ~130
(§11). This is not a tuning problem either. **The map bake must become
per-region or per-band and incremental — baked as the player enters a band, or
shipped pre-baked as an asset — before the corridor lands.** It is the second
hard prerequisite alongside the scatter, and unlike the terrain bake it cannot
be moved offline by fiat, because `bake_cached`'s whole design is that the
terrain recipe is the only input and the cache key is its hash.

The honest option worth pricing first: **ship the baked map PNG as a committed
asset** the way the terrain regions already are, and keep `bake_cached` as the
dev-tooling path. The terrain is baked offline and committed; there is no reason
its top-down picture should not be.

**(c) The capture tooling hard-codes the same constants.**
`tools/capture_perimeter.gd:30` `RADIUS := 235.0` and `SEGMENTS := 40` walk the
ring that `D51` deletes outright — that tool needs rewriting, not re-tuning,
alongside `world_perimeter.gd`. `tools/capture_hillside.gd:50` documents its
viewpoints as "MUST stay inside the baked world (±256 m, `world_size` 512)" and
records that an eye past the edge broke Terrain3D's streaming for a whole
survey run, not just one frame. Both are survey infrastructure, so if they are
not moved with the world the first evidence of the corridor being wrong will be
a survey that renders nothing.

### 8.5 What this does to the build order

**Streaming is a prerequisite, so it is a child item ahead of the trail work,
not after it.** The order that follows:

1. Scatter streaming (`Terrain3DInstancer` swap), dynamic collision, **and the
   map system (§8.6)**, on the **current 512 m world**, where a regression is
   visible in one survey run and `smoke_traversal` already covers the ground.
   Ship it before the footprint changes.
2. The footprint and the bake (`OW5B`), including the **three** defects in §1.3,
   the `road_polylines()` cache and the `_config` hoist in §1.1, and a **timed
   single-region bake first** to anchor the unit cost (§1.1).
3. The trail, loops and edges (`OW5C`).
4. Relocation of everything in §10 (`OW5D`).

Doing (1) after (2) means debugging a streaming bug and a 64-region bake at the
same time, with a three-hour turnaround on the bake.

#### Reconciling this order with `MQ2B`

`MQ2B` is explicit: *"Do not build all five bands at mediocre density. Take the
first appropriate Meadows region and finish it to the actual desired production
standard… Only after this region passes should its composition/content
principles be used to author the remaining bands."* Step 2 above bakes all five
bands' terrain before any region has passed that gate. The review is right that
this needs an answer rather than silence.

**The answer is that `MQ2B`'s gate is about content density, and the terrain
bake is not content.** The two are separable and the seam is clean:

- **`build_playground_terrain.gd` is monolithic by construction.** It writes one
  height/colour/control image pair for the whole world and calls `import_images`
  once. There is no per-band bake and building one would be a new system, which
  §0.6 and `MQ2A`'s "do not create a parallel second world-layout system" both
  argue against. So the bake is all-or-nothing regardless of the build order.
- **What the bake commits is landform, not density**: the heightfield, the road
  paint, the carves. `MQ2B`'s checklist — vegetation structure, landmark,
  exploration loop, gatherable placement, creature habitat, optional discovery,
  memorable encounter, day/night readability, no empty filler — is **entirely
  above the terrain layer**, in `vegetation.json`, `props.json`, `spawns.json`,
  `harvest.json`, `map_landmarks.json`, `trainers.json` and the scene.
- **The bake is cheap to redo and cheap to avoid redoing.** `height_at` is
  analytic and reads the JSON live (`ralph/DONE.md:2752`), so any landform
  change can be *measured* with a probe before it is baked. A failed `MQ2B`
  gate does not invalidate the bake; it changes what gets scattered on it.

**So the reconciliation, stated as a rule `OW5C`/`OW5D` are bound by:**

> `OW5B` may bake all 64 regions of landform. **No band beyond the `MQ2B`
> region may receive content** — scatter authoring, prop clusters, spawn
> placement, harvest nodes, landmarks, trainers or beats — until that region has
> passed `MQ2B`'s playtest gate. Baked ground with nothing on it is not "five
> bands at mediocre density"; it is an empty canvas, and `MQ2B`'s prohibition is
> about density, not about pixels.

**And the `MQ2B` region is Band 2 — Stone & Root — not Band 1.** Band 1 is the
shipped Lower Meadows, which §3 and §0.6 keep at its exact current coordinates
and which was authored to an older standard; proving Band 1 proves nothing about
the production recipe, because the recipe is not what built it. Band 2 is the
first wholly new band and it independently satisfies `MQ2B`'s checklist without
being stretched to fit: final-quality terrain composition (the `rock_form`
scarp), a major landmark (the Old Quarry), a dungeon (the Burrow Warrens), three
regional loops, a reconnect/shortcut (the quarry haul road), `D41`'s drained
ground as environmental story, and its own creature set. If it passes, its
composition principles carry to Bands 3 and 4; if it fails, the failure is
discovered on 3.2 km of corridor rather than on 12.

---

## 9. Re-deriving D46 — the river, and the spoke it cost

`docs/decisions/D46` decided that the river really divides the map and that
this costs exactly one spoke: the storm road's collapsed bridge ends up on the
far bank, unreachable until the Old Mill Crossing opens.

**That decision was correct for a 512 m disc and does not survive the
corridor.** Its own reasoning says why: the disc was *demonstrably full*. Every
bearing was searched at 1° and every offset at 2.5 m, and the best compliant
chord left a far side 17 m deep — a verge, not a region. The choice was "divide
it and pay one spoke, or do not divide it."

In a 2,048 m-wide corridor that constraint evaporates. A river crossing the
**width** at z ≈ 4,200 divides the map completely and trivially: it needs 2,048
m of course plus overrun past both edges, it crosses every possible route
because there is only one direction of travel, and the far side is 3,400 m
deep. There is no search to run and no chord to compromise.

**Decision: the storm road is recovered — conditionally.** In this layout all
seven spokes stand, and the storm road moves to the far end at (0,7000) →
(0,7620), past the stronghold, in Band 4/approach. D46's cost is repaid.

**Stated in the right tense, which revision 1 did not.** The shipped game has a
severed storm road: `rift_collapse.gd` is built against it, `smoke_riding` and
`smoke_boss` assert against its walls, and `ralph/DONE.md:16` records it as
delivered. Nothing in this document has moved it. The recovery is what becomes
true **once `OW5B`, `OW5C` and `OW5D` have all landed** — the corridor baked,
the spokes re-sited, the river re-authored across the width. Until then D46
still describes the world as it runs. `D50` records the supersession with that
condition attached; do not read either document as saying the seven spokes stand
today.

What is deliberately kept from D46, because it was right about these and they
are not about the disc:

- The river is a **river**, not a dry gorge. D46 rejected the dry gorge and the
  reasoning holds.
- The crossing is sited **on a road**, at narrows where a mill and a bridge
  would actually stand — "cut and given a way over, in one gesture, which is
  the whole grammar of `crossings[]`."
- The **dry-gorge remainder** is kept as a *technique*, not as an accident. D46
  recorded honestly that the north 60 m of the course runs above the water
  plane and is dry. In the corridor the river runs across a low, wet band on
  purpose, so it should be wet end to end — but where the course climbs to meet
  the eastern rock formation, a dry upper gorge feeding the river is a
  legitimate and now-intentional piece of landform.

D46 is superseded on its central claim and is not deleted. `docs/decisions/D50`
records the supersession.

---

## 10. The relocation table

These are duplicated sources of truth. They must move **together** or they
drift, and the drift is invisible until something is standing in a hillside.
"Current" is `main` as of 2026-08-16. "New" is the corridor frame.

Band 0 and the village are **unmoved by design** (§3). Everything else moves.

### 10.1 Unmoved — verify, do not touch

| what | file | coordinate |
|---|---|---|
| Grandpa's house | `playground_world.gd` `HOUSE_AT`, `flats[0]`, `building_aprons.footprints[0]`, `vegetation.footprints[0]`, `village.json` | (−22, −16) |
| village square / well | `flats[1]`, `village.json` `well`, `building_aprons.footprints[4]` | (10, −10) |
| workshop | `village.json` | (2, 2) |
| wagon | `village.json` | (6.5, −1.5) |
| cottage_a / cottage_b | `village.json`, `building_aprons.footprints[2,3]` | (18, −2) / (21, −14) |
| fence runs ×3 | `village.json` | (14,−20) (19.5,−25.5) (3,−18) |
| square oaks ×2 | `village.json` | (25.5,−9.5) (1,10.5) |
| junction signpost | `playground_world.gd` `SIGNPOST_AT` | (13.5, −7) |
| road gate / gate key | `playground_world.gd` `GATE_AT` / `GATE_KEY_AT` | (27.5,−16) / (24,−10) |
| Practice Meadow | `paths.routes[1]`, `vegetation.clearings[3]`, `spawns` bramblebun | (30, −40) |
| The Rise + its trailhead | `flats[3]`, `paths.routes[3]`, `paths.trailheads[0]`, `rises.peaks[0]` | (74,−41) / (140,−90) |
| `spawn_pad` | `terrain_playground.json` | (0, 0) |
| `map_landmarks` `grandpas_village`, `the_rise` | `map_landmarks.json` `regions` | (6,−22) r60 / (88,−43) r55 |
| village NPCs Mira, Oskar, Tam, Sela, Kell | `village_npcs.json` | unchanged |
| harvest nodes ×12 near the village | `harvest.json` | unchanged |

### 10.2 Moved

| what | file(s) | current | new |
|---|---|---|---|
| The Pond + basin | `water.pond_centre`, `valley.centre`, `spawns` paddlenewt/mosshell/brooktail/reedwing, `map_landmarks` `the_pond` | (−145,138) / valley (−120,130) r150 | **(−395, 545)**, valley (−370,560) r180 |
| mill + footbridge | `village.json`, `flats[4]`, `building_aprons.footprints[5]`, `vegetation.footprints[2,3]` | (−132,107) / (−136.3,113) | **(−382, 514)** / (−386, 520) |
| ranger station | `village.json`, `flats[5]`, `vegetation.footprints[4]` | (−100,100) | **(−350, 507)** |
| stream (`water.stream.points`, 25 pts) | `terrain_playground.json` | z 0…140 | re-authored feeding the pond from (−200,300) |
| South Bridge crossing + gully carve + gate | `crossings[0]`, `flats[6,7]`, `vegetation.clearings[7]`, `paths.trailheads[1]`, `map_landmarks` `south_bridge` | carve (5,80) | **carve (0, 1330)**, abutments (0,1317)/(0,1343) |
| Old Quarry (floor, foundations, pylons, drains ×4) | `flats[8]`, `old_quarry.json`, `drains.stations[0..3]`, `vegetation.clearings[8]`, `harvest` ×5, `map_landmarks` `the_old_quarry` | (23,158), drains (27,162)…(41,121) | **(400, 1800)**, drains re-laid along the new haul road |
| Burrow Warrens | `burrow_warrens.json` `site.at` | (70,−140) | **(−420, 2470)** |
| Warrens-area harvest ×5 | `harvest.json` | (60,−136)…(92,−158) | around (−420, 2470) |
| Tether Relay (site, walls, gate, decks, ramps, apparatus, conduits) | `relay_site.json`, `tether_relay.json`, `drains.stations[4..6]`, `map_landmarks` `the_tether_relay` | (108,34) | **(350, 3760)** |
| relay trainers Hess, Orrin, Dell, Captain Vance | `trainers.json` | around (108,34) | around (350, 3760) |
| the river (18-point course) | `river.course` | (211,−87)…(75,246) | **crosses the width at z ≈ 4,200**, x −800…+800 |
| Old Mill Crossing + mill + abutments | `crossings[1]`, `flats[9,10]`, `map_landmarks` `old_mill_crossing`, `the_long_water` | (162.4,42.1) | **(−150, 4200)** |
| Stronghold | `stronghold.json` `site.at`, `map_landmarks` `stronghold`, `playground_world.gd` `SIGIL_GATE_AT` | (141.8,−215.4) / sigil gate (130,−176) | **(0, 7560)** / sigil gate (0, 7400) |
| stronghold trainers Verrick, Solene, Hald, Warden Aldis | `trainers.json` | around (141.8,−215.4) | around (0, 7560) |
| three regional captains Halder, Vess, Oreth | `trainers.json` | unplaced/near village | **(170,5590) / (−280,6460) / (−100,4350)** |
| seven spokes (`road`, `blocker.carve`, `sign`) | `spokes.routes` | radial, 160–200 m | §7 table |
| `rises.peaks[1..4]` | `terrain_playground.json` | (−165,−150) (60,175) (78.4,−184.2) (24.4,−198.8) | re-sited as Band 2 scarp and Band 4 wind ridge |
| all remaining `spawns.json` entries | `spawns.json` | within ±150 m | to their band per spec §13 (§5 above) |
| `props.json` clusters ×5 | `props.json` | near village | per band |
| perimeter | `world_perimeter.gd` | circle r235 | §6, D51 |
| `world_size` / `vertex_spacing` | `terrain_playground.json` | 512 / 1.0 | bounds **x[−1024,+1024] z[−512,+7680]** / 2.0 |
| `WORLD_EDGE` | `tests/smoke_traversal.gd` | 240.0 | corridor bounds |

### 10.2b The map system and the survey tooling

**Added in revision 2. Revision 1 omitted every file in this table**, including
the three that hard-code the world's extent and the one that writes it to the
save. The reasoning for each is §8.6; this is the checklist.

| what | file | current | new |
|---|---|---|---|
| map bake extent | `scripts/world/map_baker.gd:36` `HALF_SPAN` | 256.0 | two-axis bounds; **and the bake must become per-region/per-band or pre-baked — §8.6(b)** |
| map bake cost | `map_baker.gd::bake()` / `bake_cached()` | 512² px on the player's first launch | incremental or shipped as an asset |
| minimap extent | `scripts/ui/minimap.gd:49` `WORLD_HALF` | 256.0 | two-axis bounds, matching `map_baker` exactly |
| fog grid | `autoload/map_state.gd:28–30` `GRID` / `CELL` / `ORIGIN` | 128 / 4.0 / (−256,−256) | rectangular: **`GRID_X` 512, `GRID_Z` 128, `CELL` 16.0, `ORIGIN` (−1024, −512)** |
| **the save format** | `map_state.save_data()` `visited_b64`, via `D27` | 16,384 bytes, geometry implicit | **explicit grid descriptor or a version bump — a silent constant edit silently corrupts every existing save (§8.6a)** |
| the map decision itself | `docs/decisions/D33` | states "a 128×128 cell grid over the ±256 m playground world" as part of the decision | amend, do not just edit the code |
| perimeter survey | `tools/capture_perimeter.gd:30` `RADIUS` 235.0, `SEGMENTS` 40 | walks the ring | **rewrite — `D51` deletes the ring** |
| hillside survey | `tools/capture_hillside.gd:50` | viewpoints documented as "MUST stay inside ±256 m" | re-site; an eye past the edge broke Terrain3D streaming for a whole survey run, per the file's own comment |

**Run the full suite on the `map_state` change.** It is the only item in this
document that touches persisted player data, and `test_map_baker.gd`,
`test_progression_state.gd` and the save round-trip tests are what stand between
a constant edit and a corrupted save.

**New coordinates in this table are the layout's intent, not surveyed ground.**
`height_at` is analytic and unbounded, so every one of them can and must be
probed for slope and clearance before it is written — that is `OW5D`'s first
job, not a formality. Structure sites in particular (`stronghold.json` `skirt`
18, `burrow_warrens.json` `skirt` 10) need ground that will accept a skirt.

### 10.3 Two deferrals the repo booked against the re-bake

Both say "the day the terrain is re-baked", which is `OW5B`. Flagged here so
they are not missed:

- **`terrain_playground.json:656`**: `tether_relay.json`'s `dead_ground.enabled`
  **must** flip to `false` on the first re-bake, or the relay site is tinted
  twice — once by the baked `drains` stations and once by the runtime dead
  ground.
- **`docs/decisions/D45`'s postscript**: the quarry's baked drain colour must be
  **re-evaluated**, not inherited. It was authored against a quarry 158 m from
  the village on a 512 m map; at (400,1800) in a band whose whole identity is
  exposed rock, the same tint against the same near-white base is a different
  picture.

---

## 11. The signpost problem

`scripts/world/signpost.gd` draws **one arm per `paths.routes` entry** and the
post fits four: `ARM_START_HEIGHT` 2.05 stepping down by `ARM_SPACING` 0.44
puts a fifth arm at 0.29 m, in the grass. A 12 km trail cannot be four routes.

**It does not have to be.** `playground_heightfield.road_polylines()` (`:1116`)
is the single definition of "where the roads are", and it already unions three
sources: `paths.routes`, `spokes.routes[].road`, and `crossings[].road`.
Anything in any of them gets painted soil in the control map, vegetation held
off it, path-stone scatter down it and a verge fringe — automatically. Only
`paths.routes` feeds the signpost.

So the corridor's spine and loops are expressed as **new sources unioned into
`road_polylines()`**, not as `paths.routes` entries:

- add `trail.bands[]` (the §3.1 spine, one entry per band) and `trail.loops[]`
  (the §3.2 table) to `terrain_playground.json`;
- union both in `road_polylines()`, exactly as `crossings` already is;
- leave `paths.routes` as the village's own four dirt tracks, forever. The
  four-arm fingerpost by the well keeps naming the four places you can walk to
  from the square, which is what a village junction sign is for.

**This is not free, and §1.1 is why.** `road_polylines()` is called from inside
`path_factor`, which the bake calls once per pixel and `map_baker` calls once
per map pixel, and it rebuilds its whole result from the config Dictionary on
every call with no cache and no distance rejection. Today it returns **13 lines
/ 47 segments**. The §3.1 spine adds **81 segments** across six polylines and
the §3.2 loops add ten more polylines — roughly **4× the per-pixel road work,
over 16× the pixels.**

So this section's data change and §1.1's `road_polylines()` cache are **one
piece of work, not two**, and the cache must land first. The cheap version is a
bounding box per line, rejected before the segment loop: the trail's bands are
1.4–3.4 km long and 900 m wide at most, so a pixel in Band 4 rejects Bands 0–2
in three comparisons instead of 54 segment-distance calls. The complete version
caches the `PackedVector2Array` set at `_init` and rebuilds it only when the
config is reloaded, which nothing does at bake time.

Wayfinding along the trail is `paths.trailheads` — the existing one-arm
fingerpost object, already used for The Rise and the South Bridge, and already
reused by `severed_spokes.gd` through `signpost.gd`'s `routes_override`. One
per fork. That is the correct object and it needs no redesign; the junction
post needs no redesign either, because it stops being asked to do a job it
was never built for.

---

## 12. Open questions this document does not settle

- ~~**Whether forty minutes is a walking figure or a floor.**~~ **ANSWERED by
  the owner, 2026-08-16: it is a walking figure.** He was shown the arithmetic —
  §2's corrected sprint cycle gives a sustained 7.00 m/s and a **27.6 minute**
  crossing for a player who works the stamina bar, 31% under the directive,
  against **38.6 minutes** at walk — and the three alternatives it opens
  (lengthen the trail to 16,800 m, retune stamina so the sustained rate falls
  nearer the walk, or accept 27 minutes as the real target). He chose to ship
  the layout as authored.

  So **the 11,594 m spine and the 8192 × 2048 footprint are settled**, and a
  sprinter crossing in 27.6 minutes is the intended outcome rather than a miss:
  sprinting is supposed to save time. Do not re-open this by treating the 40
  in `OW5`'s text as a floor, and do not lengthen the trail to chase it.
- **The bake unit cost has no anchor** (§1.1). 2584 µs/px is measured on this
  container and confirmed by nothing. Every minute figure in this document and
  in `D50` inherits that. A timed single-region bake settles it for the price of
  a coffee.
- **Whether content is free at bake time** (§1.1). The two-tile experiment could
  not answer this because `path_factor` rebuilds `road_polylines()` per call and
  both tiles paid the same road scan. `ralph/PERF1`'s cache had **not** landed
  on `origin/main` as of `5c7ec165`. Re-measure with content varied, not tiles.
- **Whether 2.0 m spacing holds the carves on the statistic that decides it**
  (§1.2). `blocked_60` against carve depth, at the now-fixed origin, on the
  three spoke carves and the gully. The margin is ~5°, not ~15°, and the
  phase-dependent swing is as wide as the margin.
- **The frame cost of a dynamic collision rebuild step** at
  `collision_shape_size` 64 vs 256. §8.2's radius recommendation is reasoned
  from `sprint_speed`, not measured.
- **Whether the `_config` hoist in §1.1 is worth an hour.** Unmeasured. Measure
  before believing the multiplier.
- **Water level in a corridor.** `water.level` is one flat plane for the pond
  and `river.water_level` another for the river. A corridor 8 km long descending
  through four bands cannot use one plane for everything; Band 3's marsh (§6)
  and the pond are 3,600 m apart. `OW5B` needs a plan for more than two water
  bodies, or an authored per-body level.
- **Whether 2,048 m of width is right after the `MQ2B` region is built.** §5's
  own rule is "only as large as the team can make meaningfully dense". If Band
  2's flanks come out empty, the fallback is **1,024 m** (`x ∈ [−512, +512]`,
  two region columns, 32 regions) — the next aligned value down; 1,536 is not
  available at any centring (§1.3a). But narrowing is **not** the cheap edit
  revision 1 implied: at ±512 the spine's own ±430–450 swing uses 84–88% of the
  half-width, all six lateral spoke blockers fall outside the world, and most
  of §3.2's loops have nowhere to go. Narrowing means re-authoring the spine,
  the loops and the spokes together, and it should be decided before `OW5B`
  bakes, not after.
- **How `map_state`'s save format changes** (§8.6a). The recommendation is
  `GRID_X` 512 / `GRID_Z` 128 / `CELL` 16.0, and it is reasoned from the reveal
  radius rather than measured. Whether it lands as a version bump or an explicit
  grid descriptor is `D27`'s question, not this document's.
- **Whether the baked map ships as an asset** (§8.6b). Committing the top-down
  PNG the way the terrain regions are already committed removes a first-launch
  cost from the player's hardware entirely, and nothing about `bake_cached`'s
  design forbids it. Not decided here.
