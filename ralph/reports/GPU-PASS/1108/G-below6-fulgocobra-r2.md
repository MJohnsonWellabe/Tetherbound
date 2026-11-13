# G-below6-fulgocobra-r2: olive-black scales with gold veins at emission 0.8 (F36#46, F41#13; GPU High)

## Verdict: DO NOT SHIP. Both rows lose.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F41#13** electric finish (Stormraven idle over Fulgocobra idle) | **7.37** | 6.91 | **−0.46** | 0/3 | 6.95, 6.95, 6.83 |
| **F36#46** Fulgocobra pose stage (stand, hit, faint mid, faint end) | 5.94 | 5.64 | −0.30 | 1/3 (2/3 prefer base) | 5.81, 5.94, 5.17 |

## Why (3/3 unless noted)
- **F41#13: base's coat is the stronger charged read.**
  - **Base, in the Stormwood idle:** a "navy blue cobra with crisp white-cyan lightning veins, glowing eyes, gold bands and a copper collar plate". The judges call it "clear charged-material contrast in the Stormwood palette". Judge a marks the defect FIXED on base.
  - **Arm:** "green with bright yellow glowing veins". The veins read as charge, but yellow is "off the white-violet Stormwood palette", and "the green body merges into the grass".
- **F36#46: the olive recolour does not lift the stage read.**
  - On the arm the stage shows a "dark green body with thin yellow lines ... low value against the stage, muddy silhouette" (2/3).
  - Base's black body with gold bands and copper plates "separates much better" for 2/3. Judge b scores the arm slightly higher because base's black head and hood sink into the backdrop.
  - The "dark body" defect is PRESENT on the arm for 2/3.
- **The faint is the real F36#46 lever, unchanged on both sides (3/3).** The neck stays raised at full height with the hood flared, and "the faint never reaches the ground". The hit pose barely differs from standing.
- **The GPU lane's pre-check holds:** the vein cores now read gold, not white. Clipping is gone. The problem is the hue and value of the body, not the emission level.
- **Stop rule.** This is round 2 of the Fulgocobra recolour, after r1's white-hot veins. If r1 was also judged without a gain of 0.5 or more, park the olive and gold recolour.
  - The next ideas: keep base's navy coat and its white-cyan veins (it already reads at 7.37 in the field), and fix the faint pose so the neck and head lie on the floor with the hood folded.

## Rows
- **F41#13 on tb/below6 base (Stormraven night coat ON):** 7.37. This is above the 7.0 close-out-exception line. The near-bar close-out push should keep this base coat.
  - Earlier: G-below6-stormraven-r3's arm read 6.67 (a different panel).
- **Remaining F41#13 asks (3/3):** the Stormraven's white speckle "reads as frost or sparkle more than charge". Give it white-violet lightning feather edges (2/3). In the frame: black blotches on the grass, a posterised banded sky and an overbright cottage.
- **F36#46 base:** 5.94 here; the board has 5.87.

## Frames
- **Source:** `tb/gpu-frames-1108`, High, `tb/below6` ba924ea82 on both sides (its two Fulgocobra textures re-imported). The Stormraven night coat is on both sides.
  - **base:** no overlay.
  - **arm:** `BELOW6-FULGOCOBRA/overlay.json`: olive-black scales with gold vein lines, vein emission 0.8 (r1 was 1.5).
  - 0 script errors.
  - **Pair:** `G-below6-fulgocobra-r2-pair` (27a505c49), Stormraven and Fulgocobra idle, `--fixed-fps 20`.
  - **Poses:** `G-below6-fulgocobra-r2-poses` (9e9521178), `capture_f36_poses.gd` hit and faint, whole body with context.
- **Render check:**
  - Fulgocobra idle mean difference 3.2; Stormraven 0.0.
  - Stage frames 0.4–0.5, because the stage background dominates.
  - By eye, the black body with tan bands becomes olive green with gold veins.
- **Sets:**
  - F41#13: Stormraven idle over Fulgocobra idle, stacked.
  - F36#46: the pose-stage 2×2 of hit-000, hit-050, faint-050 and faint-100, cropped (560, 200, 1560, 840), with G-fb's recorded defects.
  - The `_crop_base_r1arm_r2arm.jpg` comparison was not used as a frame.

## Batch `G-fc`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.269, intercept −1.169, r 0.964, anchor RMSE 0.26. No warnings.
- Yardstick: `yardstick_g_below6_fulgocobra_r2/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F41#13 | 7.1, 6.7, 6.4 | 6.4, 6.4, 6.3 |
| F36#46 | 6.0, 5.4, 5.4 | 5.5, 5.6, 5.0 |

Bar B: no on both sets (3/3).
