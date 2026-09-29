# F14#0 Tess: serial-lane C3 round on main with the Mirejaw side-on camera (BAR written before rendering)

**Build:** `tb/closer` at 3adba568 = main f4ebca9e (contact spacing merged via #442) plus one change: Tess's Mirejaw combat override `camera_composition_yaw_deg` 70 and `camera_trainer_beside_ally` (presentation only; `combat_manager.gd::_take_camera`, `_stand_the_trainer_aside`). No combat number changed.

**Render (the fixed final-round parameters, unchanged):** the command in `ralph/reports/TIDEWAKE/phase1/f14_0/tess_final/BAR.md`, via render.yml (opengl3, xvfb, 1280x720), `--out` renamed only.

**Frames judged:** every frame the render writes (`frames.json`); an empty or unreadable frame makes the round invalid (infrastructure), not re-rolled.

**Rubric:** `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`, unchanged, handed to each judge before any frame. Two code-blind judges (sonnet and default model) using `ralph/reports/TIDEWAKE/phase1/f14_0/tess_final/JUDGE_PROMPT.md` verbatim, then one strict re-check.

**Pass line (all three):** Judge A >= 90%; Judge B >= 90%; every tell-start frame shows its ground marking for both judges.

**Fail conditions I will record, not argue away:** any Mirejaw frame where a head is covered by the other fighter or the trainer; Mirejaw mostly off-screen; a tell-start with no marking; the trainer covering the ally's head (new risk from the beside-the-ally stand); the camera inside a boulder or wall.

**Last result for reference (spacing round 2, b2ce4df6):** judge A 92.1% (rule 5 on 3 tell-starts), judge B 81.6% (4 Mirejaw ally-over-head, 2 trainer-over-head, 1 off-screen).

**Limit:** two attempts on this root cause. Judge B is stricter and variable; the rubric is used unchanged and judge noise is not chased.
