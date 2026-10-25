# Tidewake close-1024 round t2: T2 depth-graded water, CPU pre-judge (25 Oct 2026, CT): LOST, stays OFF

## What was tried

`surfaces_candidate` water, on top of the T1 currents (both would ship together):
- shallow #4fcfc4, mid #2a8fb0, deep #0f3058;
- mid depth 2.0 m, band break 1.0 m, falloff 14;
- foam_depth 0.55 → 0.35.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 2207).
- **Calibration:** `calibrate.py` slope 1.14, r 0.957, anchor RMSE 0.30.

| Set | t1 alone | t1 + t2 | Δ | Judges |
|---|---|---|---|---|
| Swim views (along day, across day, along night) | **6.41** | 6.02 | -0.39 | t1 alone higher x3 |
| First Shore, lesson dune, First Shore 18:00 | **6.52** | 6.25 | -0.27 | t1 alone higher x3 |

## Why it lost

- **Too dark offshore:** all three judges read the deep navy as "saturated royal blue, much darker than the board's cyan". The teal shipping deep reads closer to the board.
- **Night got worse:** the night sea is darker still.
- **Unchanged by t2, named by all three:**
  - a hard navy stripe at the horizon that reads as a painted seam;
  - no foam line or wet-sand edge at the shore;
  - the night sea has no moon glint or specular.

## Confirmation for t1

In this independent batch, t1's swim views map to 6.41 (t1 batch: 5.92). This confirms t1 clears 6.

## Next (t2b)

- Keep a teal deep, close to shipping, and lift the shallows toward turquoise.
- Find and soften the horizon stripe.
- Add a shoreline foam and wet edge.
- Add night specular.
