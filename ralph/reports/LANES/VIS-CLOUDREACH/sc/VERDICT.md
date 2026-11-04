# sc: P2-105 (F40#6) earlier scramble, 4 Nov 2026

Arm: `cloudreach_physical_runtime.json:mounted_drop_no_air_drive.scramble_after_s` 0.7 -> 0.3 (quick_judge `qj_scramble03`, tree 676deacee0f8; landing_tree_clear, low_mist and the scramble already ON in both arms).
Frames: terrace 1.0 s, terrace after recovery, terrace road back 1.5 s (CPU, Compatibility, 1920x1080). Three fresh code-blind judges, standard JUDGE_PROMPT, 3 anchor pairs (craft, f36_0_npc, p2_094_r4; seed 1717); `calibrate.py` linear, r 0.97, anchor RMSE 0.31 -> `calibrated.json`.

| Arm | Raw judges | Measured | Mapped |
|---|---|---|---|
| base (0.7 s) | 5.0 / 4.6 / 4.9 | 4.83 | 4.38 |
| candidate (0.3 s) | 5.7 / 6.0 / 6.0 | 5.90 | **6.10** |

Gain +1.72 mapped; the recorded defect ("upright riding silhouette ... unsupported across the cloud floor") FIXED 3/3 on the candidate, PRESENT 3/3 on the base. **Ships ON.** The scramble still fires only with no walkable floor within 100 m under the mount (survivable ride-offs land as before; the saddle-remount smoke's ledge leg covers that).

Next for P2-105, from the judges: flat cloud volume and uniform grass carpet on the terrace; the deer and rider read small from behind.
