# G-things-wardenring and G-closeout-f41-13-main: Warden ring arm (F38#28) and the F41#13 close call (GPU High and Medium)

## Verdicts
- **Warden ring arm (F38#28): SHIP.** It gains on Medium (3/3) and on the other Warden frames (3/3); High is level. No set loses.
- **F38#28 does not close.** The arm reaches **7.52 on Medium** but **7.05 on High** in this batch.
- **F41#13 does not close.** It reads **6.91 on both High and Medium**.

| Row | Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|---|
| **F38#28** | job frames 03/05/08, **Medium** | 7.05 | **7.52** | **+0.47** | 3/3 | 7.61, 7.47, 7.47 |
| **F38#28** | job frames 03/05/08, **High** | 7.05 | 7.05 | 0.00 | identical per judge | 7.05, 7.05, 7.05 |
| no-loss | Warden fight r04/r10/r16/a03, High | 5.80 | 6.03 | +0.23 | 3/3 | 6.22, 5.94, 5.94 |

| Row | Panel | High | Medium | Control F38#38 |
|---|---|---|---|---|
| **F41#13** (main 317b3372f, Stormraven night coat) | this batch, High and Medium side by side | 6.91 (7.19, 6.77, 6.77) | 6.91 (same) | 7.94 / 7.94 |

- **Control.** F38#38 read 7.94 on both presets against its closing 8.16/8.30, so this panel is about 0.3 strict. That control is above the top anchor (7.53), and this batch's anchors reach 7.35 or more, so it is a confirming batch.

## Warden ring (F38#28)
- **Medium: the arm fixes the recorded defect for all three judges.** On the arm "the ring is almost gone ... nothing crosses a creature silhouette" (FIXED 3/3). On base "a visible curved turquoise band runs around the floor and passes behind the creatures" (PARTIAL 3/3).
- **High: the judges see no difference.** Both sides read as "a curved, soft-glowing cyan ring ... still reads as an overlay", PARTIAL 3/3. The pixel difference is the same as at Medium (1.7–2.0), so the band is fainter and lower on the arm at High too, but not enough for any judge to separate the sides. The High read is what keeps the row open.
- **No-loss frames:** the arm is a little better (3/3). In frame 3 (r16) the base still shows the cyan ring "behind the deer and the dog"; on the arm it is barely visible.
- **Remaining defects (3/3, both sides):**
  - **A near-black frame (r10):** the camera sits inside or behind dark geometry. A real artefact, flagged as serious by all three judges.
  - A thin teal vertical bar in the dark doorway on the left wall (3/3) and a straight teal strip at the left wall base (1/3), read as stray guide geometry.
  - A single saturated orange grade with the same brick tiling everywhere; the judges ask for cool fill or rim light on the creatures.
  - The red Team Tether banner on the hall wall is flagged as a possible oxblood leak (2/3). It is a known asset on both sides.
  - Floating flat heart and key icons over the Warden in the win frame (2/3).
- **Path to close:** take the High band to what Medium shows (lower alpha at High as well, or remove the band and use a floor-material edge, 3/3), then re-judge High and Medium side by side.

## F41#13 (Stormraven and Fulgocobra, current main)
- **High and Medium score the same** (render difference 2.2–2.5), at 6.91. The earlier 7.37 was a single High read on tb/below6.
- **Recorded defect PARTIAL on both presets (3/3):**
  - Stormraven's white speckles "read more like frost or sequins than lightning".
  - Fulgocobra's cyan hood edge and glowing eye read as charged, but the "gold bands read as pattern, not charge".
- **Possible red (3/3):** Fulgocobra's copper-red collar plates sit near the reserved red range.
- **Scene (3/3):** blotchy oversaturated green ground, a Meadows-style warm cottage, flat white light shafts.
- **Judges' asks (3/3):** branching white-violet arc lines along Stormraven's feathers; glowing veins on the cobra; drop the copper-red collar.

## Frames
- **Warden ring:**
  - Sources: `G-things-wardenring-high` (82af295af) and `-medium` (884d25cbd), `tb/things` 5f3d5c320 (contains main 317b3372f) on both sides.
  - **base:** no overlay. **arm:** `overlay_warden_ring.json` (arena.boundary_per_trainer_candidate: ring alpha 0.3 → 0.12, height 0.8 → 0.45 m).
  - The F38#28 repro (`phase2_capture_fights.gd south_bridge_grunt,warden_aldis`), `--fixed-fps 20`, 0 script errors.
  - **Sets:** job frames warden_aldis-03/05/08 stacked (one set per preset); no-loss r04/r10/r16/a03 2×2 at High. The south_bridge_grunt frames are left out because they use a rotated camera between the sides at High, as the GPU lane flagged.
- **F41#13:** `G-closeout-f41-13-main` (eb8d96d47), main 317b3372f as it is, High and Medium, stormraven idle over fulgocobra idle.
- **Control:** F38#38's closing High and Medium crafting frames (`gpu-frames-1108/F38-38/live`).
- **Render check:** the arm's cyan band is fainter and lower in every job frame at both presets; nothing else changes.

## Batch `G-co`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.396, intercept −1.883, r 0.975, anchor RMSE 0.22.
- **Warning:** "meets the bar only above the top anchor (7.53): F38#38 High and Medium; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch". F38#28 Medium at 7.52 is below the top anchor.
- Yardstick: `yardstick_g_wardenring_f41_13/`.

**Raw Bar A (judges a, b, c):**

| Set | Side 1 | Side 2 |
|---|---|---|
| F38#28 High (base / arm) | 6.4, 6.4, 6.4 | 6.4, 6.4, 6.4 |
| F38#28 Medium (base / arm) | 6.4, 6.4, 6.4 | 6.8, 6.7, 6.7 |
| Warden other frames (base / arm) | 5.6, 5.4, 5.5 | 5.8, 5.6, 5.6 |
| F41#13 (High / Medium) | 6.5, 6.2, 6.2 | 6.5, 6.2, 6.2 |
| F38#38 (High / Medium) | 7.1, 7.0, 7.0 | 7.1, 7.0, 7.0 |

Bar B: no on every set except F38#38 (yes 3/3).
