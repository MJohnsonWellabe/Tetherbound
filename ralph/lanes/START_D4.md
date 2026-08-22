# START D4 — Upper Meadows / Ironwood

**Branch:** `ralph/gate-d-band4-upper-meadows`
**Band directory:** `data/config/bands/band4_upper_meadows_ironwood/` — yours whole
**Reserved `order` range:** 4000–4999
**Owning prompt:** `docs/ralph-prompts/65-BAND4-finished-upper-meadows.md`
**Spine:** z 4760 → 7000, **2240 m — the longest region in the chapter.**
Upper Meadows, old-growth forest, wind ridge, high pasture, ruined watchtower,
Team Tether patrol camps, trainer road.

Read `ralph/lanes/COMMON.md` first, then `ralph/GATE_D_LANE_CONTRACT.md`, then
your prompt, then `ralph/DONE.md`'s Gate D4 entry.

The region's question: **have I become powerful and versatile enough to
challenge the regional stronghold?** Prompt 65's definition of done: *opening the
final approach feels like the result of a strong, experienced five conquering
the Upper Meadows — not simply reaching the far end of the map.*

## Already done on this branch — do not redo it

Branch head `2cac171`, pushed.

- **Density**: 8 clusters / 18 creatures → **76 clusters / 272 creatures**, at
  the top of the owner's 55–75 / 200–300 target. **Density is done.** Generated
  with `tools/_gen_band4_density.py`, which walks the band's spine plus all
  three loops: ~50 m spacing in old-growth and pasture, ~100 m on the ridge,
  about one in three sited off-route as habitat pockets.
- **Ironwood finally exists inside its own region** — 5 harvest nodes in the
  western-swing old-growth. Before this the only authored ironwood in the whole
  game sat in Band 2, around the Burrow Warrens.
- **Special encounter**: a solitary Terrapup, one of exactly three species
  (with Ripplet and Galewisp) that spawn wild nowhere else in the chapter. Plus
  a night Duskhush pocket.
- **`patrol_ridgeline`** — an optional Team Tether grunt on the watchtower spur,
  existing rig, `grunt` rank, no new mesh — with a `ridge_patrol_camp` prop
  cluster built from the same furniture family `quarry_station` and
  `ranger_camp` already use, and dialogue in `data/dialogue/trainers.json`.
- Two clearings in a new band `vegetation.json`: the patrol arena, and a
  field-camp pad on the eastern loop between the two captains.
- Two new named map regions, append-only: "The Ironwood Grove" and "The
  Ridgeline Watch".
- **Dead travel**: longest z-projected gap between authored points of interest
  **370 m → under 92 m**, measured with `tools/_probe_ow5_walk.gd` driving a real
  Player body — 20/20 waypoints reached, 3436 m walked on the real polyline,
  11.4 walked minutes at foot speed (about half that ridden), no falls, one
  recoverable wedge walking into Captain Halder's own body rather than terrain.
- **Five-creature pressure validated**: 13 distinct wild-catchable species
  encountered across bands 1–4, of 17 in the roster, against a cap of 5.
- `tests/test_band_vegetation.gd`'s exact-count assertion loosened to `>=`,
  same correct change three lanes made independently. **Leave it.**

## A real bug the suite caught — the lesson stands

The special encounter was first authored as a wild **Tuskroot** and
`test_no_evolved_form_spawns_wild` refused it: Tuskroot is Mudsnout's own
evolved form behind `progression.json`'s Heartstone gate, and a catchable wild
one would let a player skip the only evolution line in the Meadows. It was
replaced with Terrapup. **Do not reintroduce a wild evolved form anywhere.**

## What is left

1. **A blind visual pass — this lane has never had one.** Both capture attempts
   stalled for 10+ minutes rendering the 272-creature world under the shared
   box's contention and were killed. **This should now be cheap**: the streaming
   lane has shipped distance-based activation on `ralph/gate-d-wild-streaming`,
   which drops the ticking creature count from all-live to ~15 at a time, and
   you have this container to yourself. Re-attempt the captures of the Ironwood
   stand, `ridge_patrol_camp`, and the watchtower spur, then **ask the
   coordinator to dispatch the independent critic**. Do not judge them yourself.

   The previous round argued the new assets are low-risk reuses — the ironwood
   trees are byte-identical model and scale choices to Band 2's shipped stand,
   and the patrol camp reuses a compositional technique already blind-critiqued
   elsewhere. That argument is reasonable and it is **not** a blind pass. It was
   flagged honestly as undone; finish it.

2. **A second clean full-suite run.** The record is honest that only one full
   run completed: 1301 tests with 2 failures (the vegetation assertion and the
   Tuskroot bug), both then fixed, after which a 95-test targeted rerun came
   back 0 failed and a second full run was started but killed under contention
   rather than claimed. Run it properly now.

3. **Riding payoff** — prompt 65 wants Meadowhart plus the saddle to become
   genuinely useful here without turning the creature into a dead combat slot.
   `tests/smoke_riding.gd` exists; verify against current state before building.
   Note the density was authored for mounted traversal speed, not walking speed.

4. **Camp/home rhythm** — a plausible reason to use the field camp or return
   home, and a return trip that feels valuable rather than mandatory
   backtracking. Coordinate with `docs/ralph-prompts/31-CONTENT-HOME-*`.

## Your outstanding request to the coordinator

`density_scale` **0.05 for band4**, up from the chapter floor of 0.03, matching
band2. Reasoning is in `ralph/DONE.md`. The coordinator applies all five lanes'
requests in one edit and one bake at integration — **do not edit
`vegetation.json` yourself.**

## Scope note

The third Sigil captain, `captain_riverwatch`, lives in Band 3's file at
z=4350 and is not yours to move. Treat the Riverwatch Sigil as already
obtainable and author the 0/3 → 3/3 progression around it.
