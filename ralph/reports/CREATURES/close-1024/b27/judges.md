# b27 (24 Oct 2026, CPU candidate pick, fixed stage): bolder weathering without glow; dog3 with prone faint and chestnut coat

Base tiles are reused from b26: shipping Trailpup and Mudsnout, and dog2. The candidates are recaptured on the same fixed stage.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: p2_094_r4, f36_0_gap:C3, f36_0_npc:C1. This is a confirming batch.
- Fit: linear, slope 1.387, intercept -2.158, anchor RMSE 0.45.

| Species | Base | Candidate | Δ | Verdict |
|---|---|---|---|---|
| mudsnout | 7.04 (shipping) | **7.51** (bolder hardened hide and scar, tusk build) | +0.47 | Win. Three of three judges said the tusks and darker face mask give a stronger boar identity. |
| trailpup | 7.88 (shipping) | 7.51 (bolder weathering and scars) | -0.37 | Loss. Three of three read the pale scar lines as a texture seam, so Trailpup goes back to its shipping albedo. |
| terrapup | 7.55 (dog2) | 7.41 (dog3) | -0.14 | Within noise. Faint FIXED x3 now. Two of three preferred dog2's darker brown; one preferred dog3's warmer coat. |

Shared notes, none of them a touch issue:
- The quadruped hit reacts read as a rear or leap rather than a planted flinch.
- Terrapup's plates read as "stuck-on".
- Mudsnout's fur reads as flake-like clumps.

The CPU readings above the top anchor (Trailpup 7.88, dog2 7.55) come from a confirming batch, so they count as confirmed on CPU. GPU decides.
