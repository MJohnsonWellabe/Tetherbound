# r29 (26 Oct): SW7 follow-up bundle (heart cleft), code-blind CPU

Arms: lane `tb/stormwood` at 05dc9659, with `hero_interior` ON (SW7, central core column), against the same commit with the bundle ON:
- `hero_interior.heart_cleft` ON: the lightning core moves into the north trunk split. Root-wall bark closes the split deep in the wall, a 15 m crystal heart sits at its foot, and a vein-lit seam climbs from it with tapering branching bolts.
- `core_column.enabled` false.
- The hollow's forked charge is not drawn while the cleft is ON. It showed only in building/break, so the judged calm and fading sets are unaffected.
- `steam.rise_fade_m` [0.45, 1.3]: Fading steam fades out between 0.45 m and 1.3 m above the ground.

Stand: the F41 catalogue Stormheart cameras v02-v05 (-101.56, 5466.87), 2x2 grids, calm and fading.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f36_0_gap C4, f36_0_npc C4), seed 2908. calibrate.py fell back to the offset method (least-squares slope 2.62 is outside 0.5-2.0; r 0.93), intercept +0.07, anchor RMSE 0.60.

| Set | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Stormheart calm | 5.37 | 5.90 | +0.53 | 5.3->5.8, 5.4->5.9, 5.2->5.8 |
| Stormheart fading | 5.10 | 5.64 | +0.54 | 4.9->5.4, 5.2->5.7, 5.0->5.6 |

Recorded defects:
- Core tube: PRESENT 6/6 -> PARTIAL 4, FIXED 2 ("thin jagged lightning, reads as real lightning"; still "floats free of the wood"; the crystal reads as "a small glass dais").
- Fading puffs: PRESENT 3/3 -> PARTIAL 2, PRESENT 1 (knee-to-waist wisps remain).
- Sky strip: PRESENT on both arms in frame 4 (v05: the south entrance split) and at the frame 3 edge.

Still asked by all three judges:
- vertical structure (stacked decks, stairs) and warm lantern pools or shafts;
- break the tiled bark and the flat grass ring with roots, moss and black pools;
- a distinct grade for the fading phase.
