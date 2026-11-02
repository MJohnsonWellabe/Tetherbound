# Tidewake beach scenes r3: full stack (r2b) vs main, CPU verdict

- **When:** 31 Oct 2026, evening CT.
- **Arms:**
  - Main: no new sections.
  - Full stack: `--tidewake-look-sections=beach_scene_candidate,beach_declutter_candidate,beach_groups_candidate`.
  - Both use the r2 capture (the r2b commit 8dfd1f4d2).
  - This is a direct comparison, so it checks the r1 + r2 chained estimate (+0.75).
- **Capture and judging:** the same capture and judging recipe as r1. Seed 3109, anchors craft and f36_0_npc:C1.
- **Fit:** linear, slope 1.353, intercept -1.946, r 0.970, anchor RMSE 0.27. Confirming batch.
- **Warning:** some candidates lie more than 0.5 outside the anchors' measured range. The low main-side scores are extrapolated.

| Island | Main | Full stack | Delta |
|---|---|---|---|
| gull_rest | 4.73 | 5.72 | **+0.99** |
| tidal_cradle | 4.55 | 5.54 | **+0.99** |
| lantern_cove | 5.18 | 6.04 | **+0.86** |
| salt_crown | 4.32 | 5.18 | **+0.86** |
| reedhaven | 5.36 | 6.17 | **+0.81** |
| sluice_isle | 5.09 | 5.90 | **+0.81** |
| first_shore | 5.27 | 6.04 | **+0.77** |
| deep_watch | 5.04 | 5.63 | **+0.59** |
| drowned_garden | 5.36 | 5.95 | **+0.59** |
| brine_steps | 5.63 | 5.95 | +0.32 |
| shellwatch | 5.68 | 5.59 | -0.09 |
| **Mean** | **5.11** | **5.79** | **+0.68** |

- **Read:** every judge's top change is "keep and add a hut, dock or tower cluster at every named location; never replace buildings with a grass carpet". The arm does this, and the judges preferred it on 9 of 11 islands.
- **Shellwatch is flat:** the dock pump station blocks the close view on both sides (a dock action station, not this lane's to move). The slimmed hamlet there trades cottages for huts with no net gain.
- **Remaining defects:**
  - Salt Crown: the shrine hut tilts on its slope (fixed in a later commit, not in this capture).
  - Tidal Cradle: a floating diamond sign at the dune edge, an existing prop.
  - Bare and flat-lit sand, untextured dark dune faces, no haze. These belong to the terrain and lighting owners.

## GPU request

The nine islands at +0.59 to +0.99 go to the GPU as arm **TW-look-2** (`tb/tidewake-2-on` 773118e1f). It supersedes TW-look-1.
