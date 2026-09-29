# F14#1 Nerissa: serial-lane C3 round, ordinary-side placement (BAR written before rendering)

**What changed, disclosed first.** The fixed final-round command (`ralph/reports/TIDEWAKE/phase1/f14_1/nerissa_final/BAR.md`) places the player on the trainer's +Z side, which for Nerissa is the crystal side of the Heart Chamber (interior z 100+). The judged frames of every earlier round (r15-r19) show her fights beside the containment crystal and its plinth blocks (fighter interior z 101-116, crystal at (0, 5, 113)); the crate frames judge B failed come from that. The ordinary route enters at z 4 and reaches her from the south, where her fights form about 8 m south of her stand (`data/config/water_veilfall.json` `_why_captain_position`, `tests/test_water_veilfall_arena_bounds.gd`), far from the crystal. This round adds an opt-in capture flag `--stand=south` (`tests/capture_tidewake_named_fights.gd`) that puts the player 2.7 m south of her, and nothing else about the capture changes. **This is a different placement from r15-r19, not a fix to the game**: no game code changes in this round. A pass here shows the ordinary-side fights frame well; it does not show the crystal-side placement frames well, and the two are reported separately.

**Build:** `tb/closer` on main 75b825b0 (contact spacing, #442; Tess camera, #444) plus the capture flag only.

**Render:**
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script res://tests/capture_tidewake_named_fights.gd -- --trainer=water_trainer_nerissa --stand=south \
  --out=res://shots/closer/nerissa --pilot=READER --level=43 --interval=16 \
  --tells-per-opponent=3 --max-frames=90 --cap-s=700 --render-only-saves
```
Run through render.yml (opengl3, 1280x720). Every other parameter is the fixed r17/r19 one.

**Frames judged:** every frame the render writes (`frames.json`); an empty or unreadable frame makes the round invalid.

**Rubric:** `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`, unchanged, handed to each judge before any frame. Two code-blind judges (sonnet and default model) with the verbatim prompt of `ralph/reports/TIDEWAKE/phase1/f14_0/tess_final/JUDGE_PROMPT.md` (folder substituted), then one strict re-check by an independent agent that is told about the placement change above.

**Pass line (all three):** Judge A >= 90%; Judge B >= 90%; every tell-start frame marked for both judges.

**Fail conditions I will record, not argue away:** any head covered by scenery, the other fighter or the trainer; a combatant mostly off-screen; a tell-start with no marking; the camera in geometry.

**Reference (r19, crystal-side placement, spacing round 2):** judge A 91.3%, judge B 87.0%, tell markings 8/8.

**Limits:** one render; two attempts on this root cause; stills cannot test the 0.25 s clause. If it passes, F14#1 is recorded as met on the ordinary-side placement with this caveat in the board, and STATE says the crystal-side placement was not re-passed.

## Round 1 result (recorded, not argued): FAIL by 0.7 points
Ordinary-side placement, `r1/`, main 75b825b0 plus the capture flag. Judge A (sonnet) 50/56 = 89.3% (below 90%); judge B (default model) 49/53 = 92.5%; tell-start markings 12/12 for both. The pass line needs both judges at 90% or above, so round 1 did not pass, and no strict re-check was run on a failed round. Failures both judges shared: tell-start-000.27 and tell-ended-000.57 (rule 1, Cannonback half or mostly off the right edge at the fight opening), tell-start-193.25 (rule 4, Riverdrake's head under the enemy panel), tell-ended-273.02 (rule 4, Riptusk from behind, head lost at the action panel). Judge A only: tell-start-274.77 and tell-ended-274.87 (rule 3, marginal, the human over Ripplet's face). Crate frames: none (the crystal is more than 12 m from every fight in this placement).

## Round 2 (attempt 2, written before rendering)
**One root cause addressed:** the Cannonback opening crop. `data/config/water_characters.json`: Nerissa's Cannonback combat override gets `camera_composition_yaw_deg` 20 (Nerissa's other team members and the shared 35 degrees are unchanged; the key and its accessor already exist from #444). Presentation only.
**Not addressed, expected to remain:** the Riverdrake head under the panel (1 frame), the Riptusk rear view (1 frame), the marginal human-over-face calls (judge A, 2 frames). With Cannonback's two frames fixed, judge A would have 4 failures (about 92.9%) and judge B 2 of 53 (about 96%); the round still fails if the new yaw creates other failures.
**Render, judging and pass line:** identical to round 1 (same command and `--stand=south`, output `res://shots/closer/nerissa_r2`), rubric unchanged, both judges at 90% or above and every tell-start marked, strict re-check told about the placement change. If round 2 fails, the exact remaining defects go in STATE and this lane stops on F14#1: two attempts.
