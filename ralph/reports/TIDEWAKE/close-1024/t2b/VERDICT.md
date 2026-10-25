# Tidewake close-1024 round t2b: softer depth-graded water, CPU pre-judge (25 Oct 2026, CT): LOST, the colour route is parked

## What was tried

`surfaces_candidate` water, on top of the t1b currents:
- shallow #6ccabb, mid #2a93a6 at 6 m, deep #1b5a6c;
- band break 1.5 m;
- falloff 5 → 30 m;
- foam_depth 0.5;
- fresnel 0.45.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 3319).
- **Calibration:** `calibrate.py` slope 1.14, r 0.876, anchor RMSE 0.45.

| Set | t1b alone | t1b + t2b | Δ | Judges |
|---|---|---|---|---|
| Swim views | **6.16** | 5.40 | -0.76 | t1b alone higher x3 |
| Shore views | **6.58** | 6.46 | -0.12 | level x2, t1b higher x1 |

## Why it lost (all three judges)

- **Swim views:** the 30 m falloff keeps the whole lane-side sea in the "shallow" colour. It reads as a milky, knee-deep pool with no depth.
- **See-through artefacts:** the lighter, more see-through colour shows submerged geometry, a "ghost" of the buoy poles and logs on the seabed.
- **Shore:** the hard navy step at the drop-off is unchanged in the shore views.

## Decision

- **Two consecutive losses** on the water-colour route (t2, then t2b). Per the two-attempts rule the route is parked. `surfaces_candidate` stays OFF.

## What the judges name instead, repeated across t1, t2 and t2b

1. The current lane is a lighter flat band with straight edges, a "geometry slab". This is the t1 `lane_opacity` band and channel tint.
2. White foam strokes on open water away from any shore.
3. No foam line or wet-sand edge where the sand meets the water.
4. The night sea is a flat navy wash.

The next rounds target these on the currents and shore, not the water colour.
