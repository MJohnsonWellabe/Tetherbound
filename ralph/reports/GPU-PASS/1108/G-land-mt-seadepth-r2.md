# G-land-mt-seadepth-r2: sea depth gradient without wind slicks and whitecaps (GPU High, base vs arm)

## Verdict: DO NOT SHIP. **F39#10 LOSES on this panel: 6.60 → 6.31 (−0.29, 0/3).** The current states are now level, 6.31 = 6.31 (1/3), so round 1's −0.85 loss is gone. F39#15 6.01 vs 5.81 (+0.20, 3/3). F39#1 level, −0.04.

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F39#15** (terraces route + walk_01, sluice route) | 5.81 | 6.01 | +0.20 | 3/3 | 6.0→6.2, 5.0→5.1, 4.9→5.1 | PRESENT / PRESENT 3/3 |
| **F39#10** (terraces route, first shore route) | 6.60 | **6.31** | **−0.29** | **0/3** | 6.4→6.1, 5.8→5.6, 5.6→5.4 | a,c PARTIAL→FIXED on base side; b PARTIAL/PARTIAL (base FIXED, arm PARTIAL for a, c) |
| F39#1 (brine walk_03, first shore route) | 6.26 | 6.22 | −0.04 | 0/3 (2 ties) | 6.1→6.0, 5.4→5.4, 5.5→5.5 | PARTIAL / PARTIAL 3/3 |
| F39#17/#16 states no-loss | 6.31 | 6.31 | 0.00 | 1/3 | 6.2→6.1, 5.6→5.4, 5.3→5.6 | streaks PARTIAL both; restored-only change a,b PRESENT, c PARTIAL |

- **Scores:** all mapped. Fit: r 0.928, slope 1.25, anchor RMSE 0.52; the batch is confirming.
- **What the arm is:** its route frames are effectively round 1's arm (pixel difference 0.15 to 0.32), against the same base.

## The two panels disagree on F39#10. I am stating it, not hiding it.
- **Round 1 (j19):** F39#10 went 6.48 → 7.10 (+0.62, 3/3), with the arm on side B.
- **Round 2 (j21):** the same frames go 6.60 → 6.31 (−0.29, 0/3), with the arm on side A.
- **What flips:** the judges' reading of the same pixels. Round 1 said base was "flat inky navy, a hard two-tone" and the arm "a mid-blue deep tone with a gradual falloff". Round 2 says base has "a clear navy deep band, a turquoise shelf and pale shallows (FIXED)" and the arm "mostly light cyan behind the terrace walls (PARTIAL)".
- **Position bias:** in both batches every water set leaned to whichever side was B. The change is too small for the panel to rank reliably.
- **My read:** the gradient is a wash for F39#10, and its +0.62 in round 1 is not robust. On this batch's evidence, the ship rule fails (one row loses 0/3).
- **F39#15:** gains on both panels, +0.43 and +0.20, with the arm on B both times. That is small and not position-independent either.

## What the judges see
- **States (3/3):** round 1's "radiating dark streak bands and confetti flecks" are gone. Both sides now show a few crescent flecks and one long white streak in frame 2, with concentric halos round the islets. One judge calls the arm's dark navy foreground "heavy and murky" with "a ruler-straight diagonal hard edge that reads as a shadow wedge"; another prefers its depth. Level.
- **What the judges want (3/3, both panels):** offshore water that is deep navy and also softly graded, following the seabed. Base is deep but hard-edged. The arm is soft-edged but reads as lighter cyan. Neither has both.

## Next asks (LANE-LAND-MT)
1. **Keep base's deep-navy offshore value and soften only the shallow-to-deep transition band** (a wider, noisier falloff that follows the seabed shape), rather than lifting the deep tone to mid-blue. That is what both panels reward. Then re-capture F39#10, F39#15 and states.
2. **F39#15's recorded defect is untouched on every panel (PRESENT 3/3).** Replace the straight chain of identical tan discs with irregular sandbars and reefs. This is what will move the row; water tone will not.
3. **States:** remove the concentric islet halos and the single long white streak in frame 2. Give the restored state a visible colour or sandbar change.
4. **No more tone-only rounds on this arm.** If the next round is again within the panel's position noise, PARK the sea-tone approach for F39#10.
