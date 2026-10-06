# Village static batch: before/after evidence

Change: `static_batch_settlements` (performance.json) folds each village.gd building's static, unscripted kit modules into one MeshInstance3D per equivalent material (`scripts/world/static_mesh_batch.gd`). Door leaves, interiors and scripted children are left alone.

## Structural numbers (Meadows F26 route stands, Compatibility under xvfb, 2000 m far floor)

| Stand | Draws before | Draws after | Primitives before | Primitives after |
|---|---:|---:|---:|---:|
| stand_0 (Grandpa's door) | 8,641 | 5,396 | 6.67M | 6.75M |
| stand_1 | 4,461 | 2,525 | 6.16M | 6.09M |
| stand_2 | 2,428 | 963 | 5.34M | 5.28M |
| stand_3 (Hall nave) | not in the baseline run | 8,972 | — | 8.07M |

The before numbers come from `../probe/meadows_baseline.json`; the after numbers are from `../probe/meadows_batch_lod.json`. A merged surface gets a regenerated LOD chain, and without one primitives rose about 10%. The fold costs 537 ms once, in the village build, for 797 module meshes.

## Visual check

The 8 route stills (4 stands, day and night, 1920x1080, Low/Compatibility) were taken with the flag off and on at the same commit. The pairs were relabelled X/Y at random (`judge_key.json`) and given to a code-blind judge that saw no source and was not told what changed.

**Verdict: EQUIVALENT on all 8 pairs.** Neither build was worse anywhere. The only differences were clouds, a pickup glow's pulse phase, sub-pixel roof glints from the sky and ambient shifts under one level. Geometry, tiles, materials, windows, lights and shadows matched at 2× zoom.

The judge also found defects present in both builds and unrelated to this change, recorded here for the visual lanes:
- The Crossing Hall interior has flat doorway planes and clipped labels.
- The Hall facade's tiled stone texture is oversized.
- A dark band crosses the cottage roof tiles.
- The village ground dressing is thin.
- The trainer looks self-lit at night.

The `*_before.jpg` and `*_after.jpg` files are downscaled day frames.
