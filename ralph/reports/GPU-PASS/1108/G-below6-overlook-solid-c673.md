# G-below6-overlook-solid-c673: F40#15 overlook ruin collision and new walk stands (GPU High, base vs arm)

## Verdict: SHIP (gain > 0, 3/3 prefer the arm, no judged set loses)

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base → arm) |
|---|---|---|---|---|---|---|
| **F40#15** walk_02_day, walk_03_day | 4.23 | **5.60** | **+1.37** | 3/3 | 4.8→5.3, 4.4→5.4, 3.8→4.9 | FIXED → PARTIAL 2/3, PRESENT 1/3 |
| No-loss: route_day, vista_dusk, walk_01 | 4.86 | 4.86 | 0.00 | 0/3 (3 ties) | 5.0=5.0, 5.0=5.0, 4.2=4.2 | PRESENT on both |

All scores are mapped. No set loses. **F40#15 row read on main with this arm: 5.60 High** (walk pair only; the windscar aerie job frame was not captured). The earlier pooled read was ≈5.47.

## Caveat on the gain
The arm adds two capture-stand overrides, so walk_02 and walk_03 are new stands, by design. Most of the +1.37 comes from what those stands show:
- **Base (3/3):** see-through glass-like planes hang over the trainer (walk_02), and the camera hugs a giant wall over an empty void (walk_03).
- **Arm:** shows the arch, ring, pennants, cliffs and distant islands.

The defect reverses: base shows no strips only because its stands looked away from them. The arm's stands show dark slab strips on the grass again:
- a dark slab at the trainer's feet in walk_02;
- flat dark plank and green-top slabs in walk_03, plus a bare grey ramp wedge in the foreground.

That is PARTIAL for judges b and c, PRESENT for judge a. The ghost-plane fix itself (ruin_collision) is real, and the row read is honest for the new stands.

## Frames
- `tb/gpu-frames-1113` 0c52bcb7b. Tree c673d5285, whose files equal main 4f9ee3967. High, 1920 JPEG.
- Arm: `BELOW6-OVERLOOK-SOLID/overlay.json` (ruin_collision_1113 plus two capture_stands heading overrides).
- Pixel differences:
  - walk_02: 35.6.
  - walk_03: 74.5 (new stands).
  - route_day, vista_dusk, walk_01: 2.0, 1.7, 5.3.

## Batch
Shared with G-below6-overlook-join-c673: `yardstick_g_overlook_1113/`.
- Anchors: craft, f36_0_npc:C1, f10_2_r3_capacitor.
- Fit: r 0.945, RMSE 0.45. It is a confirming batch.

## Next asks (LANE-LAND-CS)
1. **Clear the dark slab and plank strips now visible from the new stands:** walk_02 at the trainer's feet; walk_03 green-top slabs left of centre and the bare grey ramp wedge in the foreground. That is what keeps F40#15's own frame PARTIAL. Scene.
2. **Fix the stretched, blurry brown path texture** in walk_02, right of the trainer. Scene.
3. **Give the overlook ground pale-stone terrace paving and edging.** All three judges' top ask for the batch. Scene or new_art.
4. **Capture the second F40#15 job frame,** windscar_ravine 06 windscar_flight_aerie vista_dusk, so the row can be scored on both of its frames.
