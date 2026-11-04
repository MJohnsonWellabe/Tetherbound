# Visual lane v1/b8: Meadows map paint (F38#4) (3 Nov 2026, ~16:35 UTC)

**Arm:** `data/config/map_paint.json` ON vs OFF. ON adds a north-west hillshade, canopy painted from the baked tree and grove layers, and painterly grain to the shared map bake. Frames: `phase2_capture_ui.gd --biome=meadows` map frame. Base reuses the ui_base frame; the candidate uses the same launch with paint ON. CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (craft, f36_0_npc:C8, f36_0_gap:C6; a confirming batch), three fresh code-blind judges. `calibrate.py`: linear, slope 1.11, intercept -0.58, r 0.66, anchor RMSE 0.62, no warnings.

| Row | Item | CPU base (mapped) | Paint ON (mapped) | Decision |
|---|---|---|---|---|
| F38#4 | P2-002 map | 5.90 | **6.30 (+0.40)** | **ON**; at or above 6.0 |

**Judges:**
- Agreement: 3/3 preferred the painted side. "Darker canopy blotches inside the circle hint at tree groves, so there is some terrain context." The flat side "reads more like a placeholder".
- Recorded defect: PARTIAL on both sides.
- Remaining asks:
  - water and building footprints in the surveyed area
  - landmark icons and destination labels
  - a lighter fog
  - controller-only prompts (the panel mixes `[Minus]`/`[Q]` with controller letters)
