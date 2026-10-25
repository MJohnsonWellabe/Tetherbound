# Tidewake close-1024 round nv1: Veilfall crown on the reframed 750 m vista stand, CPU pre-judge (25 Oct 2026, CT): LOST, READY withdrawn

## Stand

- **New stand:** `veilfall-vista` and `veilfall-vista-rain` were reframed to about 750 m offshore, so the whole landmark is in frame.
  - The coordinator approved it. The old pose is in each view's `_why`.
- **Fresh captures:** both arms were re-captured on the new stand.
  - shipping;
  - `current_flow,veilfall_falls_candidate,rain_fog_candidate,veilfall_mountain_candidate`.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 15523).
- **Calibration:** `calibrate.py` slope 1.17, r 0.86, anchor RMSE 0.48.

| Arm | Mapped | Judges |
|---|---|---|
| **Shipping** | **4.75** | 4.8, 4.7, 4.5 |
| Crown + cap (+ t1e, falls f2, rain fog) | 4.51 | 4.3, 4.3, 4.8 (lower x2) |

## Why it lost now when mt1 won

- **mt1 was a cropping artefact:** the 200 m stand cropped the summit, so mt1 (3.52 → 4.64) scored the lower island.
- **With the whole island in frame:**
  - The crown is a small cluster on top of a big smooth cone, which judges read as "a placeholder primitive".
  - Its falls shrink to "a tiny white slab".
  - Shipping keeps the broad main fall over the block heap, which reads as "dramatic".
- **Defects that did improve:** the road markings went PRESENT → PARTIAL (t1e), and the rain fog went PRESENT → PARTIAL.

## Decision

- **Withdrawn:** the `veilfall_mountain_candidate` READY line of 22:40 is withdrawn. The candidate stays OFF.
- **What would work, named by all three:** the terraced cliff tiers and several stepped falls must cover the whole mountain, not just a summit crown.
- **What that means:**
  - With walkable heights up to 197 m, the crown can only replace terrain above about 210 m.
  - So the fix is either a crown-family treatment of the lower slopes (terraced relief, cliff bands, falls down the face), or keeping the broad main fall running down the capped face.
- **Separate items still stand:** t1e (currents) and `rain_fog_candidate` still lift this view and stay READY.
