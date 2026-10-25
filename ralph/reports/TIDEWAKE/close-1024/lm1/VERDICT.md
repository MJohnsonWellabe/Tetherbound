# Tidewake close-1024 round lm1: MESHY 11-12 destination landmarks (P2-011), CPU pre-judge (25 Oct 2026, CT)

## What `destination_landmarks_candidate` places (OFF in play)

From tb/meshy-1024 7a5f3318a, presentation only, with no collider so no route can be blocked:
- `tidewake_sluice_twin_pumps`: 9 m, beside `sluice_twin_pumps`;
- `tidewake_shellwatch_rescue_jetty`: 10 m lookout tower, beside `shellwatch_rescue_jetty`.

## Probe stands

- **Not a catalog camera set:** a temporary set, 28 m back and 12 m up from each destination point, with the trainer at the point.
- **For the GPU lane:** this needs a committed camera set (below).

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 14411).
- **Calibration:** `calibrate.py` slope 1.08, r 0.91, anchor RMSE 0.58.

| Set | Shipping | Landmarks | Δ | Judges |
|---|---|---|---|---|
| Sluice twin pumps and Shellwatch rescue jetty, midday | 4.33 | **5.58** | +1.25 | higher x3 |

**Defect changes:**
- **"Named destination reads as an unmarked slope or generic structure":** PRESENT x3 → PARTIAL x3.

## What holds them back (all three)

1. **Small at distance:** both read at about 2-3 trainers tall.
2. **Away from the water:**
   - the pumps tie to no channel or sluice;
   - the jetty's deck runs onto dry dune. The `shellwatch_rescue_jetty` point is on a hilltop (16.7 m).
3. **Nobody there:** no boats or villagers, so "occupied rescue post" is not met.

## Next

1. Seat the jetty on the nearest shoreline and the pumps at a channel edge. This needs a shoreline probe.
2. Scale both up about 1.5x.

## GPU capture

A committed camera set for these two stands is needed. I'll add `P2-011-destinations.json` with the probe poses. Then capture shipping vs `--tidewake-look-sections=destination_landmarks_candidate`.
