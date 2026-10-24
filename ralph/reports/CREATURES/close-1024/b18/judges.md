# b18 (24 Oct 2026, CPU candidate pick): the closest-to-7.5 GPU subjects

What was compared:
- Candidates:
  - Aquaryn and Tidecoil: a gentler held shove (gain 0.9; `--candidate-r18`), because b17 judges saw the hind feet leave the stage.
  - Mosshell: a -90 faint roll instead of -60 (`candidate_nat1024r`; the roll Terrapup and Burrowback use, both GPU-confirmed).
- Base: shipping (land 5cecc01bd).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f36_0_gap:C6, p2_094_r4. This is a confirming batch.
- Fit: linear, slope 1.399, intercept -2.529, RMSE 0.55.

| Species | Shipping | Candidate | Decision |
|---|---|---|---|
| aquaryn (gentle shove) | 7.08 | 6.94 | OFF |
| tidecoil (gentle shove) | 7.27 | 7.03 | OFF |
| mosshell (-90 faint) | 7.31 | 7.17 | OFF: the roll shows the shell edge to the camera, and limbs poke up |

Gain rule: Aquaryn and Tidecoil have now had two pose rounds with no gain (b17 recoil, b18 gentle shove), so both are parked on poses.
- Every judge names the material as the next lever: the glossy single-value cyan loses the board's white belly and navy value break.
- That needs new art (a Meshy naturalistic remake), not another pose tweak.

Mosshell ships its current -60 roll. Judges rate its model at the style bar; the faint is the weak point.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
