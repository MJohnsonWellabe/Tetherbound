# CREATURES-RALPH r2: Task 1 regressed remakes, batch 2 (CPU, three blind judges)

Same harness as r1: CPU llvmpipe, `capture_f36_poses.gd --whole-body --context`, stands hit-000, hit-050, faint-050 and faint-100, both arms on the same tree and camera. Anchors were craft, f36_0_npc:C5 and f36_0_gap:C4 (seed 110202). Fit: linear, slope 1.41, intercept −2.41, r 0.95, RMSE 0.33. No warnings.

| Creature | Mapped shipped → fix | Gain | CPU target (old GPU − 0.8) | Verdict |
|---|---|---|---|---|
| **Craghorn** | 5.75 → **6.45** | +0.70 | ≥ 6.12 | **KEEP**, CPU-provisional |
| Cannonback | 4.99 → 5.18 | +0.19 | ≥ 5.88 | not kept (attempt 1) |
| Cragclaw | 4.52 → 4.52 | 0 | ≥ 5.10 | not kept (attempt 1) |
| Mangrove Monitor | 5.56 → 4.61 | −0.95 | ≥ 5.37 | not kept, regressed (attempt 1) |

## Kept

**Craghorn.** Skin weights are relaxed in the GLB by `tools/art_pipeline/relax_stretched_weights.py`, two passes. Over the hit, faint, attack and charged clips, the worst stretch falls from 1.38 m to 0.17 m.
- All three judges see no doubled horns in hit-050 (PARTIAL ×3).
- What the judges still see:
  - The horns are overlong and thin, and they cross the ground in faint-mid.
  - The silhouette is thin, with flat white fur.

## Not kept: next approach

- **Cannonback** (weathered regional grade, matte finish, restrained glow, weight relax). The cannon studs still read as toy styling, and a lighter shell makes the barrels pop more. The defect lives in the silhouette, so the next try needs mesh or Meshy work on the barrels, or a darker, moss-covered treatment.
- **Cragclaw** (weight relax only). There was no visible change. The judges want the body lighter and the head and limbs visible outside the shell.
- **Mangrove Monitor** (countershaded grade, matte finish, aqua lines lit). The lighter, more saturated lime body read as more rubbery. The shipped darker olive is preferred.
  - The tail-through-trainer defect is staging: the trainer sits inside the tail's sweep.
  - The judges also see back plates that detach in faint-end.

Sheet `_sheet_r2.jpg`: shipped on the left, fix on the right. Rows are Craghorn, Cannonback, Cragclaw and Mangrove Monitor.
