# diag_village_passage_0919 — Diagnostic physical traversal from the R14 training start through live village gates

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 13 s over 15174 frames at 0.0006 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/passage-0919-attempt3/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.22
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260916T030951Z-closeout-r14/S03p1/saves/S03p1-exit.json (4193311 bytes)
- events: t=0.22
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 517 ms (30 settle frames); re-priced at boot:title: 22304 physics waits at 0.01459 s, 67 process waits at 0.00049 s and 0.0 fixed seconds = 325 s against 14399 s remaining
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
- events: t=1.70
- verdict: PASS

### D07 — wait_until
- expected: Live world ready
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1.70
- verdict: PASS

### D08 — press
- expected: Deploy earned party member
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=2.32
- verdict: PASS

### D09 — teleport
- expected: Diagnostic setup at original pre-failure start, not partial travel; excluded from campaign evidence
- actual: DIAG teleport to (46, -43); distance/dead-travel accumulators reset
- events: t=3.32
- verdict: PASS

### D10 — move_to_entity
- expected: Reach the exact living foe physically through an open gate in original budget
- actual: selected wild began a verified live fight during physical approach after 1602 walking frames (0 held); no interact pressed
- events: t=30.02
- verdict: PASS

### D10b — interact_with
- expected: Exact selected fight starts from Engage or is already active from production aggression; no substituted foe
- actual: VERIFIED-CONDITION the pinned wild already started this active fight during approach; no redundant interact input issued
- events: t=30.02
- verdict: PASS

### D10b-settle — wait
- expected: Let the production 0.25-second entry input guard expire before a one-shot flee press
- actual: waited 30 physics frames
- events: t=30.52
- verdict: PASS

### D10c — press
- expected: Physical RB flees the diagnostic fight without claiming a victory
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=30.97
- verdict: PASS

### D10d — wait_until
- expected: Combat has ended before reverse physical walk
- actual: combat_running=false (wanted false) [true after 6 physics frames]
- events: t=31.07
- verdict: PASS

### D11 — move_to
- expected: Return physically through an open gate within same budget
- actual: walked 75.1 m to (46, -43) in 1623 walking frames (0 held)
- events: t=58.13
- verdict: PASS
