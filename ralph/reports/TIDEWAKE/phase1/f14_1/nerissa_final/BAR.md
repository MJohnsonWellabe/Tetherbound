# F14#1 Veilfall / Guardian (Nerissa): final C3 round, bar fixed before rendering

This is the coordinator's single final round, with the owner's approval. It is written and committed before any frame is rendered. There is one render, both judges run once, then the strict re-check. On a pass, the round lands. On a fail, STATE records the exact remaining defects and the lane stops.

**Build:**
- main at the Combat Spacing PR's merge commit, as sent by that lane. tb/tidewake merges it with no other change.
- Stated in the round's README as the commit SHA.

**Render (the r17 parameters, unchanged):**
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script res://tests/capture_tidewake_named_fights.gd -- --trainer=water_trainer_nerissa \
  --out=res://shots/tidewake/nerissa_final --pilot=READER --level=43 --interval=16 \
  --tells-per-opponent=3 --max-frames=90 --cap-s=700 --render-only-saves
```
- Disclosed shortcut, as in r15-r17: the player is placed at Nerissa in the Heart Chamber, which has a 9 m ring.

**Frames judged:** every frame the render writes, and no others.
- `t-*`: the timed samples every 16 s of active combat.
- `hit-*`: the landed hits.
- `tell-start-*` and `tell-ended-*`: three tells per opponent.
- The full list is `frames.json`, from the one render.
- A frame the render wrote empty or unreadable makes the round invalid. That is recorded as an infrastructure failure, not re-rolled.

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

Framing is PASS / (PASS + FAIL); EXCLUDED frames leave the denominator. Anything under that is a fail. The 0.25 s occlusion clause is unverified from stills.

**Last result for reference:** r17 scored 98% / 83%, with tells 12/12. Judge B's failures were contact-range rule 3.

**Strict re-check after judging:** an independent agent re-reads both verdicts against this BAR and the frames. It checks the arithmetic, that every frame was judged, and that the rubric was applied as written.
