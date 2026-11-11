# G-remakes-floor1: Ribbonray navy coat and Voltarach charcoal coat (F36#61, F36#86; GPU High)

**Frames:** `tb/gpu-frames-1108` 9c6d71c8, High. Capture: `capture_f36_poses.gd --whole-body --context`.
- **base:** `tb/remakes` ac738b144 with flags OFF, which is the main build.
- **Ribbonray arm:** base plus `REMAKES-RIBBONRAY/overlay.json`, a navy floor1 coat plus the `remakes_floor_ribbonray_hit` clip blend.
- **Voltarach arm:** base plus `REMAKES-VOLTARACH/overlay.json`, a charcoal floor1 coat plus glow.

**Sets:**
- The same crop as the pose re-scores: 560,200 1000×640 at 1080p.
- Tiles: standing (hit 000), hit 050, faint 050 and faint 100.
- Brief: the F36 (1) brief, with the 24 Oct roster causes as recorded defects.

**Render check:**
- Pixels changed per sheet: 2.6% each. The creature fills a small part of the crop.
- Blank frames: 0 of 10 per side.

**Batch `G-rm`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.3123, intercept −1.2837, r 0.901, RMSE 0.431. No warnings.

## Verdict: BOTH SHIP (3/3, no loss)

| Row | Base (main) | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) |
|---|---|---|---|---|---|
| **F36#61 Ribbonray** | 5.02 | **6.90** | **+1.88** | 3/3 | 5.1, 4.8, 4.5 → 6.4, 6.3, 6.0 |
| **F36#86 Voltarach** | 5.15 | **6.50** | **+1.35** | 3/3 | 4.9, 4.9, 4.9 → 5.9, 6.0, 5.9 |

- **Both rows return to the 6–7 band.** The base scores match the morning re-score (ribbonray 5.68, voltarach 5.11), allowing for batch scale.

**Recorded defects:**

| Row | Defect | Base | Arm |
|---|---|---|---|
| Ribbonray | magenta effect | PRESENT 3/3 | FIXED 3/3 |
| Ribbonray | airborne hit | PARTIAL 3/3 | FIXED 3/3 |
| Voltarach | chrome-gold statue | PRESENT 3/3 | PARTIAL 3/3 |
| Voltarach | face lost | PRESENT 3/3 | PRESENT / PARTIAL / PARTIAL |

- **Ribbonray's detached tail tip** in the base hit frame (judges a and c) is gone on the arm. The arm hit is "a grounded flinch with the tail attached".

## What still holds them back (named on the arm side)
**Ribbonray:**
- An "upright, bipedal" stance that is "odd anatomy for a ray" (3/3, new_art).
- A tiny eye.
- Judge c: the faint frames twist, and the fin juts up at faint end.

**Voltarach:**
- **Face (3/3):** still "one blue eye spot, no head mass".
- **Hit pose (3/3):** the hit reaction "is almost the same as standing", and faint mid barely sags.
- **Gold sheen (3/3):** some remains on the leg tips and front plates.
- Asks: a readable head with an eye glow, and a distinct grounded flinch.

**Owner rules:** no red or oxblood on either creature arm. Both are taller or wider than the trainer.

## Recommendation
1. **Land both overlays.**
2. **Next swings:**
   - Voltarach: a head/eye read and a hit clip (scene/pose).
   - Ribbonray: a natural ray anatomy (Meshy).
