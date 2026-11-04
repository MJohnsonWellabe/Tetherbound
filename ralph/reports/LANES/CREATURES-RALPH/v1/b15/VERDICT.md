# Visual lane v1/b15: hold-peak hit react (`hold_clip.py`) on stage (3 Nov 2026, ~23:20 UTC)

**Arm:** the hit clip of the shipped Terrapup and Burrowback (Nightburrow) GLBs, with every key after the peak deviation held at the peak pose. The game crossfades to idle once the clip ends.

**Frames:** `capture_f36_poses.gd --species=nightburrow,terrapup --whole-body --context`. Base and candidate come from the same run (`q_hold`). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.15, r 0.77, RMSE 0.51.

| Row | Item | CPU base (mapped) | Hold (mapped) | Decision |
|---|---|---|---|---|
| F38#2 (stage) | Terrapup hurt pose | 6.37 | 6.79 (+0.42) | GLB not kept |
| F36#56 | Nightburrow | 5.95 | 5.91 | GLB not kept |

**Judges:** on Terrapup the hold works. All 3/3 judges read hit-end as "a hunched recoil, head down", and the defect moves to FIXED 2 / PARTIAL 1 from PARTIAL 3. The gain is under 0.5, though. The stage row is already at or above 6.0. The board row F38#2 (world frames, 5.58) did not move with any pose change in v1/b14.

On Nightburrow the plates "swallow the face and outline", so the pose cannot read. Its next lever is fewer plates (new art), not animation.

**Pose work is parked** after b7, b14 and b15. The creature rim arm (`4e606ff6`) is the next F38#1/#2/#26 lever. Its capture is queued.
