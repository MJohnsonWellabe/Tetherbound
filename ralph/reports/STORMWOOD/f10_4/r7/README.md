# F10#4 round 7: Deepwood closes at eye level (denser stands), re-judged at all three stands

**Why.** The r6 strict re-check returned NOT MET on the forest clause, with this finding:
- Off-road Deepwood read as EDGE OF WOOD even 60 m inside the 380 m deepwood_heart.
- That is a Phase 1 readability defect: see-through density.
- The fix is to repair it, then re-judge the off-road stands.

**Measured cause** (`tools/_probe_deepwood_sightlines.gd`). The probe uses the committed scatter pass, with each trunk as a circle of its collider radius × scale, and casts a 21-ray eye-level fan (±30°) per stand. Values are before → after (3d5fb0e6):

| Stand | Median first trunk (m) | Rays open past 120 m |
|---|---|---|
| heart_north (the r5 stand) | 56 → 26 | 3 → 1 of 21 |
| heart_west (the r6 stand) | 107 → 27 | 9 → 1 of 21 |
| forest_road (along the road) | 59 → 69 | 5 → 3 of 21 (the road itself stays open) |

**Change** (`data/config/stormwood_vegetation.json` `dense_stands`; re-baked `data/scatter/stormwood/`):
- deepwood_heart and deepwood_west: 17 m → 12 m spacing, skip 0.15 → 0.1.
- deepwood_hall: 17 m → 12 m spacing, skip 0.2 → 0.15.
- The new spacing stays above the 9 m tree occupancy cell.
- Bake: 38,789 → 43,161 placements kept, 108 regions.

**Regression checks on the new bake:**

| Check | Result | File |
|---|---|---|
| Stormwood, scatter and vegetation suites (clearances, route walkability, pockets, perf) | 505 tests, 0 failed | — |
| All five loops, walked from the earned 4_core save | 20 checks, 0 failures | `route_walks_loops_dense.txt` |
| dynamo_west_approach | 8 checks, 0 failures | `route_walks_dynamo_west_dense.txt` |
| Deepwood pocket walk (from 3_rootgate) | 22 checks, 0 failures | `pocket_walk_deepwood_dense.txt` |

**Code-blind forest judge** (`JUDGE_forest.md`; the three views shuffled and re-encoded, key in `forest_blind_key.json`). All three read **INSIDE DEEP FOREST**:

| Stand | Verdict | Notes |
|---|---|---|
| r5 heart north | Strongest | "every sightline at eye level ends on a trunk" |
| heart west | Weak pass | A lawn-like clear floor to the right |
| forest road | Borderline | The sky shows at the road's far end |

**Rod line (unchanged since r5).** The r5 judge answered YES, and it was confirmed by both strict re-checks.

**Restored sky (unchanged since r5).**
- Where sky shows (glass, rod_line and stormheart aftermath), it stays purple, with lighter rain, no lightning and structures still present. Both strict re-checks accepted this.
- Under the canopy, all three stands show the same place with rain nearly gone and no lightning, consistent with the owner's aftermath ruling. The judge notes it is brighter and greener than Calm. That comes from the existing aftermath values (`_why_f10_4_restored_sky`). The r6 re-check already routed it as a Phase 2 lighting note.

**Recorded for Phase 2 (Bars A/B catalog):**
- Canopy colour: plain green, not storm-tinted.
- No lightning visible under a closed canopy in Break frames.
- Aftermath brightness under the canopy.
- Glass-scar ground treatment (flag off).
- The Stormheart hero tree and the giant stand.
- The heart-west clearing floor.
- The cottage's red roof.
- The road-current look.

**Shortcuts disclosed.**
- Frames: one debug teleport per stand, hour pinned, surge clock pinned to phase start plus 2 s, aftermath set by flag, HUD hidden, llvmpipe software GL. They were rendered on 3d5fb0e6's bake.
- Walks: the seams listed in `../../f09_3_r8/README.md`.
