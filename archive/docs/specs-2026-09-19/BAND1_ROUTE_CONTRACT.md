# Band 1 route contract — village → the Rise → the Pond → South Bridge

**Status:** orchestrator design contract, 2026-09-03, for the Gate 2 world lanes.
Written from the owner's 2026-09-03 playtest ("nothing outside the village: barely any
creatures, no trees, nothing to do and nothing to see") and the route investigation in
`archive/reports/reset-2026-09-02/BAND1_ROUTE_INVESTIGATION.md`. Lanes implement slices
of this; they do not redesign it. The route is the authored trail in
`data/config/terrain_playground.json` `trail.bands[0]`: 2,421 m walked, village square
(arc 0) to South Bridge (arc 2,421). "Arc" below is metres walked along it.

## What the data says the player actually meets

- Creatures exist along the whole route (~230 individuals in 68 clusters) but are
  invisible as *life*: each stays within 7 m of its spawn point for its whole life
  (`wild_creature.gd` `_wander_radius = 7.0`), notices the player only within 9–14 m,
  and most clusters sit 20–40 m off the road. The player sees the same three
  silhouettes (Bramblebun, Mudsnout, Pipwing) standing still in the middle distance.
- Beyond the village hub (arc 0–150) there are **two trainers and nine harvest nodes in
  2,270 m**. The longest trainer-free stretch is 1,500 m; the longest gatherable-free
  stretch is the first 480 m out of the village.
- Trees are not absent in the data (3,324 instances within 40 m of the route) but the
  procedural fill never places a tree closer than 15 m to the road
  (`layers.trees.corridor_fill.trail_offset_min: 15.0`), only three hand-placed tree
  stations exist in 2,421 m, and the first 450 m out of the village are genuinely thin
  (8–26 trees per 150 m leg against 100–575 further on). What the player sees from the
  road for the first two minutes is a bare field with trees somewhere else.
- The same featureless boulder model is the dominant foreground object at most stands.

So the complaint is right and the cause is composition and authored content, not raw
density. Raising density multipliers is explicitly the wrong fix.

## The route as five authored places

Each place gets: a reason to stop, a wild presence the player can see from the road, one
thing to gather, and a silhouette that tells them where they are. Coordinates are in
world XZ metres; lanes pick exact spots by probing the terrain, not by guessing.

| # | Place | Arc | What it is for | Composition (foreground / mid / distance) |
|---|---|---|---|---|
| 1 | **The Gate Meadow** | 0–450 | the first two minutes; must not be empty | a tree station of 6–9 mixed-height trees at 8–12 m either side of the road within 120 m of the gate; a rock line (3–5 varied rocks, not the boulder) along the first bend; a herd of 4–5 Trailpups grazing *on* the road shoulder within 15 m; a wood node and a stone node within sight of the road; the village behind, the Rise ahead |
| 2 | **The Rise** | 450–900 | the first overlook; one optional discovery | a hero tree on the crest visible from the gate; a flat shoulder with a signpost; **the discovery**: a cache 40–60 m off the crest (TM or the Ironwood-tier recipe) marked by a lone dead tree; a Galecrest pair that circles and lands near the crest; a trainer with a reason ("the shepherd on the Rise", fields two Trailpups, teaches nothing, is a fight you can see coming) |
| 3 | **The Pond pocket** | 900–1,200 | the approved lush reference; keep it | do not thin it; add the water-edge wildlife the spawn table already has (Paddlenewt, Reedwing, Brooktail) with a 20 m wander so they move between reeds; a fiber node and berries; one bench-and-firepit camp prop within sight of the water; a fisher NPC who mentions the South Bridge (dialogue only, no fight) |
| 4 | **The Long Field** | 1,200–1,950 | the stretch that must not read as dead travel | trees clustered into two groves at 1,050–1,200 and 2,100–2,250 (the thin legs), each 8–12 trees with scale variety and a clearing; the trail camp at 833 stays; a second trainer at ~1,300 ("the wanderer at the trail camp", Mudsnout and Pipwing); a stone node and a wood node every ~250 m; Bramblebun and Mudsnout clusters moved to within 15 m of the road with 20 m wander so they cross it |
| 5 | **The Bridge approach** | 1,950–2,421 | anticipation of the first gate | a rock line and a broken fence leading the eye to the bridge; the Meadowhart pair already off-route (136 m) moved to 40 m so it is *seen* before it can be fought; the grunt trainer stays; the gully at (7.9, −3.4, 1319) fixed (separate lane) |

## Rules that bound every slice

- No new meshes. Use the installed nature family (asymmetric tree forms, the CherryBlossom
  wide form, saplings), the installed rock forms, and installed props.
- Creatures loom; never shrink them. Visibility comes from siting, wander and contrast.
- The Pond pocket's density is the reference; do not spread it elsewhere.
- Perf proxy stays inside `band1_open ≤ 7,500 draws / ≤ 12.0 M prims`
  (`tools/perf_render_stats.gd`, same stands, same settle). Anchors and moved clusters
  are near-free; a tree offset change is near-free; density multipliers are not to be
  raised.
- Re-bake scatter after any vegetation edit and commit the bake with the change
  (`scripts/world/bake_playground_scatter.gd`, then `--import`); the freshness test must
  be green.
- Every addition is authored with a purpose comment (`_why_*`) in the data, as the
  existing entries are.

## Slices (one lane each, disjoint files)

**WORLD-TREES** — `data/config/vegetation.json` (`layers.trees.corridor_fill.trail_offset_min`
15 → 6; `layer_anchors` for places 1, 2, 4 with the compositions above; rock-form variety
in the rocks layer so the single boulder is not the default), `data/config/bands/band1_lower_meadows/vegetation.json`
(clearings for the two groves), the scatter bake. Evidence: the five survey stands plus
a stand at each place, before/after, blind-judged; perf proxy before/after.

**WORLD-LIFE** — `scripts/creatures/wild_creature.gd` (wander radius as a per-cluster
data field defaulting to 7, set to 20 for herd/water clusters), `data/config/bands/band1_lower_meadows/spawns.json`
(move the named clusters to within 15 m of the road; the Trailpup herd on the shoulder;
Galecrest pair at the Rise; Meadowhart pair at 40 m), `scripts/combat/encounter_director.gd`
only for the wander field plumbing. Evidence: a probe walking the route logging how many
creatures are within 25 m of the player per 100 m; blind judge on the same stands.

**WORLD-CONTENT** — `data/config/bands/band1_lower_meadows/trainers.json` (+2 trainers with
the reasons above and rosters without starters), `harvest.json` (+8 nodes at the spacing
above), `props.json` (Rise signpost, Pond camp prop, bridge fence line), the discovery
cache (`item_cache_pickup` entry), one dialogue conversation each for the fisher and the
two trainers in `data/dialogue/bands/band1_lower_meadows.json`. Evidence: the Gate F S03
segment and `smoke_gate_b_continuous` still pass; a walk log showing no 250 m without a
gatherable and no 700 m without a trainer.

## Acceptance for the route (Gate 2 in `docs/ROADMAP.md`)

Blind judge on the five survey stands and the five place stands: composition has
foreground, mid-ground and distance in every frame; creatures are visible in at least
three of the five place stands; the walk log shows no dead-travel interval over ~60 s;
the owner walks out of the village and does not say "nothing to see".
