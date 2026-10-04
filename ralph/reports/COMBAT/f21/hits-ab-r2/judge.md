# F21#5 matched A/B judge r2: after preferred 4/4

**Method.** A fresh code-blind sub-agent judged pixels only, and saw all 16 contact sheets at full size.
- Before is `../hits-ab-r1/before`: the same build, seed, route and inputs, with the F21 impact layer off (no weighted knockback, no reaction recoil, no damage numbers, no class flash/shake styling) and legacy hitstop kept.
- After is `after/`, with the layer on.
- A/B were shuffled per shot (`ab-key.json`).
- Question: "which makes the hit feel more weighty and readable?"

| Shot | Preferred | Decoded | Confidence |
|---|---|---|---|
| quick | A | after | high |
| charged | B | after | high (reads a camera kick on the heavy hit) |
| crit | B | after | high (the gold "✦" style is distinct; larger burst; the target rears) |
| incoming | A | after | medium (the number floats above the head) |

**Verdict: the judge prefers after over before in 4 of 4 shots. The F21#5 judge half PASSES.**
r1 also preferred after 4/4, but saw only 31 of 56 frames.

**Defects still open in the after frames**, routed rather than silently decided:
- **Spec (COMBAT §11):** the number size follows the hit class (crit 1.35×, super-effective, resisted), not the move weight, so "46" and "10" are the same size; there is no pop-in scale; the own-creature number is 0.85× in the same palette. Changing these is a spec decision.
- **F25 effect craft (VFX lane):** the burst disc covers a small target for 2–4 frames; there is no hurt flash on the mesh.
- **HUD (UX):** no HP-bar chip or drain flash.
- **Tuning:** light knockback (0.3 m) barely shows at fight distance; heavy (1.2 m) shows only a small shift in stills.
