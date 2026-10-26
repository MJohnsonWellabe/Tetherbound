# r30b (26 Oct): Lantern Pools hollow re-judged with the baked forest present (supersedes r30)

r30 compared two arms rendered with a stale Stormwood scatter bake: no baked forest in either, so the authored grove looked like a large gain. This round repeats it after the re-bake (b7811192), on the merged head. Arms: lane (the Lantern Pools discs, stones and posts, inside the baked `hollows_wood`) against `basin` + `glow_fungi` + `grove` ON. Same three catalogue views, calm.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f36_0_gap C7, p2_094_r4), seed 3032. calibrate.py linear fit: slope 1.83, intercept -4.69, r 0.94, anchor RMSE 0.47, no warnings.

| Item | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Lantern Pools | 5.24 | 4.57 | **-0.67** | 5.5->5.2, 5.5->5.1, 5.3->4.9 |

**Verdict: LOSS. The hollow stays OFF and `tb/stormwood-m30-on` is withdrawn.** With the baked forest present:
- The basins' root rings and glow fungi bury the pools: "dark smudges hidden inside root rings and mushrooms".
- The plain discs read as "dark water ovals with a cyan rim".
- The grove's trees take a paler tint than the baked canopy ("pale grey-green foliage cards next to dark green canopy look out of family").

All three judges ask for:
- real lanterns with lit glass and copper fittings instead of the black-bar posts (new art);
- recessed reflective water with stone or root banks;
- natural brown-grey trunks instead of the canopy's mauve;
- layered fog, rim light and lightning.
