# Round 7 — summit arena occupation

Scope is the F10 summit arena presentation only. The canonical Round 6 frame
shows the 36 m fight deck as a broad unbroken paved field bounded by one low,
mostly level wall band. The three relays, lee pockets and rear machinery exist,
but they do not form a readable event hierarchy from the production camera.

## Declared image axes

- F10 must still show the real 36 m combat deck, southern approach and central
  circulation space. Presentation cannot make the arena look denser by changing
  the camera, shrinking the playable disc or blocking the fight lanes.
- The perimeter should form an uneven authored skyline rather than one low ring:
  compare the height and spacing of the left, rear and right silhouettes.
- Each teal lee floor should read together with its real masonry windbreak. Each
  relay should have a visible route from the inner fight field to its exposed
  core without inventing a new gameplay affordance.
- Rear and side work bays should read as an occupied Team Tether final position:
  oxblood marks, installed machines and deliberately unequal staging, not a
  symmetric row of loose crates.

## Bounded source change

- The configured arena origin/radius, cylinder collision, approach collision,
  runtime surface, three lee safe floors and windbreak collisions are unchanged.
  Relay offsets, imported apparatus, housing collisions, interaction sites,
  hazard overlay and progression bindings are unchanged.
- Visual-only oxblood standards and compact banners rise from the existing lee
  windbreaks. They add no bodies and keep the shelter footprint exact.
- The west/east relay approaches use narrow paired bronze conduit rails with
  small oxblood ties under the live telegraph overlay. They connect the inner
  field visually to the existing relay cores, and every added rail/tie is
  explicitly non-colliding. A first real F10 capture rejected the wider version
  because it read as a bright red carpet.
  A second capture rejected the southern crown pair: its relay sits behind the
  production camera, so those rails read as a disconnected ladder under the
  trainer. The west/east pairs remain; the crown apparatus itself remains intact.
- The rear machinery spine now has unequal scaffold heights, a larger installed
  wall machine and staggered service bases. The occupied perimeter varies retained-
  wall height and radius, adds four unequal visual-only watch towers, and divides
  the side work into different boiler/banner and machine/wagon bays. A pylon tried
  in the first capture was removed because its pale silhouette read as a detached
  beacon rather than occupied machinery.
- All additions reuse installed castle, village-prop and Team Tether assets plus
  the existing Cloudreach masonry, bronze, teal and reserved-oxblood materials.
  The expanded perimeter is visibility-capped at 700 m. No creature, gameplay,
  director, progression, collision or configuration file is in this batch.

## Verification state

- Source diff check: clean. A collision-contract comparison against the current
  baseline found the arena cylinder, approach, lee windbreak, relay housing and
  runtime-surface lines unchanged; all added primitive calls are non-colliding.
- Godot 4.7 check-only: exit 0.
- Related unit coverage: **37 tests / 1,195 assertions, zero failures** across
  Cloudreach world data, environment, chapter, production integration and world
  payoff coverage.
- Real foundation structural smoke: PASS; six regions, twelve landmarks, five
  bridges and the player settled at `(0, 105.0002, -260)`.
- Final real Windows/NVIDIA Compatibility capture: twelve of twelve unretouched
  production frames at 1280x800, using the exact Round 6 stands and targets.
  `shots/` is the canonical set and `contact-sheet.png` is its only candidate
  sheet. The two rejected full captures remain local and untracked as
  `before-runner-fix-*` and `before-crown-runner-removal-*`.
- Final F10 visual inspection: the 36 m deck remains open for combat circulation,
  while uneven towers/walls, occupied machinery bays, mounted banners, relays and
  lee standards form a substantially stronger event perimeter. No carpet, ladder
  or detached beacon remains. The static court centre is still necessarily broad;
  this is an observation, not a whole-biome production-bar claim.
- F1–F9/F11/F12 were re-inspected at full size. No new arena silhouette, material
  leak or visibility artefact appears outside the summit views. F7 retains its
  established gate composition; F6 remains the known broad dark cliff finding and
  is outside this F10-only round.

## Quiet measured performance

Actual Windows, GTX 1060 3GB, Compatibility/OpenGL, 1280x800. No other Godot
world ran during these static intervals. This is not ROG Ally or continuous-play
acceptance.

| Static view | Sample | Mean ms | p95 ms | p99 ms | Max ms |
|---|---:|---:|---:|---:|---:|
| Arrival | 10.007 s / 1,018 frames | 9.830 | 10.239 | 10.998 | 11.511 |
| Galefoot | 10.010 s / 940 frames | 10.649 | 11.507 | 12.326 | 13.725 |
| Arena | 10.005 s / 1,207 frames | 8.289 | 8.406 | 8.454 | 8.577 |

At the same F10 camera, Round 7 measures **1,486 draws / 5,841,340
primitives**, an increase of **118 draws / 17,276 primitives** over Round 6.
The expanded perimeter is visibility-capped at 700 m. No visual self-acceptance
or whole-biome B-bar claim is made.

## External review limitation

A fresh code-blind A/B reviewer could not be commissioned for this checkpoint.
Repeated direct and child-agent attempts after Round 6 returned `agent thread
limit reached`; the remaining capacity was occupied by the required continuous
chapter evidence lane throughout Round 7. The full-size inspection above is
implementation QA only, not a substitute verdict. External ChatGPT/owner visual
acceptance remains open.
