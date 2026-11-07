# Quick judge f38_20-keep-big: F38#20

- Head `35efb1fb39d2f7354a1dc613315e4aa54935ad6d`, tree `8cfc94f7f7c5`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_003_candidate": {"keep": {"width_m": 210.0, "offset": [0.0, 0.0, 149.2]}, "add_companions": [{"id": "crag", "path": "res://assets/props/meshy-1024/meadows_cliff_a/meadows_cliff_a.glb", "width_m": 280.0, "offset": [0.0, -10.0, 158.6], "yaw_deg": 180.0, "albedo_tint": "#9a958c", "fog_disable": true, "_why_on": "F38#20 r5 (VIS-MEADOWS, 4 Nov 2026): CPU 5.87 -> 6.05 (+0.18, all three judges prefer it; quick_judge f38_20-crag2, slope 1.07 r 0.76 RMSE 0.78, anchor-residual caveat; ralph/reports/LANES/VIS-MEADOWS/qj/f38_20-crag2/). The judges read the keep as floating on the skyline with no base; the installed Meshy meadows_cliff_a (230 x 112 m) stands behind the hall's last chamber (front face about z 110 > 103), its top about 107 m up the keep, so the keep rises from a rock crag. Visual only: no collision, route or save change. Owner 4 Nov: a judged gain ships ON."}]}}}`
- Capture: 2 launch(es); base 398s, candidate 390s, wall 788s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1769, intercept -0.8656, r 0.8774, anchor RMSE 0.41, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 6.08 | **6.20** | +0.12 | 6.2 5.6 5.9 / 6.3 5.7 6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
