# P2-016 (24 Oct 2026): hurt poses keep the idle silhouette in a real fight

Source: the coordinator's GPU F38 fight scan (tb/gpu-pass `ralph/reports/GPU-PASS/F38-0/main-1024/VERDICT.md`, South Bridge grunt and Warden Aldis).

Who fights there:
- Grunt: Mudsnout and Burrowback, both naturalistic remakes playing their own clips.
- Warden Aldis: Burrowback, Galecrest, Brooktail, Meadowhart and Tuskroot.
  - Brooktail and Tuskroot play their f36 recipes, which are ON.
  - Meadowhart is a remake.
  - Galecrest plays its installed clips; its recipe was judged worse on GPU.

Root cause (scripts/creatures/creature_animator.gd):
- Only an installed f36 recipe hit started at its impact sample and held it through hitstop and same-step movement.
- A remake's own held hit clip started at frame 0, its neutral lead-in, so hitstop froze that frame. The next movement request then cancelled the hold.
- A real fight frame therefore showed the idle silhouette, even though the stage capture (fixed timing) showed the wince.

Fix (tb/creatures-land 879fd9c1c):
- species.json `hit_impact` (start 0.12, release 0.5) is set on the 15 naturalistic remakes whose clip script has that held-shove shape.
- The animator treats a named window like a recipe's: it starts at the wince and holds until release.
- Species without a window behave as before.

Checks:
- New tests/test_creature_hit_impact_window.gd.
- Telegraph animation, f36_pose, rest_pose, companion_presence, combat_feedback, hitstop and flinch: 62 tests, 0 failed.

Real-fight check on CPU:
- Capture: `capture_named_fight.gd --trainer=south_bridge_grunt --frames=24 --interval=0.15 --attack`, before (top) and after (bottom). The sheet shows frames 2, 8, 12-16, 18 and 21, cropped on the enemy.
- The fights drift between runs, so the frames are not matched one to one.
  - Before: none of the 9 shows Mudsnout's wince; it is standing in every clear frame.
  - After: frame 14 shows the rear-back recoil.

Second cause seen in both runs, which is not a pose issue: on the impact frame, the tan hit-spark disc covers the struck creature's body (frames 13, 16 and 21). Shrinking that disc, or moving it off-centre to the contact point, would let the wince read. That is effects work, not this row's.
