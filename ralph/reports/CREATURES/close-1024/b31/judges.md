# b31: owner-note touches on land (Mudsnout tusks, Trailpup rim + paw dust, Cindercub ash mask, Nightburrow chipped plates), CPU Low, three fresh code-blind judges

Standard JUDGE_PROMPT, 3 anchor pairs (f36_0_npc:C1, f36_0_gap:C2, f10_2_r3_capacitor), calibrate.py.
Fit: slope 0.860, intercept 1.271, anchor RMSE 0.616, confirming batch (no warnings).

| species | before | after | change |
|---|---|---|---|
| Cindercub (ash mask) | 7.44 | 7.52 | +0.08 |
| Mudsnout (tusk build, hide, scar, cower hit) | 7.12 | 7.09 | -0.03 |
| Nightburrow (chipped plates) | 6.63 | 6.66 | +0.03 |
| Trailpup (rim 0.25, paw dust 1.22) | 7.18 | 7.09 | -0.09 |

All four are within noise.
- **Trailpup:** two of three judges read the rim and paws as bleached legs. The rim is dropped (b20 had also found no rim gain) and the paws soften to 1.1, in land 78361d936.
- **Hit poses:** all three judges read the Cindercub and Trailpup rear-up hits as a pounce or lunge, so both get the cower in 78361d936. Mudsnout's cower read as a flinch, but a subtle one.
- **Other flags:**
  - Nightburrow's faint reads as a curled ball, and a thin violet streak floats above its back in every frame.
  - Cindercub's tail sweeps through the ruler in staging.
  - Mudsnout and Trailpup are borderline against the "taller than the trainer" rule. Mudsnout stays in its small class.
