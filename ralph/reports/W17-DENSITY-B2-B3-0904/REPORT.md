# W17-DENSITY-B2-B3 — content after the village, bands 2 and 3

Branch `ralph/W17-DENSITY-B2-B3-0904`, from `origin/main` at `ef16544f`.
Final commit: **see the last section** (filled at the end of the lane).

## What a player gets

- **Stone & Root (band 2)** and **The River Lock (band 3)** hold materially more to do
  and more reasons to leave the road. Band 2 went from 57 to 71 wild clusters and 26 to
  46 harvest nodes; band 3 from 54 to 66 and 31 to 49. Every new cluster and node has an
  authored `_why` naming the place it belongs to (the quarry floor's burrowback nest, the
  rim loop at day and at night, the ranger spur, the far-west pocket, the undertrail's
  second mouth, the Reach's shelf, the relay's pylon line, the far bank, the Long Water's
  west pool, both seams).
- **46 authored findables** stand in the two bands, read from a new
  `data/config/bands/<band>/pickups.json` per band: 33 candies (18 Good / 11 Great /
  4 Rare) and 13 revives, potions and mushrooms. The critical path carries two Good
  candies per band and nothing better; side ground carries Good; the bands' authored
  detours, named places and harder optional fights carry Great; the four Rare sit on
  Nightburrow's cave mouth, the far-west pocket, Stormtrail's tether hardware and
  Riftfrill's still pool. Recovery arrives before the attrition it supports and never
  between Hess and the restored crossing (contract P-3.1).
- **Candy tiers read at instancing from one mesh**: a tint per tier, an emissive
  medallion on the crown in the item's own colour, and two small wings on Rare only.
  Mushrooms are tinted per tier and the Wild Shroom's cap is broader.
- **A taken pickup stays taken** across save/load, per placement: the seam's once-flag
  is now keyed on the placement id, not the item id.

## Files changed

| File | Change |
|---|---|
| `scripts/world/band_pickups.gd` | **new** — loader: reads every band's `pickups.json`, validates, stands each entry up through `item_cache_pickup.gd` on real ground (`ground_height_at`) and off solid scatter (`vegetation.gd::has_solid_scatter_near`, with a ring of nudges), keyed on its id; the per-tier look |
| `scripts/world/item_cache_pickup.gd` | **outside the ownership list, flagged for the coordinator** — additive: `setup()` gains an optional fifth `flag_key`; `_key()` resolves it; `was_taken`/`restore`/`_on_picked_up` use `_key()`. Every existing cache (no key) behaves exactly as before. Without it two Good Candies share `cache:good_candy` and the second is deactivated on the next boot; `test_band_pickups.gd` was seen red on that |
| `scripts/world/playground_world.gd` | the one hook: `_place_band_pickups()` beside `_place_item_caches()`, plus the preload |
| `data/config/bands/band2_stone_and_root/pickups.json` | **new** — 22 placements |
| `data/config/bands/band3_the_river_lock/pickups.json` | **new** — 24 placements |
| `data/config/bands/band2_stone_and_root/spawns.json` | +14 clusters (orders 2070–2083), appended |
| `data/config/bands/band3_the_river_lock/spawns.json` | +12 clusters (orders 3060–3071), appended |
| `data/config/bands/band2_stone_and_root/harvest.json` | +20 nodes (orders 2020–2039), appended |
| `data/config/bands/band3_the_river_lock/harvest.json` | +18 nodes (orders 3040–3057), appended |
| `tests/test_band_pickups.gd` | **new** — 20 tests |
| `tools/_probe_band_density.gd` | **new** — per-band authored census |
| `tools/_capture_band_pickups.gd` | **new** — xvfb frames of placed pickups |
| `docs/WORLD_AND_CONTENT.md` | §6/§7 tables (spawn, harvest, pickup counts, per-km) |
| `docs/CURRENT_STATE.md` | CL-O4 density half, bands 2–3, one row in §3 |
| `docs/decisions/D74-a-world-pickup-is-its-place-not-its-item.md` | **new** |
| `ralph/reports/W17-DENSITY-B2-B3-0904/` | this report, census outputs, judge verdict, one contact sheet |

Not touched: `vegetation.json`, `trainers.json`, `items.json`, band 1/4/5 files,
`props.json` (see CL-E2 below), the test fixture mirror (no existing entry moved).

## CL-E2's prop half — already shipped, verified rather than re-authored

The brief asks for "a three-prop Riverwatch post at Oreth's stand in band 3
`props.json`". It exists: cluster order 3010 `riverwatch_post` (bench, barrel, stone;
`_why` cites C-2 / G3-BAND3-0903) at (−97..−98.5, 4352..4354), 2–4 m from Oreth at
(−100, 4350), banner deliberately omitted per its own `_why_no_banner`. The props
loader stands up all 37 clusters in `smoke_playground` (`[props] placed 267 props in
37 clusters`; 15+3+11+5+3 = 37). The closure plan row (`GATE2_GATE3_CLOSURE_PLAN.md`
CL-E2) still says "not done" for that half; that file is not in this lane's ownership,
so the coordinator should mark it. Oreth's `facing_deg` is −160.5 (re-derived, per his
own cluster's `_why`), so the facing half is done too.

## Measurements

### Authored data (`tools/_probe_band_density.gd`, full output in `density_census_after.txt`)

| Band | spine m | wild clusters (gated, alpha) | heads | clusters/km | harvest | harvest/km | pickups (critical/optional) | G/G/R candy | recovery |
|---|---|---|---|---|---|---|---|---|---|
| band 1 (reference) | 2403 | 69 (6, 1) | 222 | 28.7 | 48 | 20.0 | 0 | — | — |
| band 2 before | 2653 | 57 | 190 | 21.5 | 26 | 9.8 | 0 | — | — |
| **band 2 after** | 2653 | **71** (14, 4) | **237** | **26.8** | **46** | **17.3** | **22** (3 / 19) | 9 / 5 / 2 | 6 |
| band 3 before | 2375 | 54 | 157 | 22.7 | 31 | 13.1 | 0 | — | — |
| **band 3 after** | 2375 | **66** (10, 4) | **193** | **27.8** | **49** | **20.6** | **24** (6 / 18) | 9 / 6 / 2 | 7 |

(The census attributes one band-2 seam cluster to band 3 by z, so it prints 67 for
band 3; the file holds 66.)

Worst gap between points of interest along the spine, authored data, 30 m notice:
band 2 123 m (141 m in clear daylight with gated clusters hidden), band 3 126 m (171 m
daytime); pickups did not move the worst gap in either band (they sit beside things
that were already pulls, by design), they raised the number of things met on the spine
from 76 → 86 (band 2) and 79 → 98 (band 3).

### Runtime (`tools/_probe_gate_f_corridor.gd`, `corridor_before.txt` / `corridor_after.txt`)

Booted world, creatures that actually stood up with time/weather gates applied, things
met within 30 m of the spine. This probe predates `pickups.json` and does not count it.

| Band | met before → after | wild | gather | worst gap before → after |
|---|---|---|---|---|
| band 1 (reference) | 172 → 172 | 130 | 35 | 142 → 100 m (unchanged content; the walker's tie-break moved) |
| band 2 | **100 → 133** | 75 → 93 | 23 → 38 | **165 → 141 m** |
| band 3 | **117 → 127** | 90 → 94 | 22 → 28 | **163 → 118 m** |
| chapter worst gap | — | — | — | 165 m (band 2) → 156 m (band 4) |

Both bands' figures moved materially toward band 1's per-km values. Band 3's runtime
wild count rose less than its authored count because five of its twelve new clusters
are night- or rain-gated (deliberately: the river in rain, the camp's night edge) and
three sit off the 30 m notice band by design (the far-east pocket guard, the Long
Water's west pool). Grounding: 1018 wilds, 0 underground.

### Pickup siting, booted (`smoke_playground`)

`[playground] placed 46 band pickups (0 already taken, 9 nudged off scatter, 0 unclear,
0 without ground)`.

## Tests

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_band_pickups.gd` | 20 tests, 7851 assertions, 0 failed |
| `... --only=test_band_content.gd,test_spawns_data.gd,test_spawn_tables.gd,test_harvest.gd,test_starters_are_exclusive.gd,test_wild_once.gd,test_chapter_curve.gd,test_band_pickups.gd` | 148 tests, 817,100 assertions, 0 failed |

Seen red first, then restored (`test_band_pickups.gd` header records it):

- a duplicated id (`b3_candy_mill_yard` renamed to `b2_candy_quarry_ledge`) →
  `test_ids_are_unique_across_the_chapter` FAIL: "pickup id 'b2_candy_quarry_ledge' is
  in both band2_stone_and_root and band3_the_river_lock; the id is the once-flag";
- the seam's `_key()` reverted to `_item_id` →
  `test_two_placements_of_the_same_item_have_independent_flags` FAIL: "taking one Good
  Candy deactivated a different Good Candy placement", and
  `test_the_nodes_key_is_the_placement_id_not_the_item` FAIL: "expected
  b3_candy_springhead, got great_candy".

## Smokes (grep `^ERROR:` and `SCRIPT ERROR`)

| Command | Result | `ERROR:` set |
|---|---|---|
| `godot --headless --path . --script tests/smoke_playground.gd` (baseline, unmodified tree) | `smoke: OK` | `Parameter "material" is null` ×4 (known-benign, alpha builds) |
| same, with the lane's content | `smoke: OK` | `Parameter "material" is null` ×3 — same set, count varies as AGENT_WORKFLOW §6 says |
| `tests/smoke_wild_streaming.gd` | `wild streaming: OK` | none |
| `tests/smoke_warrens.gd` | SMOKE_WARRENS_RESULT | SMOKE_WARRENS_ERRORS |
| `tests/smoke_relay.gd` | SMOKE_RELAY_RESULT | SMOKE_RELAY_ERRORS |

## Visual: candy tiers and mushrooms in place

RENDER_SECTION

## Known limitations, and what was deliberately not done

- **`item_cache_pickup.gd` is outside the ownership list.** The change is additive
  and default-preserving (a new optional parameter); no other 0904 lane names the file.
  Routed to the coordinator by this note rather than by stopping the sub-item, because
  without it the pickups cannot honour the contract's "one persistent identity per
  authored location".
- **The corridor probe does not count band pickups** (it recognises `tm_pickup.gd` and
  `key_pickup.gd`, not `item_cache_pickup.gd`). Adding the kind is a two-line change to
  a shared tool; not made here. The data census counts them.
- **Candy's "medallion" is an emissive primitive disc, not a decal texture swap.** The
  installed `candy_pickup.glb` is one textured surface with no medallion region to
  swap; a per-tier decal texture would be new art. The disc is the honest reading of
  "medallion per tier" with the assets that exist; ASSET_LEDGER's own open item on the
  candy's flat-top seam still stands.
- **Level-cap / funnelling safety** (addendum §B) is the candy item's effect, not
  placement; not touched here.
- **No per-band blind judge of the world** (CL-E9) — only the pickup frames.
- **Whether the counts feel right on a played route** is the evidence run's question.
- The `.import` files Godot generated for untracked reference crops under
  `assets/creatures/tetherbound/*/reference/` were not committed.

## Commit hash and branch

FINAL_COMMIT
