# failures — D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260916T030951Z-closeout-r6

Save-linked phases are separate raw executions; published aggregate parents are omitted to avoid double counting. Phase clocks restart at load. Raw elapsed time includes added save/load seams; route rows exclude those wrappers. No continuous timeline or cadence across boundaries is inferred. Missing telemetry is not evidence of zero activity. Analytics do not certify acceptance.
Boundary-step failures remain visible and labelled; they are not silently discarded.

15 failing steps in 8 distinct shapes.

## S03p1 · FAIL · x4
- steps: S03-32ar6, S03-32cr6, S03-32dr6, S03-32fr6
- first: **close the shell for real**
- expected: Whichever branch was taken, the shell is in ordinary grid focus by now, so this closes it -- the same unconditional 4-press sequence S03-39e..j already validated in both the fainted and nobody-fainted case.
- actual: FAIL press guard: 'menu_cancel' is not live in input_context 'world'; its binding JoyBtn:1 would fire hotbar_1 here instead -- the press was refused so the run does not act on a verb the step did not name (0 of 1 menu_cancel presses landed before the refusal, input_context 'world')

## S03p1 · FAIL · x3
- steps: S03-32b2, S03-32e2, S03-32g2
- first: **challenge it (attempt 2)**
- expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer and refuses a fainted-ally message like "Ripplet is out of the fight"/"Put Moss away" instead of misfiring into it.
- actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Bramblebun away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.

## S03p1 · SKIP · x7
- steps: S03-36b, S03-36c, S03-36e, S03-36g, S03-36h, S03-36i, S03-36j
- first: **aim and throw until caught, or out of tries (attempt 2)**
- expected: the target is caught, or every allotted throw against it is spent -- a missed throw does not end the fight (catching.json's own cooldown exists so a failed catch can be re-thrown once the wobble clears; combat_manager.gd re-engages the same target on a miss), so this keeps throwing at the SAME chipped-down target instead of treating one orb as the whole attempt.
- actual: SKIPPED throw_until_caught: not needed (combat_running=false (wanted false))

## S03p1 · FAIL · x2
- steps: S03-36d, S03-36f
- first: **aim and throw until caught, or out of tries (attempt 4)**
- expected: the target is caught, or every allotted throw against it is spent -- a missed throw does not end the fight (catching.json's own cooldown exists so a failed catch can be re-thrown once the wobble clears; combat_manager.gd re-engages the same target on a miss), so this keeps throwing at the SAME chipped-down target instead of treating one orb as the whole attempt.
- actual: FAIL throw_until_caught: fight ended after throw 2 without a catch (throw 1 (tracked), throw 2 (untracked))

## S03p1 · FAIL · x2
- steps: S03-32e, S03-32g
- first: **walk to a live bramblebun (attempt 5)**
- expected: RIG-16: tracks a live bramblebun's own position every frame instead of a fixed cluster-centre coordinate.
- actual: FAIL did not reach bramblebun (species_id, #2 nearest of 76 (Wild_bramblebun_0_1, Wild_bramblebun_0_2, Wild_bramblebun_0_3, Wild_bramblebun_1003_1, Wild_bramblebun_1003_2, Wild_bramblebun_1006_1, ...)) in 3000 walking frames; stopped 19.8 m short at (15.0, 1.0, -55.0) (0 held)

## S03p1 · FAIL · x1
- steps: S03-32h2
- first: **challenge it (attempt 8)**
- expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer and refuses a fainted-ally message like "Ripplet is out of the fight"/"Put Moss away" instead of misfiring into it.
- actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Put Moss away", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.

## S03p1 · FAIL · x2
- steps: S03-32i2, S03-32j2
- first: **challenge it (attempt 9)**
- expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer and refuses a fainted-ally message like "Ripplet is out of the fight"/"Put Moss away" instead of misfiring into it.
- actual: FAIL the live prompt is "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Chop", which does not contain "Engage" -- pressing here would activate a different provider. Not pressed.

## S03p1 · FAIL · x1
- steps: S03-39
- first: **the team is five**
- expected: data/config/tournament.json entry.min_party_size is 5 and objectives.json's tournament_build_team says 'Build your full team of five for the village tournament.' The old `min: 3` predates FIRST-HOUR-FUN-REBUILD. Five is also the hard ownership cap (autoload/party.gd MAX_CREATURES), so this is the complete permanent team, never storage or a reserve.
- actual: party size 4 (wanted >= 5)
