STATUS: parked
BRANCH: tb/item-meshy-recheck-parked  HEAD: see origin (READY only; no config change)

Lane LANE-MESHY, owner order 8 Nov ("Turn on the judged Meshy gains after re-checking them"). Rows 2-4 of the lane brief. The re-check found that each of these three installed Meshy pieces was CPU-judged as a gain and then judged on the GPU rig, where it gained nothing or lost. The coordinator agreed (8 Nov): keep OFF, no judge round, no config change.

## Row 2: Meadows ironwood (`data/config/meadows_hero_pieces.json` `ironwood`, OFF)
- CPU 25 Oct (`ralph/reports/MEADOWS/close-1024/iw1024-mapped.json`): 5.20 -> 5.86 (+0.66), "recommend ON".
- GPU 25 Oct, MH (`ralph/reports/GPU-PASS/F38-0/MH-meadows-heroes-ace3dd7e20/VERDICT.md`): **worse**.
  - Ironwood Grove: Medium 6.42 -> 6.12 (-0.30), High 5.75 -> 5.59 (-0.16); canopy defect PARTIAL -> PRESENT (5 of 6 calls).
  - Ridgeline Watch: Medium and High 5.21/5.67 -> 4.60/5.06 (-0.61 both); the day reverse camera sits inside the new ridge trunk (clipping PRESENT on the candidate only).
  - Judges read the Meshy crowns as puffy lime "broccoli", worse than the live canopies.
- Since then `clearings` (ridgeline_glade, radius 17 m at (-244, 6497)) shipped ON; `ridge_a`/`ridge_b` would now stand inside that glade.
- Stays OFF. A fix needs new canopy art (layered leaf cards), which is outside this lane (no generation).

## Row 3: Stormwood junction lantern posts (`data/config/stormwood_path_posts.json`, OFF)
- The brief called the junction use unjudged; it was judged twice.
- CPU r39b 26 Oct (`ralph/reports/STORMWOOD/close-1024/r39/VERDICT.md`): 5.88 -> 6.43 (+0.55), weak fit (r 0.64, RMSE 0.64).
- GPU SW17 26 Oct (`ralph/reports/GPU-PASS/F10-2/SW17-stormwood-path-posts-de3d78ffd/VERDICT.md`): **no gain**, -0.03 to -0.06 at all three junctions, both presets. The short post sits inside the lantern halo, so the judges barely see it; the live chain/pole-hung lanterns already read as supported.
- Stays OFF.

## Row 4: Cloudreach High Perches island shell (`data/config/cloudreach_f40_items.json` candidates[2], OFF)
- CPU b3 25 Oct (`ralph/reports/CLOUDREACH/close-1024/b3/VERDICT.md`): 5.98 -> 6.64 (+0.66).
- GPU S-cloudreach (`ralph/reports/GPU-PASS/F40-0/S-cloudreach-2ca35bc7d/VERDICT.md`): Medium 6.06 -> 5.48 (**-0.58**), High 5.74 -> 5.88 (+0.14); P2-023 PARTIAL on both arms, "no gain". Covered by matrix pieces 57-64 (the High Perches live tool did not run on GPU).
- Stays OFF.

## Flags
- ON: none. OFF: all three, unchanged.

## Tests / pre-ready check
- No file outside this READY changed, so no test applies.

## Process note
Every CPU "gain" here was +0.55 to +0.66 and reversed on GPU. CPU mapped gains of that size are not reliable evidence alone (the noise floor measured in row 0 is in `ralph/reports/LANES/ITEM-P2-014/READY.md`).
