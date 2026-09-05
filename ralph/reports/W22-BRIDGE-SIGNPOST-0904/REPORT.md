# W22-BRIDGE-SIGNPOST-0904 — report

Branch `ralph/W22-BRIDGE-SIGNPOST-0904`, from `origin/main` at `ef16544f`.
Final commit: __W22_COMMIT__.

Brief: prompt 74 §7 (signpost and bridge deck brought toward board 18 without Meshy) and
closure plan CL-B3's in-rules half (the South Bridge as a held crossing from the approach).

## Files changed

| File | What |
|---|---|
| `scripts/world/signpost.gd` | one pointed plank per arm (ArrayMesh via SurfaceTool; full height at the post, 0.92 by the body's far end, then a point), a bracket block at each golden-angle mount, three rope coils above the top arm, a pointed cap; post/plank/rope/ink colours as constants, tuned against a render; `_label_scale()` fits the tapered body's shallow end |
| `scripts/world/gated_crossing.gd` | `_build_rail()` builds squared posts on stone footings, two sagging hemp ropes, wraps + knots at every post, edge beams and under-deck bearers from the recipe's `rail` block; `_string_rope()` helper; called once from `build()` after the colliders |
| `scripts/world/south_bridge.gd` | `_build_occupation()` (occupation dressing only): staked banners, crossed-timber barricades, crates/barrel/rope coil against the archway, a teal-cored post lantern with an OmniLight, and the posted sentry via `village_npcs.gd`; banner holders numbered |
| `data/config/building_prefabs.json` | `south_bridge` recipe: floor slabs yawed 90° (plank seams across the walk), fourteen `Prop_WoodenFence_Single` modules removed, new `rail` block, `retint` of `MI_WoodTrim` toward board 18's weathered brown, `_why_w22_deck`. Colliders untouched |
| `data/config/south_bridge_dressing.json` | new: the Bridge Sentry (`rank: grunt`, `base: grunt_b`, no greeting, `place_when: unless_flag south_bridge_open`) |
| `tests/test_signpost_geometry.gd` | new: six behavioural tests on a really built signpost |
| `tests/smoke_traversal.gd` | `_assert_south_bridge_held()` before the gate walk, `_assert_south_bridge_stood_down()` after it |
| `tools/_capture_w22_bridge_signpost.gd` | new: one-load world capture of the three `_capture_band1_signpost_legibility` stands (read from that tool's own `VIEWPOINTS`) plus four bridge stands |
| `tools/_capture_bridge_deck_isolated.gd` | new: §7 step 1, the deck/rail and a four-arm signpost on a bare bench |
| `docs/decisions/D86-the-south-bridge-is-held-from-the-approach.md` | new |
| `docs/VISUAL_BIBLE.md` §4a, `docs/CURRENT_STATE.md` | status |
| `ralph/reports/W22-BRIDGE-SIGNPOST-0904/` | this report, `JUDGE.md`, `JUDGE_PROMPT.md`, `_sheet_signpost_ab.png`, `_sheet_bridge_ab.png` |

Not touched: `data/config/bands/*`, vegetation, the gate mesh, `south_bridge.gd`'s checkpoint
gatehouse/hero-gate code, `docs/owner/*`.

## What the player sees

- **Every signpost** (the village junction and every trailhead) is a fingerpost with pointed
  single-plank arms in a warm dark brown, cream lettering with a dark edge, a rope-wrapped
  band under a pointed cap, and a bracket where each arm meets the post.
- **The South Bridge and the Old Mill Crossing decks** carry plank seams across the walk and a
  rope rail: squared timber posts on stone footings, two hemp ropes sagging between them,
  rope wound round each post, a kerb beam along each edge and bearers under the deck.
- **The South Bridge from the approach**: two staked oxblood sigil banners flank the road in
  front of the checkpoint gate, crossed-timber barricades stand on both shoulders (the road
  itself stays clear), Team Tether crates and a barrel are stacked against the archway, a
  post lantern carries the faint reserved teal, and a grunt stands posted under it facing
  back up the road. He has no prompt. Open the gate and he is gone; the barricade, banners
  and lantern stay.

## Numbers decided before the renders

Board 18's "Directional (Multi)" panel, crop medians: planks H25 S57 V52–58, post H29 S64 V57,
lettering cream. Isolated bench render, same stand, warm-wood mask over the signpost crop:

| | H | S | V | pixels with luminance > 0.85 (cream) |
|---|---|---|---|---|
| before | 39 | 39 | 99 | 22.8 % (the whole pale plank) |
| after | 25 | 53 | 44 | 2.9 % (the lettering) |

Bridge approach, whole-frame pixel fractions:

| stand | oxblood (H350–15, S>45) before → after | teal (H155–185, S>45) before → after |
|---|---|---|
| bridge-approach-played | 0.04 % → 3.52 % | 0.004 % → 0.014 % |
| bridge-checkpoint-shoulder | 0.02 % → 1.63 % | 0.000 % → 0.006 % |
| place5-bridge-approach | 0.30 % → 0.30 % (the checkpoint is 30 m off, below the rim) | — |

The teal is meant to be faint by day; the number confirms it is present and small.

## Tests and smokes

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_signpost_geometry.gd` | 6 tests, 101 assertions, 0 failed. Seen red first: with `_label_scale()` returning a flat 0.008, `ARM_SPACING` 0.20, the rope band skipped and `ARM_TIP_LENGTH` −0.2, 4 of 6 failed for those reasons; restored, 6/6 |
| `... --only=test_crossing_failsafe_placement.gd,test_river_crossings_stay_open.gd,test_item_gate.gd,test_signpost_geometry.gd` | 26 tests, 184 assertions, 0 failed |
| `godot --headless --path . --script tests/smoke_traversal.gd` (run 1) | **FAIL, and a real finding**: "the South Bridge flies 1 banner(s); a held crossing flies two" — the second `CheckpointBanner` holder was auto-renamed by the tree. Everything else passed: 18 rail posts, sentry posted while shut, locked walk −5.0 m, unlocked +22.9 m, sentry stood down after opening, Old Mill Crossing −8.0 / +23.7 m |
| `godot --headless --path . --script tests/smoke_traversal.gd` (run 2, banners numbered) | **OK** — "18 rail posts, 2 banners, sentry posted"; locked −5.0 m / unlocked +22.9 m; "sentry stood down, barricade still standing"; Old Mill Crossing −8.0 / +23.7 m; the Sigil Gate, river and doors unchanged. Log errors: one known-benign `Parameter "material" is null`, no `SCRIPT ERROR` |
| `godot --headless --path . --script tests/smoke_gate_b_continuous.gd` (core) | **OK** — "gate B continuous (CORE): OK — a fresh save walked opening, road gate, village tools and tournament readiness in order", 544 s. Log errors: two known-benign `Parameter "material" is null` and one exit-time `4 resources still in use at exit` — confirmed baseline by lane W24-LANDING: the identical line appears on `origin/main` at `504c7b55` in the same smoke, so the known-benign set did not grow |

`^ERROR:` / `SCRIPT ERROR` in the traversal log: one `ERROR: Parameter "material" is null.`
(the known-benign headless one recorded by G3-BAND5-0903), zero `SCRIPT ERROR`. The set did
not grow.

## Renders and the blind judge

- Isolated bench (`tools/_capture_bridge_deck_isolated.gd`), before and after: the deck was
  seven kit slabs with grain along the span, railed by picket fence; the signpost was a pale
  cream box-plus-cone arm with dark ink.
- World (`tools/_capture_w22_bridge_signpost.gd`, 1280×800, Compatibility, software GL,
  ~55 min per load in this container), before and after, seven stands: the three signpost
  stands from `_capture_band1_signpost_legibility.gd`, the played stand the Gate 2 judge
  graded the bridge on (`G2-S05-0755-objective`, player at (9.66, 1319.38)), `place5-bridge-approach`,
  a checkpoint-shoulder close stand and the deck from the far landing.
- Sheets: `_sheet_signpost_ab.png`, `_sheet_bridge_ab.png` (A = before, B = after; the judge
  was not told which).
- Verdict (`JUDGE.md`, code-blind, given only the sheets, the frames under neutral A/B names,
  `docs/reference/`, board 18 and the visual-judge skill — see `JUDGE_PROMPT.md`):

_The lane left this block unfilled and never committed a verdict; the sheets and
`JUDGE_PROMPT.md` are here but `JUDGE.md` was not. Lane W24-LANDING ran the round at landing
time on the lane's own four questions, per the owner directive of 2026-09-05 02:24 UTC. Full
verdict: `JUDGE.md` beside this report._

**Call: not shippable for a first playable — but the remaining work is scene and material
work, not new art.** The judge identified the after column as the finished pass without
being told which was which, and split the result: **ship the bridge deck and rail** once the
value fixes land (silhouette, plank orientation and deck colour already match board 18, the
deck sampling `(127, 90, 61)` against the reference's `(127, 91, 68)`); **do not ship the
signpost**, which is the right model and unreadable at gameplay distance (glyph cap height
5–7 px, text-to-board contrast about 1.3:1 in world rows, against 3.0–11.6:1 in the studio
turntables); **do not ship the checkpoint dressing**, whose "held" read is carried by
untextured blockout barricades that sit beside the road rather than across it, with a guard
wearing none of the faction's red.

The approach dressing does work where it is shot properly: red banners at `#90392b` against
board 18's `#993633`, and 22.1 % of the pixels in `bridge-approach-played` changed. It fails
from the far bank, where tower stonework occludes the red and the gate's own blue banners
still fly beside it.

## Known limitations, and what was deliberately not done

- The hero checkpoint gate's own banners are blue (the Meshy scan from board 21). The oxblood
  is on the two staked banners in front of it; the mesh was not touched (not this lane's).
- `place5-bridge-approach` sees the checkpoint from 30 m at the rim; the dressing is small
  there by construction. The played stand is where the "held" read is graded.
- The signpost crest stands show a single-arm trailhead post at 10–15 m; the label is a few
  pixels tall at either version, as it was before. The bench frames carry the letterform
  comparison.
- No Meshy brief written: the judge did not fail the deck or the signpost twice.
- The barricade never crosses the deck (D86 §1); the sentry is dressing, not a fight (D86 §3).
- The Old Mill Crossing inherits the rope rail through the shared recipe (D86 §4) and was not
  re-rendered here.
- The full unit suite was not run (the brief did not ask for it); the named tests and both
  smokes were.
