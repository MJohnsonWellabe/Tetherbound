# Visual lane v1/b16: Stormwood storm-light set vs a FRESH base (3 Nov 2026, ~23:20 UTC)

**Arm:**
- `stormwood_surge.json` `presentation.storm_sky_1101` and `presentation.soft_rain_1101`
- `stormwood_ground_finish.json` `moss_variation_1101` and `value_lift_candidate`

Candidate `swc_cand` was captured 18:27–20:49 UTC. It is compared with a fresh base, `swb_base`, captured 20:50–22:20 UTC on the same branch with the same launches. This replaces the stale v1/b13 comparison. CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.31, intercept -1.43, r 0.93, anchor RMSE 0.31. Warning: some candidates are extrapolated.

| Row | Item | CPU base (mapped) | Arm ON (mapped) |
|---|---|---|---|
| F41#5 | forest ground and distance | 4.84 | **5.84 (+1.00)** |
| F41#2 | surge phase presentation | 5.06 | **5.80 (+0.74)** |
| F41#17 | Crown Arch | **6.45** (above 6.0 as shipped) | 6.80 (+0.35) |
| F41#19 | Glass Field spike bases | 5.32 | 5.45 |
| F41#4 | destination identities | 5.54 | 5.58 |
| F41#1 | Stormheart | 4.88 | 4.71 (noise) |

**Decision: all four flags ON.** Two rows gain more than 0.5 and no row drops beyond noise. F41#5 and F41#2 are still under 6.0.

**Judges (3/3):** the dark treeline band and the black pools add the missing distance layers and value range. Storm clouds and heavier break rain make the phases easier to tell apart, but Calm and Building still look alike.

**Remaining asks:**
- A flat lavender sky with no shafts or fog.
- Uniform ground carpet.
- Pool specular that blows out to white in one frame.
- A saturated green ground patch, flagged on the candidate side.

**Next levers:**
- F41#2: a per-phase grade.
- F41#5: groves and clearings.
- F41#1: needs new art (a living tree with a crown and a core).
- F41#19: the slab base itself.
