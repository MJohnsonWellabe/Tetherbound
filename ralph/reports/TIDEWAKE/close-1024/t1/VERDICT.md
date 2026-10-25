# Tidewake close-1024 round t1: T1 currents flow foam (P2-066), CPU pre-judge (25 Oct 2026, CT)

## What changed (OFF in play; `--tidewake-look-sections=current_flow` captures it)

The GPU baseline put currents and docks at 3.61, with P2-066 reading as giant opaque white bars and yellow dashes, like road markings.

- **Removed:** dashes, comets, chevrons and painted rims (`streak_density`, `dash_fill`, `comet_opacity`, `chevron_opacity` and `channel_edge_opacity` all 0).
- **Kept:**
  - soft foam tongues along both banks, with `seam_opacity` 0.4 and 1.2 m wide;
  - a faint lane band (0.08) and a soft channel tint (0.18);
  - the Meshy driftwood and spar buoys from earlier rounds.
- **Wavelet caps** (`shaders/water_current_flow.gdshader`):
  - Each cap is now offset, sized (0.55-1.0) and faded per cell, and broken up by the seam's lace noise, so the caps never form a grid.
  - Settings: `chop_cap_opacity` 0.35, scale 2.6 m, density 0.35.
  - Only the candidate turns caps on, so shipping is unchanged.
- Flow vectors, strengths and the restored state are unchanged.

## Mapped Bar A (CPU pre-judge; the GPU decides done)

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 1031).
- **Calibration:** `calibrate.py` slope 1.44, r 0.961, anchor RMSE 0.26, confirming batch. Shipping currents are extrapolated below the anchors.

| Set | Shipping | t1 | Δ | Judges |
|---|---|---|---|---|
| Currents, swim views (along day, across day, along night) | 3.66 | **5.92** | +2.26 | higher x3 |
| First Shore and lesson-dune, midday | 5.87 | **6.64** | +0.77 | higher x3 |

The CPU shipping score (3.66) matches the GPU baseline (3.61).

**Defect changes (all three judges):**
- **"Road markings, white bars or yellow dashes":**
  - Swim views: PRESENT x3 → FIXED x3.
  - Shore: PRESENT x3 → PARTIAL x2 and FIXED x1.
- **"Foam reads as a regular repeating pattern":** PRESENT x3 → PARTIAL x3.
- **"Path and direction cannot be read":** PARTIAL on both sides.

**Remaining, named by all three judges:**
1. At night (23:00) the lane almost disappears into a flat navy.
2. The yellow triangle pennants on the leaning spar buoys are loud and oversized in the foreground.
3. The across-lane crescents still look a little evenly spaced.
4. The water itself is a single flat cyan with no depth gradient. That is T2, being captured.

## Sheet

`_sheet_t1.jpg`:
- Top: currents, shipping on the left and t1 on the right.
- Bottom: shore, shipping on the left and t1 on the right.

## GPU capture (Medium and High, `tb/tidewake` 131b098c9 or later)

- `tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/T2-current.json --capture-size=1920x1080 --preset=<Medium|High> --source-sha=<sha>`
  - once without and once with `--tidewake-look-sections=current_flow`.
- The same pair with `--camera-set=res://tools/visual_judge/camera_sets/F39-look.json --views=shore-day,lesson-dune`.
