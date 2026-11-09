# GPU arm round 1108, G-f40-2-windows: F40#2 summit aviary: night window energy 0.8 -> 2.4 (live vs arm, GPU High, mapped)

**Verdict:**
- **Does not ship.** Gain +0.05, with 1 of 3 judges preferring the arm (2 level).
- Brighter windows do read on GPU High, but they move the score very little. The judges' problem with this landmark is its form, not its light.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| live vs arm (`window_night_energy` 2.4) | 6.75 | 6.80 | +0.05 | 1/3 (2 level) | No |

- **Per judge, mapped (raw):**
  - Live: 6.56 / 6.99 / 6.71 (5.9 / 6.2 / 6.0).
  - Arm: 6.56 / 7.13 / 6.71 (5.9 / 6.3 / 6.0).

**My own look at the night frame (the GPU lane asked for it by eye):** live and arm are almost the same at this distance. The windows are lit on both sides, and the arm's are at most slightly warmer. That agrees with the +0.05.

**What the judges saw:**
- **Both sides:** a solid blue-glass dome on a pale stone base, with lit windows at night, so the night silhouette now reads. The recorded defect is PARTIAL on both sides.
- **Still short (all three judges):**
  - It is a single small building on flat grass, not the board's layered stone sanctuary on stratified cliffs.
  - The night grade is a heavy cyan cast over the grass.
  - Two judges list a cliff-built sanctuary as new_art.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f40-2-windows`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
