# Tidewake close-1024 round t4c: surf vary and grouped stones, each against t1e + surf, CPU pre-judge (25 Oct 2026, CT)

## Arms (all OFF in play)

- **vary:** `shore_surf_vary_candidate` (new optional `surf_vary` 0.9 in `water.gdshader`). A broad world-space noise scales the surf band's reach 0.25-1.6x along the shore.
- **stones:** the existing `stones_candidate`. Pebbles are grouped into patches with a tide band.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 7741).
- **Calibration:** `calibrate.py` slope 1.36, r 0.92, anchor RMSE 0.38.

| Set | t1e + surf | Arm | Δ | Judges |
|---|---|---|---|---|
| Shore, 3 views | 6.63 | **vary 6.86** | +0.23 | higher x3 (+0.1 to +0.2) |
| Deep Watch, 2 views | 6.04 | **vary 6.18** | +0.14 | higher x3 (+0.1) |
| Shore, 3 views | 6.63 | stones 6.54 | -0.09 | level or lower |
| Deep Watch, 2 views | 6.18 | stones 6.04 | -0.14 | lower x3 (-0.1) |

## Decision

- **vary:** a small, consistent gain, every judge higher on both sets. It is added to the T4 READY state as an optional layer. Under the GPU rule it stays OFF until the GPU passes it.
  - "Foam reads as a drawn outline" is still PRESENT on every side. The wander does not show enough at these distances.
- **stones:** level to slightly lower. Judges read the sparser beach as emptier rather than more authored. Stays OFF.

## Named by all three, unchanged

1. **The beach:** authored clusters (driftwood piles, rock groups, dune grass in drifts) with open sand between, instead of grass in even rows.
2. **The surf:** a wet-sand darkening band behind it.
3. **The horizon:** the hard dark navy band.
4. **New art:** landmark islands for the bare dune silhouettes, matching the Meshy requests 10-12 already posted.

## GPU capture (`tb/tidewake` 286b196a7 or later)

Same as `t4/VERDICT.md`, adding `shore_surf_vary_candidate` to the section list: `--tidewake-look-sections=current_flow,shore_surf_candidate,shore_surf_vary_candidate`.
