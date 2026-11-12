# GPU arm round 1108, G-f41-13-charged: F41#13 electric creature finish: `charged_1105` (live vs arm, GPU High, mapped)

**Verdict:**
- **Ships.** Both arms gain +0.61, and 3 of 3 judges prefer the arm on each. The arm is the comparison the coordinator said counts, because ghost-glow ships.
- It does not reach 7.5: 6.14 with the arm.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| live vs arm (`charged_1105` on) | 5.53 | **6.14** | **+0.61** | **3/3** | **Ships** |
| live vs armGlow (charged plus ghost-glow settings) | 5.53 | **6.14** | **+0.61** | **3/3** | **Ships** |

- **Per judge, mapped (raw):**
  - Live: 5.29 / 5.86 / 5.43 (5.0 / 5.4 / 5.1).
  - Arm and armGlow: 6.14 / 6.14 / 6.14 (5.6 / 5.6 / 5.6) each.

**Arm vs armGlow:**
- The two arms' frames differ in bytes, but all three judges said the two sets showed the same frames, and they scored them identically.
- At this distance, the ghost-glow settings (glow threshold 1.6) do not visibly change how the charge accent reads. So shipping ghost-glow does not undo this arm.
- There was no ghost-glow-only F41#13 capture, so live here is plain main.

**What the judges saw:**
- **Arm side:** the Stormraven's charge reads as a bright white-blue glow, and the gold bands on the Fulgocobra catch light. The defect is reduced (PARTIAL 3/3, against PRESENT 3/3 on live).
- **Live side:** both creatures are dark navy, and the charge cannot be seen against the dark moss.
- **Still short:**
  - The glow is a soft wash over the whole body, not lines or veins on the animal. On the raven it blurs the feather outline and face.
  - Both creatures stand at or below the trainer's height, which breaks the scale rule. All three judges said so.
  - Rain streaks are the brightest thing in frame.
  - The sky is a flat lavender.
  - Two judges list a remake of both creatures to the owner style bar (taller, with clear charged veins and a rim light) as new_art.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f41-13-charged`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
