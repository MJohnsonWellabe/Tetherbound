# G-things-cloudrain-r2: rain ground-light lift with the slate deck kept (F40#0, F40#19, F40#21; GPU High)

## Verdict: DO NOT SHIP, and PARK the rain-overcast arm. The ground lift does not register, and the two sets that move are both driven by the High Perches plaza floor, not by the arm.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| F40#0 day rain (9 places, gameplay) | 6.88 | 6.92 | +0.04 | 1/3 (2 ties) | 7.13, 7.26, 6.37 |
| F40#19 rain sky (gate crag, 4 views) | 6.62 | 6.67 | +0.05 | 1/3 (2 ties) | 6.88, 6.88, 6.24 |
| F40#0 night rain (9 places, gameplay) | 7.00 | **6.62** | **−0.38** | 0/3 | 6.75, 7.13, 5.99 |
| F40#21 rain cleanliness (9 places, approach) | 6.75 | **6.62** | −0.13 | 0/3 | 6.88, 6.88, 6.12 |
| Clear weather no-loss (Three Bells) | 7.59 | 7.59 | 0.00 | identical | 7.76, 7.76, 7.26 |

## Why
- **The sky is fixed.** F40#19 no longer loses: the slate deck is kept, and the judges see the two sides as "near identical" (+0.05). That undoes round 1's −0.12.
- **The ground lift does not show.** Day rain is level (+0.04). The judges still describe both sides' grass as "a uniform green carpet" under "flat grey overcast" (3/3). The GPU lane's ground L 67 → 86 does not move the read.
- **The two losses are the High Perches plaza, again.** Round 2 captured each side from one boot, but the crown-court floor still renders differently between the sides.
  - On base it is a cobbled stone disc in the night-gameplay and day-approach views.
  - On the arm it is a flat green disc with a thin line-drawn ring and spokes in those same views. In day gameplay both sides show cobbles.
  - I checked this by eye. All three judges name that tile as the night set's difference: base has "a textured stone circle", the arm "a flat line ring with spokes on bare grass ... placeholder geometry". The arm's F40#21 tile is "a dark flat line ring on the grass".
  - The night −0.38 and the F40#21 −0.13 are that floor, not the rain grade.
- **Stop rule.** Round 1 lost on F40#19, and round 2 is level where the arm acts. Two rounds have gained under 0.5, so park this arm until there is a new idea.

## A real defect this exposed (for PLACES or BELOW6)
**The High Perches crown-court floor sometimes renders as a flat green disc with a line-drawn ring** instead of its cobbled stone. It happens per view, even within one boot. The judges read the fallback as "placeholder geometry" (3/3), and it costs F40#21 cleanliness wherever it appears. It looks like a material or decal loading race on that floor. Fixing it is worth more than the rain grade.

## Other shared defects (3/3, both sides)
- Night grass stays "saturated mid-green under a night storm sky"; the night grade only reaches the sky and stone.
- The orange path is a flat, stretched, glowing ribbon.
- At the Three Bells: a pink glow blob at the left frame edge, a flat dirt rectangle, and a cobalt night boulder.
- A yellow glow halo around the trainer in the bottom-left approach tile (2/3).

## Pooled current-main lines (rain-only sets, High)
- **F40#0 day rain:** 6.38 (G-things-cloudrain base) and 6.88 (this base), ≈ 6.63.
- **F40#0 night rain:** 6.55 and 7.00, ≈ 6.78.
- **F40#21 rain:** 6.18 and 6.75, ≈ 6.47.
- **F40#19:** 6.46 and 6.62, ≈ 6.54.
- This panel ran about 0.4 more lenient than round 1's: the clear no-loss read 7.59 here against 6.96. So the pools are between-panel averages.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-cloudrain-r2` (d18132857), High, `tb/things` ad723a6a1 on both sides.
  - **base:** no overlay.
  - **arm:** `overlay_rain_bright_overcast.json` round 2 (no sky block; keeps the slate deck and lifts only the ground light).
- **Capture:** one boot over pieces 1–96 per side, camera spring 5.2 m on every frame, HUD and framing matched. 104 frames per side.
- **GPU lane numbers:**
  - Day rain sky L 118 → 124, ground 67 → 86.
  - Night sky 59 → 63, ground 72 → 84.
  - The clear frames are unchanged.
- **Other side differences:** the creature spawn at the Perches still differs (a blue drake on base, a ram on the arm), and so does the plaza floor (above).
- **Sets:** as in G-things-cloudrain.
  - The same nine stands in 3×3 grids: gameplay for F40#0 day and night, approach for F40#21.
  - realm_gate_crag's four day-rain views for F40#19.
  - Three Bells clear day and night for no-loss.

## Batch `G-c2`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.268, intercept −1.110, r 0.893, anchor RMSE 0.62.
- **Warning:** the clear no-loss set sits above the top anchor on both sides (7.59). This batch confirms that read, but it is not a row close-out.
- Yardstick: `yardstick_g_things_cloudrain_r2/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#0 day rain | 6.4, 6.6, 5.9 | 6.5, 6.6, 5.9 |
| F40#19 rain sky | 6.2, 6.3, 5.8 | 6.3, 6.3, 5.8 |
| F40#0 night rain | 6.5, 6.8, 5.9 | 6.2, 6.5, 5.6 |
| F40#21 rain | 6.4, 6.4, 5.8 | 6.3, 6.3, 5.7 |
| Clear no-loss | 7.0, 7.0, 6.6 | 7.0, 7.0, 6.6 |

Bar B: no on every rain set (3/3). The Three Bells clear set gets yes from 3/3.
