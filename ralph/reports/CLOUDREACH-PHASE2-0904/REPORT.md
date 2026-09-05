# Cloudreach Phase 2 visual-foundation evidence — 2026-09-04

This report records a real in-game evidence checkpoint for the Cloudreach world foundation. It
is not final visual acceptance and does not claim that Phase 2 or the Cloudreach chapter is
complete.

## Capture contract

- Production scene: `scenes/world/cloudreach_cliffs.tscn`
- Runtime: Godot 4.7 stable, Windows/OpenGL3
- Adapter: NVIDIA GeForce GTX 1060 3GB
- Resolution: 1280 x 720
- Camera/player/HUD: production third-person player shell and gameplay camera
- Frames: arrival reveal, Broken Causeways, Windscar Ravine, High Roost before Fly, upper
  Cloudreach/Cliffhold, and summit approach
- Contact sheet: `contact-sheet.png`
- Raw frames: `shots/`
- Performance sample: 24 rendered frames per view, recorded in `performance.json`

## Performance

| View | Draw calls | Primitives | Objects | Measured frame time |
| --- | ---: | ---: | ---: | ---: |
| Arrival reveal | 1,684 | 334,480 | 2,253 | 5.44 ms |
| Broken Causeways | 1,305 | 267,420 | 1,874 | 4.36 ms |
| Windscar Ravine | 776 | 201,903 | 1,345 | 3.04 ms |
| High Roost before Fly | 197 | 65,265 | 766 | 1.93 ms |
| Upper Cloudreach / Cliffhold | 630 | 107,818 | 1,199 | 2.82 ms |
| Summit approach | 454 | 90,651 | 1,023 | 2.37 ms |

The highest recorded draw count is below the Hall reference ceiling of 4,000 draws. The
engine-reported instantaneous FPS was not treated as evidence because it includes capture-start
noise; measured frame time and structural renderer counters are the useful values here.

## What this checkpoint proves

- The six authored chapter regions can be rendered from real gameplay viewpoints.
- The route, suspended-cliff, cloud-sea, bridge, vegetation, settlement, shrine, and summit
  massing runs on the target-class local GPU without exceeding the reference draw-call ceiling.
- The latest camera stands no longer produce degenerate or fully occluded evidence frames.
- The evidence is reproducible through `tools/capture_cloudreach_foundation.gd` and
  `tools/contact_sheet.gd`.

## Open visual result

The required code-blind visual review is a clear **FAIL**. All six locations still read as one
sparse tan/rust/gray construction blockout. The reviewer found no convincing creature-led life,
insufficient authored environment density, weak landmark identity and depth, repetitive hanging
cliff geometry, flat lighting/material response, missing scale cues, and Meadows-specific HUD
copy leaking into Cloudreach. Neither required bar passed:

- Belongs to the world of the Tetherbound Meadows key art: **No**
- Looks like the same kind of game as the Palworld references: **No**

The reviewer identified these three largest reference gaps:

1. Creature-led life and gameplay activity are absent from these particular evidence frames.
2. Replace sparse/repeated construction geometry with clustered habitat detail, purposeful
   surface language, and differentiated regional palettes.
3. Recompose arrival, Cliffhold, High Roost, and summit around unmistakable landmark silhouettes
   with foreground/midground/background depth.

The full code-blind critique is preserved in `JUDGE.md`. Final visual acceptance remains with an
external ChatGPT review.

Owner follow-up after reviewing the sheet: creature staging is deliberately deferred and is not
a blocker for this environment pass. The next implementation priority is to port the Meadows
procedural grass/flower/ground-cover approach, give the procedural cliffs the same terrain and
material language, densely place approved asset trees/rocks, and iterate lighting, composition,
and landmarks until the environment itself meets the reference-art bar.

## Reference gap

The Cloudreach concept board named by the build directive is not present in the repository or
the local C:/D: workspaces. This pass used the written Cloudreach directive, the Meadows key art,
and the five standard Palworld comparison frames. The missing board remains a disclosed input
gap, not permission to invent a competing art direction.
