# Quick judge F41-FR-b-matched: F41-FR

- Head `2fc31d77ac8bb943f5a17a6dce1dc22a998396ad`, tree `83cc79692052`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_rim.json": {"realm_scenes": ["res://scenes/world/stormwood.tscn"]}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1156s, wall 1156s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3045, intercept -0.8871, r 0.8472, anchor RMSE 0.613, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41-FR | Named wild-creature fight in a dense storm forest (Stormwood Hollows): one fight, one-second interval frames (iNN) plus the enemy's telegraphed attacks (tell1/tell2 a-f, start to recovery). Does the fight read on screen - both fighters (the large wild creature and the player's smaller creature) clearly visible, without trunks, roots, canopy or foliage blocking the view, and do the fighters separate from the ground? | 6.33 | **6.33** | +0.00 | 5.6 5.4 5.6 / 5.7 5.4 5.5 | PARTIAL / PARTIAL |

Missing frames (not judged): F41-FR:stormwood__fight__hollows_alpha-i05, F41-FR:stormwood__fight__hollows_alpha-i06, F41-FR:stormwood__fight__hollows_alpha-i07, F41-FR:stormwood__fight__hollows_alpha-i08, F41-FR:stormwood__fight__hollows_alpha-i09, F41-FR:stormwood__fight__hollows_alpha-i10, F41-FR:stormwood__fight__hollows_alpha-i11, F41-FR:stormwood__fight__hollows_alpha-i12, F41-FR:stormwood__fight__hollows_alpha-i13, F41-FR:stormwood__fight__hollows_alpha-i14, F41-FR:stormwood__fight__hollows_alpha-i15, F41-FR:stormwood__fight__hollows_alpha-i16, F41-FR:stormwood__fight__hollows_alpha-i17, F41-FR:stormwood__fight__hollows_alpha-tell2-a-start, F41-FR:stormwood__fight__hollows_alpha-tell2-b-mid, F41-FR:stormwood__fight__hollows_alpha-tell2-c-late, F41-FR:stormwood__fight__hollows_alpha-tell2-d-strike, F41-FR:stormwood__fight__hollows_alpha-tell2-e-impact, F41-FR:stormwood__fight__hollows_alpha-tell2-f-recovery

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
