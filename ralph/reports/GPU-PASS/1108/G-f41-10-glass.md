# GPU arm round 1108, G-f41-10-glass: F41#10 Glass Sink: shards plus fused glass (tb/item-f41-10 files) (live vs arm, GPU High, mapped)

**Verdict:**
- **Does not ship.** Gain +0.04: 1 of 3 judges prefers the arm, 1 prefers live, 1 is level.
- This repeats the CPU result (+0.04). GPU High does not make the glass read.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| live vs arm (`meshy_rim.shards` and `fused_glass` on) | 5.72 | 5.76 | +0.04 | 1/3 (1 level, 1 prefers live) | No |

- **Per judge, mapped (raw):**
  - Live: 5.43 / 6.00 / 5.72 (5.1 / 5.5 / 5.3).
  - Arm: 5.15 / 6.00 / 6.14 (4.9 / 5.5 / 5.6).

**What the judges saw:**
- **Both sides:**
  - A raised stone ring with copper bands holding blue crystals, perched on a cliff edge. It reads as a crown or planter, not a sunken basin.
  - Below it, a flat dark plane with little reflection or glass read.
- **Arm side:** all three judges saw crystal clusters floating over the water off the cliff in frames 1 and 3. Those are the far-floor shards, and with no visible floor under them they read as floating props.
- **Next:** a sunken reflective glass basin (new_art, 3/3). The shards should not return unless the floor under them reads.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f41-10-glass`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
