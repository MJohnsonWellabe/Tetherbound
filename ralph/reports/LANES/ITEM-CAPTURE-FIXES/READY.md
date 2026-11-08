STATUS: land
BRANCH: tb/item-capture-fixes  HEAD: 002f4dca (final catch tool); this READY updated in tb/item-f38-33's merge commit

Smallest fix for each reproduced capture blocker (STATE §0 tooling lane). Each was checked in engine on CPU (xvfb, Compatibility).

| Fix | File | What | Check |
|---|---|---|---|
| a | `tools/visual_judge/quick_judge.py` `find_frame` | Carries VIS-TIDEWAKE's `quick_judge_find_frame.patch.py`. As a last resort, an id ending `<tag>-SSS_SS` takes the same-tag `<tag>-SSS.SS` frame nearest in time, whatever the drift. Main's `__fight__` fallback kept a 1.0 s window, which CPU tell times exceed (F39#28). | `tools/visual_judge/tests/test_quick_judge.py` 15/15 OK; a tell-start 1.62 s off now resolves (main returned None). |
| b | `ralph/reports/VISUAL/item-scores/job.json` (F38#19 repro) | `--hud-settle-frames=180` -> 900, so the HUD frame is past the opening fade. | JSON parses. |
| c | `tools/phase2_capture_creatures.gd` `_join_grass_clearing` | The stand turns physics off to hold a pose, so `_update_grass_clear` never ran. The seated body now joins the clearing exactly as a settled body does (radius meta, `grass_clear` group, `clearings_dirty`) and releases it on exit. | F38#26 crops: clearing ON uncovers the hare's feet, OFF buries them (`.artifacts`, local). |
| d | same tool | The `alpha_idle` pose calls `body.set_alpha(true)` as `encounter_director.gd` does in play. | F38#31 frames: the alpha trailpup now wears its alpha colourway, with the aura ring. |
| e | `tools/phase2_capture_catch.gd` | On CPU the orb resolves before the shake still, and the 1.8 s broke-free card had expired (text cleared) by `06-breakout`. Final tool (002f4dca): from the throw, the tool holds the HUD's own `_outcome_left` and `_catch_focus_left` at their raised values (topped up on every `SceneTree.process_frame` and every beat frame) until the verdict shot, then releases them; the HUD keeps processing and drawing. Holding `_catch_focus_left` keeps `hud.json catch_card.step_back_on_break` hidden through the shot. History: a first version froze the HUD's `_process` (card undrawn); c594c79d (on main via #849) held only the card timer, so the step-back panels came back mid-hold. | Full catch runs: `06-breakout` shows "Bramblebun broke free / Weaken it more, then throw again." with the step-back holding (F38#33 round 11072025). |

Parse checks: `godot --headless --check-only` clean on both tools.
Row rounds on these fixes: tb/item-f38-31 (land, 6.69 -> 6.84), tb/item-f38-26 (parked, re-score 6.53), tb/item-f38-33 and tb/item-f38-19 (see their READY files).
Known, not fixed here: on CPU the `05-orb-shakes` still shows the creature already out (the shake beat lands after the resolve); not in any F38#33 frame.
