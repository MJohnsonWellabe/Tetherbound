# Tidewake close-1024 round dw1: T1e currents on the Deep Watch landform views, CPU pre-judge (25 Oct 2026, CT)

The GPU baseline put "deep-watch landforms" (`P2-008-shore.json`) at 4.89. The shipping capture shows the bay crossed by the current's white bars and yellow dashes. At 23:00 they glow and are the brightest thing in the frame. So this row carries the P2-066 defect too.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 5527).
- **Calibration:** `calibrate.py` slope 1.00, r 0.80, anchor RMSE 0.56.

| Set | Shipping | t1e | Δ | Judges |
|---|---|---|---|---|
| Deep Watch beach, 08:00 and 23:00 | 5.46 | **6.09** | +0.63 | higher x3 |

**Defect changes:**
- **Road markings:** PRESENT x3 → PARTIAL x3. The remaining read is "small white streak and fleck shapes, still decal-like".
- **Unchanged x3:** layered shore ecology (PARTIAL or PRESENT) and "the beach reads empty or evenly scattered" (PRESENT).

## What is still needed (all three)

1. **The islands:** layered shore around them, grass → rock shelf → wet sand → foam.
2. **The beach:** authored clusters (driftwood, rocks, grass groves) instead of even pebble and tuft scatter.
3. **The waterline:** a surf or foam line.

## GPU capture

`tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/P2-008-shore.json`, without and with `--tidewake-look-sections=current_flow`, at `tb/tidewake` 63aeaefe6 or later, Medium and High.
