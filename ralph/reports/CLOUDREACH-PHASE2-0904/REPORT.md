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
| Arrival reveal | 704 | 1,057,747 | 704 | 4.54 ms |
| Broken Causeways | 756 | 902,634 | 756 | 4.33 ms |
| Windscar Ravine | 730 | 1,120,070 | 730 | 4.44 ms |
| High Roost before Fly | 215 | 347,926 | 215 | 3.05 ms |
| Upper Cloudreach / Cliffhold | 502 | 1,029,743 | 502 | 4.27 ms |
| Summit approach | 467 | 6,479,973 | 467 | 8.49 ms |

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
for failure. Neither required bar passed:

- Belongs to the world of the Tetherbound Meadows key art: **No**
- Looks like the same kind of game as the Palworld references: **No**

The reviewer identified these three largest reference gaps:

1. Authored, lived-in world density: clustered foliage, rocks, flowers, built edges, route-side
   stories, negative-space clearings, habitation traces, and intermediate scale cues.
2. Finished landform and landmark vocabulary: irregular geology and readable constructed parts
   instead of banded cutaway slabs, repeated arch teeth, skeletal pavilions, and enlarged primitive
   fortress masses.
3. Lighting, material, and atmospheric depth: stable warm/cool separation, coloured shade,
   corrected material scale, controlled haze, and several overlapping distance layers.

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
