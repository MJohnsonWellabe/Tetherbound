# Tidewake close-1024 round b2: swimmer sw2 and destinations s3, CPU pre-judge (25 Oct 2026, CT)

Two candidate sets were judged in one batch. Everything stays OFF in play; READY means queued for the GPU.

## sw2: swimmer without the ring (`swim_candidate`, P2-071/P2-072)

- **Pose (same as sw1):** chest 0.14 m below the surface, body pitch 76 deg, head -32 deg.
- **Ring:** the contact ring fades to opacity 0.12 at 1.0 m, with 4 trail rings kept as a low wake. sw1's judges blamed the white ring, not the pose.
- **Arms:** A = `current_flow`, B = A plus `swim_candidate`, on the T2-current views (swim-away day, swim-across day, swim-away night).

## s3: destinations at the shore (`destination_landmarks_s3_candidate`, P2-011)

- **What it does:** layered on `destination_landmarks_candidate`. Its entries replace lm2's pumps and jetty by `landmark_id` (`water_landmark_models.gd` `_destinations`).
- **Pumps:** no water lies within 180 m of the `sluice_twin_pumps` point in any direction (heightfield probe). They move to the nearest shore at (990.1, 2717.4), face the sea and grow to 19 m. The destination point itself is unchanged; this is presentation only.
- **Jetty:** grows to 19 m. The Meshy 1024 moored sloop now floats beside it (new `float_y_m` key).
- **Camera:** new `pumps-shore` stand in P2-011-destinations.json. The original `pumps` stand is kept for matched lm1/lm2 rounds.
- **Arms:** A = `destination_landmarks_candidate`, B = A plus s3.

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 21377).
- **Calibration:** slope 1.30, r 0.98, anchor RMSE 0.32.

| Set | A | B | Δ | Judges |
|---|---|---|---|---|
| Currents swim | 5.25 | **6.03** | +0.78 | higher x3 |
| Pumps (shore stand) and jetty | 4.60 | **6.07** | +1.47 | higher x3 |

**Defect changes:**

- **Swimmer reads upright or on a ring:** PRESENT x3 → PARTIAL x3.
- **Current direction unclear:**
  - PRESENT x2, PARTIAL x1 → PARTIAL x2, PRESENT x1.
- **Road markings:** PARTIAL on both sides.
- **Unmarked slope or generic structure:** PRESENT x3 → PARTIAL x3.
- **Structure stands away from its water:**
  - PRESENT x2, PARTIAL x1 → FIXED x1, PARTIAL x2.
  - The PARTIAL calls say the pumps sit mostly on dry sand with only the wheel in the surf.
- **Structures read small:** PRESENT x3 → PARTIAL x3. Shellwatch is still small from its stand.

## Remaining (all three)

1. **Currents:** still read as evenly spaced white crescent strokes in mixed orientations. Every judge asks for long, aligned flow bands in one direction.
2. **Swimmer:** still head-up and small; at night it nearly disappears.
3. **Shellwatch:** reads as a small derrick, not a rescue jetty. It needs ring buoys, a hut, and to be bigger or closer to its stand.
4. **Pumps:** should stand in the water (on piers, with an intake channel).
5. **Sand foreground:** a flat, evenly rippled carpet with evenly scattered grass tufts.

## Oxblood note

One judge flagged a reddish creature on the beach in the swim frame. It is the Sluice wild spawn already raised as a QUESTION in NOTES.
