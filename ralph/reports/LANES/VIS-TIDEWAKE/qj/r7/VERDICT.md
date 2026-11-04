# Quick judge r7: F39#5, F39#14

- Head `d61b47c8f81a0ae4074bbce8555eb3e3b29a288e`, tree `1df1c750daa2`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/human_water_contact_visual.json": {"wake_trail": {"trail_lifetime_s": 2.8, "trail_spacing_m": 0.55, "trail_interval_s": 0.12, "grow_to": 2.6}}}`
- Capture: 1 launch(es); base 927s, candidate 895s, wall 1822s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.8904, intercept -4.5766, r 0.9851, anchor RMSE 0.141, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#5 | surface swimming trainer pose | 6.20 | **6.14** | -0.06 | 5.6 5.9 5.6 / 5.6 5.8 5.6 | PRESENT / PRESENT |
| F39#14 | swimmer water contact | 6.89 | **6.77** | -0.12 | 5.9 6.3 6 / 5.9 6.2 5.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

## Lane disposition

- The wake_trail tune (base = batch-11 wake_trail ON) is flat or worse on both rows, so it stays OFF and nothing ships from r7.
- F39#5 on the shipped base maps 6.20 (CPU), above the 6.0 floor; F39#14 base maps 6.89.
- All three judges: the trail reads as stamped, evenly spaced radial "pinwheel" discs; the swim still reads as wading because the legs and boots show straight down through clear water. Next F39#5 lever is the body/pose or near-surface murk, not more rings.
