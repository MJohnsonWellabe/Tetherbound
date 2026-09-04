# G3-WARDEN-ARENA-0904 — W-4 (arena dressing + silhouette re-measurement) and R-2 (the waystop duty board)

Task: the two items G3-FINALE-0903 left open honestly rather than fake —
`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` contracts **W-4** and **R-2**.
Branch `ralph/G3-WARDEN-ARENA-0904`, from `ralph/G3-LAND-0904` @ `44f06cf9`.
No PR, per the coordinator's brief.

## W-4 — Warden Arena dressing

### What was built

`scripts/world/stronghold.gd::_build_warden_arena_dressing()`, called from
`build()` after `_build_conduits()`. All of it stays out of the 11 m combat
ring (`data/config/combat.json`'s `arena.radius`), which the 24×26 m room
clears with a metre to spare, per the contract's own "keep it empty" clause
— nothing added carries collision.

- **Two war banners** on the end wall behind `warden_stand` (the one wall in
  the room with no passage in it), using the same `_hang_banner`/+z-wall yaw
  convention `_build_yard_banners()` already established for this building.
- **Two lit conduit runs** hugging the entry wall's base, from each jamb
  toward the passage centreline — "the conduits converging on the chamber
  door" — using the same `_live_material()` teal every other inter-chamber
  floor cable in this building already carries.
- **Two brazier baskets** flanking the entry threshold, outside the ring
  (14.06 m from the arena centre, verified by `test_stronghold_warden_arena.gd`).
  These are added to `hall_occupation.gate_source` (baskets with no light of
  their own, the same trick the gate's own fire points already use) rather
  than `hall_occupation.braziers`, specifically because the Hall's own
  `EXTERIOR_OMNI_BUDGET` (22) was already spent to 21 before this pass
  (`stronghold.gd::_report_light_budget`'s own count) — a real third pair of
  omnis here would have pushed it over for two props that only need to read
  as fire, and the arena's own two ambient sky-fill `lights` already do the
  actual lighting job. `smoke_stronghold.gd` confirms the count is still
  21/22 after this pass.

### The silhouette measurement — the contract's own literal metric

Method: the same one `tools/_probe_grass_separation.gd` /
`_grass_separation_ratio.py` established for `CREATURE-LEGIBILITY-0903`'s
1.5:1 floor — Rec.709 luma, fixed crop boxes, real rendered frames. New tool:
`tools/_probe_warden_arena_silhouette.gd`, which boots the full Meadows world
(the real `Stronghold` + `StrongholdClimax`, not a bare fallback), places a
camera at the `warden_challenge` mark (eye height 1.6 m) aimed at the
Warden's own body at `warden_stand` — **16.00 m apart**, printed live by the
tool, matching the contract's own number exactly.

```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x800 --script tools/_probe_warden_arena_silhouette.gd -- \
  --out=ralph/reports/G3-WARDEN-ARENA-0904 --tag=<before|after>
```

`before` = `git checkout 44f06cf9 -- scripts/world/stronghold.gd
data/config/stronghold.json` (this lane's own parent commit, pre-W-4);
`after` = this branch. Crop boxes (pixel, left/top/right/bottom, 1280×800
frame): Warden `(625,375,655,420)` — his coat torso, the mass of his own
silhouette; near floor `(560,610)`+`(665,715)` at y `435–460` — the floor at
his own feet, either side of his boots; far floor `(50,300)` at y `455–478`
— open floor near the camera, clear of HUD and the two waypoint-line overlays
the live HUD draws across the shot.

| | Warden luma | near-floor luma | far-floor luma | ratio (near) | ratio (far) |
|---|---|---|---|---|---|
| before | 0.0908 | 0.0296 | 0.0124 | **3.067** | **7.348** |
| after  | 0.0908 | 0.0296 | 0.0124 | **3.069** | **7.353** |

**Both clear the 1.5:1 floor by a wide margin, before this pass and after
it.** This is an honest finding, not an oversold one: the ratio is
essentially unchanged, because none of W-4's new geometry sits inside either
crop box — the banners are beside him, the conduits and braziers are 16 m
away at the entrance. `CONTENT-0828B`'s "97% of pixels under luminance 40"
finding was true of the *room as a whole* before its two ambient sky-fill
lights (`lights` entries at `[-8,90.2]`/`[8,90.2]`) were authored in an
earlier pass; those two lights already cleared the contract's own named
metric (Warden vs. floor) on their own, and W-4's wall dressing does not
regress that. `warden_challenge`↔`warden_stand` distance and both ratios are
printed live by the probe tool, not hand-measured off a screenshot.

### The blind judge — the problem the floor-luminance metric can't see

Two passes, per this project's "never judge your own frames" rule, each a
fresh sub-agent shown only the frame(s), told nothing about what changed.

**First pass** (banners at `half.x*0.45`, inner edges 2.7 m clear of
`warden_stand`'s centreline either side — the initial, literal reading of
"banners on the end wall behind `warden_stand`"), verbatim on the point that
matters:

> "the banners sit to his left and right, not behind him... his silhouette is
> still sitting against the same dark, low-contrast stone it was against
> before... If the goal was to make the boss figure poppable against the
> backdrop for combat tracking, this specific change doesn't accomplish it."
> "Shrunk to ~30%... the figure effectively disappears."

This is a real gap the floor-luminance metric is blind to: the contract's
own number compares him to the *floor*, but a player tracking him in a fight
is reading him against the *wall*, and the judge is right that two banners
several metres either side of a person do nothing for that.

**Response**: `half.x*0.45 -> 0.28` — banners' inner edges now ~0.7 m off
`warden_stand`'s centreline (a ~1.4 m gap instead of ~5.5 m), without the two
cloths overlapping each other or the corners. Re-rendered, re-measured (table
above, "after" row — unchanged, as expected: still outside both crop boxes).

**Second pass**, fresh agent, on the narrowed frame only:

> "The character silhouette does read against the wall, but the banners do
> not frame him — they flank him at a distance... a noticeably wide gap of
> bare stone wall directly behind his torso and head... Shrunk to 30%, I'd
> expect the figure to lose most of its readability... He'd likely blend
> into the background gap between them." "the whole chamber reads as
> underlit, with the banners themselves lit slightly better than the
> character, which is part of why he under-reads."

**Honest verdict: the narrowing was a directional fix, not a solved one.**
A ~1.4 m gap around a ~0.5 m-wide figure viewed from 16 m is still a visible
gap, and the second judge's own diagnosis — the banners are the *brightest*
things in frame and the character himself carries no rim light or
self-illumination — points at the actual lever: this is the same
"dark-thing-against-dark-thing" shape `CREATURE-LEGIBILITY-0903` solved for
Bramblebun with a material-side fix (`field_emission`, a value floor on the
*creature's own* body), not a prop-placement fix, and it is exactly the
class of problem this repo's own `burrow_warrens.json` history warns cannot
be solved by moving fixtures around or adding more wash. **Not chased
further this pass**: the Warden's own rig/material is outside this lane's
file ownership (`scripts/creatures/**` is explicitly not this lane's), and
reactively bumping a light's energy without measuring first is the precise
mistake that repo's own four-round history says wastes a pass. Flagged here
for the coordinator to route to whichever lane owns the Warden's own
material/rig, with the two blind-judge quotes above as the starting
evidence and the measured fact that the *floor* metric already passes, so
whatever fix lands next should be judged against the *wall*, not re-litigate
the floor number.

### What W-4 delivers, plainly

- Arena walls and far end dressed (banners, converging conduits, threshold
  braziers) — contract's literal ask, met.
- Ring stays empty of collision — verified.
- Zero cost to the Hall's light budget — verified (21/22, unchanged).
- The 1.5:1 floor-luminance metric the contract names — passes, measured,
  before and after.
- The *combat-legibility* question a player actually experiences (does the
  Warden pop against the wall he's fought in front of) — **still open**,
  independently confirmed by two blind passes, with a specific, evidenced
  next lever named above rather than asserted.

## R-2 — the waystop duty board

`stronghold_climax.gd::_place_readout` is no longer hard-wired to the
`reveal` config entry alone: it now takes `(spec, node_name)` and returns the
built panel, so `build()` calls it twice — once for `reveal` (unchanged
behaviour, `TetherReadout`) and once for a new `duty_board` entry
(`StrongholdDutyBoard`). Same primitive panel, same `interactable.gd` +
conversation mechanism, no new mesh.

`data/config/stronghold_climax.json`'s new `duty_board` block has no `mark`
(the waystop is band 5's own clearing, outside the stronghold's marker set)
— only `fallback: [-25.0, 7466.0]`, world metres. That point sits **9.9 m**
from the waystop's own campfire (`(-22.6, 7456.4)`,
`data/config/bands/band5_stronghold_approach/props.json`, not touched by
this lane) almost exactly on the bearing from that fire to the Hall
(`outer_works`, world `(8, 7560)`) — in frame as the player leaves camp for
the works, and 5 m clear of the northmost camp prop, so it stands in the
open rather than inside the furniture cluster.

Conversation `stronghold_duty_board` (`data/dialogue/stronghold.json`):

> GARRISON DUTY BOARD — HALL APPROACH. POSTINGS AS ROTATED.
> VERRICK — 2. SOLENE — 3. HALD — 3. WARDEN — 5.
> Each posting stands until relieved by the one behind it. None of them
> stand down early.
> NO RELIEF UNTIL THE DRAW IS STABLE.

Numbers checked against the real gauntlet table
(`data/config/bands/band5_stronghold_approach/trainers.json`: Patrolman
Verrick 2, Warder Solene 3, Keeper Hald 3, Warden Aldis 5) — a board that
lied about them would undercut the readiness layer it exists to give.
Carries no flag and gates nothing; reading it is optional, same as the
reveal. Contains none of `tests/test_dialogue_runner.gd`'s forbidden words
(legendary/veridian/stag/living power/power source) — it names the draw,
never what chamber five holds.

## Tests run

- `godot --headless --path . --script tests/smoke_stronghold.gd` — **pass**
  (route order, floor-per-space, the shutter, the gauntlet, the recovery
  bed; light budget printed 21/22).
- `godot --headless --path . --script tests/smoke_boss.gd` — **pass**, first
  attempt, in a real fight: the Warden reachable, the reveal readable before
  he speaks, **the duty board reachable and honest** (new assertion, 195 m
  from the Warden — nowhere near the Hall), the chamber gated until he
  falls, the boss fought and won, the legendary freed once, the release
  ceremony reached with a full belt.
- `godot --headless --path . --script tests/run_tests.gd -- --only=test_stronghold_warden_arena.gd`
  — **3 tests, 28 assertions, 0 failed** (new file: ring clearance, light-
  budget neutrality, duty board config shape, duty board honesty against the
  real trainer table).
- `godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_runner.gd`
  — **66 tests, 1010 assertions, 0 failed** (the new conversation does not
  trip the spoiler scan or the STRONGHOLD_FILES exemption count).

## Evidence

`_sheet.png` in this directory: before (left) / after (right), same fixed
camera stand, same tick — the "after" frame is the narrowed-banner version
the second blind judge saw. Per-frame captures are not committed
(matching this project's `ralph/reports/CREATURE-*/**/[!_]*.png`-style
evidence-payload policy); the contact sheet is the tree's own record.

## Open items for the coordinator

- **The Warden's own combat legibility against the wall** (not the floor) is
  the one thing this pass did not close, evidenced by two independent blind
  passes rather than asserted — see the "blind judge" section above for the
  exact quotes and the specific lever (self-illumination/rim on his own
  material, not further prop placement) named as the likely next step. Out
  of this lane's file ownership.
