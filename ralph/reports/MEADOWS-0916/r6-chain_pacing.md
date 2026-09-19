# chapter pacing — D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260916T030951Z-closeout-r6

Save-linked phases are separate raw executions; published aggregate parents are omitted to avoid double counting. Phase clocks restart at load. Raw elapsed time includes added save/load seams; route rows exclude those wrappers. No continuous timeline or cadence across boundaries is inferred. Missing telemetry is not evidence of zero activity. Analytics do not certify acceptance.
Phase play_s is unavailable; phase route spans are lower-bound observations listed separately. Phase verdict counts include explicitly added seam steps. Totals of play_s cover unsplit rows only; wall totals cover known per-execution durations (chain log preferred, metadata fallback).

| seg | play_s | wall_s | walk_m | dead_m | dead_s | P | F | SKIP | defects | ms |
|---|---|---|---|---|---|---|---|---|---|---|
| S01 | — | — | — | — | — | — | — | — | — | — |
| S02 | 332 | — | 124 | 38 | 21 | 87 | 0 | 0 | 0 | 33.6 |
| S03p1 | — | 732.66 | 495 | 0 | — | 171 | 15 | 7 | 15 | 38.8 |
| S03p2 | — | — | — | — | — | — | — | — | — | — |
| S03p3 | — | — | — | — | — | — | — | — | — | — |
| S04 | — | — | — | — | — | — | — | — | — | — |
| S05 | — | — | — | — | — | — | — | — | — | — |
| S06 | — | — | — | — | — | — | — | — | — | — |
| S07 | — | — | — | — | — | — | — | — | — | — |
| S08 | — | — | — | — | — | — | — | — | — | — |
| S09 | — | — | — | — | — | — | — | — | — | — |
| S10a | — | — | — | — | — | — | — | — | — | — |
| S10b | — | — | — | — | — | — | — | — | — | — |
| S10c | — | — | — | — | — | — | — | — | — | — |
| S10d | — | — | — | — | — | — | — | — | — | — |
| S10e | — | — | — | — | — | — | — | — | — | — |
| **total** | **332** (0.09 h) | **733** (0.20 h) | **618** | | | **258** | **15** | **7** | | |

## phase clocks and cumulative receipt metrics
Sum of known raw phase play clocks (including seams): 546.72 s across 1/1 phase reports; separate execution durations, not a continuous timeline.
- S03p1: raw play=546.72 s; raw wall=732.66 s; original-route observed span=538.13 s; cumulative original metrics={"dead_travel_m": 0.0, "dead_travel_peak": 0.332710444927216, "distance_m": 537.341197546146, "since_interaction_s": 83.3999999999966, "trace_rows": 1030}; aggregate published=False. unavailable: legacy events lack reliable per-step ownership

## encounter cadence
| seg | catch | fight | landmark | objective | resource | talk |
|---|---|---|---|---|---|---|
| S02 | 6 | 2 | 4 | 5 | 3 | 12 |
| S03p1 | — | — | — | — | — | — |

## defects
- **S03p1** `SHIP` — expected: Whichever branch was taken, the shell is in ordinary grid focus by now, so this closes it -- the same unconditional 4-press sequence S03-39e..j already validate / actual: FAIL press guard: 'menu_cancel' is not live in input_context 'world'; its binding JoyBtn:1 would fire hotbar_1 here instead -- the press was refused so the run does not act on a verb the step did not name (0 of 1 menu_cancel presses landed
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Bramblebun away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: Whichever branch was taken, the shell is in ordinary grid focus by now, so this closes it -- the same unconditional 4-press sequence S03-39e..j already validate / actual: FAIL press guard: 'menu_cancel' is not live in input_context 'world'; its binding JoyBtn:1 would fire hotbar_1 here instead -- the press was refused so the run does not act on a verb the step did not name (0 of 1 menu_cancel presses landed
- **S03p1** `SHIP` — expected: the target is caught, or every allotted throw against it is spent -- a missed throw does not end the fight (catching.json's own cooldown exists so a failed catc / actual: FAIL throw_until_caught: fight ended after throw 2 without a catch (throw 1 (tracked), throw 2 (untracked))
- **S03p1** `SHIP` — expected: Whichever branch was taken, the shell is in ordinary grid focus by now, so this closes it -- the same unconditional 4-press sequence S03-39e..j already validate / actual: FAIL press guard: 'menu_cancel' is not live in input_context 'world'; its binding JoyBtn:1 would fire hotbar_1 here instead -- the press was refused so the run does not act on a verb the step did not name (0 of 1 menu_cancel presses landed
- **S03p1** `SHIP` — expected: RIG-16: tracks a live bramblebun's own position every frame instead of a fixed cluster-centre coordinate. / actual: FAIL did not reach bramblebun (species_id, #2 nearest of 76 (Wild_bramblebun_0_1, Wild_bramblebun_0_2, Wild_bramblebun_0_3, Wild_bramblebun_1003_1, Wild_bramblebun_1003_2, Wild_bramblebun_1006_1, ...)) in 3000 walking frames; stopped 19.8 m
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Bramblebun away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: the target is caught, or every allotted throw against it is spent -- a missed throw does not end the fight (catching.json's own cooldown exists so a failed catc / actual: FAIL throw_until_caught: fight ended after throw 2 without a catch (throw 1 (untracked), throw 2 (untracked))
- **S03p1** `SHIP` — expected: Whichever branch was taken, the shell is in ordinary grid focus by now, so this closes it -- the same unconditional 4-press sequence S03-39e..j already validate / actual: FAIL press guard: 'menu_cancel' is not live in input_context 'world'; its binding JoyBtn:1 would fire hotbar_1 here instead -- the press was refused so the run does not act on a verb the step did not name (0 of 1 menu_cancel presses landed
- **S03p1** `SHIP` — expected: RIG-16: tracks a live bramblebun's own position every frame instead of a fixed cluster-centre coordinate. / actual: FAIL did not reach bramblebun (species_id, nearest of 76 (Wild_bramblebun_0_1, Wild_bramblebun_0_2, Wild_bramblebun_0_3, Wild_bramblebun_1003_1, Wild_bramblebun_1003_2, Wild_bramblebun_1006_1, ...)) in 3000 walking frames; stopped 6.5 m sho
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Bramblebun away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Moss away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Chop", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer an / actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Chop", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.
- **S03p1** `SHIP` — expected: data/config/tournament.json entry.min_party_size is 5 and objectives.json's tournament_build_team says 'Build your full team of five for the village tournament. / actual: party size 4 (wanted >= 5)

## regions visited
- S02: grandpas_village (605 rows)
- S03p1: grandpas_village (699 rows), the_rise (331 rows)
