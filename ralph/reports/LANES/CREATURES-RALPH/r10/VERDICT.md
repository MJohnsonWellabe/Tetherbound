# CREATURES-RALPH r10: GPU main1102 regressions, Tuskroot, Ashtusk and Torrentoad (CPU, three blind judges)

The coordinator's GPU confirmation of #796, installed → shipped:
- Torrentoad 7.06 → 5.59;
- Tuskroot 7.17 → 6.31;
- Ashtusk 6.83 → 6.31.

The harness matches r1. Arm A is the shipped remake on main; arm B adds the fix. Anchors: craft, p2_094_r4 and f36_0_gap:C5 (seed 110210). Fit: slope 1.52, intercept −2.48, r 0.96, RMSE 0.39. There were no warnings.

| Creature | Change | Mapped shipped → fix | CPU target (old GPU − 0.8) | Verdict |
|---|---|---|---|---|
| **Tuskroot** | Mid-brown coat, tan muzzle and belly, mossy grey-green stone plates with value jitter (`creatures_ralph_tuskroot_brown`) | 5.55 → **7.42** | ≥ 6.37 | **KEEP**, ON; dark-mass defect FIXED ×3 |
| **Ashtusk** | Its live aspect repaint lifted about 1.45× with sharper detail (`creatures_ralph_ashtusk_lift`) | 5.71 → **7.07** | ≥ 6.03 | **KEEP**, ON |
| Torrentoad | Teal-blue toad coat at the installed value, speckled back, pale belly; weights relaxed | 4.64 → 5.55 (+0.91) | ≥ 6.26 | not yet; flag OFF, attempt 2 next |

## What the judges still see

- **Tuskroot:** the hide reads slightly pink and rubbery, and there is no rim light.
- **Ashtusk:** the eye is small, and the ember lines show mostly in the faint frames.
- **Torrentoad:** the silhouette is still the gaunt upright biped (new art), and the lighter coat reads as glossy "wet plastic".
  - The faint-end "dorsal spikes" are its feet in the air. They come from the faint pose, so the weight relax cannot remove them.
  - Attempt 2 is a matte finish.
  - If that fails too, the coordinator generates a new Meshy blue-toad model.
