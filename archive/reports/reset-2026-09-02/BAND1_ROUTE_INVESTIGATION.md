# Band 1 route investigation — village → the Rise → the Pond → South Bridge

Method: reconstructed the actual authored road as `terrain_playground.json`
`trail.bands[0].points` (the "spine", prefixed with the village hub and the
`road_gate` waypoint) — 21 vertices, **2421 m of actual walked path** (village
to South Bridge), not the 1360 m of straight z-distance chapter_curve.json
uses for the band boundary. All distances below are "meters off this
polyline" and "arc-length walked from the village square".

Config data was cross-checked against the **live, in-engine** placement
math (`scripts/world/scatter_rules.gd`), not just the on-disk bake — the
shipped bake's `config_fingerprint` does **not** match the current
`vegetation.json` (`is_fresh()` returns false), so `vegetation.gd:363-366`
silently falls back to recomputing scatter live from current config at
boot. That fallback is intentional and documented ("an out-of-date bake is
ignored, never used" — `vegetation.gd:345`), so the numbers below reflect
what actually ships, not the stale `.bin` files, but it does mean every
boot pays the full procedural-placement cost instead of a file read.

## 1. Route in ~150 m legs

Trees/bushes/rocks = baked-layer instances within 40 m of the route,
recomputed live per the fallback above. Spawn/harvest/trainer/prop columns
are the authored entries in `bands/band1_lower_meadows/*.json` whose
position falls in that arc-length window (within ~40 m of the line).

| Leg (arc m) | Trees | Bushes | Rocks | Wild clusters (species×count) | Harvest | Trainers/Props |
|---|---|---|---|---|---|---|
| 0–150 (village/road_gate) | 13 | 12 | 15 | bramblebun×3(0), mudsnout×2(1,1070), galecrest×1(12), duskhush×1 night(1050), bramblebun×3(1006) | 11 nodes (wood/stone/fiber/berries, orders 0-11) | Bryn, Mira, Oskar, Tam; work_area, farmhouse_yard, trainer_camp, tournament_ground |
| 150–300 | 8 | 23 | 21 | pipwing×3(10), mudsnout×4(1007), pipwing×5(1008), duskhush×2 night(1051) | none | none |
| 300–450 | 26 | 174 | 13 | galecrest×3(1009) | none | none |
| 450–600 | 39 | 326 | 3 | bramblebun×4(1010), mudsnout×5(1011) | none | none |
| 600–750 | 575 | 562 | 1 | pipwing×3(1012), galecrest×4(1013) | fiber(1000, arc≈130) | none |
| 750–900 | 249 | 213 | 9 | bramblebun×5(1014), mudsnout×3(1015), bramblebun×1(1018,off-route 75m mosshell 1900) | none | none |
| 900–1050 | 398 | 377 | 3 | pipwing×4(1016), paddlenewt×2, mosshell×1, brooktail×1, reedwing×2, brooktail×1(the Pond cluster) | none | none |
| 1050–1200 | 86 | 231 | 1 | pipwing×1(1020), mudsnout×1(1019), bramblebun×4(1022) | fiber(1001,arc≈312) | none |
| 1200–1350 | 116 | 424 | 0 | mudsnout×5(1023), pipwing×3(1024) | none | none |
| 1350–1500 | 581 | 286 | 4 | bramblebun×5(1026), mudsnout×2(1002), trailpup×3(1072) | wood(1002,arc≈666) | none |
| 1500–1650 | 302 | 438 | 2 | mudsnout×3(1027), pipwing×4(1028), bramblebun×2(1003), trailpup×5(1058) | none | **Trail Camp** (trail_camp prop, arc≈833) |
| 1650–1800 | 182 | 318 | 4 | bramblebun×5(1029), mudsnout×3(1030), pipwing×4(1031), bramblebun×2(1073), trailpup×2(1074) | stone(1003), berries(1004) both arc≈865-905 | old_champion_bram (arc≈880, 116 m off-route) |
| 1800–1950 | 139 | 142 | 22 | bramblebun×4(1034), mudsnout×4(1003-dup), duskhush×4 night(1053) | none | none |
| 1950–2100 | 402 | 290 | 3 | mudsnout×5(1035), trailpup×4(1060,1061), pipwing×3(1036) | none | none |
| 2100–2250 | 19 | 121 | 2 | galecrest×4(1037), duskhush×2 night(1054) | none | none |
| 2250–2400 | 167 | 167 | 3 | bramblebun×5(1038), mudsnout×3(1039), pipwing×5(1044) | fiber(1005), stone(1006) arc≈2115-2260 | none |
| 2400–2421 (South Bridge) | 22 | 57 | 1 | mudsnout×4(1049, 117m off-route), meadowhart×2(1005, 136m off-route) | none | **south_bridge_grunt** trainer |

Landmarks passed: `road_gate` (arc≈18), `band1_trail_camp` (arc≈833,
25 m discover radius), `south_bridge` (arc≈2421). No signposts config file
exists under `data/config/` — `signpost.gd` draws its arms procedurally
from `paths.routes`/`trail.bands`, there is no separate signpost placement
list to audit.

## 2. "Barely any creatures" — the mechanism

**There is no alive/simultaneous cap.** `encounter_director.gd:323-506`
(`_spawn_creatures`) instantiates **every** cluster in the merged spawn
table at boot and never despawns them ("`_spawn_creatures()` ... instantiates
and never despawns", line 179 comment). `_stream_clusters()`
(`encounter_director.gd:1560-1571`) only toggles `set_physics_process` per
cluster based on distance — it does not hide or free anything:

```
var should_be_active := player_pos.distance_to(centre) <= radius + margin
...
for wild: Node3D in (cluster["members"] as Array[Node3D]):
    _set_wild_active(wild, should_be_active)
```

`visible` stays `true` from spawn unless a cluster is night/weather-gated
(`_wild_gates`) or the creature has fainted. So on paper 68 clusters / ~230
individual creatures exist simultaneously along this 2421 m stretch, and
the table above shows most clusters sit **11–40 m off the road**, close
enough to be visually reachable.

What *does* suppress the "meets creatures" feeling, from data:
- `wild_creature.gd:35` — `_wander_radius: float = 7.0`: every wild stays
  within 7 m of its spawn point for its whole life; nothing roams toward
  the road.
- `wild_creature.gd:37` and `encounter_director.gd:1511-1513` — `notice_range`
  defaults 9 m (peaceful) / 14 m (aggro config), and the activation margin
  added on top is `max(aggro,peaceful)+10` ≈ 24 m. A creature 20-40 m off
  the road (most of the table above) never notices or reacts to a player
  staying on the path — it is a static, silent prop until the player leaves
  the road and walks up to it.
- Only ~6 distinct species repeat through the whole band
  (bramblebun/mudsnout/pipwing/galecrest/trailpup/duskhush), cycling in the
  same fixed pattern (`meadows_open`→`meadows_air` alternation, orders
  1006-1044), so even a player who does see several clusters is seeing the
  same two or three silhouettes over and over.
- `data/config/bands/band1_lower_meadows/harvest.json` and `trainers.json`
  show the true drought: **beyond the village hub (arc 0-150), only 2
  trainers exist in the remaining 2270 m** (`old_champion_bram` at arc≈880,
  116 m off-route, and `south_bridge_grunt` at the very end), and only 9
  harvest nodes are scattered across that same 2270 m (≈1 every 250 m) vs.
  20 nodes packed into the first 150 m around the village. Wild creatures
  exist along the whole route; **things to *do*** (fights that seek you
  out, gathering) are almost entirely front-loaded at the village.

## 3. "No trees" — the mechanism

Per current `data/config/vegetation.json` (recomputed live, see method
note above — the on-disk bake is stale and ignored):

- `corridor_bands` (`vegetation.json`) sets `band1_lower_meadows`
  `density_scale: 0.18` for `z_min: -512, z_max: 1360` — **this multiplier
  applies to every scatter layer**, not just ground cover, despite its own
  `_why_b11` comment framing it as a "ground-cover density" fix.
- The `trees` layer's own `corridor_fill` (`vegetation.json` → `layers.trees.corridor_fill`)
  carries `density_scale: 6.0`, `trail_bias: 0.85`,
  `trail_offset_min: 15.0`, `trail_offset_max: 65.0`. Effective keep-chance
  for a candidate clump in band 1 is `6.0 × 0.18 × 1.0 ≈ 1.08` (clamped to
  "always kept" since `rng.randf()` is `< 1.0`), so **trees are not data-
  starved in band 1** — the live recompute placed 3324 tree/grove/sapling
  instances within 40 m of the 2421 m route (leg table above), i.e. an
  average of one within 40 m every ~0.7 m walked. Legs 0-2 (0-450 m, the
  village-to-first-bend stretch) are the thin exception: 8-26 trees per
  150 m leg vs. 100-575 for legs further out — this is the actual "empty
  meadow" the player sees in their first two minutes.
- **`trail_offset_min: 15.0`** on the trees layer means no `corridor_fill`
  tree candidate is ever centred closer than 15 m to the trail — the
  immediate near-field the player is looking at while walking the road is
  structurally kept clear of the procedural fill; what's visible close-in
  is only the hand-placed `layer_anchors` (three stations: 45,58 / -136,289
  / 480,1023+427,953 — literally three curated tree groups in the whole
  2421 m) plus whatever legacy square-layer trees exist near the village.
- `grass_field.json`'s `suppress_scatter_layers` is `["grass","flowers"]`
  only — it does **not** remove `trees`/`bushes`/`rocks`, so the shader
  grass carpet is not the cause of missing trees.
- Band-local `clearings` (`bands/band1_lower_meadows/vegetation.json`, 11
  entries, radius 10-22 m) sit at the village square, road junctions, the
  pond edge and South Bridge — small, sparse, and not a blanket suppressor
  of the route.

**Conclusion for §3**: the data does not show "no trees" as a corridor-wide
problem — it shows (a) a genuinely thin opening 450 m near the village
(legs 0-2), (b) a structural 15 m dead zone immediately flanking the road
everywhere (by design, via `trail_offset_min`), and (c) only three curated
tree groups anywhere close to the camera; everything else is anonymous
procedural fill 15-65 m off to the side. Because the shipped bake is stale
and silently bypassed, whatever the owner played may also have been
running an **older** live-recompute than this repo state if their build
predates a recent `vegetation.json` edit — worth confirming which commit
the playtest build was on.

## 4. Longest interactive-free stretch within 40 m of the road

Combining trees/bushes/rocks/harvest/wild-cluster-edge/trainers, the
longest gap is **arc 758.8 m → 804.8 m, 46.0 m long** (between the
600-750 m and 750-900 m legs, just past the mid-route bramblebun/mudsnout
pair and before the Pond's water-edge cluster). Every other gap is under
16 m. So *by this combined metric* (which includes procedural scatter)
there is effectively no long dead stretch — reinforcing that the
"nothing to do" complaint is about **authored** content (trainers,
harvest, curated scenery) rather than raw scatter/spawn density: the
longest *trainer-free* stretch is arc 150 → 1650 m (the village's last
trainer, then nothing until `old_champion_bram`, 1500 m of walking with a
trainer only 116 m off-line at the far end), and the longest
*harvest-node-free* stretch is arc 150 → 630 m (480 m with no gatherable
at all).

## 5. Three minimal data-level changes

1. **File**: `data/config/vegetation.json` → `layers.trees.corridor_fill`.
   **Key**: `trail_offset_min`. **Current**: `15.0`. **Proposed**: `6.0`
   (matching `bushes.corridor_fill.trail_offset_min: 10.0` roughly halved
   again for trees, still clear of the 3 m painted path + 1.5 m shoulder).
   Brings the nearest procedural tree candidates into the player's
   immediate view cone instead of always starting 15 m out. **Perf-proxy
   cost**: near-zero — this only moves *where* the already-budgeted
   `density_scale: 6.0` candidates land, it does not add instances, so
   `band1_open`'s 7500-draw/12.0M-prim ceiling (`VISUAL_BIBLE.md` §6) is
   unaffected; may add a handful of draw calls from more MultiMesh cells
   crossing the near frustum, not a new prim count.

2. **File**: `data/config/vegetation.json` → `layers.trees`.
   **Key**: `layer_anchors.trees` (hand-placed stations).
   **Current**: 3 curated stations (village edge, first bend, eastward
   swing) covering roughly arc 20-100 m, 260-330 m, and 1500-1600 m of the
   2421 m route. **Proposed**: add 2-3 more stations at the identified
   thin legs — near arc 1050-1200 (leg with only 86 trees vs. 300-580
   neighbours) and near arc 2100-2250 (19 trees, the lowest of any leg
   past the opening) — same recipe as the existing anchors (6-10 trees,
   radius 10-13 m, positioned within FOV of the path). **Perf-proxy
   cost**: 2-3 anchors × ~8 trees ≈ 16-24 extra static instances, trivial
   against the 12.0M-prim budget; this is the cheapest lever in the file
   because anchors are exact placements, not density multipliers.

3. **File**: `data/config/bands/band1_lower_meadows/trainers.json` and
   `harvest.json`. **Key**: add entries with `order` in the band's
   reserved 1000-1999 range. **Current**: 2 trainers and 9 harvest nodes
   across arc 150-2421 m (2270 m of route). **Proposed**: add 2-3 trainers
   and 6-8 harvest nodes spaced through the 150-1650 m trainer-dead
   stretch identified in §4 (e.g. one trainer near arc 700-800, one near
   1200-1300; harvest nodes near each thinly-covered leg). **Perf-proxy
   cost**: trainers and harvest nodes are not scatter-layer instances —
   each is one NPC/interactable body, not a MultiMesh cell; cost is a
   handful of draw calls each (well under `band1_open`'s 7500-draw
   ceiling) plus `encounter_director.gd`'s per-cluster boot-time
   `_stand_on_ground`/`_pick_clear_spot` cost, which is O(clusters), not
   O(instances) — negligible at this scale (adding ~10 entries to a table
   that already holds 68 wild clusters + 9 harvest + 9 trainers).

## Caveat

All of §1-§4 is derived from static config plus the live scatter/spawn
placement code paths, not from an actual play session — I did not run the
game with a rendering driver (sandbox instruction). The picture the data
supports is: wild-creature and vegetation *density* along the route is not
data-starved (and is denser than the stale on-disk bake would suggest,
since the fallback recomputes live), but **authored, deliberately-placed
content** — curated tree anchors, trainers, and harvest nodes — is heavily
front-loaded at the village and thin for the next ~1.5 km, and the wander/
notice-range mechanics keep the abundant wild creatures passive and easy
to walk past unnoticed. If the owner's playtest build predates the current
`vegetation.json`/`spawns.json` (both carry recent "HARVEST-ALL" / density
tuning comments), the live experience they saw may have been meaningfully
sparser than what this repo state would produce today — worth confirming
against the build/commit they played before spending budget on §5's
changes.
