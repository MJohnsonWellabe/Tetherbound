# CREATURES-RALPH r12: the coordinator's r9 Meshy models against the shipped owner1101 remakes (CPU, three blind judges)

The coordinator generated and rigged the r9 models on the GPU machine (dog3 for Aquaryn and Mangrove Monitor, rig_bird for Duskhush) and merged them from `tb/meshy-r9`. Before judging, this lane made these fixes:

- **Aquaryn and Mangrove Monitor** (dog3):
  - hit: neck ×0.45, head ×0.6, tail_1 ×0.4;
  - faint: root roll ×0.6 and legs ×0.6, no longer belly-up;
  - weights relaxed over the hit, faint, attack, charged, walk and run clips (Aquaryn worst stretch 0.51 m → 0.20 m).
- **Mangrove Monitor only:** the hit root hop is scaled to 30% of its height, because the r9 hit lifted the body 1.19 m.
- **Duskhush:** wing bones ×0.5 in attack and fly_grip (wing smear 1.19 m → 0.67 m), plus a weight relax.

The harness matches r1. Anchors were craft, f36_0_npc:C3 and f36_0_gap:C6 (seed 110212). Fit: slope 1.41, intercept −2.66, r 0.86, RMSE 0.58. There were no warnings.

| Creature | Mapped shipped → r9 | Target (coordinator) | Verdict |
|---|---|---|---|
| **Duskhush** | 4.61 → **6.30** | ≥ 6.3 | **KEEP.** The flag points at r9. The "one mid-tone / no eyes" and "flat lump" defects are PARTIAL ×3. |
| Aquaryn | 4.28 → 6.11 (+1.83) | ≥ 6.5 | Not yet. The flag stays on owner1101; attempt 2 next. |
| Mangrove Monitor | 4.84 → 4.98 | ≥ 5.4 | Not yet. The flag stays on owner1101; attempt 2 next. |

## What the judges see on r9

- **Aquaryn:** a bright, large, readable cyan drake. But **every faint stays standing** (×3), and the hit barely changes. The ×0.6 roll was too little for this long body.
- **Duskhush:** a pale lavender owl that reads at once. The eyes still don't read at stage scale, and the faint end is a heap with a wing up.
- **Mangrove Monitor:**
  - a smooth, glossy, rubbery green body with pale flank lines that "read as UV seams";
  - the faint flips with its legs up;
  - the tail passes through the trainer, the same staging problem as the shipped remake;
  - the shipped remake's dorsal spikes read reddish, a possible red leak, while r9's do not.

## GPU

Duskhush r9 is listed in `QUEUE.md` for the coordinator's GPU check before landing.
