# W18-DENSITY-B4-B5 — content after the village, bands 4 and 5 (CL-O4 density half)

Branch: `ralph/W18-DENSITY-B4-B5-0904` (from `origin/main` @ `ef16544f`, merged with
`origin/ralph/W17-DENSITY-B2-B3-0904` @ `434ec537` for the pickups loader).
Final commit: **see the last section** (filled when pushed).

## What the player gets

**Band 4 — Upper Meadows / Ironwood (3,436 m of spine)**

- **40 one-time world finds** where there were none: 16 Good, 9 Great and 4 Rare Candy
  plus 3 revives, 5 potions and 3 mushrooms. Each sits at a place the band already names
  and each carries a `why`. The road carries only three Good candies and three basic
  supplies; the Greats are on the loops and at the named points of interest (the wind
  ridge crest, the high pasture's herd edge, the severed conduit post, the rocky-shoulder
  den, the Broken Tower, behind the grove's alpha Burrowback, the Galecrest alpha's crag,
  the far side of the Ironwood stand, halfway up the rest-free climb); the Rares are the
  answer to "why go over there": the rain-gated Stormtrail's crag, Rue's deep-branch
  patrol, the herd bull on the Highfield, and the far corner of the watchtower spur where
  the stronghold is first seen.
- **Recovery before attrition, never after:** a potion on the old-growth swing before the
  two alphas, a revive on the Ironwood pad, a potion on the road before Halder, a revive on
  the approach to the stock camp (not inside it), a potion beside the picket before the
  rest-free climb, a revive on the climb below Vess, a potion at the seam before the
  approach. Mushrooms (speed / stamina / wild) sit on detours.
- **19 more things to gather** (26 → 45 nodes): the old-growth swing had no harvest at all
  over 300 m and now has ironwood, wood, fiber, stone and berries; the Juno→Halder pasture,
  the ridge fork, the climb's shoulder, the run-out and the seam each got nodes. Ironwood
  is now also at the Highfield fork and on the watchtower spur, so the tier can be
  restocked without the 2 km walk back to the stand. Berries exist above the river for the
  first time.
- **10 more wild clusters / 29 creatures** (81 → 91 clusters, 280 → 309 creatures) with a
  habitat reason each: the stand's rock foot and its far-side roost, a second herd on the
  pasture, life on the deep branch out to Rue (a trailpup pack, galecrest circling above),
  the pasture's west wallow, burrowback on the climb's shoulder, a night duskhush roost on
  the run-out, pipwing over the last meadow, and two galecrest sentries at the seam. No
  alpha is added; levels resolve from `chapter_curve.json` as before.

**Band 5 — Stronghold Approach (651 m; D70: short on purpose)**

- **15 one-time finds** (7 Good / 3 Great / 1 Rare + a large potion, a revive, a wild
  mushroom, a small potion), twelve of them off the road at the places the band already
  names (the seam's west shoulder, the outer watch, the alpha Galecrest pack, the scorched
  pocket P-5.2 announces, the Sigil gate's near-side wing, the dell behind the waystop, the
  doorstep alpha). The Rare is at the doorstep alpha, the band's hardest optional encounter.
  Nothing is inside the waystop clearing (R-5).
- **The road's beat list is unchanged** (P-5.3): the one added cluster and both added
  harvest nodes are off-road under the outer watch's own stonework and on the west shoulder.
  `docs/decisions/D74-band-5-findables-sit-off-the-road.md` records the call.

## Files changed

| File | Change |
|---|---|
| `data/config/bands/band4_upper_meadows_ironwood/pickups.json` | new: 40 pickups |
| `data/config/bands/band5_stronghold_approach/pickups.json` | new: 15 pickups |
| `data/config/bands/band4_upper_meadows_ironwood/harvest.json` | +19 nodes, orders 4032–4050, appended (baseline mirror untouched) |
| `data/config/bands/band4_upper_meadows_ironwood/spawns.json` | +10 clusters, orders 4103–4112, appended |
| `data/config/bands/band5_stronghold_approach/harvest.json` | +2 nodes, orders 5009–5010 |
| `data/config/bands/band5_stronghold_approach/spawns.json` | +1 cluster, order 5023 |
| `tools/_probe_band_density.gd` | new: per-band authored census + real-world site validation (shared with W17) |
| `tools/_capture_w18_pickups.gd` | new: tier frames for the blind judge |
| `tests/test_band_pickups.gd` | W17's test; `AUTHORED_BANDS` extended to bands 4–5 so the tier/critical-path rules run over this lane's files |
| `docs/decisions/D74-band-5-findables-sit-off-the-road.md` | new |
| `docs/WORLD_AND_CONTENT.md` | §6/§7 tables: counts, per-km values, pickups row |
| `docs/CURRENT_STATE.md` | §2 row for this lane; content counts |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | CL-O4 row: density half, bands 4–5 |
| merged from W17 | `scripts/world/band_pickups.gd`, `item_cache_pickup.gd`, `playground_world.gd` hook, bands 2–3 `pickups.json` |

## Measurements (`tools/_probe_band_density.gd`, authored census per band's own spine)

| Band | Spine | Spawn clusters (/km) | Creatures | Harvest (/km) | Pickups G/Gr/R + rec. (/km) | on-road (≤30 m) / off | Worst authored gap |
|---|---|---|---|---|---|---|---|
| 1 (reference) | 2403 m | 69 (28.7) | 222 | 48 (20.0) | — | — | 111 m |
| 4 before | 3436 m | 81 (23.6) | 280 | 26 (7.6) | 0 | — | 110 m |
| **4 after** | 3436 m | **91 (26.5)** | **309** | **45 (13.1)** | **16/9/4 + 11 = 40 (11.6)** | 17 / 23 | FILL |
| 5 before | 651 m | 23 (35.3) | 78 | 8 (12.3) | 0 | — | 52 m |
| **5 after** | 651 m | **24 (36.8)** | **81** | **10 (15.4)** | **7/3/1 + 4 = 15 (23.0)** | 3 / 12 | FILL |

FILL-IN: per-km harvest against band 1; the worst-gap column; the site validation rounds.

## Tests and smokes

FILL

## Visual evidence

FILL

## Known limitations / deliberately not done

FILL

## Final commit
FILL
