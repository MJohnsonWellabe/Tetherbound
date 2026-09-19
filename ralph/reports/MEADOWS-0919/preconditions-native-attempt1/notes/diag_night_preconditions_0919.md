# diag_night_preconditions_0919 — Diagnostic physical redeployment after bed recall and earned harvest flags

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 16 s over 17099 frames at 0.0006 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/preconditions-0919-attempt1/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.25
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260919-meadows-r17/S03p3/saves/S03-exit.json (4195381 bytes)
- events: t=0.25
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 658 ms (30 settle frames); re-priced at boot:title: 24887 physics waits at 0.01392 s, 978 process waits at 0.00061 s and 0.0 fixed seconds = 347 s against 14399 s remaining
- events: t=0.77
- verdict: PASS

### D04 — focus_move
- expected: Load Game focused
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@33) -> 'Load Game' (@Button@34)
- events: t=0.80
- verdict: PASS

### D05 — press
- expected: Real slot picker
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=0.92
- verdict: PASS

### D06 — press
- expected: Production save loaded
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=1.75
- verdict: PASS

### D07 — wait_until
- expected: Live world ready
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1.75
- verdict: PASS

### D08 — press
- expected: Deploy earned party member
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=2.45
- verdict: PASS

### D08b — wait_until
- expected: Verify actual deployment before physically reproducing recall
- actual: living active companion visibly deployed=true [true after 0 physics frames]
- events: t=2.45
- verdict: PASS

### D08c — press
- expected: Physically recall the companion as the campaign bed sequence did
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=3.70
- verdict: PASS

### D09 — teleport
- expected: DIAG setup at original pre-night camp position; not acceptance travel
- actual: DIAG teleport to (-8, -38); distance/dead-travel accumulators reset
- events: t=4.70
- verdict: PASS

### S03-66-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:0.0 for the authored wood node at [16.0, -28.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:0.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-68-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:7.0 for the authored fiber node at [12.0, -22.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:7.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-70-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:10.0 for the authored berries node at [20.0, -16.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:10.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-72-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:4.0 for the authored stone node at [22.0, -34.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:4.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-74-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1023.0 for the authored fiber node at [24.0, -24.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1023.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-76-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1021.0 for the authored wood node at [36.0, -16.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1021.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-78-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1027.0 for the authored fiber node at [31.0, -32.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1027.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-80-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:2.0 for the authored wood node at [40.5, -28.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:2.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-82-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:5.0 for the authored stone node at [47.0, -34.5]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:5.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-84-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:11.0 for the authored berries node at [38.0, -36.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:11.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-86-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1024.0 for the authored fiber node at [46.0, -40.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1024.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-88-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1.0 for the authored wood node at [26.0, -44.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-90-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:8.0 for the authored fiber node at [34.0, -46.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:8.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-92-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1020.0 for the authored wood node at [7.0, -24.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1020.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-94-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1025.0 for the authored fiber node at [2.0, -30.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1025.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-96-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:9.0 for the authored fiber node at [-2.0, -20.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:9.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-98-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1022.0 for the authored wood node at [-14.0, -8.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1022.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-100-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:1026.0 for the authored fiber node at [-10.0, -14.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:1026.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-102-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:6.0 for the authored stone node at [-18.0, 6.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:6.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-104-again — verify the exact authored node is depleted
- expected: The successful first interaction must set harvest_node:order:3.0 for the authored wood node at [-8.0, 8.0]. Production nodes deplete in one ledger claim; verify that outcome instead of pressing again at an absent prompt.
- actual: flag harvest_node:order:3.0 set (wanted set)
- events: t=4.70
- verdict: PASS

### S03-216a — call out a companion after the creature bed interaction
- expected: With world input, press physical RB to deploy after the creature-bed recall; the bed may own the X prompt but RB is its separate mapped verb. Omit only when the exact living active companion already has a visible body; the next step verifies deployment.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=6.35
- verdict: PASS

### S03-216b — verify companion deployment has finished
- expected: The active earned creature has an actual visible world body before selecting a pilot.
- actual: living active companion visibly deployed=true [true after 0 physics frames]
- events: t=6.35
- verdict: PASS

### S03-216c — select a healthy earned pilot for the night fight
- expected: Use physical party cycling and verify the healthiest living non-resting earned companion before approaching a wild.
- actual: physical world pilot selection: {"no_input":true,"ok":true,"physics_frames":0,"presses":0,"process_frames":0,"selected_index":0,"why":"healthiest earned creature and actual companion verified; 0 physical LB taps"}
- events: t=6.35
- verdict: PASS

### S03-217 — approach a living wild creature by torchlight
- expected: Section E.1 CB-13: a night fight under torch conditions
- actual: walked 28.3 m to poi:wild (poi kind, nearest of 1028 (Wild_bramblebun_0_1, Wild_bramblebun_0_2, Wild_bramblebun_0_3, Wild_mudsnout_1_1, Wild_mudsnout_1_2, Wild_trailpup_2_1, ...); selected /root/MeadowsPlayground/Wild_mudsnout_1070_2) in 343 walking frames (0 held)
- events: t=12.08
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S03-218 — engage a wild creature at night
- expected: CB-13's night case
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Engage Mudsnout" (provider 'EncounterDirector'): context world -> combat
- events: t=14.62
- verdict: PASS

### S03-221 — fight by torchlight
- expected: Win the selected night encounter through production combat and observe live victory XP; unfinished combat or a loss remains a failure.
- actual: fought 334 frames: 8 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 90 frames; production won exit and live XP progress verified
- events: t=21.45
- verdict: PASS
- observation: Bound inherited from the replaced attack and wait pair: 22 taps cost 44 physics plus 704 process waits; the following eight-second wait cost 480 physics, for 1228 total awaited frames. At gap18, fight budget1100 is priced at1120 physics plus106 process waits (1226 total). This reallocates idle waits into active combat and does not assert equal physics-only duration. The bound is not widened if the live fight cannot finish. S03-222 independently checks that combat ended.

### S03-222 — verify the night fight ended
- expected: rewards and control return
- actual: combat_running=false (wanted false)
- events: t=21.45
- verdict: PASS
