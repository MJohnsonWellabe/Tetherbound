# VIS-STORMWOOD j4: Glass Sink and harvest (4 Nov 2026, ~06:20 UTC)

**Capture:** base `s1_base` and candidate `s1_cand` come from the same CPU run (launches 6-9).

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (seed 1104004), three fresh code-blind judges. `calibrate.py`: linear, slope 1.30, r 0.91, anchor RMSE 0.57, no warnings.

| Row | Item | CPU base (mapped) | Candidate (mapped) | Arms | Decision |
|---|---|---|---|---|---|
| F41#10 | Glass Sink | 4.03 | **5.07 (+1.04)** | `hero_landmarks_1101.glass_sink`, `stormwood_glass_sink` `dark_pool_candidate` + `obsidian_1104` | **ON** |
| F41#9 | harvest identity | 4.76 | 4.59 (-0.17) | `stormwood_harvest_hero2` | OFF: three thin spires lose the base |

**Judges (3/3) on F41#10:**
- "Now reads as a dark glass sink", with rim shards and a better fit to the black pools on the board. The defect is PARTIAL.
- **Remaining:**
  - The cell lines are regular and read as computer-generated.
  - There is still no bowl depth.
  - The huge untextured white cliff wall at left needs fixing.
  - The edge is abrupt.

**F41#9 remaining:**
- The frame-3 node (glowmoss) reads as "a cloud puff".
- Asks: a material-specific silhouette with a grounded base, and copper or glass cues.
