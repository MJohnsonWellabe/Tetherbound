# v1/b22: Nightburrow value lift (F36#56) ships ON

**Arm:** `creature_coat_flags.json` `creatures_ralph_nightburrow_value_lift`. It is a value-lifted copy of the live partial-plates albedo: midtone gamma 0.78 and saturation x1.12, taking mean value from 0.31 to 0.41. It merges over `creatures_ralph_nightburrow_partial_plates`, so that arm's glow map and energy are kept.

**Frames:** `capture_f36_poses.gd --species=nightburrow --whole-body --context`, base (OFF) and candidate (ON) from one run (`q_nlift.sh`). Stage set is hit 50/100 and faint 50/100. CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py` (linear, slope 1.58, intercept -3.32, r 0.99).

| Row | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect base / cand |
|---|---|---|---|---|---|
| F36#56 Nightburrow | 6.01 | **7.06** | +1.05 | 5.8 6.1 5.8 / 6.5 6.6 6.6 | PRESENT, PARTIAL, PRESENT / PARTIAL, FIXED, PARTIAL |

**Verdict:** ships ON; all three judges score it higher.
- **Tests:** `test_nightburrow_partial_plates_flag` now checks that the plates arm still resolves with the lift OFF, and that the shipped lift sits on top and keeps the glow map.

**What the judges still name:**
- Face and eyes barely findable at stage distance.
- No glowing element visible.
- A noisy orange mottle on the hide.
