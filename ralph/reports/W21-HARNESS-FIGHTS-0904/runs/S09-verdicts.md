# S09 — Stronghold approach / Band 5: Sigil gate -> outer watch -> checkpoint -> final camp decision -> Hall threshold

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 789 s over 131695 frames at 0.0060 s/frame (re-priced after each boot)

### S09-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S08-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.25
- verdict: PASS

### S09-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: save directory /tmp/w21-userdata/S09/godot/app_userdata/Tetherbound/saves does not exist yet; nothing to wipe
- events: t=0.25
- verdict: PASS

### S09-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/gate-f-run-W21-S09/saves/S08-exit.json (6640 bytes)
- events: t=0.25
- verdict: PASS

### S09-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 491 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0060), 131662 frames left + 0 s boot = 858 s against 14399 s of budget left
- events: t=0.87
- verdict: PASS

### S09-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.87
- verdict: PASS

### S09-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.93
- verdict: PASS

### S09-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.02
- verdict: PASS

### S09-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.67
- verdict: PASS

### S09-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.67
- verdict: PASS

### S09-09a — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing -- encounter_director.gd::_engageable() returns null on a null ally before any distance check, so no combat/catch/gate-flag assertion downstream of a load can mean anything without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=182.13
- verdict: PASS

### S09-10 — the full belt travelled
- expected: five of five across the handoff
- actual: party size 5 (wanted >= 5)
- events: t=182.13
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S09-11 — the Hall is tracked
- expected: Section E.5 objective 23/27 `fight_through_the_hall`, 'Fight through the guard inside Meadows Hall.' with the n/3 count appended
- actual: tracked objective id=defeated_stronghold_elite text=Fight through the guard inside Meadows Hall. 0/3 (wanted fight_through_the_hall = flag_id defeated_stronghold_elite) [matched on entry id -> flag_id]
- events: t=182.13
- verdict: PASS

### S09-12 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 0.1 Hz segment plus event-forced frames, with the band 4 -> band 5 handoff window inside it. No background-recorder action exists in the vocabulary; recorded as a gap.
- events: t=182.13
- verdict: PASS

### S09-12b — Section H band-handoff windows in this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 'Mandatory for the highest-risk segments: ... every band handoff +/-60 s (region transitions)'. The pairs in this segment raise the background recorder from the 0.1 Hz journey baseline to 0.5 Hz across each band boundary this segment crosses, and `record_stop` returns to the baseline rather than switching the recorder off, so the record stays continuous either side. AMBIGUITY RECORDED: +/-60 s cannot be sized exactly from a step script. A `move_to` leg's duration is not known before the run and a leg cannot be split, so each window is placed to contain the crossing plus as much of its approach and its settle as the surrounding steps allow -- erring long, because the schema's own measurement makes a 0.5 Hz window affordable as a window (1.05 ms/frame for its length) while a window that missed the transition would cost the evidence.
- events: t=182.13
- verdict: PASS

### S09-13 — open the Map tab
- expected: Section E.5 at a major objective
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65186)
- events: t=182.32
- verdict: PASS

### S09-14 — zoom out to see the approach
- expected: Section E.5's map-usefulness record
- actual: pressed map_zoom_out x3 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=182.60
- verdict: PASS

### S09-15 — close the shell
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=182.83
- verdict: PASS

### S09-16 — Section E.5 nav note -- fight_through_the_hall
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 23/27 `fight_through_the_hall`. Wording: 'Fight through the guard inside Meadows Hall. n/3' -- it names WHAT, a count, and a named WHERE. Player-visible information: `stronghold` is a `major` map landmark with `silhouette: true`, meaning it is the castle pin rather than a route entrance; the Hall itself is meant to be visible on the horizon from the approach, and Team Tether's pylon line runs north along the causeway with drained ground under it. Route decision: follow the causeway north under the pylons toward the silhouette, because a landmark you can see is a better instruction than any line of text. Reasoned from GF-18-MAP-02 (S08) and GF-12-APPR-02 below. Operator: record whether the Hall was actually visible before it was reached -- that is what GF-12-APPR-02 exists to prove or disprove.
- events: t=182.83
- verdict: PASS

### S09-16a — record_start: band 4 -> band 5, the walk to the three-Sigil gate and through it
- expected: this is the band 4/5 crossing proper, and it happens entirely inside S09: the window opens before the walk up the causeway so the approach under Team Tether's pylon line is recorded
- actual: DELEGATED the §H record window "band 4 -> band 5, the walk to the three-Sigil gate and through it" to capture lane S09C (this is the logic lane; it keeps no continuous record)
- events: t=182.83
- verdict: DELEGATED

### S09-17 — walk to the three-Sigil gate
- expected: Section D RT-11: 'Stronghold approach (sigil gate -> Hall threshold)'. playground_world.gd's SIGIL_GATE_AT is (63.6,7400), on the causeway between the gorge carves
- actual: walked 401.6 m to (64, 7400) in 5701 walking frames (0 held)
- events: t=277.87
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S09-18 — rescan for points of interest
- expected: the approach's own content joins the POI set
- actual: 1123 points of interest in the tree
- events: t=277.87
- verdict: PASS

### S09-19 — open the gate with the three Sigils
- expected: Section L.5's gate/crossing row: 'sigil gate ... each locked-probe then legitimately opened'. The 0-2 Sigil probe is X06's; this is the legitimate opening. `road_gate.gd` is the gate BODY and the three Sigils are its key
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=278.23
- verdict: PASS

### S09-20 — let the gate open
- expected: the leaf re-poses and the causeway is walkable
- actual: waited 240 physics frames
- events: t=282.23
- verdict: PASS

### S09-21 — capture GF-12-APPR-01
- expected: Section G: sigil gate opening, gate site -- 3-Sigil payoff
- actual: DELEGATED GF-12-APPR-01 to capture lane S09C (this is the logic lane; it takes no frames)
- events: t=282.23
- verdict: DELEGATED

### S09-22 — capture GF-21-WEATHER-04
- expected: Section G: each weather preset first naturally encountered (clear/cloudy/fog/rain) -- weather identity; palette holds
- actual: DELEGATED GF-21-WEATHER-04 to capture lane S09C (this is the logic lane; it takes no frames)
- events: t=282.23
- verdict: DELEGATED

### S09-22a — record_stop: back to the 0.1 Hz journey baseline after band 4 -> band 5, the walk to the three-Sigil gate and through it
- expected: the window closes after GF-12-APPR-01 and GF-21-WEATHER-04, so the gate opening and its settle are inside the raised window
- actual: DELEGATED the close of the §H record window to capture lane S09C (this is the logic lane; no window was opened here)
- events: t=282.23
- verdict: DELEGATED

### S09-23 — walk to the outer watch
- expected: Section B's span order: 'Sigil gate -> outer watch -> checkpoint'. Section E.1 CB-04: 'S09: stronghold_outer_watch, checkpoint'. Watchman Corr stands at (-68,7140)
- actual: walked 285.1 m to (-68, 7140) in 3774 walking frames (4282 held)
- events: t=416.52
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S09-24p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=416.52
- verdict: PASS

### S09-24p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@66798)
- events: t=416.72
- verdict: PASS

### S09-24p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=417.07
- verdict: PASS

### S09-24p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED press: not needed (revive count 0)
- events: t=417.07
- verdict: SKIP

### S09-24p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED press: not needed (revive count 0)
- events: t=417.07
- verdict: SKIP

### S09-24p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell: context menu_backpack -> world
- events: t=417.35
- verdict: PASS

### S09-24p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=417.35
- verdict: PASS

### S09-24p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=417.88
- verdict: PASS

### S09-24p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=418.88
- verdict: PASS

### S09-24p9 — party-health gate before the stronghold outer watch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 199.5 HP
- events: t=418.88
- verdict: PASS

### S09-24 — challenge Watchman Corr
- expected: the approach's first required fight
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=419.08
- verdict: PASS

### S09-25 — hear him out
- expected: Team Tether at the top of its escalation
- actual: advanced 2 line(s) over 2 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'combat'
- events: t=420.22
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). /CL-H2: was a fixed `press interact, times: N`. A count is right for one conversation length; over-pressing re-opens the panel and under-pressing leaves input_context on `narrative_modal` where the next step expects combat -- G3-BAND5 measured exactly that at the outer watch, and the fight never started. `advance_dialogue_until_closed` reads dialogue_runner.gd::line() and stops the moment the panel closes. G3-BAND5 measured this exact step leaving input_context on `narrative_modal` with combat_running false: the twelve presses ran out before the panel closed and the fight never started, taking the rest of the segment with it.

### S09-26 — let the fight stage
- expected: Section L.6 T05: the combat camera acquires both combatants at fight start
- actual: waited 180 physics frames
- events: t=423.22
- verdict: PASS

### S09-27 — combat owns input
- expected: input_context is 'combat'
- actual: input_context=combat (wanted combat)
- events: t=423.22
- verdict: PASS

### S09-27f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was received, not merely pressed
- actual: combat_running=true (wanted true)
- events: t=423.22
- verdict: PASS
- observation: T2-GATEF-RUN6 / RIG-26, and the fix T5-FEEL's played-path evidence independently recommended: assert that a fight is RUNNING, not merely that combat-shaped input is owned. `input_context == "combat"` was the strongest claim these segments made after an engage, and it is not the same claim -- it is why two instrumented segments produced 128 events with zero `combat_start` and it read as a candidate GAME blocker for six runs.

### S09-28 — capture GF-14-COMBAT-04e
- expected: Section G: CB-04: representative fight per band -- S09, stronghold_outer_watch -- per-case: band 5's representative fight
- actual: DELEGATED GF-14-COMBAT-04e to capture lane S09C (this is the logic lane; it takes no frames)
- events: t=423.22
- verdict: DELEGATED

### S09-29 — fight the outer watch
- expected: Section E.1 per-fight record; band 5's difficulty read against a full belt
- actual: fought 1231 frames: 40 quick, 0 handover(s), 0 refused switch(es); ended because flag 'defeated_stronghold_outer_watch' set, SET 'defeated_stronghold_outer_watch'
- events: t=444.25
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N` -- the failure mode SEGMENT_SCHEMA.md names by name. A counted press block is right for exactly one matchup, and G3-BAND2's own telemetry watched all four party members faint in sequence inside one such block while every step reported PASS. `fight_until_resolved` presses combat_quick only while the action machine reads READY, presses party_cycle once when the pilot drops below switch_below of max HP (which is CB-09's switching-under-pressure, driven by the creature's real HP instead of a scripted beat), and stops only when both is_fighting() and trainer_battle_active() have been false for quiet_frames. The scripted mid-fight party_cycle is gone; the switch now fires on the pilot's real HP.

### S09-32 — let the fight end
- expected: rewards and control return with no stuck modal
- actual: waited 600 physics frames
- events: t=454.25
- verdict: PASS

### S09-32x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED press: not needed (active creature at 149.6 HP)
- events: t=454.25
- verdict: SKIP

### S09-32x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: waited 60 physics frames
- events: t=455.25
- verdict: PASS

### S09-25w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=world (wanted world)
- events: t=455.25
- verdict: PASS
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S09-33 — walk north through the gate to the checkpoint
- expected: Section E.1 CB-04's second band 5 fight: stronghold_checkpoint, Warder Ness at (45,7440), north of the sigil gate
- actual: FAIL did not reach (45, 7440) in 15300 walking frames; stopped 81.3 m short at (18.0, 4.0, 7363.0) (1778 held)
- events: t=739.90
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S09-34p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=739.90
- verdict: PASS

### S09-34p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@70957)
- events: t=740.07
- verdict: PASS

### S09-34p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=740.40
- verdict: PASS

### S09-34p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED press: not needed (revive count 0)
- events: t=740.40
- verdict: SKIP

### S09-34p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED press: not needed (revive count 0)
- events: t=740.40
- verdict: SKIP

### S09-34p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell: context menu_backpack -> world
- events: t=740.68
- verdict: PASS

### S09-34p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=740.68
- verdict: PASS

### S09-34p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=741.03
- verdict: PASS

### S09-34p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=742.03
- verdict: PASS

### S09-34p9 — party-health gate before the stronghold checkpoint
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 193.2 HP
- events: t=742.03
- verdict: PASS

### S09-34 — challenge Warder Ness
- expected: the approach's second required fight
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=742.27
- verdict: PASS

### S09-35 — hear her out
- expected: the last thing between the player and the Hall's own ground
- actual: BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.
- events: t=742.27
- verdict: FAIL
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). /CL-H2: was a fixed `press interact, times: N`. A count is right for one conversation length; over-pressing re-opens the panel and under-pressing leaves input_context on `narrative_modal` where the next step expects combat -- G3-BAND5 measured exactly that at the outer watch, and the fight never started. `advance_dialogue_until_closed` reads dialogue_runner.gd::line() and stops the moment the panel closes.

### S09-36 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-36c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-36f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-38 — a charged attack
- expected: the charged verb's hold edge
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-37 — fight the checkpoint
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-40 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-40x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-40x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-41 — capture GF-12-APPR-02
- expected: Section G: Hall dominant on horizon, drained land in frame, RT-11 mid -- escalating dread; occupied/drained grammar
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-42 — Section B's final camp decision is not specified
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-43 — open the pause shell
- expected: the pause shell, opened by its bound button
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-44 — cycle to the Build tab
- expected: four RB presses reach Build
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-45 — open the build menu
- expected: 'Open Build Menu' is the tab's only focusable control
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-46 — let the build menu open
- expected: it reopens on the last category and piece used this session
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-47 — move to Survival
- expected: `build_menu.gd::CATEGORY_ORDER` -- Survival holds the Camp (12 wood / 8 stone / 10 fiber)
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-48 — arm the camp
- expected: paid at the real cost; free_build is OFF for the whole run
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-49 — let the ghost arm
- expected: the placement camera takes over
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-50 — place the camp on the approach
- expected: Section B's final camp decision, taken
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-51 — let the placement register
- expected: `GameState.placed_buildings` gains the camp
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-52 — rest before the Hall
- expected: Section L.6 T08: 'rest -> next day ... day advances, party heals per rules, flags set, weather re-rolls legally'
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-53 — let the rest panel open
- expected: the bed panel takes input
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-54 — confirm the rest
- expected: Section L.4: 'Player rest / sleep -> next day'
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-55 — let the day advance
- expected: the fade runs and the team is rested for the Hall
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-55a — record_start: band 5 -> the Hall
- expected: the last handoff of the chapter: the window opens before the walk from the final camp to the Hall threshold
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-35w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-56 — walk to the Hall threshold
- expected: Section D RT-11 ends at (150,7595), the `stronghold` landmark -- the castle silhouette east of the stronghold's own built footprint. Section B: S09's span ends at 'Hall threshold'
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-57 — the player stands at the threshold
- expected: Section D RT-11's endpoint
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-57a — record_stop: back to the 0.1 Hz journey baseline after band 5 -> the Hall
- expected: the window closes on the threshold assert. Section H's other half of this +/-60 s needs no pair -- S10 carries `record_hz: 0.5` for its whole length
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-58 — the approach was actually walked
- expected: Section D RT-11 plus section B's back-and-forth order is well over 2 km; no pacing claim may come from a shortcut (section 0.6)
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-59 — the 2 Hz trace ran throughout
- expected: Section C.2
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-60 — the approach's longest empty stretch is on the record
- expected: Section D: '>= 250 m is a finding; 150-250 m is a watch item'. The drained approach is meant to read as emptied ground, so what the meter says here is a design question as much as a pacing one
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-61 — Section B save handoff
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-62 — open the pause shell
- expected: the game_menu button, sent as a real physical event, opens the pause shell onto the Satchel tab
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-63 — cycle right to the Save tab
- expected: five RB presses move from Satchel to Save, the sixth tab in data/config/menu.json
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-64 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-65 — move focus to slot 4's Save button
- expected: focus starts on slot 0's Save button (tab_save.gd::first_focus) and four d-pad downs reach slot 4's
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-66 — press Save
- expected: the focused Save button activates and writes slot 4 -- the handoff slot; autosave is slot 0 and slots 1-3 stay free for natural play coverage
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-67 — give the write a moment
- expected: the slot file is on disk and section I.4 has timed the save operation
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-68 — copy slot 4 out into the run directory
- expected: Section B: the resulting `user://` slot file is copied into the run directory as `saves/S09-exit.json`
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-69 — close the shell
- expected: B closes the shell and hands the world back
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP

### S09-70 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S09-35 (BLOCKER advance_dialogue_until_closed at step S09-35: no narrative modal is open. input_context is 'world' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'world' now.
- verdict: SKIP
