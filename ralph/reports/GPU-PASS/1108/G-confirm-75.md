# G-confirm-75: one-sided High re-judge of the three near-bar rows

Frames: `tb/gpu-frames-1108` manifest `G-confirm-75-ghostglow` (b1f6e317): live on main d9d79ff93, with ghost-glow shipped, at High preset.
Batch `F-confirm75-1`: one-sided sets (the same image on both sides; the score is the mean of the two sides), three code-blind judges and the standard prompt.
Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this counts as a **confirming batch**.

Fit: linear, slope 1.3722, intercept −2.1075, r 0.876, anchor RMSE 0.557 (6 points).

| Row | Item | Raw (j1, j2, j3) | Mapped judges | **Mapped High** | above_top_anchor | ≥7.5 High |
|---|---|---|---|---|---|---|
| F40#12 | Cloudreach dialogue speaker | 7.3, 7.4, 6.8 | 7.91, 8.05, 7.22 | **7.73** | yes (confirmed) | **yes → capture Medium** |
| F38#28 | Meadows Warden arena boundary | 6.9, 7.2, 7.0 | 7.36, 7.77, 7.50 | **7.54** | yes (confirmed) | **yes → capture Medium** |
| F41#17 | Stormwood Crown Arch | 7.0, 6.9, 6.3 | 7.50, 7.36, 6.54 | **7.13** | no | no (0.37 short) |

Warning (calibrate): F38#28 and F40#12 meet the bar only above the top anchor, but this batch's anchors reach 7.35, so it is the confirming batch.

Against earlier High scores (G-exposure live): F40#12 7.55 → 7.73, F38#28 7.50 → 7.54, F41#17 7.55 → 7.13.
F41#17 drops below the bar on this pool. One judge (6.3 raw) marked the recorded defect PARTIAL.

## Next
- **F40#12 and F38#28:** capture Medium on the same camera set. Each closes if Medium maps to 7.5 or above.
  F38#28 is a thin pass (7.54, spread 7.36–7.77), so a Medium near 7.4 would not close it.
- **F41#17:** not closable as is. The judges' remaining defects:
  - A hard-edged square plinth on the black pool.
  - Uniform lavender block stone with no copper or glass accents.
  - Oversized white rain streaks.
  - An NPC overlapping the trainer in front of the arch.

  Bedding the plinth into the terrain with broken edges, plus material accents, is the scene fix the judges name.
- **Note for F38#28:** one judge flagged red banners on the Warden arena wall as a possible Team Tether red-reserve conflict. Worth checking against ART_DIRECTION before Medium.
