# G-glass-sink-lip-rim: Glass Sink lip slabs seated on the rim (F41#10)

Frames: `tb/gpu-frames-1108` bbd41bdc, High.
- **Live:** main 90886c306.
- **Arm:** live plus `assets/props/blender-1109/glass_sink_lip`, `stormwood_glass_sink.gd`, `stormwood_world.gd` and `stormwood_glass_sink.json` at dbebf021c (seat_on_rim), with the lane's overlay.

## Pre-judge render check
The arm changes 5–8% of pixels, and the slabs are visible in 3 of 3 frames. This replaces the VOID `G-glass-sink-lip`.

## Judged
Batch `G-a3lip` (see G-storm-light-a3 for the fit). This is a confirming batch.

| Row | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#10 Glass Sink | 5.92 (raw 5.8, 5.2, 5.4) | 5.24 (raw 5.3, 4.6, 5.0) | **−0.68** | 0/3 |

## Do the slabs read as a basin lip?
**No.** All three judges independently describe the arm's slabs (frames 1 and 3) as placeholder or broken geometry:
- "untextured dark-blue box slabs with flat white spikes … reads as placeholder geometry"
- "a hard dark-blue block … white crystal spikes float near it as plain triangles"
- "dark navy untextured blocks with flat white triangle shards hanging off the cliff edge. It reads as broken geometry"

On the live side, the same edge shows the existing pale crystalline cliff face, which every judge preferred. One judge marked the recorded defect PRESENT on the arm, against PARTIAL on live.

## Verdict
- **DO NOT SHIP.** The slabs read as untextured boxes, and their material, not their placement, is the problem: they render flat navy with untextured spike triangles.
- **Parking.** This is the second failed approach on the lip, so park it until there is a new idea. That idea would be a textured glass or stone material on the slabs, or a stepped glass bowl hero mesh, which all three judges list as their top new-art change.
- **Remaining defects on both sides:**
  - The basin is a flat dark plane.
  - The ring reads as a pedestal or well, not a sink.
