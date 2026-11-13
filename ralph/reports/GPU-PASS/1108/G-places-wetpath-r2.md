# G-places-wetpath-r2: wet trail round 2, with half the darkening, the warm hue kept and none at night (F40#0, F40#19; GPU High)

## Verdict: SPLIT again, closer. Do not ship as is: night rain still loses (−0.12, 2/3 prefer base).

| Set | Base | Arm | Gain | Prefer arm | Round 1 gain |
|---|---|---|---|---|---|
| Gate clear (control) | 6.41 | **7.06** | **+0.65** | 3/3 | +0.57 / +0.60 (clear sheets) |
| Gate rain (F40#19 piece) | 5.85 | **6.41** | **+0.56** | 3/3 | +0.65 |
| Summit day rain | 5.85 | **6.41** | **+0.56** | 3/3 | +0.08 |
| Overlook rain (no-loss) | 5.28 | 5.24 | −0.04 | 2/3 (1 prefers base) | −0.09 |
| **Summit night rain (no-loss)** | 6.49 | 6.37 | **−0.12** | 1/3 (2 prefer base) | −0.34, 0/3 |

- **What improved.** Every day set now gains above 0.5 with 3/3. The night loss shrank from −0.34 to −0.12. The overlook is now level.
- **Why it still fails.**
  - The night set loses, with 2 of 3 judges preferring base.
  - On the arm's night frames the path is "a dark soot-like smear ... a hole or stain rather than a path" (2/3).
  - Base's night path is "golden-brown, slightly over-bright for night" (2/3). Judge c instead calls base's path "self-lit" and prefers the arm.
- **Darkening still applies at night.** The round-2 brief said "none at night", but the GPU lane's own numbers show it still darkens:
  - night grass 83 → 72;
  - night trail 56 → 52.5.
  The night switch is not gating the soil darkening.

## What the judges say (3/3 unless noted)
- **Base's trail by day** is "a saturated orange band of even width ... a painted strip laid over the terrain". The arm's is "a darker, broken brown with soft edges" that "reads as worn earth".
- **Every judge's top change** asks for one blended, low-saturation earth path with soft edges and grass encroachment that "responds correctly to night light", with neither the self-lit gold nor the black stain.
- **The overlook (Ec)** is the weakest place in the batch:
  - box walls, flat banner planes and a bare hoop arch;
  - a billboard cloud bank and two unsourced glowing orbs.
  - The arm's path there is "greyer, blends better but washed out". The place needs new art; the trail is not what holds it.
- **The night set** keeps the batch's best mood beat: the lit dome under a navy storm sky. It also has a flat grey slab rock at right (3/3).

## Next
1. **Gate the darkening to non-night.** Night must see no soil or grass change, which the arm was supposed to do. Re-capture p88 to check it: night trail L and grass L should match base.
2. **Optional: lift the night trail slightly from base's value, without the glow.** This is a later round; the first goal is that night does not lose.
3. **Ship the day result.** With night unchanged, this arm ships: gate clear +0.65, gate rain +0.56, summit day +0.56, all 3/3.

## Frames
- **Source:** `tb/gpu-frames-1108`, High.
  - `G-places-wetpath-r2-gate` (5675aeffc): pieces 3–4, clear and rain.
  - `-p84` (3ed68930f): summit day rain.
  - `-p88` (0f611b9fd): summit night rain.
  - `-p92` (416317a71): overlook day rain.
- **Build:** `tb/places` 5c372b751 on both sides.
  - **base:** no overlay.
  - **arm:** `PLACES-WETPATH/overlay.json`, round 2.
- **Health:** 0 script errors, 0 blank frames.
- **Sets:** four views per place (approach, gameplay, reverse, detail) in a 2×2 grid. The rain and clear briefs are the gatepaving briefs; night uses "at night in rain".
- **Render check:** mean difference:
  - gate rain 6.9, gate clear 1.0;
  - summit day 7.3, summit night 6.4, overlook 6.9.

## Batch `G-wp2`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.2114, intercept −0.492, r 0.891, anchor RMSE 0.63. A looser fit; sets are about ±0.3.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| Gate clear | 5.8, 5.8, 5.5 | 6.4, 6.3, 6.0 |
| Gate rain | 5.4, 5.3, 5.0 | 5.9, 5.8, 5.4 |
| Summit day | 5.5, 5.2, 5.0 | 6.0, 5.7, 5.4 |
| Overlook | 5.2, 4.5, 4.6 | 4.9, 4.6, 4.7 |
| Night | 6.2, 5.8, 5.3 | 5.9, 5.6, 5.5 |
