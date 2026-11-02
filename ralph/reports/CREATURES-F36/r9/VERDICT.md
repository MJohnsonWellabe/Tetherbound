# CREATURES-F36 r9: height batch 2 via the scale flag (CPU, three judges)

**Verdict:** Pipwing and Sparkit are GPU READY as arm `tb/co-f36-8-on` 4c13f7560, built on CO-F36-7 (control: main a41e1b30). Paddlenewt, Riftfrill and Glimmermoth are left out.

| Species | Factor | Height | Mapped main | Mapped arm | Gain | "Barely taller than the trainer" (main / arm) |
|---|---|---|---|---|---|---|
| **Pipwing** | x1.6 | 1.90 -> 3.04 m | 5.67 | **6.78** | **+1.11** | PRESENT x3 / FIXED x3 |
| **Sparkit** | x1.6 | 1.95 -> 3.12 m | 5.62 | **6.39** | **+0.77** | PRESENT x3 / FIXED 1, PARTIAL 2 |
| Paddlenewt | x1.4 | 2.15 -> 3.01 m | 5.52 | 5.77 | +0.25 | PRESENT / PARTIAL |
| Glimmermoth | x1.3 | 3.10 -> 4.03 m | 6.15 | 6.30 | +0.15 | PARTIAL-FIXED / PARTIAL-FIXED |
| Riftfrill | x1.4 | 2.15 -> 3.01 m | 5.43 | 5.57 | +0.14 | PRESENT / PRESENT-PARTIAL |

**Fit:** linear, slope 1.45, intercept −2.70, r 0.95, RMSE 0.35. Confirming batch (craft, f36_0_npc:C1). No warnings.

**Why three missed:** Paddlenewt and Riftfrill are long and low. The judges look at the body line, not the crest, and at x1.4 the back still sits around the trainer's head; it would need about x1.8. Glimmermoth's height is in its wings; its faint poses (wings still up) are what the judges mark.

**Arm shape:**
- CO-F36-8 makes one tree for every flag arm in this lane:
  - CO-F36-2: Sirenseal pose flag.
  - CO-F36-3 and -8: scale flags.
  - CO-F36-4, -5 and -7: coat flags.
  - CO-F36-6: clip flag.
- Each flag is off by default. New flag here: `creatures_f36_taller_than_trainer_2` in `data/config/creature_scale_flags.json`.
- Landing note: like CO-F36-3, turning it on grows these two creatures' gameplay colliders. Pipwing and Sparkit are not rideable.

Sheet `_sheet_r9.jpg`: main on the left, arm on the right; rows are Pipwing and Sparkit.
