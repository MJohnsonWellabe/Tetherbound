# b33: Mosshock graded Meshy retexture (tb/creatures-land a888fb436) vs the batch-2 look (4e5217f1b), CPU Low, three fresh code-blind judges

Standard JUDGE_PROMPT, 3 anchor pairs (f10_2_r3_capacitor, f36_0_gap:C7, f36_0_npc:C1), calibrate.py.
Fit: slope 1.113, intercept -0.184, anchor RMSE 0.588, confirming batch (no warnings).

| | raw (j1, j2, j3) | mapped |
|---|---|---|
| Mosshock, batch-2 look | 5.9, 5.4, 6.2 | 6.31 |
| Mosshock, graded retexture | 6.5, 5.9, 6.8 | **6.94** (+0.63) |

What the judges saw:
- **Retexture (all three):** cleaner olive-green, a clearer silhouette and a readable face. One judge called the eye ring odd; one called the surface slightly plasticky, with no rim light.
- **Batch-2 look:** camouflage and gold flecks read as noise.
- **Both sides:** the hit reads as a crouch or lunge (PARTIAL), and the faint as a belly-up flip with the feet up (PRESENT 2 of 3).
