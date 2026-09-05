# Round 5 — declared comparison contract

Baseline: pushed round4, fresh `../round4/JUDGE-ASTRA.md`: board relationship Yes,
shipping-game comparison No. Preserve palette, twelve camera stands/targets,
collision, progression gates, routes, quest/runtime data and encounter lanes.

## Image axes declared before capture

- F9 east arrival: compare the bounding extent of masonry obstructing the central
  30% of the frame (x35–65%, y10–75%); record whether the onward yard/house entrance
  is visible instead of a path terminating at a pier. This is obstruction, not a
  beauty score.
- F5 aerie approach: compare tall-grass edge continuity on each side from the
  foreground to the crest; record visible breaks, lateral width variation and
  whether both sides still form parallel unbroken rails. Keep the same camera.
- F11 aerie: compare the visible flat cyan panel's bounding extent and rectangular
  edge visibility; verify animated wind reveals the landscape behind it and that
  the same locked traversal state remains visually readable. Do not improve the
  metric by hiding the locked feature or changing its flag.
- F2: distinguish actual bell mouth/lip/clapper/yoke from suspended ovals and
  compare far-deck contact/rock ledge continuity; F6: compare rounded skirt/base
  transition, not town visibility from an impossible lower sightline.
- F3/F12: count visible worn doorway-to-yard connections and inspect foundation
  contacts. F10: inspect distinct service groups and worn floor value structure
  while the central fight and all three lee pockets remain clear.

Structural counters and quiet ten-second static frame samples are separate from
startup/world-assembly time, continuous play reliability and any ROG Ally claim.
No score, self-pass or external final visual acceptance is implied by these axes.

## Bounded implementation

- Replaced the opaque locked-gate box with three animated, edge-faded crosswind
  layers. The existing barrier shape, transform, required flag and visibility
  lifecycle are unchanged. Aerie perch timber now has longitudinal grain,
  sockets and braces; the old decorative plinth no longer conceals the actual
  floor-height actors. No physical aerie surface changed.
- Moved only the upper settlement's decorative watchtower from rear-east to
  rear-west. House thresholds and the arrival join now connect through worn
  ground to the existing shared yard. Replaced the noncolliding round skirt
  with a closed rock/subsoil volume, sloping turf shoulder and installed rock
  buttresses. The authoritative 48m-square collision terrace is unchanged.
- Bridge abutments gained overlapping rock feet below the existing end decks;
  no chasm was filled or deck/collision profile changed. Bells now have an open
  mouth, lip, clapper and yoke with braced, iron-strapped timber construction.
- Route cover uses asymmetric two-dimensional planting lobes, variable worn
  margins and short/tall transitions instead of matching continuous tall rails.
  Sampling still uses the authored supported surfaces and gameplay exclusions.
- Arena material wear now distinguishes worked arcs and broad worn patches.
  Perimeter bays differentiate boiler service from wagon supply. Lee walls use
  existing weathered masonry; relay cores use restrained teal facets and aged
  metal feeds rather than white heads. All floor, lee, relay, hazard and prompt
  transforms remain unchanged.

No generated assets, creature changes, new progression rules or palette retint.

## Evidence and verification record

- Check-only: clean, exit 0 after the concurrent director edit was complete.
- Focused world-data units: 13 tests / 407 assertions, zero failures, exit 0
  (`world-data-tests.log`).
- First real Windows/NVIDIA Compatibility capture: 12/12 frames, exit 0.
  Preserved at `before-fix-shots/`, `before-fix-contact-sheet.png` and
  `before-fix-capture.log`; it is **not** the final evidence set.
- That inspection exposed an open underside between the new F6 turf and rock
  buttresses, and F5 planting still aligned into rails. Closed the decorative
  subsoil volume and changed the planting field before final recapture. These
  are observed defects, not claims that source existence proved an improvement.
- Corrected real twelve-view capture: 12/12, exit 0, no script/shader errors.
  `shots/` contains the unchanged camera contract, `contact-sheet.png` the full
  labeled frames, `capture.log` the result and `shots/performance.json` raw
  measurements.
- Foundation smoke: PASS, exit 0, six regions/twelve landmarks/five bridges,
  production player settled at `(0,105.0002,-260)`. `foundation.log` also proves
  the existing cover-count/solid-world/bridge-gap/detail-support assertions.
- Explicit real Fly: PASS, exit 0, double-Jump plus actual controller inputs from
  the declared unlocked aerie checkpoint reached `(533.9439,765.5444,3170.625)`.
  No airborne position writes. `fly.log` records climb/glide, stamina and no
  collision contacts; `shots/10-real-fly-silhouette.png` shows the real carrier,
  suspended player and controller HUD. It is separate from the same-twelve-view
  sheet so F1–F12 do not shift. The fixture explicitly unlocks Fly but does not
  play the quest; its initial story card is not narrative-continuity evidence.
  `fly-performance.json` is a 24-frame sample, not a sustained benchmark.
- Fresh code-blind Astra review: **A Yes / B No**, recorded in `JUDGE-ASTRA.md`.
  It inspected the twelve views plus the separate real flight frame, the Meadows
  board and all five Palworld references. A standalone Cloudreach concept board
  was unavailable in the searched repository paths; no acceptance against an
  unseen board is claimed. Specific remaining work: lawn-like clearings, hard
  road-strip boundaries, broad cliff forms/haze, empty arena staging, canopy and
  stone material cohesion, disconnected working props and unclear wind contours.
- Related parent regressions pass **26 tests / 794 assertions**, no errors,
  including shared interaction registration and chapter/environment/payoff data.
  Together with this lane's world-data tests: **39 tests / 1,201 assertions**.
  Meadows `smoke_playground.gd` completes OK, exit 0. Its complete distinct
  `ERROR:` set is the known headless alpha `Parameter "material" is null`;
  no new script/shader error is hidden by checking only SCRIPT ERROR.
- One twelve-view `_sheet.png` and written evidence are checkpointed. Raw frames,
  intermediate failed captures and logs remain local. Implementation completion
  is not visual acceptance. Next pass must address the named remaining defects.

### Same-camera observations, not a verdict

- **F9 obstruction:** at 1280x800, the old tower approximately occupied
  x362–697/y0–488. Its intersection with the declared central review region was
  about x448–697/y80–488. The new tower is approximately x250–414/y150–417,
  entirely outside that region. Houses, doorway and onward yard are visible.
  These are manually inspected bounding extents, not segmentation/beauty scores.
- **F5 rails:** each shoulder now contains visible interruptions rather than two
  continuous tall rows. The near left clump ends around image x355/y580, with
  open short-ground separation before the next crest-side growth; the right
  shoulder has a large clear section beside the player. The broader flat ramp
  and its straight surface seam remain visibly unresolved.
- **F11 panel:** the old uninterrupted cyan rectangle around x612–744/y81–251
  is absent. Wind filaments remain visible across the same opening, and the
  distant grey crag is visible behind them. There is no opaque rectangular edge
  or horizontal fill division. Timber rest arms and floor-height actors read.
- **F2:** three flared bell mouths and dark lips replace the suspended ovals;
  knee braces/straps articulate the overhead frame. Bridge wood remains visible.
  The much larger far plateau still has a broad smooth face and abrupt grassy
  crown; small abutment feet did not resolve that whole-landform issue.
- **F6:** open sky gaps under the new turf are closed in the corrected frame.
  Recessed rock buttresses replace the round stack, but the upper turf wedge and
  the overall monumental isolated mass still need the critic's scrutiny.
- **F3/F12:** the arrival path connects into the village yard and at least three
  visible doorway directions; cottage thresholds are grounded. Broad smooth
  lawn margins remain. **F10:** worn patches/arcs and boiler/supply silhouettes
  are distinct, and the lee pockets/central fight floor remain clear. The empty
  court still dominates the static view; no claim that floor wear alone solves
  its destination composition.

### Quiet measured performance

Actual Windows, GTX 1060 3GB, Compatibility/OpenGL, 1280x800. No other Godot world
ran during these samples. Peak across twelve views: **4,587 draws / 6,928,266
primitives**, under the repository structural ceilings. The 24-frame samples
range 4.07–10.12 ms and are not sustained-play proof.

| Static view | Sample | Mean ms | p95 ms | p99 ms | Max ms |
|---|---:|---:|---:|---:|---:|
| Arrival | 10.009 s / 1091 frames | 9.174 | 9.511 | 9.914 | 12.233 |
| Galefoot | 10.010 s / 986 frames | 10.152 | 10.325 | 10.712 | 12.081 |
| Arena | 10.008 s / 1219 frames | 8.210 | 8.365 | 8.394 | 8.459 |

World assembly still takes roughly a minute before capture; no build-stage
profiling or startup optimization was attempted in this bounded appearance pass.
The table excludes startup and does not certify continuous frame pacing or Ally
performance. No A/B verdict or external acceptance is claimed.
