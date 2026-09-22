# diag_oskar_approach_0919 — Diagnostic physical Mira to Oskar approach west of tournament bench

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 23 s over 17205 frames at 0.0006 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/oskar-0919-attempt1/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.23
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260919-meadows-r15/S03p1/saves/S03p1-exit.json (4193343 bytes)
- events: t=0.23
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 500 ms (30 settle frames); re-priced at boot:title: 36715 physics waits at 0.01471 s, 2088 process waits at 0.00054 s and 0.0 fixed seconds = 541 s against 14399 s remaining
- events: t=0.75
- verdict: PASS

### D04 — focus_move
- expected: Load Game focused
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@33) -> 'Load Game' (@Button@34)
- events: t=0.78
- verdict: PASS

### D05 — press
- expected: Real slot picker
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=0.87
- verdict: PASS

### D06 — press
- expected: Production save loaded
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=1.77
- verdict: PASS

### D07 — wait_until
- expected: Live world ready
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1.77
- verdict: PASS

### D08 — press
- expected: Deploy earned party member
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=2.38
- verdict: PASS

### D09 — teleport
- expected: DIAG setup at Mira doorway; not campaign travel
- actual: DIAG teleport to (14, 5); distance/dead-travel accumulators reset
- events: t=3.38
- verdict: PASS

### S03-59b — clear the south-west shop corner on the public street
- expected: Clear the rotated cottage south wall before turning toward its rear pen; do not ask the walker to cross the shop interior walls.
- actual: walked 3.5 m to (14, 9) in 44 walking frames (0 held)
- events: t=4.13
- verdict: PASS

### S03-59c — walk around the south side of Mira's shop to Oskar's pen
- expected: Reach the west side of the bench before turning toward live Oskar
- actual: walked 8.9 m to (23, 9) in 108 walking frames (0 held)
- events: t=5.95
- verdict: PASS

### S03-60 — walk past Oskar on the way back
- expected: Reach the live Oskar at the creature pen behind the shop, after clearing the shop south wall via the authored exterior waypoints.
- actual: walked 3.7 m to Oskar (node name; selected /root/MeadowsPlayground/VillageNPCs/Oskar) in 46 walking frames (0 held)
- events: t=6.73
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S03-61 — speak to Oskar
- expected: RT-02's third stop; section E.6.14 records what each villager re-offers
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Greet Oskar" (provider 'Interactable'): context world -> narrative_modal
- events: t=8.07
- verdict: PASS

### S03-62 — hear him out
- expected: record what the line acknowledges about the player's progress
- actual: pressed interact x10 (tap, 1 frames each) on the default device, resolved to JoyBtn:2 [unchecked against input_contexts.json: input_context 'panel:SwapPanel' is not in input_contexts.json]
- events: t=13.08
- verdict: PASS

### S03-62a — close Oskar's creature swap without trading
- expected: S03 does not exercise creature trading (that is X-lab territory); back out to world control with nothing swapped. T2-GATEF-RUN5. Oskar's greeting ends with `shop:creatures:oskar` (data/dialogue/village.json), which sequence_director.gd::_maybe_open_shop() opens as a SwapPanel the moment his dialogue box closes -- exactly the way Mira's greeting opens her goods shop. Mira's is closed by S03-56 and the world re-asserted by S03-56a; Oskar's was never closed at all. Nobody noticed for four sessions because GAME-8 meant the walk to Oskar never arrived and his dialogue never ran. With GAME-8 fixed, this run's telemetry shows `input_context` pinned at 'panel:SwapPanel' from S03-62 to the end of the segment: every hotbar_N press after it was swallowed by playground_hud.gd::_world_input_allowed() (so equipped stayed {hotbar_slot: -1, item: ""} despite a correctly bound bar), and every walk reported '0 held' while never leaving (19,-6), because a panel owning input is not the same thing as locomotion being disabled. Same shape as RIG-13..RIG-22: a real fix closing one gap and the next one behind it becoming visible for the first time.
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1 [unchecked against input_contexts.json: input_context 'panel:SwapPanel' is not in input_contexts.json]
- events: t=13.87
- verdict: PASS

### S03-62b — the world owns input again
- expected: The world must own input before the gathering loop begins. This assert is the guard the Oskar branch never had: with the SwapPanel still up, every walk and every hotbar press below is silently swallowed and the segment reports 71 FAILs that all have one cause.
- actual: input_context=world (wanted world)
- events: t=13.87
- verdict: PASS
