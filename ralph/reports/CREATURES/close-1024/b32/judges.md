# b32: GPU batch-1 follow-ups on land (Mosshock compressed values + 3.6 m, Riftfrill roughness, Stormtrail rim), CPU Low, three fresh code-blind judges

Standard JUDGE_PROMPT, 3 anchor pairs (f36_0_npc:C1, f04_6_r22, f36_0_gap:C1), calibrate.py.
Fit: slope 0.974, intercept 0.505, anchor RMSE 0.389, confirming batch (no warnings).

| species | before | after | change |
|---|---|---|---|
| Mosshock (base = the 4fb473e7a look the GPU judged) | 6.25 | 6.32 | +0.07 |
| Riftfrill (roughness 0.32 -> 0.63) | 6.90 | 6.97 | +0.07 |
| Stormtrail (rim 0.25) | 7.49 | 7.39 | -0.10, rim reverted in 4e5217f1b |

What the judges saw:
- **Mosshock:** both sides still read as busy yellow-green camouflage. The blotch shapes are baked into the source atlas. Its cower hit reads as a flinch on two of three judges (the GPU-judged side's rear-up read as a pounce). Its faint still reads as a lump.
- **Stormtrail:** close to the Tanglevolt bar, but the hit is weak (a head dip).
- **Riftfrill:** a strong silhouette, but the rear-up hit is ambiguous.
