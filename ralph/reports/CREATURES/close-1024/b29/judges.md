# b29 (24 Oct 2026, CPU candidate pick, fixed stage): Mosshell withdraw faint (tier 2)

What was compared:
- Candidate: the faint withdraws into the shell. The head drops under the rim, the legs fold in, and the shell settles low with a slight nose-down lean.
- Base: shipping, the -60 side roll. GPU H mapped it 6.93 and said its faint "barely differs from standing".
- Only the faint clip changes (rest differs by 0.0003, float noise).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: p2_094_r4, f36_0_gap:C4, f36_0_npc:C1. This is a confirming batch.
- Fit: linear, slope 1.375, intercept -1.918, anchor RMSE 0.35.

| Species | Shipping | Withdraw | Δ |
|---|---|---|---|
| mosshell | 6.70 | **7.38** | +0.68 |

Faint end:
- Withdraw: FIXED, PARTIAL, PARTIAL ("shell settled low, head tucked, limbs in: reads as down").
- Shipping: PRESENT x3 ("rolls onto its edge like a wheel" / "tips up rather than collapsing").

Remaining:
- Small pale limb geometry shows at the shell rim on the faint.
- The rear-up hit reads as rearing more than recoiling.

Land commit b8fd842b8. Tests: rest_pose, f36_pose, water_species, four_biome and scale_ladder, 60 tests, 0 failed.
