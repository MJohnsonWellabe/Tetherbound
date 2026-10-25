# Tidewake close-1024 round b5: destinations s4, CPU pre-judge (25 Oct 2026, CT)

## What changed (`destination_landmarks_s4_candidate`, OFF in play, layered on s3)

s4 entries replace s3 entries by `landmark_id`; a later layer wins. The new test `tests/test_water_landmark_destinations.gd` covers this (2 tests, 6 assertions).

- **Pumps:** 5 m further seaward, to (993.0, 2712.3), so the wheels stand in the surf. Still 19 m.
- **Shellwatch jetty:** grows from 19 m to 25 m, the top of the coordinator's 1.5–2x range over 13 m.
- **Rescue-post group:** built from the installed Tidewake family:
  - keeper hut, 7 m
  - signal lantern post
  - buoy and pot stack
  - net drying rack
  - beached rowboat
- **Arms:** A = `destination_landmarks_candidate,destination_landmarks_s3_candidate` (s3, judged in b2). B = A plus `destination_landmarks_s4_candidate`.
- **Stands:** `pumps-shore` and `jetty` (P2-011-destinations.json).

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 24733).
- **Calibration:** slope 1.30, r 0.93, anchor RMSE 0.51.

| Set | s3 | s4 | Δ | Judges |
|---|---|---|---|---|
| Pumps and Shellwatch | 6.36 | **6.84** | +0.48 | higher x3 |

**Defect changes:**
- **Structures read small:** PRESENT x3 → PARTIAL x3.
- **Unmarked or generic:** PRESENT x1, PARTIAL x2 → PARTIAL x3.
- **Away from its water:** PARTIAL on both sides. The pumps base still reads as on dry sand, with only the wheel at the waterline.

## Disposition

s4 is above the 6.7 CPU-provisional floor in this batch. Across rounds the destinations went from lm2 4.60 → s3 6.07 (b2), and from s3 6.36 → s4 6.84 here. The two batches are separate scales.

**READY for the GPU, CPU-provisional.** A GPU pass is owed before 7.5 is claimed.

## Remaining (all three)

1. **Pumps:** read as a mill or twin towers. They need a sluice gate or channel with pipes in the water (new art).
2. **Shellwatch:** still small at its stand's distance. Judges ask for a long walkway into the water, lifebuoys and flags.
3. **Dune foreground:** empty and uniform, with evenly scattered grass.
4. **Shoreline:** a flat white band blows out at the right edge.
