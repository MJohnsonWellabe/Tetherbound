# diag_training_sprint_0919 — Diagnostic selected Mudsnout approach under original R16 budget

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 15 s over 19582 frames at 0.0006 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/sprint-0919-attempt2/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.22
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260919-meadows-r16/S03p1/saves/S03p1-exit.json (4193310 bytes)
- events: t=0.22
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 515 ms (30 settle frames); re-priced at boot:title: 26074 physics waits at 0.01442 s, 1043 process waits at 0.00050 s and 0.0 fixed seconds = 377 s against 14399 s remaining
- events: t=0.73
- verdict: PASS

### D04 — focus_move
- expected: Load Game focused
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@33) -> 'Load Game' (@Button@34)
- events: t=0.77
- verdict: PASS

### D05 — press
- expected: Real slot picker
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=0.85
- verdict: PASS

### D06 — press
- expected: Production save loaded
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=1.72
- verdict: PASS

### D07 — wait_until
- expected: Live world ready
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1.72
- verdict: PASS

### D08 — press
- expected: Deploy earned party member
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=2.33
- verdict: PASS

### D09 — teleport
- expected: DIAG original R16 n6 start; not campaign travel
- actual: DIAG teleport to (41, -117); distance/dead-travel accumulators reset
- events: t=3.33
- verdict: PASS

### D09a — move_to_entity
- expected: DIAG precondition: approach the Galecrest that was already defeated before R16 n6
- actual: selected wild began a verified live fight during physical approach after 0 walking frames (0 held); no interact pressed
- events: t=3.33
- verdict: PASS

### D09b — interact_with
- expected: Begin that exact real fight
- actual: VERIFIED-CONDITION the pinned wild already started this active fight during approach; no redundant interact input issued
- events: t=3.33
- verdict: PASS

### D09c — fight_until_resolved
- expected: Earn actual Galecrest victory instead of editing its state
- actual: fought 387 frames: 9 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 90 frames; production won exit and live XP progress verified
- events: t=10.65
- verdict: PASS

### D09d — recover_fainted_party
- expected: Physical paid recovery of any fainted earned companion
- actual: physical paid team recovery: {"ok":true,"reserved_physics_frames":0,"reserved_process_frames":0,"revived":0,"why":""}
- events: t=10.65
- verdict: PASS

### D09e — select_healthy_party
- expected: Physically select a healthy earned companion
- actual: physical world pilot selection: {"no_input":true,"ok":true,"physics_frames":0,"presses":0,"process_frames":0,"selected_index":1,"why":"healthiest earned creature and actual companion verified; 0 physical LB taps"}
- events: t=10.65
- verdict: PASS

### D09f — teleport
- expected: DIAG return to original R16 n6 start after verified precondition; next approach remains entirely physical
- actual: DIAG teleport to (41, -117); distance/dead-travel accumulators reset
- events: t=11.65
- verdict: PASS

### D10 — move_to_entity
- expected: Reach exact original selected creature using physical L3 and ordinary stamina within original budget; release sprint at exit
- actual: walked 170.2 m to Wild_mudsnout_1_1 (node name; selected /root/MeadowsPlayground/Wild_mudsnout_1_1) in 1511 walking frames (0 held)
- events: t=36.85
- verdict: PASS

### D11 — interact_with
- expected: Real selected fight starts from verified prompt or exact spontaneous combat
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Engage Mudsnout" (provider 'EncounterDirector'): context world -> combat
- events: t=38.58
- verdict: PASS
