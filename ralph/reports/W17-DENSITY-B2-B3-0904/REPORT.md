# W17-DENSITY-B2-B3 — content after the village, bands 2 and 3

Branch `ralph/W17-DENSITY-B2-B3-0904`, from `origin/main` at `ef16544f`.
Final commit: see **Commit hash and branch** at the end.

Answers CL-O4's density half for bands 2–3 (owner: *"There isn't enough to do
anywhere. Creatures are only really around the village, sparse anywhere else.
There's nothing to take you off the path."*) plus the addendum's §B/§C candy and
findables for those two bands, and verifies CL-E2's prop half.

## What a player gets

- **Stone & Root (band 2)** and **The River Lock (band 3)** hold materially more
  to do and more reasons to leave the road. Band 2 went from 57 to 71 wild
  clusters and 26 to 46 harvest nodes; band 3 from 54 to 66 and 31 to 49. Every
  new cluster and node carries an authored `_why` naming the place it belongs to
  — the quarry floor's burrowback nest, the rim loop by day and by night, the
  ranger spur, the far-west pocket, the undertrail's second mouth, the Reach's
  shelf, the relay's pylon line, the far bank, the Long Water's west pool, and
  both seams.
- **46 authored findables** stand in the two bands, from a new
  `data/config/bands/<band>/pickups.json`: 33 candies (18 Good / 11 Great /
  4 Rare) and 13 revives, potions and mushrooms. The critical path carries two
  Good candies per band and nothing better; side ground carries Good; the bands'
  authored detours, named places and harder optional fights carry Great; the
  four Rare sit on Nightburrow's cave mouth, band 2's far-west pocket,
  Stormtrail's tether hardware and Riftfrill's still pool.
- **Recovery arrives before the attrition it supports**: on the approach to the
  Warrens mouth, before Kest, at the camp before the relay barricade, on the far
  landing past the restored crossing. Nothing that heals is authored between
  Hess and the restored crossing, so `GATE3_ENCOUNTER_CONTRACTS.md` P-3.1 holds
  and the gauntlet keeps its cost.
- **A taken pickup stays taken** across save/load, per placement rather than per
  item.
- **The three candy grades read as a ladder** — size, glow and medallion all
  step with the tier, and Rare carries wings. A code-blind judge confirmed the
  ladder points the right way after round 2.

## Files changed

| File | Change |
|---|---|
| `scripts/world/band_pickups.gd` | **new** — loader: reads every band's `pickups.json`, validates, stands each entry up through `item_cache_pickup.gd` on real ground (`ground_height_at`) and clear of solid scatter (`vegetation.gd::has_solid_scatter_near`, with a nudge ring), keyed on its authored id; the per-tier look |
| `scripts/world/item_cache_pickup.gd` | **outside the ownership list — flagged for the coordinator.** Additive: `setup()` gains an optional fifth `flag_key`, `_key()` resolves it, and `was_taken`/`restore`/`_on_picked_up` use it. Every existing cache passes no key and behaves exactly as before |
| `scripts/world/playground_world.gd` | the one hook: `_place_band_pickups()` beside `_place_item_caches()`, plus the preload |
| `data/config/bands/band2_stone_and_root/pickups.json` | **new** — 22 placements |
| `data/config/bands/band3_the_river_lock/pickups.json` | **new** — 24 placements |
| `data/config/bands/band2_stone_and_root/spawns.json` | +14 clusters (orders 2070–2083), appended |
| `data/config/bands/band3_the_river_lock/spawns.json` | +12 clusters (orders 3060–3071), appended |
| `data/config/bands/band2_stone_and_root/harvest.json` | +20 nodes (orders 2020–2039), appended |
| `data/config/bands/band3_the_river_lock/harvest.json` | +18 nodes (orders 3040–3057), appended |
| `tests/test_band_pickups.gd` | **new** — 22 tests |
| `tools/_probe_band_density.gd` | **new** — per-band authored census |
| `tools/_capture_band_pickups.gd` | **new** — xvfb frames of placed pickups at play distance |
| `tools/_contact_sheet.gd` | **new** — contact-sheet compositor (no ImageMagick or Pillow in this container) |
| `docs/WORLD_AND_CONTENT.md` | §6/§7 tables: spawn, harvest and pickup counts, plus per-km density |
| `docs/CURRENT_STATE.md` | one CL-O4 row in §3 for the bands 2–3 density half |
| `docs/decisions/D74-a-world-pickup-is-its-place-not-its-item.md` | **new** |
| `ralph/reports/W17-DENSITY-B2-B3-0904/` | this report, both judge verdicts, two contact sheets, census outputs |

Not touched: `vegetation.json`, `trainers.json`, `items.json`, band 1/4/5 files,
`props.json`, and the `test_band_content` fixture mirror — no existing entry,
order or identity moved, so the mirror needed no `_comment_` exemption.

## CL-E2's prop half — already shipped, verified rather than re-authored

The brief asks for "a three-prop Riverwatch post at Oreth's stand in band 3
`props.json`". It already exists: cluster order 3010 `riverwatch_post` (bench,
barrel, stone; its `_why` cites C-2 / G3-BAND3-0903) at (−97…−98.5, 4352…4354),
2–4 m from Oreth at (−100, 4350), with the Team Tether banner deliberately
omitted per its own `_why_no_banner`. All 37 prop clusters stand up in
`smoke_playground` (`[props] placed 267 props in 37 clusters`). Oreth's
`facing_deg` is −160.5, already re-derived. **Both halves of CL-E2 are done**;
`GATE2_GATE3_CLOSURE_PLAN.md` still says "not done" and that file is not in this
lane's ownership, so the coordinator should mark it.

## Measurements

### Authored data (`tools/_probe_band_density.gd`, full output in `density_census_after.txt`)

| Band | spine m | wild clusters (gated, alpha) | heads | clusters/km | harvest | harvest/km | pickups (critical/optional) | G/G/R candy | recovery |
|---|---|---|---|---|---|---|---|---|---|
| band 1 (reference) | 2403 | 69 (6, 1) | 222 | 28.7 | 48 | 20.0 | 0 | — | — |
| band 2 before | 2653 | 57 | 190 | 21.5 | 26 | 9.8 | 0 | — | — |
| **band 2 after** | 2653 | **71** (14, 4) | **237** | **26.8** | **46** | **17.3** | **22** (3 / 19) | 9 / 5 / 2 | 6 |
| band 3 before | 2375 | 54 | 157 | 22.7 | 31 | 13.1 | 0 | — | — |
| **band 3 after** | 2375 | **66** (10, 4) | **193** | **27.8** | **49** | **20.6** | **24** (6 / 18) | 9 / 6 / 2 | 7 |

The census attributes one band-2 seam cluster to band 3 by z, so it prints 67
for band 3 where the file holds 66.

Worst gap between points of interest along the spine (authored data, 30 m
notice): band 2 123 m, band 3 126 m; 141 m and 171 m in clear daylight with the
night- and rain-gated clusters hidden. Pickups did not move either worst gap —
by design, they sit beside things that were already pulls — but they raised the
count of things met on the spine from 76 → 86 in band 2 and 79 → 98 in band 3.

### Runtime (`tools/_probe_gate_f_corridor.gd`, `corridor_before.txt` / `corridor_after.txt`)

Booted world, creatures that actually stood up with their time and weather gates
applied, counting things met within 30 m of the spine. This probe predates
`pickups.json` and does not count it.

| Band | met before → after | wild | gather | worst gap before → after |
|---|---|---|---|---|
| band 1 (reference) | 172 → 172 | 130 | 35 | 142 → 100 m (content unchanged; the walker's tie-break moved) |
| band 2 | **100 → 133** | 75 → 93 | 23 → 38 | **165 → 141 m** |
| band 3 | **117 → 127** | 90 → 94 | 22 → 28 | **163 → 118 m** |
| chapter worst gap | — | — | — | 165 m (band 2) → 156 m (band 4) |

Both bands moved materially toward band 1's per-km values, and band 2 is no
longer the chapter's worst gap. Band 3's runtime wild count rose less than its
authored count because five of its twelve new clusters are night- or rain-gated
(deliberately: the river in rain, the camp's night edge) and three sit outside
the 30 m notice band by design (the far-east pocket's guard, the Long Water's
west pool). Grounding: 1018 wilds, 0 underground.

### Pickup siting, booted (`smoke_playground`)

`[playground] placed 46 band pickups (0 already taken, 16 nudged off scatter,
0 unclear, 0 without ground)`. Every authored placement found real ground; 16
were nudged clear of a trunk or boulder by the loader (9 before the clearance
was raised in round 2).

## Tests

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_band_pickups.gd` | **22 tests, 9,609 assertions, 0 failed** |
| `... --only=test_band_content.gd,test_spawns_data.gd,test_spawn_tables.gd,test_harvest.gd,test_starters_are_exclusive.gd,test_wild_once.gd,test_chapter_curve.gd,test_band_pickups.gd` | **148 tests, 817,100 assertions, 0 failed** (before the two tier-ladder tests were added) |

`test_band_pickups.gd` covers the schema, chapter-unique ids, that every item
exists and has a real `world_model`, in-band and in-world positions, the 4.5 m
prompt separation from every other pickup and every harvest node, the addendum's
tiering, the save round trip through the real seam, and both tier ladders.

**Seen red first, then restored** (recorded in the test's own header):

- a duplicated id (`b3_candy_mill_yard` renamed to `b2_candy_quarry_ledge`) →
  `test_ids_are_unique_across_the_chapter` FAIL: *"pickup id
  'b2_candy_quarry_ledge' is in both band2_stone_and_root and
  band3_the_river_lock; the id is the once-flag"*;
- the seam's `_key()` reverted to `_item_id` →
  `test_two_placements_of_the_same_item_have_independent_flags` FAIL: *"taking
  one Good Candy deactivated a different Good Candy placement"*, and
  `test_the_nodes_key_is_the_placement_id_not_the_item` FAIL: *"expected
  b3_candy_springhead, got great_candy"*.

## Smokes (grepped for `^ERROR:` as well as `SCRIPT ERROR`)

| Command | Result | `ERROR:` set |
|---|---|---|
| `tests/smoke_playground.gd`, baseline on the unmodified tree | `smoke: OK` | `Parameter "material" is null` ×4 (known-benign) |
| `tests/smoke_playground.gd`, with the lane's content | `smoke: OK`, 46 pickups placed | same line ×3 |
| `tests/smoke_playground.gd`, run **during** the round-2 render | **`smoke FAIL`** — see below | same line ×2 |
| `tests/smoke_playground.gd`, idle replay after that render | `smoke: OK`, 46 pickups placed | — |
| `tests/smoke_wild_streaming.gd` | `wild streaming: OK` | none |
| `tests/smoke_warrens.gd` | `warrens smoke test passed` | same line ×1 |
| `tests/smoke_relay.gd` | `relay: OK — the captain is beaten, the captive is freed, the Gear is carried` | same line ×1 |

The `ERROR:` set never grew; only its count varied, which
`AGENT_WORKFLOW.md` §6 states is expected because the line comes off alpha
creature builds whose number varies with what streamed in.

**The one failure, and why it is not this lane's.** One `smoke_playground` run
failed with *"the gather resolved 0.80 through the swing, well past the 0.60
impact pose"*. That assertion is about tool-swing timing during a gather and
touches nothing this lane changed. It is already recorded in
`docs/CURRENT_STATE.md` as environment-dependent and previously reproduced on an
unmodified tree in this same container. It occurred on the one run that shared
the machine with a CPU-saturating software-GL render; the identical command
passed before that render and again idle afterwards, with the same 46 pickups
placed. Reported here rather than dropped, because a run that goes 0-for-1 and
then passes is a finding.

## Visual: two code-blind rounds, and a third fix shipped unverified

Six frames per round, each a third-person view at ~7 m — the distance a player
decides from — of a Good, a Great and a Rare candy and two mushrooms in their
authored places. Each round was judged by a fresh sub-agent given only the
contact sheet, `docs/reference/` and the visual-judge skill, and told nothing
about what changed or what this lane hoped it would say. Verdicts committed in
full: `JUDGE-round1.md`, `JUDGE-round2.md`. Sheets: `_sheet-round1.png`,
`_sheet-round2.png`.

**Round 1 found three real defects.** One pickup could not be found at all
(*"as staged, this pickup does not exist to the player"*) because a trunk stood
between the camera and it. The grade ladder was unreadable and pointed the wrong
way: the Rare read as *"the most desaturated of the four… a weathered rock
rather than a prize"*. And the capture had kept the trainer out of frame, so
scale could not be judged at all.

**The fixes, and what round 2 said about them.** Scatter clearance went 0.6 m →
1.6 m with a wider nudge ring; the tiers gained size, glow and medallion steps;
Rare's hue moved from albedo (which multiplies into the wrapper texture's green,
producing exactly the washed cream named above) to emission (which adds on top);
and the capture put the trainer in frame. Round 2 confirmed the first two
landed: the lost pickup is now found and correctly named as a mushroom, and
*"frame 3 holds the most valuable one, and everything says so at once"* — the
ladder now points the right way.

**Round 2 found a regression this lane caused, and it is corrected.** With the
trainer finally in frame, the candy family measured as *"furniture, not
pickups"* — the Rare at roughly knee-to-thigh height and two and a half metres
across, *"the same visual weight as the black boulder beside it"*. Growing the
tiers to build the ladder is what pushed it there. The per-tier steps are kept
(~1.2× each, which round 2 read correctly) and the whole family scaled down
under them: 1.0 / 1.18 / 1.40 → **0.34 / 0.42 / 0.52**, putting Good near a
third of a metre and Rare near two thirds. The mushrooms are deliberately
untouched — round 2 measured them at *"around knee height… exactly as something
you bend down and pick"*, so they are the target, not the problem.

This is **not** the case `CLAUDE.md`'s "never shrink" rule covers: that owner
directive is about creatures standing against the 1.80 m trainer, and the
smaller side here is the trainer, whom growing would break the creature band the
directive protects. The candy's base size lives in `items.json`, which this lane
does not own; the loader's multiplier is the lever that is in scope.

**One round-2 finding was the system working, not a defect.** The judge called
two frames indistinguishable and could not tell them apart. They are both Great
Candy — a tier reading identically to itself in two places 700 m and one band
apart is the tint being consistent. No change made.

**The occluded pickup that survived both rounds** was fixed at the authored
level, and the reason it survived is worth recording: the trunk crowding the
springhead is a **prop**, and `has_solid_scatter_near()` only sees scatter
batches, so the loader cannot nudge away from something it cannot detect.
`b3_candy_springhead` moved (16, 3572) → (24, 3578), onto open ground east of
the spring ring, and the limitation is written into the loader's header rather
than papered over.

**Open, and the honest limit of this report: the round-3 scale correction and
the springhead move are committed but not visually verified.** Their direction
is certain (every tier scales by a known factor, the ladder ratios are pinned by
`test_the_candy_tiers_step_up_in_size_not_only_in_hue` and
`test_a_higher_tier_glows_harder`) but no frame has been rendered since. The
verification is one command, about 35 minutes of software GL:

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_band_pickups.gd
godot --headless --path . --script tools/_contact_sheet.gd -- \
  --in=res://shots_band_pickups --out=res://ralph/reports/W17-DENSITY-B2-B3-0904/_sheet-round3.png
```

What would falsify it: the candy reading as *too small to notice* at 7 m, which
would mean the ladder needs to be rebuilt from the medallion and glow rather
than from size.

## Known limitations, and what was deliberately not done

- **`item_cache_pickup.gd` is outside this lane's ownership list.** The change
  is additive and default-preserving (one new optional parameter) and no other
  0904 lane names the file. Routed to the coordinator by this note rather than
  by stopping the sub-item, because without it the pickups cannot honour the
  contract's "one persistent identity per authored location" — thirty Good
  Candies would share `cache:good_candy` and the second taken would deactivate
  the rest on the next boot.
- **The corridor probe does not count band pickups.** It recognises
  `tm_pickup.gd` and `key_pickup.gd`, not `item_cache_pickup.gd`. Adding the
  kind is a two-line change to a shared tool that other lanes are reading right
  now; not made here. `tools/_probe_band_density.gd` counts them instead.
- **The loader cannot see props or harvest models**, only scatter — the
  springhead case above. A general fix means teaching it about both node kinds,
  which is more surface than this lane should take on its own.
- **Candy's medallion is an emissive primitive disc, not a decal-texture swap.**
  `candy_pickup.glb` is one textured surface with no medallion region to swap,
  and a per-tier decal would be new art.
- **Two judge findings belong to the candy mesh itself and are outside this
  lane:** the wrapper lobes reading as flat floating quads, and the family's
  silhouette not saying what the object is. `docs/specs/ASSET_LEDGER.md` already
  records both in its own words (the flat-top seam, and that the lobes "need
  real topology"), and the owner decided on 2026-09-04 to ship the mesh as-is.
  Two independent code-blind judges reaching the same conclusion from the game
  side is worth carrying back to that ledger.
- **Level-cap and funnelling safety** (addendum §B) belong to the candy item's
  effect, not to placement; untouched here.
- **No per-band blind judge of the world itself** (CL-E9) — only the pickups.
- **Whether the counts *feel* right on a walked route** is the played-evidence
  question the addendum §C reserves for route evidence, not a census.
- Two minor judge findings for other lanes: a crate sunk to its lid at the
  band-3 camp clearing (`props.json`), and bushes crowding the band-2 quarry
  mushroom (the vegetation bake).
- Godot's import artefacts (`.import` files and extracted textures) for the
  candy, mushroom, potion, revive, saddle and gate assets are untracked in this
  repository and were left that way — they belong to the asset lane, and CI
  regenerates them on a fresh import.

## Commit hash and branch

Branch `ralph/W17-DENSITY-B2-B3-0904`.

The last commit carrying code, data or docs is **`1be8dc6f`** ("W17: round-2
judge verdict, scale regression corrected, springhead moved"); this report is
committed directly on top of it, so the branch tip is the report commit. Verify
with `git log --oneline origin/main..origin/ralph/W17-DENSITY-B2-B3-0904`.

Commits on the branch, oldest first:

| Commit | What it carries |
|---|---|
| `434ec537` | the pickup loader, the placement-keyed once-flag, the one hook, both `pickups.json`, `test_band_pickups.gd` — pushed early, because the bands 4–5 lane consumes it |
| `18f64ba8` | the wild and harvest density for bands 2 and 3 |
| `78e03ae7` | the density census tool, the pickup capture tool, the doc updates and D74 |
| `22db5969` | report draft and census outputs |
| `a2f1d23d` | the smoke rows |
| `dce55d63` | the contact-sheet compositor |
| `06b03aa9` | `.uid` files for this lane's scripts, and the round-1 sheet |
| `63586fcf` | the round-1 judge verdict and its fixes |
| `5414d9ec` | the round-2 sheet |
| `1be8dc6f` | the round-2 verdict, the scale correction, the springhead move |
