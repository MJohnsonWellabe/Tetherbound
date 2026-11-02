# Tidewake beach scenes r2 (hamlet) vs r1 arm s2: CPU verdict

- **When:** 31 Oct 2026, evening CT.
- **Arms:**
  - Side 1: s2, `beach_scene_candidate,beach_declutter_candidate`.
  - Side 2: hamlet, the same plus `beach_groups_candidate`.
- **What the hamlet adds:** a smaller second beach hut and a market stall (or a hut) beside each focal piece. The canoe racks are dropped: the ones that were the focal piece at Sluice bridge and Lantern Cove arch become huts, and the one at Deep Watch beach goes.
- **Capture and judging:** the same capture and judging recipe as r1. Seed 3108, anchors craft and f36_0_npc:C1.
- **Fit:** linear, slope 1.511, intercept -2.575, r 0.918, anchor RMSE 0.37. Confirming batch, no warnings.

| Island | s2 | Hamlet | Delta |
|---|---|---|---|
| sluice_isle | 5.08 | 5.73 | **+0.65** |
| lantern_cove | 5.84 | 6.29 | +0.45 |
| first_shore | 4.83 | 5.23 | +0.40 |
| shellwatch | 5.18 | 5.53 | +0.35 |
| tidal_cradle | 5.08 | 5.43 | +0.35 |
| reedhaven | 5.78 | 6.09 | +0.31 |
| salt_crown | 4.43 | 4.73 | +0.30 |
| deep_watch | 4.58 | 4.78 | +0.20 |
| gull_rest | 5.03 | 5.23 | +0.20 |
| brine_steps | 5.73 | 5.89 | +0.16 |
| drowned_garden | 5.78 | 5.68 | -0.10 |
| **Mean** | | | **+0.30** |

- **Read:** the hamlet is up on 10 of 11 islands but under the +0.5 per-round gain on 10. This is their first sub-0.5 round. Sluice gains +0.65.
- **Judge calls:** "clutter" is now PARTIAL nearly everywhere; the judges say the problem has flipped from clutter to emptiness. Every judge's top changes are:
  1. sand value and texture variation, and the untextured dark dune faces;
  2. grass grouped into dune edges and groves;
  3. atmosphere and haze.

  (1) and (3) belong to the terrain and lighting owners, not this lane.
- **Other defects:**
  - The Salt Crown shrine hut tilts on its slope.
  - The Drowned Garden beach lost its second hut in this layout. The judges preferred two huts there.
