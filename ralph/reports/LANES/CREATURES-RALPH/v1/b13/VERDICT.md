# Visual lane v1/b13: Stormwood storm-light overlay (swc) vs sw_base (3 Nov 2026, ~21:20 UTC). PROVISIONAL: stale baseline

**Arm:** the swc overlay:
- `stormwood_surge.json` `presentation.storm_sky_1101` and `presentation.soft_rain_1101`
- `stormwood_ground_finish.json` `moss_variation_1101` and `value_lift_candidate`

The candidate (`swc_cand`) was captured 18:27–20:49 UTC on the current branch.

**Baseline problem (found in this batch):** most `sw_base` launches ran 00:43–03:33 UTC. That is before today's Stormwood changes landed on the branch, most visibly the Blender Crown Arch (ON since ~10:30). The judges saw the old blue Meshy pillar on the base side. So this is not a same-run comparison: the F41#17 row measures the arch change, not the arm, and every other row carries some branch drift. The resumable queue kept the early launches and did not recapture them. **No flag changes from this batch.** A fresh baseline (`swb_base`, same rows) is queued so the swc arm can be judged properly.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.23, r 0.81, RMSE 0.47. Warning: some candidates are extrapolated.

| Row | Item | sw_base, stale (mapped) | swc ON (mapped) | Note |
|---|---|---|---|---|
| F41#17 | Crown Arch | 4.15 (old pillar) | 5.95 | Not an arm result: the base predates the arch. The arch was judged 6.19 in v1/arch2 |
| F41#5 | forest ground and distance | 4.77 | 5.42 | 3/3 judges credit the black pools and treeline on the candidate side |
| F41#2 | surge phases | 4.89 | 5.42 | Cloud sky and heavier break rain help; Calm and Building still look alike. Flat green ground patches appear on the candidate side |
| F41#19 | Glass Field spike bases | 5.14 | 5.34 | Needs a fix to the slab base itself |
| F41#4 | destination identities | 5.30 | 5.38 | Flat |
| F41#1 | Stormheart | 4.48 | 4.60 | Needs new art (a living tree, crown and core) |

**Correction to v1/b10 and b11:** `sw_cand` launches 4–10 ran 15:23–16:58 UTC, but their bases ran 03:09–03:33 UTC, so those rows have the same drift. The "as shipped" scores (F41#11 6.90, F41#12 6.08, F41#14 6.13) are base-side frames from ~03:00 UTC on rows the arch does not touch. They stand, with that caveat.
