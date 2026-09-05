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
| Arrival reveal | 803 | 1,504,625 | 803 | 3.61 ms |
| Broken Causeways | 906 | 2,462,935 | 906 | 4.50 ms |
| Windscar Ravine | 836 | 2,280,838 | 836 | 3.90 ms |
| High Roost before Fly | 139 | 494,717 | 139 | 2.31 ms |
| Upper Cloudreach / Cliffhold | 392 | 1,389,668 | 392 | 3.31 ms |
| Summit approach | 494 | 1,192,418 | 494 | 3.09 ms |

The highest recorded draw count is below the Hall reference ceiling of 4,000 draws. The
engine-reported instantaneous FPS was not treated as evidence because it includes capture-start
noise; measured frame time and structural renderer counters are the useful values here.

## What this checkpoint proves

- The six authored chapter regions can be rendered from real gameplay viewpoints.
- Route ridges and region plates now use the exact Meadows meadow-grass, verge, dirt-path, and
  rock-scree texture family with world-space triplanar projection.
- Stacked surfaces now carry deterministic, culled MultiMesh grass, flower, and bush layers made
  from the Meadows production procedural meshes. This avoids the one-height-per-XZ limitation of
  binding the Terrain3D grass field directly to overlapping Cloudreach plates.
- Continuous irregular cliff ribbons replace the repeated hanging-cylinder supports. Route
  landings are grounded, their path joints are covered, and the arrival gate has a supporting
  crag instead of appearing unsupported.
- Production Quaternius trees and rocks now appear in clustered region groves, repeated route-edge
  groups, and non-uniform landing accents. No creature content was added in this pass.
- The updated route, suspended-cliff, bridge, vegetation, settlement, shrine, and summit rendering
  remains below the 4,000-draw reference ceiling on the local GTX 1060 capture machine.
- Meadows-only HUD/objective copy is excluded from this environment-only evidence set. The capture
  still uses the production scene, player, gameplay camera rig, lighting, and world geometry.
- The evidence is reproducible through `tools/capture_cloudreach_foundation.gd` and
  `tools/contact_sheet.gd`.

## Open visual result

The required code-blind visual review is a clear **FAIL**. All six locations still read as one
under-authored route blockout despite the new Meadows-derived surface treatment. The grass,
flowers, trees, grounded cliff ribbons, and corrected HUD context materially improve the previous
evidence set, but they do not solve the region's larger composition and terrain-form problems.
Creatures were deliberately excluded from this pass and were not used as a reason for failure.
Neither required bar passed:

- Belongs to the world of the Tetherbound Meadows key art: **No**
- Looks like the same kind of game as the Palworld references: **No**

The reviewer identified these three largest reference gaps:

1. Replace the unfinished gray slab geology with authored warm cliff strata, terraces, ledges,
   shadowed recesses, and overlapping silhouettes while preserving the traversable green caps.
2. Recompose each vista around one unmistakable exposed crossing and one farther destination;
   the present paths are too broad, straight, centered, and runway-like to communicate danger.
3. Create a stronger warm-sun/cool-shadow palette, atmospheric cloud and distance layers, and
   visibly wind-shaped vegetation clusters rather than uniform roadside bands.

The full code-blind critique is preserved in `JUDGE.md`. Final visual acceptance remains with an
external ChatGPT review.

Exact resume point: keep creatures deferred. First reshape the broad straight route ribbons and
blank region slabs into layered, irregular highland terrain with narrow embedded paths and
legible drops. Then author one dangerous bridge/crossing composition and one distinct destination
silhouette for each named reveal. Finally vary cliff materials, lighting, vegetation clustering,
and background silhouettes before recapturing these same six views. Do not call Phase 2 complete
until an external review accepts the environment on its own merits.

## Reference gap

The Cloudreach concept board named by the build directive is not present in the repository or
the local C:/D: workspaces. This pass used the written Cloudreach directive, the Meadows key art,
and the five standard Palworld comparison frames. The missing board remains a disclosed input
gap, not permission to invent a competing art direction.
