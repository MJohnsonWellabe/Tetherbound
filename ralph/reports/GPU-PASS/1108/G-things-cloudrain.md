# G-things-cloudrain: brighter broken overcast for Cloudreach rain (F40#0, F40#19, F40#21; GPU High)

## Verdict: DO NOT SHIP as it stands. F40#19, a named row, loses (−0.12, 2/3 prefer base). The F40#0 and F40#21 gains are real but small, and partly confounded.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F40#0 day rain** (9 places, gameplay camera) | 6.38 | 6.59 | +0.21 | 3/3 | 6.59, 6.83, 6.34 |
| **F40#0 night rain** (9 places, gameplay camera) | 6.55 | 6.79 | +0.24 | 3/3 | 6.71, 7.08, 6.59 |
| **F40#21 rain cleanliness** (9 places, approach) | 6.18 | 6.38 | +0.20 | 3/3 | 6.46, 6.46, 6.22 |
| **F40#19 rain sky** (gate crag, 4 views) | 6.46 | **6.34** | **−0.12** | 0/3 (2 prefer base) | 6.46, 6.71, 5.85 |
| Clear weather no-loss (Three Bells, day and night) | 6.96 | 6.96 | 0.00 | identical | 7.08, 6.96, 6.83 |

## What the judges see
- **The day rain gain is the arm.** Base's rain is "greyer and flatter" (2/3), and the arm "keeps slightly more grass saturation and more value range".
- **F40#19 loses on the sky itself.** At the gate crag the arm's sky is "paler and more washed out" (2/3; judge b ties). The sky is still "a flat grey card with little cloud form, no shafts and no depth layering" on both sides (3/3).
  - That matches G-f40-19-mist, where the darker slate overcast was +0.44, 3/3 for this row. Brightening it gives that read back.
- **Confound in the 9-place grids (3/3 named it).** At the High Perches tile (middle centre):
  - the arm shows "an ornate spoked compass floor" with "a blue drake";
  - base shows "a plain ring" or "a flat dark-green disc" with "the panda-like creature ... more mascot".
  - All three judges single that tile out as the arm side's most authored moment. The creature is the spawn difference the GPU lane flagged. The floor difference is not explained, and may be the arm's stands 05–12 re-run (a different boot) loading the crown-court floor differently.
  - So some of the +0.2 on F40#0 and F40#21 is that one tile, not the weather.
- **No loss in clear weather.** The no-loss pair scores identically per judge.

## Next
- **Keep the brighter day-rain grade where it helps,** but do not wash the sky. The judges ask for "a bright, layered sky with sun breaks, height-graded mist and light shafts" in rain (3/3), not a paler card.
  - One option: the arm's ground and grass values with G-f40-19-mist's slate cloud deck.
- **Recapture the High Perches stand on both sides from one boot** before re-judging, so the crown-court floor and creature match.
- **Shared defects, both sides (3/3):**
  - flat brown earth walls and smooth grass mounds (bottom-left and top-right tiles);
  - a uniform grass carpet;
  - night grass staying bright lime under a night sky;
  - the "Rest at cliffhold commons" prompt covering a third of a frame;
  - the electric-blue night boulder and stray pink blobs at the Three Bells.

## Pooled current-main lines
- This batch's bases are the current-main reads for these frames: F40#0 rain 6.38 by day and 6.55 at night, F40#21 rain 6.18, F40#19 6.46.
- G-baseline-f40-0-f40-21-cloudreach's whole-row matrix means (F40#0 6.58, F40#21 6.68) cover all times and weathers. They are not pooled with these rain-only sets.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-cloudrain` (ed2f549ea), High, `tb/things` 22d3005fa on both sides.
  - **base:** no overlay.
  - **arm:** `THINGS-CLOUDRAIN/overlay_rain_bright_overcast.json` (`cloudreach_visual.json` `weather_arms.rain_bright_overcast_1112`, cloudreach_cliffs only).
- **Capture:** 104 frames per side, 0 blank, 0 script errors.
  - Day rain and night rain at all 12 stands, 4 views each.
  - Day and night clear at three_bells_bridge.
  - The arm's stands 05–12 come from a 33–96 re-run so the camera holds 5.2 m like base.
- **GPU lane pre-check:** day rain top-third sky L 119 → 155; night 59 → 74.
- **Side differences that are not the arm:** HUD FOOD reads a few percent higher on the arm, and wild spawns differ at some stands.
- **Render check:** rain frames differ by 12–28 mean per frame (sky plus rain-streak positions); the clear no-loss frames by 2–7.
- **Sets:**
  - F40#0 and F40#21 use 3×3 grids of nine stands: realm_gate_crag, galefoot_waycamp, broken_skyroad_arch, sky_shrine, the_high_perches, cliffhold, old_wind_observatory, summit_eyrie, stormward_overlook. F40#0 uses the gameplay camera; F40#21 uses the approach view.
  - F40#19: 2×2 grid of realm_gate_crag's four day-rain views.
  - No-loss: three_bells_bridge approach and gameplay, day then night, clear.
  - Briefs follow G-baseline-f40-0-f40-21 (look brief for F40#0 and #19, cleanliness brief for F40#21).

## Batch `G-cr`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.232, intercept −0.684, r 0.905, anchor RMSE 0.59. No warnings.
- Yardstick: `yardstick_g_things_cloudrain/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#0 day rain | 5.8, 5.9, 5.5 | 5.9, 6.1, 5.7 |
| F40#0 night rain | 5.8, 6.1, 5.7 | 6.0, 6.3, 5.9 |
| F40#21 rain | 5.6, 5.7, 5.4 | 5.8, 5.8, 5.6 |
| F40#19 rain sky | 5.9, 6.0, 5.5 | 5.8, 6.0, 5.3 |
| Clear no-loss | 6.3, 6.2, 6.1 | 6.3, 6.2, 6.1 |

Bar B: no on every candidate set (3/3).
