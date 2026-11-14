# G-land-mt-flowstreaks: crescent caps off, soft flow-aligned streaks, F13#5 (+F39#16/#17 no-loss) (GPU High, base vs arm)

## Verdict: DO NOT SHIP. The current-states no-loss set LOSES (−0.42, 0/3), even though F13#5 gains +0.52 (3/3).

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defects (base → arm) |
|---|---|---|---|---|---|---|
| **F13#5** (four T2 swim views) | 5.52 | 6.04 | +0.52 | 3/3 | 5.3→5.8, 4.8→5.4, 4.8→5.2 | crescent decals PRESENT → PARTIAL 3/3 |
| **F39#16/#17 no-loss** (S1 live, S1 restored, S2 live) | 6.08 | **5.66** | **−0.42** | **0/3** | 5.9→5.4, 5.3→5.0, 5.3→4.9 | guide-lane streaks PARTIAL → **PRESENT** 3/3; restored-unchanged PARTIAL on both |

- **Scoring:** all scores are mapped.
- **Fit:** linear, slope 1.042, intercept 0.345, r 0.875, anchor RMSE 0.67. This is the noisiest fit tonight, so treat the absolute values as ±0.7. The direction of both results is unanimous (3/3 each way), so the verdict stands.
- **Comparison with LANE-PLACES:** the F13#5 base reads 5.52 here, against 5.38 on main in G-rescore-1113-f13-5.

## Why it fails
The streaks that help the swim views bring back F39#16's own defect on the current states. In S1 live and S2 live, the arm's streaks read as "long, thin, bright, near-parallel white streaks … exactly like painted guide lanes" (3/3). Base's scattered crescents there read as confetti or stamps but not lanes, so that defect was PARTIAL on base. A judged row loses, so the ship rule fails.

## What the judges see
- **F13#5 (3/3):**
  - The arm removes the mixed-direction crescents. A flow direction now "roughly reads".
  - The streaks are still a flat overlay: "thin, hard-edged lines", with no wake, bow-wave or ripple at the swimmer.
  - Swim-brine-day: one wide bright streak crosses the swimmer "like a light shaft / laser lane". The GPU lane flagged this too.
  - The night view is a flat saturated royal blue.
- **Current states (3/3, both sides):**
  - A hard, straight-edged navy shadow band crosses the lagoon diagonally from the left dune.
  - The restored-state shoal rings are hard concentric bands (PARTIAL).
  - A floating rock clump sits mid-water in arm frame 1 (judge c); this is spawn noise per the GPU lane.

## Next asks (LANE-LAND-MT)
1. **Keep the swim-view streaks, but gate them so the current-states live streaks are not turned into long parallel lanes.** For example, scope the streak change to the swimmer-relative cue, or break the live streaks into varied length and spacing. Then re-capture both sections. That route keeps the +0.52 and removes the loss.
2. **Anchor the cue to the swimmer:** a soft wake and bow-wave bent by the current, instead of free-floating lines (3/3 top ask for F13#5).
3. **Swim-brine-day:** remove the single wide bright band.
4. **Shared Tidewake water asks** (also in G-rescore-f39-17-f39-5-c673): fix the hard diagonal navy band and feather the shoal rings.
