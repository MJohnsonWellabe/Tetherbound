# CREATURES-RALPH r8 and r9: Meadowhart remake (CPU, three blind judges per round)

The Meadowhart remake is live. GPU batch 5 scored it 6.91 against the installed model's 7.67.

The batch-5 judges' notes (×3):
- "pale, thin vine-wrapped deer loses value contrast";
- "mottled root-veined hide muddies the read";
- the hit react "hunch reads as a broken stoop".

The CPU target is ≥ 6.9 (7.67 − 0.8). The harness matches r1. Each round compares the shipped remake with a fixed one on the same tree.

| Round | Change | Mapped shipped → fix | Fit |
|---|---|---|---|
| **r8** | Hit clip neck ×0.45 and head ×0.6 (in the GLB). Warm red-brown coat with a darker saddle, cream belly and throat, and the source kept at 30% so the vines read as soft markings (`remake_grades.json meadowhart`, coat flag `creatures_ralph_meadowhart_warm`). | 6.12 → **6.80** (+0.68). The stoop is FIXED ×3; the contrast and mottling are PARTIAL ×3. | slope 1.37, r 0.95, RMSE 0.33 |
| r9 | Attempt 2 on top: a cooler, deeper coat with the vines at 15%. | 6.23 → 6.28 (+0.05) | slope 1.52, r 0.98, RMSE 0.26 |

## Status

- **Shipped:** the hit-react clip fix is in the remake GLB, so it is live. It was part of the +0.68 arm.
- **Not shipped:** the attempt-1 coat (the r8 values, regenerated) is committed behind `creatures_ralph_meadowhart_warm`, **OFF**.
  - It gains +0.68 over the live remake but misses the 6.9 target by 0.10, so the coordinator decides.
  - Recommendation: ship it ON, because it is strictly better than the live remake.
- **What the judges still see:**
  - The body is thin, and only the antlers clear the trainer's height.
  - There is no clear glowing trait.
  - The faint frames read as a "bundled log".
  - Next levers: scale (gameplay checks: the ride seats), a vine-line glow, and the faint pose (Blender).

Sheet `_sheet_r8.jpg`, top to bottom: the shipped remake, attempt 1, attempt 2.
