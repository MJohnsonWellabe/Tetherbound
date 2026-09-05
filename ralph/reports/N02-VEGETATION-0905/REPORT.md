# N02-VEGETATION-0905

**Branch:** `ralph/N02-VEGETATION-0905`
**Base:** `origin/main` @ `f8a47ee45` (`Land W20-SMALL-FIXES, cycle-9 ledger, CURRENT_STATE through cycle 9 (#51)`)
**Sources:** W05-TREELINE-0904, W18-DENSITY-B4-B5-0904, W20-SMALL-FIXES-0904 reports.

Three gaps in `scripts/world/vegetation.gd` that three separate 0904 lanes found and
correctly left alone as outside their own file ownership. All three are addressed. Two of
the three briefs' premises had drifted since they were written, and both drifts are named
below rather than papered over — the fixes landed on what is actually true on `main`
today, and the tests were seen red for exactly the right reason before they went green.

## 1. Files changed

| File | Why |
|---|---|
| `scripts/world/vegetation.gd` | items 1 and 2 |
| `tests/test_vegetation_siting.gd` (+ `.uid`) | new — 18 tests covering all three items |
| `tools/_probe_n02_occluders.gd` (+ `.uid`) | new — the per-layer soft-occluder census quoted in §3 |
| `ralph/reports/N02-VEGETATION-0905/REPORT.md` | this file |

Nothing else. `meadow_healing.gd`, `band_pickups.gd`, `data/config/bands/*` and
`data/config/vegetation.json` were not touched — see §6 for the one thing that made me want
to and what I did instead.

## 2. Item 1 — `PROP_OFFSET` was one constant for a 10x range of scales

**What the brief said, and what is actually on `main`.** W05's finding assumed its own
tree-scale change had landed ("fill now reaches scale 2.0, heroes reach 2.7"). It did not —
W05 was rejected twice by the landing lane (`ralph/briefs/0904/LANES.md`, cycles 6 and 8),
so `main` still carries `trees.scale_max` 1.45 / `trees.heroes.scale_max` 2.1. The numbers
below are re-derived from `main`'s own `data/config/vegetation.json`, not quoted from W05.

**The defect is real anyway, and bigger than the tree case.** `PROP_OFFSET`'s own comment
claimed 1.3 m cleared "the widest trunk this scatter places (CommonTree at 1.35 scale)".
It does not clear the widest thing this scatter places, and cannot: the pile's distance was
one constant against a footprint (`collision_radius` × placement scale, the same number
`_make_collision_shape()` builds the collider from) that spans 0.17 m to 2.61 m across the
harvestable layers. Measured on `main` at `f8a47ee4`:

| layer | top scale | `collision_radius` | footprint | old offset | clears? |
|---|---|---|---|---|---|
| `saplings` | 0.5 | 0.35 | 0.18 m | 1.30 m | yes |
| `trees` (fill) | 1.45 | 0.6 | 0.87 m | 1.30 m | yes |
| `trees` (heroes) | 2.1 | 0.6 | 1.26 m | 1.30 m | by 0.04 m |
| `grove` (heroes) | 1.35 | 1.1 | **1.49 m** | 1.30 m | **no** |
| `rocks` (anchors) | 2.9 | 0.9 | **2.61 m** | 1.30 m | **no** |

**What changed.** `_prop_offset_for(placement)` derives the distance from the placement's
own scale — `collision_radius × scale + PROP_CLEARANCE` — and `PROP_OFFSET` becomes the
floor, so every placement small enough to have been cleared by the old constant lands on
exactly the distance it landed on before (scale ≤ 1.17 for `trees`, ≤ 0.78 for `rocks`).
`PROP_CLEARANCE` is 0.6 m, measured off the pile rather than guessed:
`felled_resource.gd::_build_woodpile()` lays `log.glb` (0.710 m long) at ±0.15 m either side
of centre, so the pile's own half-span is ~0.50 m and 0.6 puts the *whole* pile outside the
footprint, not only its centre. At a `trees` hero that lands the pile 1.86 m out, which is
where W05 independently asked for it ("~1.9 m").

**Honest scope, because the symptom W05 named no longer reproduces.** W05 described "a
felled-wood prop pile beside a large harvest-marked tree can sit inside the trunk". Since
RG9, `fell()` calls `harvest_permanently()` *before* `_spawn_felled()`, so the standing
tree/rock is already gone by the time the pile appears and a pile cannot intersect its own
trunk today. What was still wrong is that the distance did not track the thing it is a
distance *from*: a felled `rocks` anchor 5.2 m across left its rubble 1.3 m from the
boulder's centre, i.e. inside the ground the boulder had been standing on rather than beside
where it stood. This is a derivation fix, not a fix for a sighting, and it is written that
way in the code comment too.

## 3. Item 2 — `has_solid_scatter_near()` could not see non-colliding scatter

**What the brief said, and what is actually on `main`.** W18 wrote that the query "sees
only the collision batches". That was true when W18 ran; `08c85015`
(OWNER-0901-CREATURE-GRASS-VISIBILITY-V2) has since added a second pass over a
**bushes-only** position list at one flat 1.2 m radius. So the gap on `main` today is
narrower than the brief states but still real: it is one layer at one radius, and the
layer that most obviously buries a pickup — `deadfall`, whose `DeadTree_*` meshes are
5.7–6.4 m across and carry `collides: false` — was invisible to it.

**What changed.** The bushes-only list becomes a general soft-occluder list
(`_soft_occluder_positions` + `_soft_occluder_radii`) with a **per-placement** reach taken
from the model's own glTF bounding box (`_model_footprint_radius()`, half the wider of
X/Z, cached per model) times the placement's own scale, floored at the old bushes radius so
the check can never come out looser than what it replaced. `has_solid_scatter_near()`'s
name and signature are unchanged, as the brief required — `band_pickups.gd`,
`encounter_director.gd`, `tools/_probe_band_density.gd` and `tools/_probe_spawn_siting.gd`
all call it exactly as before.

**Which layers qualify, and why this is a named list rather than a threshold.** Measured
with `tools/measure_models.gd` (glTF bounding box, X × Y × Z metres) against each layer's
realised `base_scale × scale_max`:

| layer | widest model | realised | verdict |
|---|---|---|---|
| `bushes` | Bush_Common 1.91 × 1.58 × 1.97, Fern_1 2.83 × 0.84 × 2.65 | up to 1.27 m radius | **in** |
| `deadfall` | DeadTree_3 6.39 × 13.28 × 6.43 | 5.2 m wide, 10.7 m tall | **in** |
| `drygrass` | Grass_Wispy_Tall 1.54 × 1.67 × 1.59 | 0.49 m radius | out |
| `groundmat` | Plant_1_Big 1.81 × 2.35 × 1.95 | 0.45 m radius | out |
| `grass` | Grass_Wide_Tall 1.15 × 1.61 × 1.11 | 0.33 m radius | out |
| `flowers` | Flower_4_Group 1.78 × 2.49 × 1.37 | 0.08 m radius | out |
| `path_stones` | RockPath_Round_Wide 2.11 × 0.11 × 2.13 | 1.49 m radius but **0.11 m tall** | out |

Size alone cannot make this split — a `drygrass` clump (0.49 m) is wider than a small
`bushes` instance (0.40 m), and `path_stones` is wider than either while being flat stone
on the trail. So the two qualifying layers are named in the file, generalising the pattern
`_bush_positions` already used, with the measurements above written into the comment.

**Why the ground-cover exclusion is the load-bearing half of this.** Census over the
committed bake (`tools/_probe_n02_occluders.gd`, reproducible in ~40 s):

```
bushes            41229  soft=true   reach 1.20-1.27 m
deadfall            139  soft=true   reach 1.20-2.68 m
grass            369831  soft=false
groundmat        147649  soft=false
drygrass         134633  soft=false
flowers           70815  soft=false
path_stones        9022  soft=false
trees             43051  soft=false   (collidable, already covered)
rocks              6473  soft=false   (collidable)
grove               358  soft=false   (collidable)
saplings           2779  soft=false   (collidable)
total 825979
```

731,950 placements — 88.6% of the world's scatter — are ground cover. At
`band_pickups.gd`'s own 1.6 m clearance margin a 0.33 m grass clump answers "occupied" over
a 1.9 m disc, and enough of those tile the whole meadow; including them would not tighten
the check, it would make it return true everywhere and every authored pickup unplaceable.
That is asserted directly by `test_ground_cover_is_not_treated_as_an_occluder`.

**The list grows by 139 entries (41,229 → 41,368), so the query cost is unchanged** — it
was already a linear scan over every bush in the world.

## 4. Item 3 — `restore_drained()` was already correct and completely untested

`restore_drained(within)` is **already on `main`**: W20-SMALL-FIXES landed it at `f8a47ee4`
(CL-E12), and `meadow_healing.gd::_heal_the_scatter_within()` is already reduced to a single
`vegetation.call("restore_drained", discs)`. Every detail the brief specifies is present and
correct — the `held` dict, the early return that assigns `held` rather than clearing, the
final `_drained = held`, `_regrown +=` rather than `=`, and `_inside_any()`'s empty-list
`return true`. I verified each line rather than rewriting any of it.

What was genuinely missing is the thing the brief's acceptance criterion actually asks for:
**there was no unit test for any of it**, on `main` or anywhere. `grep -rn restore_drained
tests/` matched nothing; only `smoke_relay_station.gd` exercised it, and only end to end.
Eight new unit tests now pin it, including the empty-`within` trap named as the one most
likely to silently break the `legendary_freed` heal.

## 5. Tests

Godot 4.7-stable installed in-container (none was present) and used for every run below.
Every command was run from the repository root with `export PATH=$HOME/godot-bin:$PATH`.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_vegetation_siting.gd` | **18 tests, 57 assertions, 0 failed** |
| `… --only=test_scatter_rules.gd,test_veg_corridor.gd,test_band_vegetation.gd,test_scatter_perf_budget.gd` | **55 tests, 2,557,512 assertions, 0 failed** |
| `… --only=test_harvest.gd,test_harvest_permanence.gd,test_band_pickups.gd` | **74 tests, 1,046,823 assertions, 0 failed** |
| `godot --headless --path . --script tests/smoke_playground.gd` | OK, exit 0 (twice) |

`test_vegetation_siting.gd` runs in **1 s wall**, so it adds nothing measurable to whichever
of CI's four `verify-unit-tests` shards it lands in.

The four-suite run is the set the brief names, run with all four in one `--only=` as asked.
It includes `test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh`,
which is the exact assertion CI's `verify-scatter-bake-freshness` job runs — **green, so no
scatter re-bake is needed**, confirming the brief's expectation that item 2 is a query-time
change and touches no placement data. The harvest set is not in the brief but
`_spawn_harvest_point()` is where item 1 lands, so it is the suite that would break.

### Seen red first, for the right reason

Six mutations, each reintroducing one specific defect, each run against the same 18 tests:

| # | Mutation | Red |
|---|---|---|
| 1 | `_prop_offset_for()` returns `PROP_OFFSET` (i.e. `main`) | 2 failed — `rocks` at 2.90: pile at 1.30 m inside a 2.61 m collider; `grove` at 1.35: 1.30 m inside 1.49 m |
| 2 | `SOFT_OCCLUDER_LAYERS` cut back to `["bushes"]` (i.e. `main`) | 1 failed — a pickup 2.0 m from a full-size dead tree reads as clear |
| 3 | per-placement reach replaced by the flat floor | 1 failed — same test, so the bounding-box derivation is load-bearing, not decoration |
| 4 | `_inside_any()` empty list → `return false` (**the trap**) | **5 failed** — every unfiltered heal becomes a no-op |
| 5 | `_regrown = _placed - before` instead of `+=` | 1 failed — two partial heals of two plants report 2, not 4 |
| 6 | `_drained.clear()` instead of `_drained = held` | 2 failed — a partial heal drops the un-healed remainder |

Restored: 18 tests, 57 assertions, 0 failed. No test in this file can pass by reading source
text; the `PROP_OFFSET` test in particular checks the offset against the cylinder radius
`_make_collision_shape()` actually builds for the same placement, not against a number
retyped from the config.

## 6. Runtime validation

`smoke_playground.gd` booted the real corridor on **`main`'s `vegetation.gd`** and on **this
branch's**, twice each, alternating, on the same tree and the same committed bake:

| | props scattered | band pickups |
|---|---|---|
| `main` @ `f8a47ee4` | 385,333 in 36 batches, 57,770 harvestable | 101 placed, 0 taken, **24 nudged, 3 unclear**, 0 without ground |
| this branch | 385,333 in 36 batches, 57,770 harvestable | 101 placed, 0 taken, **24 nudged, 3 unclear**, 0 without ground |

**Identical, and that is the correct result, not a null one.** Only 139 of the world's
825,979 placements are `deadfall`, and none of the 101 authored band-pickup sites happens to
fall within reach of one. The change closes the query's blind spot without moving a single
authored site today; the next lane that authors a site next to a dead tree gets told.

One flake seen and cleared: `main`'s first `smoke_playground` run failed on
`smoke FAIL: the gather resolved 0.81 through the swing, well past the 0.60 impact pose`.
The same tree passed on the immediate re-run, and this branch passed both of its runs. It
is a load-dependent timing assertion on the chop-swing animation, in no path this lane
touches — recorded as an observed intermittent on `main`, not as anything fixed here.

No visual work was done and no blind judge was run: nothing here changes a rendered frame.
Item 1 moves a felled pickup that only exists after the player chops something, by 0.19 m
at a `trees` hero and 1.91 m at the single largest `rocks` anchor; item 2 is a query-time
predicate with no render side; item 3 is tests only. The `smoke_playground` A/B above is the
runtime evidence in place of frames.

**CI could not be checked from this container.** The GitHub REST API is refused from this
session (`403 GitHub access is not enabled for this session`) and no `gh` binary is
installed, so the three pushes to `ralph/N02-VEGETATION-0905` have triggered runs I cannot
read. Everything CI would run for these files was run locally instead and is in the table
above, including the exact `--only=` selector `verify-scatter-bake-freshness` uses. **The
landing lane must still open the run** — per the process rule, a self-report is not
evidence.

## 7. Routed findings — not this lane's files

- **The herd bull's Rare cannot be un-buried by nudging, and never could.** W18's own case
  (`b4_candy_herd_bull_highfield` at 442, 5830) is *already* flagged on `main` —
  `smoke_playground` warns `sits inside solid scatter and no spot within 5m was clear; move
  it`, along with `b4_candy_wind_ridge_crest` and `b5_candy_alpha_galecrest_pack`. So the
  site validator is not failing to *notice* these three; the nudge search is failing to
  *solve* them, because `band_pickups.gd::NUDGE_RADII_M` stops at 5 m and the sites are
  genuinely enclosed. Fixing it means either widening the nudge search or moving the
  authored coordinates — `scripts/world/band_pickups.gd` and `data/config/bands/*`, both
  explicitly outside this lane's ownership. **Ask:** give those three sites a wider nudge
  budget or re-author them; the vegetation query is now telling the truth about all three.
- **`clear_area()` does not purge the soft-occluder list** (nor did it purge
  `_bush_positions` before this change). After the Burrow Warrens clears 660 props and the
  stronghold 205, this query still counts any bush/deadfall among them. That is conservative
  in the safe direction — a cleared site reads as busier than it is, never emptier — so it
  cannot bury anything, and fixing it properly means indexing the list by position the way
  `_instance_positions` is. Named in the code comment and left alone deliberately rather
  than fixed as a drive-by inside a query-only change.
- **`_layer_for()` / `_layer_name_for()` still cannot see an anchor that overrides its
  layer's `models` list.** Pre-existing, documented on those functions, and inherited by
  both `_prop_offset_for()` and `_record_soft_occluders()`. An anchor-override model falls
  back to the floor / is not recorded, i.e. exactly today's behaviour.

## 8. Known limitations, and what was deliberately not done

- **`docs/CURRENT_STATE.md` was not edited.** `ralph/briefs/0905-followup/COMMON.md` says to
  stay inside the brief's file list exactly because lanes in this wave run concurrently, and
  my brief's ownership is `vegetation.gd` and its own tests/bake. Thirteen lanes each
  rewriting one status row is a guaranteed conflict for the landing lane; this report is the
  record instead.
- **No decision document.** Nothing here chooses between materially different game
  behaviours — `PROP_CLEARANCE` and `SOFT_OCCLUDER_LAYERS` are tunables with their
  measurements written next to them, not design calls. The next free number is still D87.
- **`SOFT_OCCLUDER_LAYERS` is a hardcoded list in the script, not a config key.** A
  `visually_solid: true` flag in `data/config/vegetation.json` would be cleaner, but that
  file is a re-bake-fingerprint input and adjacent lanes in this wave touch world dressing;
  a script-side list generalises what `_bush_positions` already hardcoded and costs nothing
  to move later. Recorded rather than done.
- **Item 1's effect is not observable in a frame today**, for the RG9 reason in §2. If a
  later lane reintroduces a prop beside a *standing* harvest point, this is already the
  function it should ask.
- **`_regrown` accumulation is tested through an overridden `_build_batch`**
  (`CountingVegetation` in the test file) because the real one needs a live Terrain3D to get
  a mesh id and no-ops without one. The arithmetic under test is the partition and the
  counters, which is what the brief names; the instancer half is `smoke_relay_station.gd`'s,
  and it still passes.

## 9. Commits

| Commit | What |
|---|---|
| `4687df271` | `vegetation.gd` items 1 and 2, plus `tests/test_vegetation_siting.gd` |
| `79eb92aeb` | the census probe and the first push of this report |
| _head_ | this hash table, corrected after `79eb92aeb` changed under an amend |

**Every claim above is reproducible at `4687df271`**, which is the whole of the shipped
change — the two commits after it add only `tools/_probe_n02_occluders.gd` and this file.
Final state is the head of `ralph/N02-VEGETATION-0905`. No pull request opened, per the
lane rules.
