# b24 (24 Oct 2026, CPU candidate pick): owner touch pass, Trailpup and Mudsnout

What was compared:
- Candidates: the owner's "war-torn or hardened" touch, baked into each remake's own albedo by `tools/art_pipeline/creature_touch.py` from `data/creatures/creature_touches.json`. Same mesh, clips and material.
  - Trailpup: weathered, darker shoulders (18.9% of the surface) and two faint flank scars (0.5%).
  - Mudsnout: hardened shoulder hide (17.5%) and a snout scar (0.3%).
- Base: shipping (the same remakes, untouched albedo).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f10_2_r3_capacitor, craft. This is a confirming batch.
- Fit: linear, slope 1.211, intercept -1.017, anchor RMSE 0.56.

| Species | Shipping | Touched | Raw (J1, J2, J3) |
|---|---|---|---|
| trailpup | 7.58 | 7.58 (above top anchor; confirming batch) | 7.1, 7.4, 6.8 on both sides |
| mudsnout | 6.82 | 6.86 | touched 6.4, 6.9, 6.2; shipping 6.3, 6.9, 6.2 |

Verdict:
- The touch is score-neutral. All three judges called the pairs near-identical, so it is light, as the owner asked ("don't go overboard").
- It lands on the lane as the owner-directed look, and the GPU pass decides it.
- In the side-by-side, the touched Trailpup's darker shoulder saddle is visible. The scars are faint.

What the judges said for both species (not a touch issue):
- The hit react rears up and reads as a leap rather than a flinch.
- Mudsnout's faint hides its legs and reads as a log.
- Mudsnout's fur reads as blotchy, stamped clumps (2 of 3 judges).

On the lane, the same painted albedo also goes to Mudsnout's tusk build (`also`: candidate_nat1024t), which shares its UV layout. Its JPEG is byte-identical to the judged one.

Check: texture_import_policy --check on the touched folders: PASS.
Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
