# F14#0 Tess: final C3 round, bar fixed before rendering

This is the coordinator's single final round, with the owner's approval. It is written and committed before any frame is rendered. There is one render, both judges run once, then the strict re-check. On a pass, the round lands. On a fail, STATE records the exact remaining defects and the lane stops.

**Build:**
- main at the Combat Spacing PR's merge commit, as sent by that lane. tb/tidewake merges it with no other change.
- Stated in the round's README as the commit SHA.

**Render (the r5 parameters, unchanged):**
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script res://tests/capture_tidewake_named_fights.gd -- --trainer=water_trainer_tess \
  --approach=sluice_isle_to_deep_watch_arrival --out=res://shots/tidewake/tess_final --pilot=READER \
  --level=43 --interval=12 --tells-per-opponent=2 --max-frames=48 --cap-s=500 --render-only-saves
```
- The route is the ordinary one: a stick walk from the Deep Watch landing, `creature_recall`, then the challenge prompt.

**Frames judged:** every frame the render writes, and no others.
- `t-*`: the timed samples every 12 s of active combat.
- `hit-*`: the landed hits.
- `tell-start-*` and `tell-ended-*`: two tells per opponent.
- The full list is `frames.json`, from the one render.
- A frame the render wrote empty or unreadable (for example from a full disk) makes the round invalid. That is recorded as an infrastructure failure, not re-rolled for a better sample.

**Rubric:** `../../C3_RUBRIC.md`, unchanged and handed to each judge before any frame.
- EXCLUDED: a knocked-out, downed, 0-HP or absent fighter.
- FAIL rule 1: a combatant is mostly off-screen.
- FAIL rule 2: the camera is inside or behind geometry.
- FAIL rule 3: the other fighter, a human or scenery covers a combatant's head.
- FAIL rule 4: a HUD panel covers a head.
- FAIL rule 5: a tell-start frame has no ground marking.

**Pass line:** all three must hold.
- Judge A (sonnet) framing ≥ 90%.
- Judge B (default model) framing ≥ 90%.
- Every tell-start frame shows its marking, for both judges.

Framing is PASS / (PASS + FAIL); EXCLUDED frames leave the denominator. Anything under that is a fail. Stills cannot test the 0.25 s occlusion clause, so it is reported as unverified.

**Last result for reference:** r5 scored 97% / 84%. Judge B failed six frames under rule 3 at contact range, 4.7-6.6 m.

**Strict re-check after judging:** an independent agent re-reads both verdicts against this BAR and the frames. It checks the arithmetic, that every frame was judged, and that the rubric was applied as written.
