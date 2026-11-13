# G-below6-stormraven-r3: near-black Stormraven with lightning and cool rim (F41#13; GPU High)

## Verdict: SHIP. F41#13 gains +0.91 with 3/3 preferring the arm, and clears the 6 floor.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F41#13 row** (Stormraven over Fulgocobra, idle) | 5.76 | **6.67** | **+0.91** | 3/3 | 6.56, 6.89, 6.56 |

- **What the arm fixes (3/3).**
  - **Base:** Stormraven is "a flat, saturated cobalt blue over the whole body, legs included ... painted plastic, not a raven".
  - **Arm:** "a believable black raven with blue-white flecks and short lightning lines through the plumage", taller than the trainer, separating from the green ground.
  - The recorded defect moves from PRESENT (base, 3/3) to PARTIAL (arm, 3/3).
- **Round 3 succeeds where round 2 did not.** Round 2's pupil change was invisible at creature-view distance (level, G-below6-stormraven-masonry). Re-materialing the whole body is what the judges asked for there, and it reads.
- **The GPU lane's white-fleck caution.** No judge marks the arm down for brightness or bloom. They say the charge "reads as speckle rather than forked arcs" (3/3), which is a pattern note, not an exposure one.
- **Fulgocobra is unchanged** (render difference 0.09), so the pair's gain is the raven alone.

## What still holds F41#13 (3/3)
1. **Raven: arcs, not speckle.** The judges want "violet-white or blue-white arc veins" in place of scattered flecks, to match the Stormwood board's forked lightning. The rim light is weak, and the black body merges with the black ground patch behind it (1/3). The eye is barely visible (1/3).
2. **Fulgocobra drifts from its board.** The board shows "olive-black scales with glowing gold vein lines". In game it is navy with painted gold bands, which "read as decorative stripes, not charge". The copper throat plates look "rigid and bolted-on". This is now the larger half of the row's gap: the next arm should give Fulgocobra emissive gold veins on a dark olive body.
3. **Staging.** Posterised green ground with near-black blotches that soak up the creatures' lower bodies, and no storm light near the subjects. These are the T-DARKRIM and P-STORMSKY causes.

## Pooled current-main line
F41#13's base on current main: 5.72 (G-below6-stormraven-masonry) and 5.76 (this batch) pool to ≈ 5.74 at High; the board has 5.97. The arm's 6.67 is the gain evidence.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-below6-stormraven-r3` (87c76c7b4), High, `--fixed-fps 20`, `tb/below6` e150f1cad on both sides. The new `_Image_0_night.png` imported cleanly.
  - **base:** no overlay.
  - **arm:** `BELOW6-STORMRAVEN/overlay_night.json` (`creature_coat_flags` `below6_stormraven_night`: near-black feather albedo, lightning glow, strong cool rim).
- **Health:** 0 script errors.
- **GPU lane pre-check:** saturated pixels in the body box 526 → 1096. The crop `_crop_base_left_arm_right.jpg` was not used as a frame.
- **Render check:** Stormraven 1.0 and Fulgocobra 0.09 mean difference. By eye, the raven goes from royal blue to near-black with lightning and a rim.
- **Set:** Stormraven idle over Fulgocobra idle, stacked, as in G-below6-stormraven-masonry.

## Batch `G-s3`
- Three code-blind judges, standard prompt, one candidate set.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22 (creature row). This is a confirming batch.
- **Fit:** linear, slope 1.088, intercept −0.078, r 0.969, anchor RMSE 0.25. No warnings.
- Yardstick: `yardstick_g_below6_stormraven_r3/`.

**Raw Bar A (judges a, b, c):** base 5.0, 5.8, 5.3; arm 6.1, 6.4, 6.1.

Bar B: no (3/3). The posterised ground and flat storm light sink it.
