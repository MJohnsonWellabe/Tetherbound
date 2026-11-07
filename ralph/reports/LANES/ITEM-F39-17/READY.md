STATUS: parked
BRANCH: tb/item-f39-17  HEAD: 32f56fadde938ea8ed0a0c97a5d0739957dce667 (this line added in the next commit)

# ITEM F39#17 P2-067 current restoration environment (LANE-TW)

- **Live:** GPU 5.09 (board 6.09 after VIS-TIDEWAKE `cause_tidewake.currents`).
- **This pass:** nothing ships ON. No code or config changed; the overlays were config-only.
  - r1 (`qj/F39-17-fe66447e263e-11072141`), judged: restored `channel_tint_opacity` 0.35, `channel_tint_colour` #5fb8c8, `lane_glint` 0.6, `seam_opacity` 0.35. CPU mapped 6.85 -> 6.85 (+0.00). All three judges scored both sides identically, and the defect was PRESENT on both.
  - r2a (not judged, no visible change): restored tint 0.22 at the shipping #2c5f80.
  - r2b (not judged, no visible change at sheet scale): restored tint 0.55 #6cc6d2, `lane_glint` 1.0, `seam_opacity` 0.6, `seam_width_m` 1.6. Only a slightly lighter soft band appears in the one restored frame (S1_restored_t0).
- **Why parked:** the current ribbon is a narrow, distant overlay in these stands, and one of the three frames shows the restored state. Shader-only restored looks cannot register. The judges' ask is an environmental change on restoration: "change water colour, foam lines, sandbars and props, not only the streaks" and "break up the evenly spaced flat sandbars".
- **Next idea (needs a world/scene change, not a shader tweak):** a restored-state presentation pass tied to the existing `water_currents_restored` flag:
  - wake the sandbars (shore foam rings and kelp or driftwood dressing that appear only when restored);
  - shift the restored sea grade in the lane region (sea shader shallow tint);
  - send calm floaters downstream with `drift_markers` restored settings (larger, slower and more numerous).
  
  These touch the sea shader and dressing configs. Check file ownership before taking it.
