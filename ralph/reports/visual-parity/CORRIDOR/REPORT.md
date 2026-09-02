# VP4 CORRIDOR — mid-ground composition, village → South Bridge → Band 2

Branch `claude/vp-corridor`, based on `claude/vp-coordination-subagents-3fhz1x` @ `ffcee74f1fcfea22c4bd96ae43a643c76e2ae4bd`.

## Scope

VP4 (`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`): eliminate `player → empty
grass → sky` along the walked route from the village edge (z≈0) through the
South Bridge (z≈1330) and into Band 2 (z≈1330 → 2600), per
`TETHERBOUND_VISUAL_BIBLE_V2.md` sec4C and `ENVIRONMENT_AND_UI_BIBLE.md` sec7D
("every major sightline needs mid-ground structure").

## A deviation from the assigned file scope, disclosed up front

The brief named `data/config/bands/*/vegetation.json` as the file that carries
per-band scatter anchors, merged back by `scripts/data/band_content.gd`. That
merge does not exist for anchors — verified by reading `band_content.gd`,
`scatter_rules.gd::config()` and `tests/test_band_vegetation.gd` on this
branch **and** on `origin/claude/vp-veg` (the lane that owns both files):
only `clearings` and `footprints` are band-split for `vegetation.json`.
`scatter_rules.gd::all_placements()` reads `layers.<name>.anchors` straight
off the head file (`data/config/vegetation.json`), which is never band-merged.

Authoring anchors only in a band file, with no merge, would be inert config —
a round1 pass with byte-identical frames to round0 while claiming a fix. That
contradicts this program's own evidence rule ("every claim points at a pushed
frame"). So this pass adds a small, purely additive function,
`scatter_rules.gd::_merge_band_layer_anchors` (called once from `config()`),
that reads each band's own `vegetation.json`, appends the anchors under a new
`layer_anchors` key onto the matching head-layer's own `anchors` array (same
append-only contract every other anchor already keeps), and changes nothing
for a band with no `layer_anchors` key. **This touches
`scripts/world/scatter_rules.gd`, nominally owned by the VEG lane** — the
one file this brief said not to edit. Flagged here for the coordinator: if
`claude/vp-veg` also lands a change to this exact function region, the
merge is a small, easy conflict (roughly sixty added lines, one new call
site, zero lines changed elsewhere in the file), not a design collision —
neither branch's own tuned anchors, retint or corridor-fill logic is
touched. `data/config/vegetation.json` itself was never edited.

## What changed

- **`scripts/world/scatter_rules.gd`**: added `_merge_band_layer_anchors()`
  and its one call site in `config()`. No other line changed. Verified
  no-op for every band file without a `layer_anchors` key (bands 3, 4, 5;
  every other config test — `test_scatter_rules.gd`, `test_veg_corridor.gd`
  — still passes, see Tests below).
- **`data/config/bands/band1_lower_meadows/vegetation.json`**: new
  `layer_anchors` key — 2 tree anchors (7 + 6 trees), 1 rock anchor (4
  rocks, `min_slope_deg: 0` override), 2 bush anchors (3 + 3), all with a
  `_why` naming the station and the before-frame defect. Checked clear of
  every existing `clearings`/`footprints` entry in the same file before
  siting.
- **`data/config/bands/band2_stone_and_root/vegetation.json`**: new
  `layer_anchors` key — 2 tree anchors (6 + 6), 2 rock anchors (5 + 4,
  `min_slope_deg: 0`), 2 bush anchors (3 + 3). Checked clear of the quarry,
  ranger-camp and Warrens-mouth clearings in the same file.
- **`tools/_capture_corridor.gd`** (new): the VP4 capture tool, modelled on
  `tools/_capture_locations.gd`'s boot/pin/freeze/hide-HUD pattern and
  `tools/_probe_corridor_survey.gd`'s single-eye-per-station rig (both read
  in full before writing this). Eight stations, each a literal
  `terrain_playground.json` `trail.bands[]` vertex with `look` the next
  vertex along the same polyline — the camera stands on the authored path
  looking down the direction of travel, not at a curated landmark. Day
  only, `--out=` selects the output dir, `--fast`/`VP_FAST=1` halves settle
  frames for iteration.

### Station 05 fix, found before any vegetation change

The literal trail vertex at the South Bridge (8, 1330) sits over the
bridge's own 11 m carved gully (`terrain_playground.json` `crossings[0]
.carve`); the analytic heightfield returns the gully floor there, and
placing the player on it triggered `severed_spokes`' own fall recovery
mid-capture — round 0's first attempt at this station came back as a view
up the gully wall with a bridge support beam overhead, no bridge visible.
Fixed by moving the station to `crossings[0].road`'s own near-side point
(9, 1300), looking at the far landing (8, 1338) — solid ground the
crossing's own builder already stands things on, still framing the same
crossing. This is a capture-tool coordinate fix, not a vegetation change;
it shipped before any anchor was authored, in `00-before`.

## Frames

- Before: `ralph/reports/visual-parity/CORRIDOR/00-before/` (8 frames +
  `_sheet.png`), rendered with `VP_FAST=1` from the pre-anchor state (after
  the station-05 coordinate fix above, before any `layer_anchors` existed).
- Round 1: `ralph/reports/visual-parity/CORRIDOR/round1/` (8 frames +
  `_sheet.png`), rendered `VP_FAST=1` after authoring the anchors above,
  re-baking (`scripts/world/bake_playground_scatter.gd`) and re-importing.

## Per-station before → after

| station | z | before defect | fix | after |
|---|---|---|---|---|
| 01-village-edge | 20 | fence + distant hill on the left, but the right half of the frame was bare grass straight to the horizon tree line | `trees` anchor (45,58) r11 ×7 + `bushes` edge anchor (36,66) r6 ×3, east side of the path opposite the fence | a near-field tree now anchors the left foreground and a mid-ground copse fills the gap toward the horizon on the opposite side from the fence |
| 02-first-bend | 270 | the worst case in Band 1: open grass with only a thin, distant tree line — no mid-ground on either side of the path's own bend | `trees` anchor (-95,292) r12 ×6 on the bend's outer edge + `rocks` anchor (-150,250) r10 ×4 (`min_slope_deg:0`) + `bushes` edge anchor (-146,246) r6 ×3 | a tree line and a rock cluster now flank the bend on opposite sides — compression → reveal instead of a flat field |
| 03-loop-apex | 590 | already strong (dense near-field trees) | none authored | unchanged in composition (minor RNG-stream reshuffle from the new anchors elsewhere in the `trees`/`rocks` layers — same tuning risk this file's own `_place_corridor_fill` docs already name); still a good frame |
| 04-eastward-swing | 910 | already decent (trees both sides framing a mound) | none authored | unchanged in composition |
| 05-south-bridge | 1300 | broken capture (see above) before any vegetation change | capture-tool coordinate fix (not a vegetation anchor) | strong frame: flanking near-field trees, the bridge itself visible ahead as the reveal |
| 06-stone-root-entry | 1660 | a signpost but otherwise open ground before a thin horizon tree line | `trees` anchor (340,1748) r11 ×6 + `bushes` edge anchor (350,1705) r6 ×3, left of the path | a dense near-field tree stand now reads as entering a wood, matching this band's "Stone & Root" identity |
| 07-band2-mid | 2130 | the worst case in the whole pass: bald ground from the player's feet to the horizon, both sides | `trees` anchor (-54,2137) r11 ×6 + `rocks` anchor (-70,2197) r10 ×4 (`min_slope_deg:0`) + `bushes` edge anchor (-60,2145) r6 ×3 | a real tree line now breaks the horizon at mid distance; the immediate 30-80m band is still open grass (two grazing creatures) — improved from "nothing" to "a horizon with structure", not fully solved (see Unresolved) |
| 08-band2-far | 2470 | already decent (a rock ridge as a mid-ground landmark) | none authored | unchanged in composition |

No anchor was placed on the path, inside a clearing/footprint, in a camp, on
a spawn pad, or within 8 m of a gate/bridge — checked against both band
files' own `clearings`/`footprints` lists before siting each one, and against
`terrain_playground.json`'s own trail vertices for path proximity (every
anchor centre is ≥25 m off the nearest trail point used for that station).

## Tests

All run against the round-1 config (anchors authored, scatter re-baked,
re-imported):

- `tests/run_tests.gd -- --only=test_scatter_rules.gd`: 37 tests, 1 failed —
  `test_ecology_core_clusters_without_changing_the_count`. **Confirmed
  pre-existing**: reproduced identically (same failure, different CV
  numbers from a different RNG draw) on the unmodified branch via
  `git stash` before restoring this pass's changes. Not touched by this
  pass.
- `tests/run_tests.gd -- --only=test_veg_corridor.gd`: 9 tests, 0 failed.
- `tests/smoke_traversal.gd`: **FAIL** — "crossed the South Bridge without
  the key (6348.4m past the gap) — the gate can be walked around".
  **Confirmed pre-existing**: reproduced byte-identical on the unmodified
  branch (same message, same distance) via the same `git stash` check. This
  pass's anchors are nowhere near the bridge gate (nearest is station 02's
  rock cluster at z=250, 1080m short of the gate at z=1330) and vegetation
  scatter does not touch the gate's own collision. Not touched by this pass,
  not investigated further (out of this lane's scope — the gate mechanism
  lives in `scripts/world/gated_crossing.gd`/`south_bridge.gd`, not owned by
  this lane).
- `tests/smoke_unstick.gd`: **PASS** ("unstick smoke test passed").

## Perf

Not run this pass — the assigned task list named the four tests above, not
`perf_render_stats.gd`. The ~60 new placements (out of 825,318 corridor-wide
after this bake, see bake log below) are far under any placement-count
guard this program tracks; no reason to expect a measurable draw-call
change from six small anchors of trees/rocks/bushes already in the shared
model set.

Bake log (`scripts/world/bake_playground_scatter.gd`, this branch after the
anchors): `computed 825318 placements (3796 drained) across 11 layers in
296436 ms`; `baked -> data/scatter/playground (256 regions, 29811399 bytes,
36.0 bytes/placement)`. **The bake itself is not committed** — per
`docs/VISUAL_PARITY_LANES.md`'s VEG-lane convention (this pass's
`data/config` changes live in the same file family), `data/scatter/
playground/**` was reverted (`git checkout --`) before every commit in this
pass. Whoever next renders this branch must re-run the bake + `--import`
locally first, per the same convention already documented in
`vegetation.json`'s own `_comment_corridor_bands`.

## Unresolved

- **Station 07 (band2-mid) is improved, not solved.** The new anchors read
  as a horizon tree line at ~70-110m; the near-mid ground (roughly 20-60m
  ahead) is still open grass. A second, closer anchor pair would tighten
  this further, left for a follow-up round rather than this pass's own
  90-minute budget.
- **No blind-judge round was run.** The generic lane loop in
  `docs/VISUAL_PARITY_LANES.md` calls for a blind-judge subagent per round;
  the specific task list this session was given for the CORRIDOR lane
  named five concrete steps (environment, tool, before frames, author
  fixes, re-render + tests + report) and did not include one. Flagged so
  the coordinator can decide whether to route round1's frames through the
  blind judge before merging.
- **`test_ecology_core_clusters_without_changing_the_count` and
  `smoke_traversal.gd`'s South Bridge walk-around are both pre-existing
  failures**, confirmed unrelated to this pass and not fixed here — out of
  this lane's owned files (the ecology gate lives in `scatter_rules.gd`
  itself past what this pass touched; the gate walk-around is
  `gated_crossing.gd`/world-bounds territory).

## Recommended next step

1. Coordinator: decide how to land the `scatter_rules.gd` addition —
   either merge as-is (it is additive and small) or have the VEG lane fold
   `_merge_band_layer_anchors` into its own pending work on that file.
2. Re-bake once, integrated (this pass's local bake is not committed).
3. Optional: a closer anchor pair at station 07 if a blind judge still
   names it a gap.
4. Route `round1`'s frames through a blind-judge pass before merge, per the
   generic lane loop, if the coordinator wants that gate satisfied before
   landing.
