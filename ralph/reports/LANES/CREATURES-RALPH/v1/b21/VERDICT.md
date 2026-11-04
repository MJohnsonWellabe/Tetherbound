# v1/b21: Mosshock value lift (F36#54) ships ON

**Arm:** `creature_coat_flags.json` `creatures_ralph_mosshock_value_lift`. It is a value-lifted copy of the live remake albedo: midtone gamma 0.78 and saturation x1.12, taking mean value from 0.33 to 0.43. Only the albedo changes.

**Frames:** `capture_f36_poses.gd --species=mosshock --whole-body --context`, base (OFF) and candidate (ON) from one run (`q_mlift.sh`). Stage set is hit 50/100 and faint 50/100. CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py` (linear, slope 1.62, intercept -3.19, r 0.91).

| Row | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect base / cand |
|---|---|---|---|---|---|
| F36#54 Mosshock | 5.63 | **6.55** | +0.92 | 5.4 5.6 5.3 / 6.0 6.1 5.9 | PRESENT / PARTIAL |

**Verdict:** ships ON (all three judges higher; recorded defect "little value separation, the face barely reads" goes from PRESENT to PARTIAL). Test: `tests/test_mosshock_value_lift_flag.gd`.

**What the judges still name:**
- The face is still small.
- The faint poses collapse into a mossy lump.
- The surface reads as uniform moss rather than hide with partial moss plates. That is new art.
