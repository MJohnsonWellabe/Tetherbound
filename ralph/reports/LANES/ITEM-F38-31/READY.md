STATUS: land
BRANCH: tb/item-f38-31  HEAD: (this commit; see git log)

Depends on tb/item-capture-fixes (4e3f0cc0, branched from it): the base needs the fixed alpha stand.

- Row: F38#31 P2-019 alpha rarity read (Meadows). Live 6.16 CPU (old stand, which never called set_alpha) / GPU 5.65.
- Fixed-stand base: CPU mapped 6.69. Best: 6.84 (+0.15), CPU, round `ralph/reports/LANES/LANE-KIT/qj/F38-31-01cde1ac0ff1-11071806/` (three judges, r 0.90, RMSE 0.51; raw base 5.7/6.3/5.9, cand 5.9/6.3/6.0).
- Flag ON: `data/config/creatures_visual.json:alpha_presence_1105.enabled` (12 motes, 0.2 body radius, 0.95 alpha, rim 1.0; gold, no red), `_why_on` names the round.
- Test flipped: `tests/smoke_alpha_aura_geometry.gd` EXPECTED_VERTICES 19872 (7-mote OFF state) -> 34560 (ON). Run under xvfb: PASS 126/126 cases, 69628/69628 checks.
- Files: creatures_visual.json, smoke_alpha_aura_geometry.gd, this READY, the qj verdict dir.
- Left OFF: nothing new.
- Judges' remaining asks: the defect is still PRESENT for 2 of 3 judges (PARTIAL for 1). They want a staged presence: a stance, a ground mark or aura in the creature's element, and a clear scale step above the trainer (frame 2's alpha trailpup reads about trainer height behind him). Brooktail's alpha (dark coat, aqua spots) reads by colour only.
- Next idea: an element-coloured ground ring under alphas, or a stronger alpha rim tuned against the bright Meadows grass. Alpha scale is a creature_scale_flags.json question (not this lane's file).
