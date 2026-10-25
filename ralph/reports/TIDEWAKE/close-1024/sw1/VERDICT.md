# Tidewake close-1024 round sw1: half-submerged swimmer (P2-071/P2-072), CPU pre-judge (25 Oct 2026, CT)

## What was tested (`swim_candidate`, OFF in play)

The GPU verdict named P2-071: the currents swimmer reads as upright.

- **Pose:** the chest bone drops from 0.10 m above the surface to 0.14 m below it, the body pitches from 68 to 76 deg, and the head lifts -32 deg.
- **Ring:** the P2-072 contact ring shrinks from 1.7 m to 1.2 m and its opacity drops from 0.5 to 0.32.
- **Arms:** A = `current_flow`, B = A plus `swim_candidate`.
- **Views:** T2-current swim-away day, swim-across day, swim-away night.
- **Tests:** human swim visual, contact visual and look profile pass (21 tests, 408 assertions).

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs.
- **Calibration:** slope 1.20, r 0.82, anchor RMSE 0.54.

| Set | Base | swim_candidate | Δ |
|---|---|---|---|
| Currents swim | 5.87 | 5.75 | -0.12, level |

**Defect calls:**
- **"Upright / riding a ring or tube":** split across judges.
  - Two judges call it PRESENT on base and PARTIAL on the candidate.
  - One judge calls the candidate more upright.
- **Road markings:** PARTIAL on both sides.
- **Direction unclear:** PARTIAL to PRESENT on both sides.

## Disposition

The candidate stays OFF; it is level.

Every judge names the white contact ring under the swimmer as what makes it read as a tube, whatever the pose. All three ask for the same next step:
- remove the ring;
- keep a low trailing wake;
- show the current as long, aligned flow bands in one direction (the night frame's lanes are the hint).

The scattered arc dashes read as decals.
