# CREATURES-RALPH r13: Aquaryn and Mangrove Monitor on r9, attempt 2 (CPU, three blind judges)

Attempt 2 builds on r12's rig fixes. The faint root roll goes from ×0.6 to about 77°. On every faint key where the mesh dipped below the floor, the root is lifted by exactly that much, so the faint lies down and rests on the ground (the lowest point is 0.01 m at every phase). Arm A is the shipped owner1101 remake, reusing the r12 frames. Anchors were craft, f36_0_npc:C8 and f04_6_r22 (seed 110213). Fit: slope 1.34, intercept −1.91, r 0.85, RMSE 0.42. There were no warnings.

| Creature | Mapped shipped → r9 | Target | Verdict |
|---|---|---|---|
| **Aquaryn** | 4.44 → **6.54** | ≥ 6.5 | **KEEP**; flag → r9. Faints FIXED ×2, PARTIAL ×1. Dark coil FIXED ×3. |
| **Mangrove Monitor** | 5.02 → **5.69** | ≥ 5.4 | **KEEP**; flag → r9. |

## What the judges still see

- **Aquaryn:** a uniform, saturated, glossy cyan that reads slightly toy-like, with little value variation. The head only just clears the trainer.
- **Mangrove Monitor:**
  - It has no clear glowing elemental trait.
  - The tail crosses the trainer in every frame, in both arms. This is staging: the stage places the trainer beside the resting bounds, and the raised tail curls over that spot.
  - All three judges flagged the dorsal stripe as close to faction red. I measured it: the bark plates sit at hue 15–30, a red-brown, and only 0.03% of texels fall below hue 15. If the GPU judges call it red, shift it.

## GPU

All three r9 models are in `QUEUE.md` and need the GPU check before landing.
