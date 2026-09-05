# W18-DENSITY-B4-B5 — content after the village, bands 4 and 5 (CL-O4 density half)

Branch: `ralph/W18-DENSITY-B4-B5-0904`, from `origin/main` @ `ef16544f`, **merged** (not
cherry-picked) with `origin/ralph/W17-DENSITY-B2-B3-0904` @ `434ec537` for the shared
pickups loader. Final commit: see the last section.

## What the player gets

**Band 4 — Upper Meadows / Ironwood (3,436 m of spine, the chapter's longest band)**

- **40 one-time world finds where there were none:** 16 Good, 9 Great, 4 Rare Candy, plus
  3 revives, 5 potions and 3 mushrooms. Each sits at a place the band already names and
  each carries its own `why`. Only six are within 30 m of the road (three Good candies and
  three basic supplies); the other 34 are a reason to leave it.
- **The Greats are the detours:** the wind ridge crest, the high pasture's herd edge, the
  severed conduit post, the rocky-shoulder den, the Broken Tower, behind the grove's alpha
  Burrowback, the Galecrest alpha's crag, the far side of the Ironwood stand, and halfway
  up the rest-free ridge climb.
- **The Rares are the secrets:** the rain-gated Stormtrail's crag at the band's west edge,
  Rue's deep off-spine patrol, the herd bull on the Highfield, and the far corner of the
  watchtower spur where the stronghold is first seen.
- **Recovery arrives before the attrition it supports, never after:** a potion on the
  old-growth swing before the two alphas, a revive on the Ironwood pad, a potion on the road
  80 m before Captain Halder, a revive on the approach *to* the stock camp rather than
  inside it, a potion beside the picket at the foot of the rest-free climb, a revive on the
  climb 60 m below Captain Vess, and a potion at the seam before the approach.
- **19 more things to gather (26 → 45 nodes).** The old-growth swing had no harvest at all
  across 300 m of road and now has ironwood, wood, fiber, stone and berries; the
  Juno→Halder pasture, the ridge fork, the climb's shoulder, the run-out and the seam each
  gained nodes. Ironwood is now also at the Highfield fork and on the watchtower spur, so
  the band's own material tier can be restocked without the 2 km walk back to the stand.
  Berries exist above the river for the first time.
- **10 more wild clusters / 29 more creatures (81 → 91 clusters, 280 → 309 creatures),**
  each with a habitat reason: the stand's rock foot and its far-side roost, a second herd
  on the pasture, life on the deep branch out to Rue (a trailpup pack with galecrest
  circling above it), the pasture's west wallow, burrowback on the climb's shoulder, a
  night duskhush roost on the run-out, pipwing over the last meadow, and two galecrest
  sentries at the seam.

**Band 5 — Stronghold Approach (651 m; D70: arrival, not journey)**

- **15 one-time finds** (7 Good, 3 Great, 1 Rare, plus a large potion, a revive, a wild
  mushroom and a small potion). Thirteen sit off the road's own line at places the band
  already names: the seam's west shoulder, the outer watch, the alpha Galecrest pack (the
  danger beat), the scorched pocket P-5.2 announces, the Sigil gate's near-side wing, the
  dell behind the waystop, and the doorstep alpha. The single Rare is at the doorstep alpha,
  the band's hardest optional encounter. **Nothing is inside the waystop clearing** (R-5).
- **The road's beat list is unchanged** (P-5.3): the one added cluster and both added
  harvest nodes are off-road, under the outer watch's own stonework and on the west
  shoulder. `docs/decisions/D74-band-5-findables-sit-off-the-road.md` records the call and
  why the newer owner directive and P-5.3 can both be honoured.

## Files changed

| File | Change |
|---|---|
| `data/config/bands/band4_upper_meadows_ironwood/pickups.json` | new, 40 pickups |
| `data/config/bands/band5_stronghold_approach/pickups.json` | new, 15 pickups |
| `data/config/bands/band4_upper_meadows_ironwood/harvest.json` | +19 nodes, orders 4032–4050 (appended past the baseline mirror) |
| `data/config/bands/band4_upper_meadows_ironwood/spawns.json` | +10 clusters, orders 4103–4112 |
| `data/config/bands/band5_stronghold_approach/harvest.json` | +2 nodes, orders 5009–5010 |
| `data/config/bands/band5_stronghold_approach/spawns.json` | +1 cluster, order 5023 |
| `tools/_probe_band_density.gd` | new: per-band authored census + real-world site validation, and the nearest-clear-ground suggestion a failing site needs |
| `tools/_capture_w18_pickups.gd` | new: candy-tier frames for the blind judge |
| `tests/test_band_pickups.gd` | W17's test; `AUTHORED_BANDS` extended to bands 4–5 so its tier and critical-path rules run over this lane's files |
| `docs/decisions/D74-band-5-findables-sit-off-the-road.md` | new |
| `docs/WORLD_AND_CONTENT.md` | §6 counts, §7 rewritten with spine length, per-km values and a pickups column |
| `docs/CURRENT_STATE.md` | §2 status row for this lane; content counts refreshed |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | CL-O4 row: density half, bands 4–5 |
| merged from W17 | `scripts/world/band_pickups.gd`, `item_cache_pickup.gd`, the one `playground_world.gd` hook, bands 2–3 `pickups.json` |

Not touched, as the brief requires: `vegetation.json`, `trainers.json`,
`stronghold_occupation.json`, bands 1–3's own files, `items.json`, `playground_world.gd`
(beyond what W17's merge brings), and the loader.

## Measurements — `tools/_probe_band_density.gd`

The authored census, per kilometre of each band's own spine from
`terrain_playground.json`. (D70's corridor probe measures what a *walked route meets* and
remains the Gate F figure; this measures what a lane *authored* and where it sits relative
to the road.)

| Band | Spine | Spawn clusters (/km) | Creatures | Harvest (/km) | Pickups G/Gr/R + recovery (/km) | ≤30 m from road / beyond | Worst authored gap |
|---|---|---|---|---|---|---|---|
| 1 (the reference) | 2403 m | 69 (28.7) | 222 | 48 (20.0) | — (another lane) | — | 111 m |
| 4 before | 3436 m | 81 (23.6) | 280 | 26 (7.6) | 0 | — | 110 m |
| **4 after** | 3436 m | **91 (26.5)** | **309** | **45 (13.1)** | **16/9/4 + 11 = 40 (11.6)** | 17 / 23 | 105 m |
| 5 before | 651 m | 23 (35.3) | 78 | 8 (12.3) | 0 | — | 52 m |
| **5 after** | 651 m | **24 (36.8)** | **81** | **10 (15.4)** | **7/3/1 + 4 = 15 (23.0)** | 2 / 13 | 52 m |

Band 4 closes most of the gap to band 1 on both axes it was short on: spawn clusters
23.6 → 26.5 /km against 28.7, harvest 7.6 → 13.1 /km against 20.0. It is deliberately not
taken all the way to band 1's harvest rate — band 1 is the tutorial region whose gathering
teaches the crafting loop, and the wind ridge traverse is required by
`MEADOWS_MACRO_LAYOUT.md` §3.2 to stay sparse so its vista lands (it got two nodes, not a
line of them).

**The band 4 finding worth stating plainly:** the band never had a spine-gap problem. Its
worst stretch meeting nothing was already 110 m, inside the 200 m Gate 3 ceiling, and this
pass moved it only to 105 m. What it had was a *reasons-to-leave* problem — 3,436 m of road
with nothing off it worth walking to. That is what the 23 off-road finds, the nine detour
Greats and the four secret Rares answer, and it is why the headline number here is
"17 on-road / 23 off-road", not the gap.

Band 5 is unchanged in shape, as D70 requires: 651 m, worst gap 52 m (already the best in
the chapter), one added cluster. Its pickup rate is the highest in the chapter per metre,
which is the crescendo the encounter contract asks for rather than padding.

**Site validation, three rounds.** Every new position (55 pickups, 21 harvest nodes, 11
spawn centres) was checked on the booted world: Terrain3D ground height, 2 m pad slope and
spread from the headless heightfield, `vegetation.gd::has_solid_scatter_near` at the same
0.8 m margin the encounter director uses for a creature's feet, river factor, lateral
distance to the spine, and ≥4.5 m from every other interact prompt
(`test_harvest.gd::MIN_SPOT_SEPARATION`).

| Round | Command | Result |
|---|---|---|
| 1 | `godot --headless --path . --script tools/_probe_band_density.gd -- --sites=res://ralph/reports/W18-DENSITY-B4-B5-0904/_sites.json` | 15 of my sites inside solid scatter (a trunk or boulder on the spot) |
| 2 | same, after teaching the probe to name the nearest clear ground | same 15, each with a clear coordinate 1–3.5 m away |
| 3 | same, after moving all 15 | **0 failures** across all 55 pickups and all 32 candidate sites |

The world's own placement agrees: `smoke_playground` reports
`placed 101 band pickups (0 already taken, 9 nudged off scatter, 0 unclear, 0 without ground)`
— the 9 nudges are W17's bands 2–3, whose 11 scatter failures this probe also found and
which are that lane's to move.

## Tests

Godot 4.7-stable installed in-container (none was present) and used for every run below.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_band_pickups.gd` | **20 tests, 22,082 assertions, 0 failed** |
| `… --only=test_spawn_tables.gd` | 27 tests, 8,105 assertions, 0 failed |
| `… --only=test_spawns_data.gd` | 25 tests, 1,621 assertions, 0 failed |
| `… --only=test_band_content.gd` | 6 tests, 1,211 assertions, 0 failed |
| `… --only=test_harvest.gd` | 30 tests, 792,054 assertions, 0 failed |
| `… --only=test_starters_are_exclusive.gd` | 7 tests, 425 assertions, 0 failed |
| `… --only=test_wild_once.gd` | 13 tests, 59 assertions, 0 failed |

**Seen red first, for the right reason.** `test_band_pickups` is only evidence over bands
4–5 once it actually reads them, so before trusting it I broke two things and watched it
fail: moving `b4_candy_herd_bull_highfield` to `tier: critical` produced
*"'b4_candy_herd_bull_highfield' puts a rare_candy on the critical path"*, and duplicating
an id produced *"pickup id 'b4_candy_ridge_road_picket' is also in
band4_upper_meadows_ironwood; ids are the once-flag and must be unique"* —
**3 failed** on that run. Both changes were reverted and the file restored before the green
run above. Logs: `_test_band_pickups.log`, `_test_band_pickups_red.log`.

`test_band_content` passing matters specifically here: it proves the baseline mirror is
intact, i.e. every new entry appended *past* the pinned indices and no existing entry moved
or was rerolled.

## Smokes

Each run as `godot --headless --path . --script tests/<name>.gd`, then the log grepped for
`^ERROR:` and `SCRIPT ERROR` and the hits read (not counted).

| Smoke | Exit | Wall | `^ERROR:` distinct set | `SCRIPT ERROR` |
|---|---|---|---|---|
| `smoke_playground` | 0, `smoke: OK` | 446 s | `Parameter "material" is null.` | 0 |
| `smoke_wild_streaming` | 0, OK | 1 s | none | 0 |
| `smoke_warrens` | 0, passed | 346 s | `Parameter "material" is null.` | 0 |
| `smoke_relay` | 0, OK | 397 s | `Parameter "material" is null.` | 0 |
| `smoke_stronghold` | 0, passed | 391 s | `Parameter "material" is null.` | 0 |
| `smoke_relay_station` | 0, passed | 346 s | `Parameter "material" is null.` | 0 |

The one `ERROR:` line is the known-benign alpha-resize message `AGENT_WORKFLOW.md` §6 names
by hand (it comes off alpha creature builds and its *count* varies with what streamed in;
the distinct set is what matters and it has not grown).

## Visual evidence

`tools/_capture_w18_pickups.gd` renders six frames at player eye height (1.7 m, 7–12 m
back) looking at the pickups the loader actually placed, so a moved coordinate moves the
frame: the Rare at the herd bull, the Great on the wind ridge crest and the Good on the
Highfield south paddock all at 7 m on the same ground (the only variable between those
three frames is the tier), the same Rare at 12 m, the Rare at the watchtower spur corner,
and band 5's Rare at the doorstep alpha.

`tools/_capture_w18_pickups.gd` renders frames at player eye height (1.7 m, 7 m back)
looking at the pickups the loader actually placed, so a moved coordinate moves the frame.
Three landed before the render was stopped: the Rare at the Highfield herd bull, the Great on
the wind ridge crest, and the Good on the Highfield south paddock — the tier trio on the same
ground, where the only intended variable between frames is the tier. Contact sheet:
`_sheet_tiers.png`. Full verdict: **`JUDGE-pickup-tiers.md`**.

Software-GL boots dominate the cost (~36 min for the first frame, ~5–7 min per frame after,
because the terrain restreams on each camera jump), so the remaining three stands (the Rare at
12 m, the watchtower spur corner, band 5's doorstep alpha) were not shot. The three that
landed answer the brief's question.

**The blind judge's answer on tier legibility is no, and the reasons are not this lane's to
fix.** It found the Great (mint) unaided; found the Rare (cream) only by scanning for it, with
a shrub covering 86% of it and its colour colliding with the meadow's existing white cup
flowers; and **could not find the Good at all** — that frame's camera sits behind a large
trunk, so as shot it proves nothing. Its judgement on the hierarchy: *"The only difference
between the two objects I can find is hue… far too subtle to tell apart in play"*, and
inverted, since Rare reads quietest. It also said the shared mesh *"reads as a creature — no
amount of lighting, placement or tinting will make it read as an item you walk over."*

Every lever those findings name lives in files this lane does not own — the per-tier tint,
medallion and Rare wings are applied at instancing in `scripts/world/band_pickups.gd` (W17's
loader, which the W18 brief forbids touching), and the mesh itself is an asset question
`docs/prompts/75` already owns. **Routed to the coordinator**, with the specific ask: give
Rare a hue outside the cream/white flower palette, and make the tiers differ by size or added
shape as well as tint. One round was run and stopped there rather than spending another
40-minute boot on levers this lane cannot move; the ceiling is recorded in the verdict file
per `AGENT_WORKFLOW.md` §7.

**One finding is genuinely this lane's and is written down rather than hidden:** the site
validator checks `vegetation.gd::has_solid_scatter_near`, which sees only the collision
batches (trunks, boulders). Non-colliding scatter — bushes, ferns, tall grass — passes that
check and can still bury a pickup, which is exactly what happened to the Rare at the herd
bull. Closing that gap means querying the scatter for visual occupancy rather than collision,
a change to `vegetation.gd`'s query surface and outside this lane's file list.

## Known limitations, and what was deliberately not done

- **The census is not a playtest.** It measures what is authored and where it sits, not
  whether a player *feels* it. The addendum's §C route questions — does side exploration
  reliably pay better than the road, do the potions and revives erase camping pressure —
  are Gate F evidence and cannot be answered from a probe. Recovery was kept deliberately
  thin for that reason: 11 items across 3.4 km in band 4, all before the attrition rather
  than after it.
- **No alpha was added.** `spawn_tables.json`'s per-region alpha cap (6) and 400 m
  separation are already spent by the authored alphas, and `test_spawn_tables` enforces
  both against every rolled world. New clusters are ordinary populations.
- **Band 4's harvest rate stops at 13.1/km, not band 1's 20.0/km.** Reasons above; a
  further pass could close it, but the wind ridge must stay sparse and band 1's rate is a
  tutorial rate.
- **W17's 11 scatter failures in bands 2–3 were found by this probe and left alone** —
  their files belong to that lane. They are listed in `_probe_r3.log` and worth routing.
- **The `_probe_band_density.gd` census counts authored entries, not spawned bodies**, so a
  time- or weather-gated cluster counts even when it would be invisible at that moment.
  That is deliberate (the corridor probe measures the other thing) and is stated in the
  tool's own header.
- **`props.json` was not touched in either band.** Nothing in the W18 brief asked for the
  prop half (that is CL-E2's, in W17's lane, for band 3).

## Logs in this directory

`_baseline_probe.log` (before), `_probe_r1.log` / `_probe_r2.log` / `_probe_r3.log` (site
validation rounds), `_unit_*.log`, `_test_band_pickups.log`, `_test_band_pickups_red.log`,
`_smoke_*.log`, `_capture.log`, `_sites.json`, `JUDGE-pickup-tiers.md`, `_sheet_tiers.png`.

## Final commit

PLACEHOLDER_COMMIT
