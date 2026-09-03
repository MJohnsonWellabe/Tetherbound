# WORLD-TREES-0903 — blind visual judge, two rounds

Sub-agents with no code/config/conversation context, per `.claude/skills/visual-judge/SKILL.md`,
judging `_sheet_before_after.png` (ten stands, before over after: the five
`tools/survey.gd` stands plus one stand at each `BAND1_ROUTE_CONTRACT.md`
place) against `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg` and `site/img/page-board.jpg`.

## Round 1 — found two capture-tool bugs, not game bugs

- **place1-gate-meadow: no change seen.** Root cause: the capture eye sat
  11.7m from the practice-trainer clearing centre, inside its 14m radius —
  the frame was shot from inside a fenced training pen, never looking at
  the new tree anchors at all. Fixed in `tools/_capture_band1_places.gd`
  (moved onto the road, aimed straight up it).
- **place3-pond-pocket: badly broken in both before and after.** Root
  cause: the capture eye's ground height (-19.40) was below `water.level`
  (-17.0) — the camera stood on the pond bed, underwater. Fixed (moved to
  the shore, then to a fully clear spot inside the mill's own clearing
  after a second placement collision — see round 2 below).
- **place2-the-rise, place4-long-field: real improvement**, both already
  correctly framed in round 1.
- **place5-bridge-approach: regression** — see "The place5 finding" below.

## Round 2 — re-judged on the corrected frames

- **place1-gate-meadow: real improvement, the biggest win.** Two trees now
  flank the path into an actual gateway read; the horizon went from three
  isolated saplings to a continuous line.
- **place2-the-rise: real improvement**, second-biggest. A crowned hilltop
  grove replaces a nearly bald hill with one lone tree.
- **place3-pond-pocket: modest, real improvement.** Composition unchanged
  and already reasonably strong (the approved reference); the far shore's
  treeline reads fuller. No leftover framing defects.
- **place4-long-field: real improvement**, matching place1/place2 in
  magnitude — the trainer now stands at the edge of an actual small grove
  (5+ trees) at a plausible ~3-4x his height instead of an empty field.
- **place5-bridge-approach: still a regression** (see below).
- Standard survey stands 01/02/03/05: essentially unchanged (expected —
  this slice's anchors and corridor_fill retuning sit on the Band 1 route,
  not these five camera positions; 03-rise-overlook in particular remains
  a bald, landmark-free hilltop, an existing gap this slice did not touch).
- 04-three-quarter: real improvement (a mature tree now anchors the left
  foreground), most likely downstream of the trail_offset_min change
  bringing corridor-fill closer to camera generally, not a place anchor.

Two consecutive rounds now name the same remaining defects with no new
ones surfacing from a config change (only the round-1 camera bugs were
new, and both are fixed) — per `AGENT_WORKFLOW.md` §7's stopping rule,
this is the ceiling for this pass.

## The place5 finding (regression, mechanism identified, not fixed)

`place5-bridge-approach`'s foreground tree cluster and one leafy landmark
tree are present before and gone after — replaced by a bare dead tree
(visible in the raw frames, `ralph/reports/WORLD-TREES-0903/{before,after}/place5-bridge-approach.png`).
WORLD-TREES made zero edits near arc 1950-2421 (no anchors, no clearings)
— this is a side effect of the one corridor-wide change the contract
named: `layers.trees.corridor_fill.trail_offset_min` 15 -> 6.

Mechanism, confirmed by a direct `placements_for` comparison (old config
vs new config, same seed) rather than guessed: `trail_offset_min` changes
which corridor_fill candidates pass the trail-distance gate along the
**entire** corridor, which changes the total number of accepted
candidates (measured: 43,865 -> 43,676 tree-layer placements corridor-wide
for the same seed). `_place_heroes` — the mechanic that scatters lone
12-19m landmark CommonTrees, corridor-wide, "at least 90m apart" — draws
from the *same shared RNG stream* immediately after corridor_fill
finishes, so a changed candidate count shifts every hero tree's position
that follows. One hero tree that used to land on this ridge moved
elsewhere; the pre-existing (unchanged) dead tree, no longer masked by a
leafy neighbour, is what is now visible.

This is the same class of RNG-stream sensitivity this file's own comments
already document repeatedly (`BAND2-FLOOR`'s anchor-count-reshuffles-
corridor-fill note; `T1-HALL-4`'s density-lever-redistributes-elsewhere
precedent) — an inherent cost of any corridor-wide density/offset lever,
not a bug in this change specifically. Not reverted: `trail_offset_min`
15->6 is the contract's named, evidence-backed fix for the "empty first
two minutes" complaint (`BAND1_ROUTE_INVESTIGATION.md` §3), and place5's
own authored content (rock line, fence, the Meadowhart move) is
WORLD-CONTENT's slice, not this one's. Recorded here as a finding for
whichever lane next touches Place 5 or the hero-tree mechanic.

## Ceilings recorded, not attempted (need art or out of this slice's scope)

- **Tree monoculture.** Every tree in every after-frame is the same
  CommonTree/TwistedTree mesh family at different counts/scales; both
  rounds named this as capping "intentionality" even where clustering is
  now real. No new meshes is a hard rule (`CLAUDE.md`); the installed
  nature family has no fourth canopy silhouette left unused in the
  approved EV2 subset.
- **No undergrowth under the new canopies** (ferns, fallen logs, moss) —
  round 2 named this specifically at place2/place4. The `bushes`/
  `saplings`/`deadfall` layers exist and could be anchored the same way,
  but doing so was not in this slice's named file list beyond the two
  grove clearings; flagged for a follow-up pass.
- **Atmospheric haze at range** (03-rise-overlook, place5's far background)
  — both rounds name this as a shader/renderer limitation of the
  Compatibility pipeline this survey and the shipped game both use, not a
  scatter-density problem.

## Bar answers (round 2, final)

**A.** Partial: the three fixed places (gate-meadow, the-rise, long-field)
now read as belonging to the key art's grove-and-path language; the
untouched survey stands and place5 do not.

**B.** No — none of the ten frames contain a creature, a fight, or UI, so
the Palworld bar's core criteria have nothing to judge; on the one fair
axis (ground/tree density), the three fixed place stands close real
distance, the rest do not.
