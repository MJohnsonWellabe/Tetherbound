STATUS: parked
BRANCH: tb/item-f39-16  HEAD: (branch tip; this file is in the last commit)

# ITEM F39#16 P2-066 live current streaks (LANE-TW)

- **Live:** GPU 6.75 (VIS-TIDEWAKE f16 CPU 6.63 -> 6.75).
- **This pass, CPU quick judge, both held OFF:**
  - r1 (`qj/F39-16-0c6f9aef2eee-11072041`): `cap_scatter` 1.0 + `chop_cap_density` 0.55 + `chop_cap_scale_m` 3.0. Mapped 7.31 -> 6.63 (-0.68), 3/3 judges lower. Denser caps read as rows of short guide dashes.
  - r2 (`qj/F39-16-542951f68810-11072057`): `cap_scatter` 1.0 + `chop_cap_density` 0.22. Mapped 7.65 -> 7.56 (-0.09), flat. Parked under the stop rule (two rounds under +0.5).
- **GPU re-score candidate:** in both batches the shipping base mapped 7.31 and 7.65 on CPU. In r2 all three judges called the guide-lane defect FIXED on the base. CPU sits about 0.8 below GPU, so the current build may already clear 7.5 on GPU. Re-score the row on the GPU before more work.
- **Code (inert):** `shaders/water_current_flow.gdshader` gains `uniform float cap_scatter = 0.0`. Above 0 it domain-warps the chop-cap cell grid, staggers each row and varies cap width. At 0 the shader path is unchanged. No config sets it, so no flag was turned ON and no test was flipped.
- **Judges' remaining asks:** the current now reads too faint, "scattered whitecaps with no direction". They ask for medium-length, curved, tapered foam streaks grouped into one directional band with edge foam, plus a subtle colour shift along the band. This must avoid the earlier guide-lane and road-paint reads; see the long `current_flow._comment` history.
- **Next idea:** a single soft directional band per lane: the existing `soft_channel_tint` at a slightly higher opacity plus tapered seam tongues (`seam_taper_m`) in the lane core rather than only at the banks. Only if the GPU re-score leaves the row under 7.5.
