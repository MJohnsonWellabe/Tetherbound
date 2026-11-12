# GPU arm round 1108, G-f41-2-building-glow: F41#2 Surge phases: `building_glow_1104` (live vs arm, GPU High, mapped)

**Verdict:**
- **Does not ship.** Gain 0.00; all three judges scored live and arm identically.
- The in-cloud sheet lightning does not show on GPU High either, so this lever is spent on GPU as well as CPU.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| live vs arm (`presentation.building_glow_1104` on) | 5.62 | 5.62 | 0.00 | 0/3 (3 level) | No |

- **Per judge, mapped (raw), identical on both sides:** 5.72 / 5.58 / 5.58 (5.3 / 5.2 / 5.2).

**What the judges saw:**
- **Both sides:** Calm, Building and Break are near-identical stills. They differ only in slight grade and rain-density shifts (PRESENT 3/3).
- The purple sky is built from blocky, faceted polygons with streak artefacts.
- **Next:** per-phase key light, fog density and lightning cadence (scene, 3/3). The other route is a Building-only world object, as in ITEM-F41-2's untested ideas.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f41-2-building-glow`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
