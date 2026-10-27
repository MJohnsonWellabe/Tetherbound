# b26 (24 Oct 2026, CPU candidate pick, fixed stage): readable touches, energy seams, Terrapup dog3

What was compared (both sides on the fixed stage from 67882b304, with no floating carried row):
- Trailpup and Mudsnout:
  - Candidate: bolder hardened shoulders and scars, plus amber energy seams drawn as a thin unshaded shell (touch_glow). Mudsnout is the tusk build.
  - Base: shipping (land).
- Terrapup:
  - Candidate: dog3, the coordinator's Bernese/Saint-Bernard redraft rigged at 3.20 m, with the +90 belly-to-camera faint and the seat at 2.58 m, z 0.0.
  - Base: dog2 as GPU-judged.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_gap:C4, f10_2_r3_capacitor, f36_0_npc:C1. This is a confirming batch.
- Fit: linear, slope 1.101, intercept 0.022, anchor RMSE 0.57.

| Species | Base | Candidate | Δ |
|---|---|---|---|
| mudsnout | 7.73 (shipping) | 7.14 | -0.59 |
| trailpup | 7.73 (shipping) | 7.07 | -0.66 |
| terrapup | 7.58 (dog2) | 6.92 (dog3) | -0.66 |

What the judges said:
- **Seams:** all three judges read the amber seam shell on fur as "gold glitter", "stray emissive speckle" or "a stuck prop/wound slash". It is an artefact, not energy, at this size.
- **Dog3 faint:** the +90 roll's faint (belly, pads and legs to camera) was marked as the listed belly-up flip (PRESENT x3). Dog2's -90 prone faint was marked FIXED x3.
- **Dog3 coat:** read "orange-red". Dog2's dark brown separates in value but sinks against the dark backdrop, as one judge put it.
- **Ride:** fixed or partial on both.

Shipping Trailpup and Mudsnout map 7.73 on the fixed stage, above the top anchor in a confirming batch. The stage fix alone takes them over the bar on CPU.

Next (b27):
- Glow off: species touch_glow is removed; the hook stays.
- The bolder weathering is kept, to test it alone.
- Dog3 gets the -90 prone faint and a coat pulled from orange-red toward chestnut (saturation x0.72).
