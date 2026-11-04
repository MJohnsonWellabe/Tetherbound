# VIS-STORMWOOD j1: Stormheart, destinations, forest ground (4 Nov 2026, ~05:05 UTC)

**Arms:**
- **Base:** `s1_base`, the branch at `9faa85e1` minus main's last merge in the working tree (storm-light set ON, rim r1 ON).
- **Candidate:** `s1_cand`, captured in the same run with the cand1 overlay ON.

**Capture:** CPU llvmpipe, Compatibility, `job.json` repro launches 1 and 2 (approach and close views).

**Yardstick:**
- JUDGE_PROMPT verbatim, 3 anchor pairs (seed 1104001), three fresh code-blind judges.
- `calibrate.py`: linear, slope 1.95, intercept -5.29, r 0.90, anchor RMSE 0.55, confirming batch, no warnings.

| Row | Item | CPU base (mapped) | Candidate (mapped) | Arms on this row's frames | Decision |
|---|---|---|---|---|---|
| F41#1 | Stormheart | 3.22 | **3.94 (+0.72)** | `stormheart_presentation` `deck_light_1101`, `hollow_floor`, `hero_interior.round2` | **ON** |
| F41#4 | named destinations | 4.00 | **4.59 (+0.59)** | `stormwood_lantern_pools` `arrival_pools`, `basin`, `lantern_model`, `glow_fungi`, `grove` | **ON** |
| F41#5 | forest ground and distance | 4.13 | 4.20 (flat) | `pool_satin_1104` (black pools) | held; judged with other rows |

**Judges (3/3):**
- **F41#1:** B's roots and storm light "hint at a living tree" (PARTIAL 3/3). Still read as a wooden ring: no crown, no core, flat white lightning strokes, radial ceiling seams.
- **F41#4:** B frame 1 adds a stone-rimmed pool, posts and mushrooms, and a denser canopy (PARTIAL 3/3).
- **F41#5:** the pool satin split the judges. Two preferred the black pool and one preferred the bright reflection.

**Remaining asks:**
- **Stormheart:** a branching crown or sky opening, a glowing core column with impact light, and bark walls instead of planks. This needs new art.
- **Distance:** dense tree walls and fog instead of the grey horizon wall, plus groves and clearings.
- **Destinations:** give each one a framed hero landmark.
