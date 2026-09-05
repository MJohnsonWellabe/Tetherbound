# Round 6 — ground joins and inhabited terrain

Baseline: pushed round5 `c1e834771`, fresh blind A Yes / B No. Same twelve
production camera stands and targets. No palette retint, collision/progression
changes, generated assets or creature changes. Parent coordinates fresh judging.

## Declared image axes before capture

- F3: inspect the transverse rectangular path start under the trainer, and trace
  whether soil merges into the foreground rather than beginning at a straight
  stamp edge. Count separately the connected worn work/door areas and interior
  vegetation masses (not the outer fence-border planting).
- F5/F9: trace the long straight ground joins outside the ochre path, from the
  bottom of the frame toward the player/crest. Record the remaining visible
  straight segments and whether there is a height/shadow lip. Do not substitute
  a changed camera, more tall grass occlusion or edge noise for removing it.
- F3/F9/F12: record whether front/side work patches join real thresholds and the
  common path, and whether non-perimeter short planting divides the lawn into
  connected usable clearings. Houses, doors and canonical walking lanes stay.
- F4/F6: inspect intermediate rock planes, shadow recesses and substantial shelf
  lips, not tiny bush count. F6 specifically: trace the long diagonal grass cap
  edge and look for inset transitions into rooted rock rather than a roof wedge.
- Preserve the existing twelve-view palette/depth survey and capture structural
  counters plus quiet ten-second static samples separately from active play,
  startup assembly and any ROG Ally claim.

## Source diagnosis before patching

`_build_routes` draws the real walkable box top at the route elevation while
`_route_ridge` draws its shoulder crown 0.72m below it. The resulting long straight
box-side/plane boundaries are geometry, not an insufficiently noisy grass mask.
Both use world-space turf already, so another tint change cannot solve them.

`_path_ribbon` draws a raised opaque strip whose shader mixes soil into its own
turf. Its UV mask fades only laterally, not at either endpoint. The F3 transverse
rectangle is therefore a real uncapped soil-mask endpoint. Small worn patches
also mix opaque turf and can clip their radial wear at the plane extent.

The settlement cover has a large central exclusion/inner clear radius plus
repeated outer-ring patches. This produces a lawn and border even when the total
grass count is high. Preserve interaction clearances, but use connected activity
wear and short interior verge masses on the supported terrace.

## Bounded implementation

- The controller route boxes, shapes, transforms, widths and authored heights are
  unchanged. Their box MeshInstance is no longer drawn. The geological route crown
  now reaches the authored walking height, so its irregular turf shoulders visually
  own the unchanged collision instead of exposing a 0.72 m straight box side.
- Trail UVs now carry physical metres from the nearest endpoint. Soil wear feathers
  over a fixed 2.2 m and the full-width surface rises from below the turf over 2.8 m.
  This replaces both the original transverse rectangle and an inspected intermediate
  symmetric arrowhead; no camera or grass occlusion hides the join.
- Settlement cover no longer cuts one circular hole around the communal centre.
  Existing building, threshold, yard and path exclusions preserve the real usable
  lanes. Short inner verge patches, paired arrival planting and connected west/east
  work wear subdivide the remaining lawn. The installed workbench/bucket/apple and
  barrel/bag/crate groups now meet the shared yard through visible wear.
- Route walls gained a broad geological bed lip with the next wall recessed behind
  it. Monumental masses use four additional large embedded outcrops and two new
  visual-only deep ledges; their original three shelf collisions are byte-for-byte
  formula-preserved. The settlement skirt gained rooted crown breaks and staggered
  south-face shelves. No new collision body was added for the new ledges.
- The canonical capture helper now records the same twelve Round 5 stands/targets at
  1280x800. The production-integration capture helper has an isolated `--round6`
  sustained-output route. No generated/new assets, palette retint, encounter lane,
  progression, director, Fly, HUD or chapter-runtime edit is in this batch.

## Verification record

- Godot 4.7 check-only: exit 0 before and after the observed endpoint repair; no
  script or shader parse error.
- Related units: **39 tests / 1,201 assertions, zero failures**, including world data,
  generated-face orientation, chapter/environment integration, payoffs and shared
  interaction registration (`related-unit.log`).
- Production foundation smoke: PASS, exit 0; six regions, twelve landmarks, five
  bridges and player settled at `(0, 105.0002, -260)` (`foundation.log`).
- Real Windows/NVIDIA Compatibility capture: twelve of twelve unretouched production
  frames at 1280x800, with the same Round 5 stands and targets. `shots/` is the final
  candidate set and `contact-sheet.png` is its only candidate sheet. Two superseded
  local captures remain untracked: the first construction check and the arrowhead
  intermediate. A later 1280x720 helper run was rejected as noncanonical and is also
  preserved locally rather than cited.
- Quiet sustained sampling ran alone in one production world, after assembly, with
  three separate ten-second static intervals. The JSON/log explicitly excludes an
  Ally claim and continuous-play frame pacing. Peak across the twelve short samples
  was **4,944 draws / 6,947,508 primitives**.
- Fresh code-blind visual judgment is owned by the parent after this implementation
  report. This report records observations, not a visual pass or chapter acceptance.

### Declared-axis observations, not a verdict

- **F3:** the transverse rectangle and inspected arrowhead are absent. Soil now begins
  as an uneven soft patch around the trainer and connects forward into the shared
  yard. West/east use groups have worn links; additional short planted pockets sit
  inside the fence rather than only on the outer border. A broad usable green apron
  still remains in the foreground.
- **F5/F9:** the long raised collision-box side/height lip is absent. F5 retains an
  ochre road centered on irregular vegetated shoulders. F9's endpoint wear has faded
  into its crest at the stand, so the foreground remains broad turf; this is not a
  claim that its settlement density is finished.
- **F12:** threshold/yard/work wear remains connected and the added inner planting is
  visible. Crown rocks were lowered after the first capture so they no longer dominate
  the bottom edge. The central house apron is still intentionally traversable.
- **F4/F6:** large lit planes, inset faces and shelf lips now interrupt the rock masses.
  F6 remains a dark, broad monolith at this approach despite the added south-face
  shelves, and its high turf cap is still conspicuous. This remains open visual work.
- **F10:** untouched by this bounded batch. The arena still reads as a large open
  paved court in the static frame and remains an explicit open blind-review finding.

### Quiet measured performance

Actual Windows, GTX 1060 3GB, Compatibility/OpenGL, 1280x800. No other Godot world
ran during these intervals. These are static desktop measurements, not ROG Ally or
continuous-play acceptance.

| Static view | Sample | Mean ms | p95 ms | p99 ms | Max ms |
|---|---:|---:|---:|---:|---:|
| Arrival | 10.002 s / 1,017 frames | 9.835 | 10.167 | 10.370 | 11.749 |
| Galefoot | 10.010 s / 938 frames | 10.672 | 11.600 | 12.724 | 13.241 |
| Arena | 10.005 s / 1,213 frames | 8.248 | 8.390 | 8.441 | 8.600 |

No self-acceptance or B-bar claim is made.
