# S07 — River & Relay / Band 3: river arrival -> relay pickets -> officer -> relay captain -> captive -> Old Mill Crossing restored

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 1220 s over 205928 frames at 0.0059 s/frame (re-priced after each boot)

### S07-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S06-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.23
- verdict: PASS

### S07-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 1 files from /tmp/w21-userdata/S07/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.23
- verdict: PASS

### S07-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/gate-f-run-W21-S07/saves/S06-exit.json (1420151 bytes)
- events: t=0.23
- verdict: PASS

### S07-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 488 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 205895 frames left + 0 s boot = 1343 s against 14399 s of budget left
- events: t=0.87
- verdict: PASS

### S07-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.87
- verdict: PASS

### S07-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.92
- verdict: PASS

### S07-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.00
- verdict: PASS

### S07-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.62
- verdict: PASS

### S07-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.62
- verdict: PASS

### S07-09a — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing -- encounter_director.gd::_engageable() returns null on a null ally before any distance check, so no combat/catch/gate-flag assertion downstream of a load can mean anything without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=181.95
- verdict: PASS

### S07-10 — the team travelled
- expected: three entrants into band 3
- actual: party size 5 (wanted >= 3)
- events: t=181.95
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S07-11 — the relay captain is tracked
- expected: Section E.5 objective 18/27 `defeat_the_relay_captain`, 'Defeat the Relay Captain.'
- actual: tracked objective id=relay_captain_defeated text=Defeat the Relay Captain. (wanted defeat_the_relay_captain = flag_id relay_captain_defeated) [matched on entry id -> flag_id]
- events: t=181.95
- verdict: PASS

### S07-12 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 0.1 Hz segment plus event-forced frames, with the band 2 -> band 3 handoff window inside it. No background-recorder action exists in the vocabulary; recorded as a gap.
- events: t=181.95
- verdict: PASS

### S07-12b — Section H band-handoff windows in this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 'Mandatory for the highest-risk segments: ... every band handoff +/-60 s (region transitions)'. The pairs in this segment raise the background recorder from the 0.1 Hz journey baseline to 0.5 Hz across each band boundary this segment crosses, and `record_stop` returns to the baseline rather than switching the recorder off, so the record stays continuous either side. AMBIGUITY RECORDED: +/-60 s cannot be sized exactly from a step script. A `move_to` leg's duration is not known before the run and a leg cannot be split, so each window is placed to contain the crossing plus as much of its approach and its settle as the surrounding steps allow -- erring long, because the schema's own measurement makes a 0.5 Hz window affordable as a window (1.05 ms/frame for its length) while a window that missed the transition would cost the evidence.
- events: t=181.95
- verdict: PASS

### S07-13 — open the Map tab
- expected: Section E.5 at a major objective
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65513)
- events: t=182.13
- verdict: PASS

### S07-14 — zoom out to see band 3
- expected: Section E.5's map-usefulness record
- actual: pressed map_zoom_out x3 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=182.42
- verdict: PASS

### S07-15 — close the shell
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=182.65
- verdict: PASS

### S07-16 — Section E.5 nav note -- defeat_the_relay_captain
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 18/27 `defeat_the_relay_captain`. Wording: 'Defeat the Relay Captain.' It names WHAT and no WHERE at all -- it names a person and a place-word ('Relay') that the player may or may not have on the map yet. Player-visible information: `the_tether_relay` is a `major` map landmark at (350,3760) with its own relay icon; the ground ahead falls toward a river. Route decision: continue north to the river and follow the near bank east to the relay pin, because the objective's only locational word is the relay's own name. Reasoned from the map frame taken above and from GF-09-WARRENS-01 (S06). Operator: record whether the relay was a pin before it was discovered.
- events: t=182.65
- verdict: PASS

### S07-17 — walk north toward the river
- expected: Section D RT-08: 'Warrens exit -> river -> Tether Relay | -> (350,3760)'. `band2_outrider_kest` stands at (0,2980) on this leg
- actual: walked 509.4 m to (0, 2980) in 6408 walking frames (0 held)
- events: t=289.47
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S07-18p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=289.47
- verdict: PASS

### S07-18p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@67521)
- events: t=289.63
- verdict: PASS

### S07-18p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=290.00
- verdict: PASS

### S07-18p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=290.22
- verdict: PASS

### S07-18p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=290.28
- verdict: PASS

### S07-18p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell on press 2: context menu_backpack -> world
- events: t=290.85
- verdict: PASS

### S07-18p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=290.85
- verdict: PASS

### S07-18p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED press: not needed (active creature at 184.8 HP)
- events: t=290.85
- verdict: SKIP

### S07-18p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=291.85
- verdict: PASS

### S07-18p9 — party-health gate before the band 2 outrider Kest
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 184.8 HP
- events: t=291.85
- verdict: PASS

### S07-18 — challenge the band 2 outrider
- expected: an optional trainer standing on the route between bands; section D counts trainer encounters per route
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=292.08
- verdict: PASS

### S07-19 — hear him out
- expected: record what he offers and whether a player would take it
- actual: BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.
- events: t=292.08
- verdict: FAIL
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). /CL-H2: was a fixed `press interact, times: N`. A count is right for one conversation length; over-pressing re-opens the panel and under-pressing leaves input_context on `narrative_modal` where the next step expects combat -- G3-BAND5 measured exactly that at the outer watch, and the fight never started. `advance_dialogue_until_closed` reads dialogue_runner.gd::line() and stops the moment the panel closes.

### S07-20 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-20c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-20f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-21 — fight the outrider
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-22 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-22x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-22x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-22a — record_start: band 2 -> band 3, the river arrival
- expected: the window opens before the walk on to the bank, so the approach to the river is inside it -- GF-10-RELAY-01's whole point is whether the river reads as a regional barrier before it is reached
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-19w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-23 — walk on to the river bank
- expected: Section D RT-08's middle: the river is the regional barrier band 3 is built around
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-24 — capture GF-10-RELAY-01
- expected: Section G: river first visible, RT-08 -- the river reads as a regional barrier
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-25 — capture GF-21-WEATHER-03
- expected: Section G: each weather preset first naturally encountered (clear/cloudy/fog/rain) -- weather identity; palette holds
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-26 — the river region at the arrival point
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-26a — record_stop: back to the 0.1 Hz journey baseline after band 2 -> band 3, the river arrival
- expected: the window closes on the river-arrival frames. CL-H7: the region_enter into `the_long_water` does NOT happen here -- the assert that used to claim it did was 728 m out and is now S07-77a, at the Old Mill Crossing, which really is inside the region.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-27 — walk to the first relay picket
- expected: Section E.1 CB-04: 'S07: relay ladder + relay_captain'. relay_picket_hess stands at (241.3,3680)
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28p9 — party-health gate before the relay picket Hess
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-28 — challenge Hess
- expected: the first rung of the relay ladder
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-29 — hear him out
- expected: Team Tether's occupation escalating
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-30 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-30c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-30f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-31 — capture GF-14-COMBAT-04c
- expected: Section G: CB-04: representative fight per band -- S07, relay ladder + relay_captain -- per-case: band 3's representative fight
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-32 — fight Hess
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-33 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-33x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-33x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-29w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-34 — walk to the second relay picket
- expected: relay_picket_orrin at (284,3710.5), the ladder's second rung
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-34c — rotate to a fresh ally before Orrin
- expected: a level-headed five-creature roster does not run the same pilot through every fight on the ladder
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35p9 — party-health gate before the relay picket Orrin
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-35 — challenge Orrin
- expected: the second rung of the relay ladder
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-36 — hear him out
- expected: the ladder escalates rung by rung
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-37 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-37c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-37f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-38 — fight Orrin
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-39 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-39x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-39x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-40 — capture GF-10-RELAY-02
- expected: Section G: relay compound approach, pylons in frame, (350,3760) approach -- Team Tether occupation escalation
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-36w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-40g — walk to the compound gate
- expected: GATE-D3-GEOM: the picket road's own approach bearing (the (230,3670)->(350,3760) leg, unit (0.8,0.6)) runs 92 degrees off tether_relay.json's own approach_bearing_deg (-34.4, unit (0.565,-0.826)) -- almost exactly parallel to the compound's front wall rather than toward it. A beeline from the road straight at Officer Dell's own coordinate clips the flank_west fence and the wall-following navigator cannot always work all the way around it inside one leg's budget (measured: tools/_probe_relay_gate_reach.gd, stuck-point replay, both legs succeed once routed through the gate first). Named here as its own waypoint rather than folded into S07-41's `at`, so a future re-siting of either the road or the gate shows up as one waypoint disagreeing with the map instead of a silent detour failure.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-41 — walk to Officer Dell
- expected: Section B: S07's span names the officer between the pickets and the captain. relay_officer_dell stands at (343.2,3771.1) (GATE3_ENCOUNTER_CONTRACTS.md V-1, G3-BAND3-0903 -- moved from (347.5,3763.5) to the gate opening; see that trainer's own `_why_v1_gate3_encounters`).
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-42 — the relay region contains the arrival
- expected: map_state.gd's containment puts the player in `the_tether_relay`
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-43 — rescan for points of interest
- expected: the compound's own content joins the POI set
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-43c — rotate to a fresh ally before Dell
- expected: GATE-D3-STAMINA (S07-34c's own note): the third real fight on the ladder, still on a five-creature roster
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44p9 — party-health gate before the relay officer Dell
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-44 — challenge Officer Dell
- expected: the ladder's third rung, inside the compound
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-45 — hear the officer out
- expected: record what the occupation says for itself
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-46 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-46c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-46f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-47 — fight Dell
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-48 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-48x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-48x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-45w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-49 — walk to Captain Vance
- expected: Section E.1 CB-04: relay_captain at (352,3757), the band's required fight
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-49c — rotate to a fresh ally before the captain
- expected: GATE-D3-STAMINA (S07-34c's own note): the band's required fight, and the ladder's fourth real battle in a row -- without this the deployed ally arrives at the hardest of the four already worn from three others
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50p9 — party-health gate before the Relay Captain
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-50 — challenge the Relay Captain
- expected: Section E.5 objective 18/27's own target
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-51 — hear the captain out
- expected: the band's named antagonist
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-52 — let the fight stage
- expected: Section L.6 T05: the combat camera acquires both combatants at fight start
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-53 — combat owns input
- expected: input_context is 'combat'
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-53f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was received, not merely pressed
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-57 — a charged attack
- expected: the charged verb's hold edge
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-54 — fight the Relay Captain
- expected: Section E.1 per-fight record; the HP margin at the end is band 3's difficulty read
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-59 — let the captain fight end
- expected: rewards and control return with no stuck modal
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-59x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-59x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-60 — the Relay Captain is beaten
- expected: `relay_captain_defeated` closes section E.5 objective 18/27
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-61 — the captive is tracked
- expected: Section E.5 objective 19/27 `rescue_the_captive`, 'Find who Team Tether is holding at the relay.'
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-62 — Section E.5 nav note -- rescue_the_captive
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-51w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-63 — walk to the captive
- expected: data/config/relay_site.json's `people[0]` is Sela at (356,3753)
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-64 — speak to the captive
- expected: Section B: S07's span names the captive between the captain and the crossing
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-65 — hear her out
- expected: the reason the crossing can be restored at all
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-66 — capture GF-10-RELAY-03
- expected: Section G: captive rescue / crossing restored moment, relay & (-152,4203) -- world visibly changes
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-67 — the captive is free
- expected: `captive_rescued` closes section E.5 objective 19/27
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-68 — the relay shutdown is tracked
- expected: Section E.5 objective 20/27 `disable_the_relay`, 'Shut down the Tether Relay.'
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-69 — Section E.5 nav note -- disable_the_relay
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-65w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-70 — walk to the relay apparatus (ground level)
- expected: data/config/relay_site.json's `site.centre` (350,3760) -- the same point map_landmarks.json pins the relay at
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-71 — shut the relay down
- expected: the rung's own verb
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-72 — see it through
- expected: record what the world does when the pylons go quiet
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-73 — the relay is down
- expected: `relay_disabled` closes section E.5 objective 20/27
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-74 — the crossing is tracked
- expected: Section E.5 objective 21/27 `restore_the_mill_crossing`, 'Restore the Old Mill Crossing.'
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-75 — Section E.5 nav note -- restore_the_mill_crossing
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-75a — record_start: band 3 -> band 4, the Old Mill Crossing
- expected: the crossing is the band 3/4 boundary and restoring it is what opens it: the window opens before the walk upstream so the approach along the bank is recorded
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-76 — walk upstream to the Old Mill Crossing
- expected: Section D RT-09: 'Relay -> Old Mill Crossing -> Upper Meadows entry | (350,3760) -> (-152,4203)'
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-77 — rescan for points of interest
- expected: the crossing's own content joins the POI set
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-77a — the Old Mill Crossing really is inside The Long Water
- expected: CL-H7's other half. map_landmarks.json puts `the_long_water` at (-150,4200) with a 52 m radius; S07-76's walk target (-152,4195.6) is 4.6 m from that centre, so this is the waypoint where the region assert the segment lost at S07-26 can actually be made. The coverage moves rather than disappearing.
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-78 — restore the crossing
- expected: Section L.5's gate/crossing row: 'Old Mill Crossing ... each locked-probe then legitimately opened'. The locked probe is X06's; this is the legitimate opening
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-79 — see it through
- expected: record what communicates that the crossing is usable again
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-80 — the crossing is restored
- expected: `mill_crossing_restored` closes section E.5 objective 21/27 and section B's S07 span
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-80a — record_stop: back to the 0.1 Hz journey baseline after band 3 -> band 4, the Old Mill Crossing
- expected: the window closes once `mill_crossing_restored` is set. Section B puts the cut here, so section H's other half of this +/-60 s is S08's own opening window
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-81 — band 3 was actually walked
- expected: Section D RT-08 plus RT-09 is well over 2 km; no pacing claim may come from a shortcut (section 0.6)
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-82 — the 2 Hz trace ran throughout
- expected: Section C.2
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-83 — band 3's longest empty stretch is on the record
- expected: Section D: '>= 250 m is a finding; 150-250 m is a watch item'. The peak is the half that proves accumulation; a PASS records a watch item and its size
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-84 — Section B save handoff
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-85 — open the pause shell
- expected: the game_menu button, sent as a real physical event, opens the pause shell onto the Satchel tab
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-86 — cycle right to the Save tab
- expected: five RB presses move from Satchel to Save, the sixth tab in data/config/menu.json
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-87 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-88 — move focus to slot 4's Save button
- expected: focus starts on slot 0's Save button (tab_save.gd::first_focus) and four d-pad downs reach slot 4's
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-89 — press Save
- expected: the focused Save button activates and writes slot 4 -- the handoff slot; autosave is slot 0 and slots 1-3 stay free for natural play coverage
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-90 — give the write a moment
- expected: the slot file is on disk and section I.4 has timed the save operation
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-91 — copy slot 4 out into the run directory
- expected: Section B: the resulting `user://` slot file is copied into the run directory as `saves/S07-exit.json`
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-92 — close the shell
- expected: B closes the shell and hands the world back
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S07-93 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S07-19 (BLOCKER advance_dialogue_until_closed at step S07-19: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP
