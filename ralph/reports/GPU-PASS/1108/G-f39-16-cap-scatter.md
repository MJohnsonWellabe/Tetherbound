# GPU arm round 1108, G-f39-16-cap-scatter: F39#16 and F39#17 currents: `cap_scatter` 1.0 and `chop_cap_density` 0.22 (live vs arm, GPU High, mapped)

**Verdict:**
- **Does not ship.** Gain 0.00 on both rows; all three judges scored live and arm identically.
- The cap scatter is not visible at these camera distances on GPU High.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| F39#16 live current streaks (3 frames) | 6.52 | 6.52 | 0.00 | 0/3 (3 level) | No |
| F39#17 current restoration (2 frames, S1_t0 and S2_t0) | 6.47 | 6.47 | 0.00 | 0/3 (3 level) | No |

- **Per judge, mapped (raw), identical on both sides:**
  - F39#16: 6.42 / 6.99 / 6.14 (5.8 / 6.2 / 5.6).
  - F39#17: 6.28 / 6.71 / 6.42 (5.7 / 6.0 / 5.8).

**What the judges saw:**
- **F39#16:** the guide lanes are FIXED 3/3, but the current now barely reads, with only sparse white flecks.
- **F39#17:** no visible restoration change in sandbars, water colour or geometry (PRESENT 3/3). The sandbars are uniform, evenly spaced oval discs that look generated.
- **Floating props on open water:** a shrub, a rock and a brown clump (2 judges).
- **Next:** the current needs a larger visible element (foam bands, wake lines or a surface-colour shift along the flow), not finer cap detail. F39#17 needs the restored-state scene change from ITEM-F39-17's READY.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f39-16-cap-scatter`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
