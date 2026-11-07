# v1/b28: Tempestwing value lift ships ON; Pebbik (split), Galewisp and Glimmermoth (flat) stay OFF

**Arms:** `creatures_ralph_{glimmermoth,pebbik,galewisp,tempestwing}_value_lift`. Each is the same albedo-only recipe used in b21-b27.

**Frames:** `capture_f36_poses.gd --species=glimmermoth,pebbik,galewisp,tempestwing --whole-body --context`. Base (OFF) and candidate (ON) come from one run. Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim; 3 anchor pairs (craft, f36_0_gap C2, f36_0_npc C5); three fresh code-blind judges. `calibrate.py` linear: slope 1.26, intercept -1.16, r 0.81.

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand (j1 j2 j3) |
|---|---|---|---|---|
| Tempestwing | 5.66 | **5.87** | +0.21 | 5.7 5.5 5.0 / 5.9 5.6 5.2 |
| Pebbik | 6.92 | 7.05 | +0.13 (split) | 6.5 6.3 6.4 / 6.7 6.7 6.1 |
| Galewisp | 7.13 | 7.17 | +0.04 (flat) | 6.7 6.7 6.3 / 6.8 6.8 6.2 |
| Glimmermoth | 5.57 | 5.57 | 0 | 5.6 5.4 5.0 / same |

**Verdict:**
- **Tempestwing ships ON.** All three judges scored the candidate higher.
- **Pebbik stays OFF.** Two judges scored it higher and one lower; the lower judge said the paler coat "goes flat". Under the lane's ship rule (a majority higher and none lower), that is not a clear gain.
- **Galewisp and Glimmermoth stay OFF.** Both are flat. These bodies are already light, so the lift has nothing to fix.

**What the judges still name (pose and model, not value):**
- **Glimmermoth:** oversized glossy wings that clip the floor at faint end.
- **Tempestwing:** wings crushed into the floor at faint, and the face is lost.
- **Pebbik:** stiff tail-up, belly-up faint.
- **Galewisp:** no visible elemental trait.

**Test:** `test_dark_value_lift_flags` adds Tempestwing (5.87).

**Next:** the remaining live remakes are lighter (albedo value 0.49 and up). The value lift has run out on them: three of the four in this batch were already light and came out flat or split. The lane's next arms are the pose defects every judge names: faint-floor clipping (Glimmermoth, Tempestwing, Sirenseal), hit-mid floating (Paddlenewt, Shadelet) and upright faint tails (Shadelet, Pebbik).
