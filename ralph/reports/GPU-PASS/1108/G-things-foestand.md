# G-things-foestand: opponent trainer stand (F38#3; F39#7, F39#19, F41#3 and Warden Aldis ride along; GPU High)

## Verdict: SHIP. The target row gains with 2/3 preferring the arm, Aldis gains 3/3, and no set loses beyond noise. F38#3's arm meets the bar at High (7.61, confirming batch) and needs Medium.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F38#3** Meadows fight camera (Tether Grunt) | 7.48 | **7.61** | +0.13 | 2/3 | 7.48, 7.48, 7.86 |
| Warden Aldis trainer fight (ride-along) | 6.80 | **7.18** | **+0.38** | 3/3 | 7.09, 7.09, 7.35 |
| F39#7 Tidewake fight composition (Venn) | 6.58 | 6.67 | +0.09 | 2/3 | 6.58, 6.84, 6.58 |
| F41#3 Stormwood Voltarach spacing | 7.05 | 7.05 | 0.00 | 0/3 (all tie) | 6.58, 7.35, 7.22 |
| F39#19 Tidewake roster contrast | 6.84 | 6.80 | −0.04 | 0/3 (1 prefers base by 0.1) | 6.71, 6.84, 6.84 |

- **F39#19 is level, not a loss.** Its frames differ by a mean of 0.3, so base and arm are the same picture. One judge scored them 0.1 apart, which is panel noise and cannot come from the arm.
- **F38#3 arm 7.61 is above the top anchor (7.53).** This batch's anchors include craft (7.35) and f36_0_npc:C1 (7.47/7.53), so it is the confirming batch. F38#3 closes only with a Medium arm capture at 7.5 or above (High first is done).
- **Pooled current-main F38#3:** High ≈ 7.33 (G-closeout-meadows-ui 7.17, this base 7.48); Medium 7.35. That stays the board score until the stand lands.
- **What the arm fixes (all three judges):**
  - **Aldis:** base puts Warden Aldis "directly under the bottom-right move-list HUD panel" (3/3) and tucks the player trainer behind Terrapup's chest. The arm stands him clear at the left.
  - **F38#3:** the ally "no longer fills half the view" on both sides (defect PARTIAL on both, 3/3). Base has the grunt against Terrapup's forelegs. The arm moves him, but he is now "half hidden behind Mudsnout's head" (3/3), so the gain is small.
  - **F39#7:** trainer still clips Ripplet's back in frame 2 on both sides (PARTIAL 3/3). In base frames 1 and 3, Venn is cut off under the bottom HUD bars; the arm is cleaner there.

## What still holds the rows (3/3 unless noted)
- **F38#3:** the grunt is still occluded, now by Mudsnout's head. A blurry foreground fence or crate intrudes at the bottom right in frames 2–3 (both sides). Light is flat and overcast or olive. The next stand should keep the opponent outside every creature's footprint as seen from the camera, not just away from the ally.
- **F41#3:** Sparkit is buried inside Voltarach's leg span (frame 3 shows only its tail), and an armoured figure clips the frame edge. Judge a flagged Sparkit as reading smaller than the trainer (1/3; a scale check worth one look). The stand does not touch the ally's spacing, so this row needs ally placement, not the opponent stand.
- **F39#7 / F39#19:** flat beige sand with no water in view, and black sky-gap polygons in the top corners (both sides). F39#19's roster defect is FIXED on both sides. Venn clips Cannonback's shell in arm frames 1–2 (2/3).
- **Aldis hall:** one orange-amber grade flattens creatures into the walls and floor; asks for cool fill or rim light. Burrowback's face blows out to a white blob in frame 3 (1/3). The red banners are fine if the hall is Tether ground (2/3 raised it).

## Caveats (from the GPU lane)
- Stormwood fight state drifts after i08, so F41#3's 24.5 render difference is fight timing, not the stand. Its scores are identical per judge.
- Venn is sometimes fully hidden by Cannonback (for example t-012); those frames were not used.
- warden_aldis-r10 is blank on both sides (resolve fade); not used.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High: G-things-foestand-meadows (720743ae5), -tidewake (4f832bdce), -stormwood (839299d82).
- **Sides:** both on `tb/things` 8cb498dba. **base:** no overlay. **arm:** `THINGS-FOESTAND/overlay_opponent_stand.json` (combat.json `arena.opponent_trainer_stand_1112`).
- **Sets** (three frames stacked):
  - F38#3: south_bridge_grunt-01/02/03.
  - Aldis: warden_aldis-02/04/06.
  - F39#7: venn t-023.02, t-024.02, t-025.02.
  - F39#19: venn t-000.00, tell-start-000.57, t-003.02.
  - F41#3: capacitor_alpha-i01, tell1-a-start, tell1-e-impact.
- **Render check:** mean difference F38#3 19.1, Aldis 23.7, F39#7 21.3, F39#19 0.3, F41#3 24.5.

## Batch `G-fs`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.278, intercept −1.083, r 0.921, anchor RMSE 0.54. Warning: F38#3 arm meets the bar only above the top anchor; this batch confirms it.
- Yardstick: `yardstick_g_things_foestand/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F38#3 | 6.5, 6.8, 6.8 | 6.7, 6.7, 7.0 |
| Aldis | 6.1, 6.1, 6.3 | 6.4, 6.4, 6.6 |
| F39#7 | 5.9, 6.0, 6.1 | 6.0, 6.2, 6.0 |
| F41#3 | 6.0, 6.6, 6.5 | 6.0, 6.6, 6.5 |
| F39#19 | 6.1, 6.3, 6.2 | 6.1, 6.2, 6.2 |

Bar B: no on every candidate set for judges a and c; judge b said yes for F38#3 and F41#3 (meadow density; storm sky).
