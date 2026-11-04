# Visual lane v1/b19: retuned storm-light set re-judged (4 Nov 2026, ~04:45 UTC)

**Arm:** the storm-light set as retuned for #808 CI (`d9c09903`):
- Storm phases have no deck rims.
- Calm contrast is 0.40 and Calm has no sheet glow.
- Break sun is 0.27 and Break ambient is 0.66.
- Calm keeps the shipped deck colour.
- Soft rain is 4500 streaks.

**Comparison:** base `swr_base` has the four flags OFF; candidate `swr_cand` has them ON, as shipped. Both were captured in the same run, on the same head, under the scene lock. CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.03, r 0.72, RMSE 0.56, no warnings.

| Row | Item | Set OFF (mapped) | Retuned set ON (mapped) | Decision |
|---|---|---|---|---|
| F41#5 | forest ground and distance | 5.04 | **5.63 (+0.59)** | stays ON |
| F41#2 | surge phases | 5.39 | 5.46 (+0.07) | stays ON |
| F41#19 | Glass Field spike bases | 5.42 | 5.46 (+0.04) | stays ON |

**Judges (3/3):**
- The black pools and darker ground patches still break the carpet. That is the main F41#5 gain.
- On F41#2, the Calm/Building and Fading stills still read as alike. Two of three see Break's forked lightning as a small gain.

**Compared with v1/b16** (same rows, before the retune: F41#5 4.84 -> 5.84, F41#2 5.06 -> 5.80): the retune kept the F41#5 gain but lost most of the F41#2 lift. Break's darker sun and the removed deck rims took the phase drama the judges had credited.

**Next for F41#2:** a per-phase grade (sky, fog colour and lightning cadence per phase) that keeps the phase rules: Calm has no lightning, Break is darkest, the aftermath is calmest. That belongs to the Stormwood region lane, so I am flagging it via this verdict.
