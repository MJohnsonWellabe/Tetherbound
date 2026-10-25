# Tidewake close-1024 round lm2: destination landmarks re-seated (s2), CPU pre-judge (26 Oct 2026, CT)

## What changed from lm1 (`destination_landmarks_candidate`, OFF in play)

- **Rescue jetty:** moved to the nearest shoreline, 64 m from the `shellwatch_rescue_jetty` point (shore probe at (230.3, 953.9), facing the sea), at 13 m.
- **Twin pumps:** stay at `sluice_twin_pumps`, because no water lies within 179 m. Grown 9 → 13 m.
- **Camera:** the `P2-011-destinations.json` jetty stand was reframed to show the shore. The old pose is in its `_why`.
- **Both arms re-captured on that stand.**

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 16633).
- **Calibration:** `calibrate.py` slope 1.20, r 0.92, anchor RMSE 0.54.

| Set | Shipping | Landmarks s2 | Δ | Judges |
|---|---|---|---|---|
| Sluice pumps and Shellwatch jetty, midday | 5.36 | **6.81** | +1.45 | higher x3 |

**Defect changes:**
- **"Unmarked slope or generic structure":** PRESENT x3 → PARTIAL x3.

## Remaining (all three)

1. **Jetty:** reads small and "derrick-like, industrial" from this distance. It needs boats, a flag and villagers to read as a rescue post.
2. **Pumps:** a "current-control station" still sits on a dry dune with no water channel.
