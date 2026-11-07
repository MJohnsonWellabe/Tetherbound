# VIS-STORMWOOD j3: dialogue rows (4 Nov 2026, ~06:05 UTC)

**Capture:** base `s1_base` and candidate `s1_cand` (cand1 overlay ON) come from the same CPU run, dialogue launch 5.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (seed 1104003), three fresh code-blind judges.

**Caveat:** `calibrate.py` fell back to an offset map. The least-squares slope was 0.49, outside the 0.5-2.0 range, and the anchor RMSE is 0.85 (above 0.75). The mapped scores carry that caveat; the raw judge scores agree in direction.

| Row | Item | CPU base (mapped) | Candidate (mapped) | Arms on this row's frames | Decision |
|---|---|---|---|---|---|
| F41#8 | named silhouettes | 4.72 | **4.96 (+0.24)** | `npc_role_accessories` | **ON** (3/3 score B higher; the staff and blue hood give individual reads) |
| F41#18 | uniform readability | 4.96 | 4.99 (flat) | rim r2, `rank_marks_1104`, `pool_satin_1104` | OFF: the marks are not visible at this distance |
| F41#15 | dialogue obstruction | 5.39 | 5.19 | (pool satin only) | no arm; FIXED 2/3 on both sides |
| F41#20 | dialogue reuse | 4.69 | 4.69 | none | the line defect is FIXED 3/3. Frame 1 (Fenn) renders black on both sides: the camera sits inside a trunk |

**Pools (judges 3/3):** the base pools are "flat lavender mirror slabs" and the pool-satin pools "crushed black holes". Asked for: dark but reflective, with real value range.

**Next:**
- Fix the camera inside geometry on Fenn's dialogue frame.
- Give the named officers their own models (Nysa uses Marrow's body).
- Try a mid-sheen pool between the two.
