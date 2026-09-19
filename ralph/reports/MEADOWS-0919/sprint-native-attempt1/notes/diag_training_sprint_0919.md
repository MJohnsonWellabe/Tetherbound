# diag_training_sprint_0919 — Diagnostic selected Mudsnout approach under original R16 budget

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 13 s over 12952 frames at 0.0008 s/frame (re-priced after each boot)

### D01 — wipe_saves
- expected: Isolated diagnostic profile has no competing slots
- actual: save directory D:/tetherbound/closeout-profiles/sprint-0919-attempt1/Roaming/Godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.25
- verdict: PASS

### D02 — seed_save
- expected: Load original earned R14 party and legitimately open gates; diagnostic only
- actual: seeded slot 4 from D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/gate-f-run-20260919-meadows-r16/S03p1/saves/S03p1-exit.json (4193310 bytes)
- events: t=0.25
- verdict: PASS

### D03 — boot
- expected: Real title
- actual: booted title in 531 ms (30 settle frames); re-priced at boot:title: 16491 physics waits at 0.01461 s, 57 process waits at 0.00054 s and 0.0 fixed seconds = 241 s against 14399 s remaining
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
- events: t=0.88
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
- events: t=2.35
- verdict: PASS

### D09 — teleport
- expected: DIAG original R16 n6 start; not campaign travel
- actual: DIAG teleport to (41, -117); distance/dead-travel accumulators reset
- events: t=3.35
- verdict: PASS

### D10 — move_to_entity
- expected: Reach exact original selected creature using physical L3 and ordinary stamina within original budget; release sprint at exit
- actual: FAIL selected wild never retained the actionable Engage offer within 2.00 m after 2000 walking frames (881 held); no interact pressed
- events: t=51.38
- verdict: FAIL

### D11 — interact_with
- expected: Real selected fight starts from verified prompt or exact spontaneous combat
- actual: FAIL selected wild no longer owns the actionable Engage offer after prompt settling; no input issued
- events: t=51.38
- verdict: FAIL
