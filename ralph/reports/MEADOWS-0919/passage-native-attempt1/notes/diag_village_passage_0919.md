# diag_village_passage_0919 — Diagnostic physical traversal from the R14 training start through live village gates

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 59 s over 14940 frames at 0.0027 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/passage-0919-attempt1/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.27
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260916T030951Z-closeout-r14/S03p1/saves/S03p1-exit.json (4193311 bytes)
- events: t=0.27
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 660 ms (30 settle frames); re-priced at boot:title: 22070 physics waits at 0.01454 s, 35 process waits at 0.00050 s and 0.0 fixed seconds = 321 s against 14399 s remaining
- events: t=0.78
- verdict: PASS

### D04 — focus_move
- expected: Load Game focused
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@33) -> 'Load Game' (@Button@34)
- events: t=0.82
- verdict: PASS

### D05 — press
- expected: Real slot picker
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=0.93
- verdict: PASS

### D06 — press
- expected: Production save loaded
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0 [unchecked against input_contexts.json: input_context 'title' is not in input_contexts.json]
- events: t=1.78
- verdict: PASS

### D07 — wait_until
- expected: Live world ready
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1.78
- verdict: PASS

### D08 — press
- expected: Deploy earned party member
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=2.37
- verdict: PASS

### D09 — teleport
- expected: Diagnostic setup at original pre-failure start, not partial travel; excluded from campaign evidence
- actual: DIAG teleport to (46, -43); distance/dead-travel accumulators reset
- events: t=3.37
- verdict: PASS

### D10 — move_to_entity
- expected: Reach the exact living foe physically through an open gate in original budget
- actual: FAIL selected wild never retained the actionable Engage offer within 2.00 m after 2000 walking frames (757 held); no interact pressed
- events: t=49.33
- verdict: FAIL

### D11 — move_to
- expected: Return physically through an open gate within same budget
- actual: walked 70.3 m to (46, -43) in 1696 walking frames (0 held)
- events: t=77.62
- verdict: PASS
