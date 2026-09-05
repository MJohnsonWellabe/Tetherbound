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
| Arrival reveal | 741 | 1,085,393 | 741 | 4.60 ms |
| Broken Causeways | 766 | 913,930 | 766 | 4.32 ms |
| Windscar Ravine | 738 | 1,130,486 | 738 | 4.47 ms |
| High Roost before Fly | 252 | 368,618 | 252 | 3.14 ms |
| Upper Cloudreach / Cliffhold | 915 | 1,076,681 | 927 | 4.38 ms |
| Summit approach | 490 | 6,494,861 | 490 | 8.51 ms |

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
- Bridge intervals now cut the route terrain, path, vegetation, and collision consistently. The
  rope and stone spans cross real chasms rather than sitting decoratively over continuous land.
- Trails use a narrower irregular visual ribbon over a controller-safe collision bed, replacing
  the broad straight dirt-carpet treatment without making traversal brittle.
- Production Quaternius trees and rocks now appear in clustered region groves, repeated route-edge
  groups, and non-uniform landing accents. Their installed meshes now share the Meadows-derived
  olive leaf palette, and each region receives an installed twisted-tree wind silhouette. No
  creature content was added in this pass.
- Eight authored roadside places add 59 bounds-normalized installed rocks, shrubs, flowers,
  paving remnants, fences, wagons, crates, and barrels at the six route reveals. Their placement
  rejects unsupported or wrong-elevation surfaces and preserves the controller route centre.
- Generated settlement house boxes have been replaced by Meadows modular cottage prefabs with
  authored wall and doorway collision, keeping Cloudreach in the established village family.
- Cloudreach now uses the production Meadows cloud-sky shader instead of an empty gradient. Cliff
  faces have warm high/mid/deep material bands, lower-frequency rock texture, and less grain.
- The summit stronghold now has an open gate throat, articulated wings, buttresses, threshold,
  crenellations, and danger banners instead of one solid wall-like cuboid.
- The updated route, suspended-cliff, bridge, vegetation, settlement, shrine, and summit rendering
  remains below the 4,000-draw reference ceiling on the local GTX 1060 capture machine.
- Meadows-only HUD/objective copy is excluded from this environment-only evidence set. The capture
  still uses the production scene, player, gameplay camera rig, lighting, and world geometry.
- The evidence is reproducible through `tools/capture_cloudreach_foundation.gd` and
  `tools/contact_sheet.gd`.

## Open visual result

The required code-blind visual review is a clear **FAIL**. The bright open sky, suspended land,
long crossings, coherent natural palette, and danger-only oxblood accents now establish a useful
Cloudreach identity, but the six locations still read as an under-authored traversal prototype.
The grass, flowers, asset trees, grounded cliff ribbons, bridge gaps, Meadows cloud sky, narrower
trails, and stronger summit silhouette materially improve the previous evidence set. They do not
yet supply the natural accumulation, human-scale construction, geology, or atmospheric depth in
the references. Creatures were deliberately excluded from this pass and were not used as a reason
for failure. The broad game-category bar now passes, but the project's own art-direction bar does
not, so the environment is still unaccepted:

- Belongs to the world of the Tetherbound Meadows key art: **No**
- Looks like the same kind of game as the Palworld references: **Yes**

The reviewer identified these three largest reference gaps:

1. Authored density and lived-in scale: clustered vegetation, rocks, built edges, route-side
   stories, negative-space clearings, and intermediate scale cues. The new lay-bys help, but broad
   platforms and straight corridors still dominate Arrival, High Roost, Cliffhold, and Summit.
2. Material and terrain richness: believable cliff layering, atmospheric distance, and varied
   silhouettes instead of broad low-detail faces, exposed polygon bands, and hard underside teeth.
3. Depth and finish at the world boundary: layered distant terrain and haze instead of the pale
   void, repeated background slabs, and stray sky marks in Causeways, Windscar, High Roost, and
   Cliffhold.

The full code-blind critique is preserved in `JUDGE.md`. Final visual acceptance remains with an
external ChatGPT review.

Exact resume point: keep creatures deferred and preserve the real chasms, open Meadows sky,
Meadows-derived surface family, and current performance structure. Replace the remaining
procedural-primitives look with a stronger authored environment-art vocabulary: irregular cliff
strata, terraces, recesses, causeway supports and edges, landmark-specific constructed parts, and
route-side habitation/secondary-scale clusters. Then correct the visible seams and summit
grass/trench intersection, widen destination-reveal compositions, and add layered atmospheric
depth. Recapture these same six views and repeat external review. Do not call Phase 2 complete
until the environment is accepted on its own merits.

## Reference gap

The Cloudreach concept board named by the build directive is not present in the repository or
the local C:/D: workspaces. This pass used the written Cloudreach directive, the Meadows key art,
and the five standard Palworld comparison frames. The missing board remains a disclosed input
gap, not permission to invent a competing art direction.
