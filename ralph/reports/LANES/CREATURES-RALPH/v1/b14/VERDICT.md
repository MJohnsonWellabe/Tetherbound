# Visual lane v1/b14: pose recipe in the Meadows world frames (F38#1, F38#2, F38#26) (3 Nov 2026, ~22:15 UTC)

**Arm:** the r23/r24 pose recipe applied to the live remake GLBs of Terrapup, Bramblebun, Pipwing, Burrowback, Aquaryn r9 and Ripplet:
- `ground_clip.py --settle` on the rest and faint clips
- hit hop x0.3
- the hit spine/root amplified x1.8 on Terrapup and Burrowback

The base and candidate are the `phase2_capture_creatures.gd` frames. The base (`po_base`) was captured at ~11:15–13:20 UTC and the candidate (`po_cand`) at ~15:35–21:50 UTC. Between the two runs the branch only changed things that do not appear in these creature frames (HUD flags, map paint, Stormwood and Tidewake props). CPU llvmpipe, Compatibility.

F39#6 (Tidewake faint) had no matching frames in either run and is not scored.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.43, r 0.97, anchor RMSE 0.32, no warnings.

| Row | Item | CPU base (mapped) | Pose recipe (mapped) | Decision |
|---|---|---|---|---|
| F38#1 | creature collapse and rest | 5.35 | 5.35 | GLBs not kept |
| F38#2 | hurt and movement poses | 5.58 | 5.58 | GLBs not kept |
| F38#26 | creature ground contact | 5.77 | 5.77 | GLBs not kept |

**Judges (3/3):** the two sides are identical at this camera. The creatures sit 15 m out in the shaded tree-trunk band, so they read as small dark shapes without rim light, and grass hides their feet. Pose changes do not register at that size.

**Stop rule:** this is the second consecutive round with no gain for the pose recipe (v1/b7 on the stage, v1/b14 in the world), so the recipe is **parked**. The hold-peak arm (`hold_clip.py`, queued as `q_hold`) is the last pose idea that is already captured.

The judges' consistent ask is presentation in the world: creature rim light and value separation from the tree band, plus shorter grass under creatures (`creature_grass_clear`). The catalogue camera is not moved; no camera reframing is used to hide a defect.
