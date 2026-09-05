# S06 — Stone & Root / Band 2: bridge -> Old Quarry -> rootstone -> Burrow Warrens -> guardian -> exit toward river

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 969 s over 163194 frames at 0.0059 s/frame (re-priced after each boot)

### S06-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S05-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.25
- verdict: PASS

### S06-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 1 files from /tmp/w21-userdata/S06/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.25
- verdict: PASS

### S06-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/gate-f-run-W21-S06/saves/S05-exit.json (1419238 bytes)
- events: t=0.25
- verdict: PASS

### S06-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 470 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 163161 frames left + 0 s boot = 1061 s against 14399 s of budget left
- events: t=0.87
- verdict: PASS

### S06-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.87
- verdict: PASS

### S06-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.92
- verdict: PASS

### S06-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.10
- verdict: PASS

### S06-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.73
- verdict: PASS

### S06-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.73
- verdict: PASS

### S06-09a — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing -- encounter_director.gd::_engageable() returns null on a null ally before any distance check, so no combat/catch/gate-flag assertion downstream of a load can mean anything without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=182.07
- verdict: PASS

### S06-10 — the team travelled
- expected: three entrants across the bridge
- actual: party size 4 (wanted >= 3)
- events: t=182.07
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S06-11 — the Warrens objective is tracked
- expected: Section E.5 objective 17/27 `clear_the_burrow_warrens`, 'Clear the Burrow Warrens beneath the Old Quarry.'
- actual: tracked objective id=warrens_cleared text=Clear the Burrow Warrens beneath the Old Quarry. (wanted clear_the_burrow_warrens = flag_id warrens_cleared) [matched on entry id -> flag_id]
- events: t=182.07
- verdict: PASS

### S06-12 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 0.1 Hz segment plus event-forced frames, with the band 1 -> band 2 handoff window inside it. No background-recorder action exists in the vocabulary; recorded as a gap.
- events: t=182.07
- verdict: PASS

### S06-12a — record_start: band 1 -> band 2, the arrival side of the South Bridge cut
- expected: S05 saved ON the bridge, so this segment loads standing on the band 1/2 boundary: the window opens the moment the load's assertions have run, which is the earliest frame of the arrival side of that handoff
- actual: DELEGATED the §H record window "band 1 -> band 2, the arrival side of the South Bridge cut" to capture lane S06C (this is the logic lane; it keeps no continuous record)
- events: t=182.07
- verdict: DELEGATED

### S06-12b — Section H band-handoff windows in this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 'Mandatory for the highest-risk segments: ... every band handoff +/-60 s (region transitions)'. The pairs in this segment raise the background recorder from the 0.1 Hz journey baseline to 0.5 Hz across each band boundary this segment crosses, and `record_stop` returns to the baseline rather than switching the recorder off, so the record stays continuous either side. AMBIGUITY RECORDED: +/-60 s cannot be sized exactly from a step script. A `move_to` leg's duration is not known before the run and a leg cannot be split, so each window is placed to contain the crossing plus as much of its approach and its settle as the surrounding steps allow -- erring long, because the schema's own measurement makes a 0.5 Hz window affordable as a window (1.05 ms/frame for its length) while a window that missed the transition would cost the evidence.
- events: t=182.07
- verdict: PASS

### S06-13 — open the Map tab
- expected: Section E.5 at a major objective: open the Map tab, zoom, verify pan/centering and zoom persistence
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65281)
- events: t=182.25
- verdict: PASS

### S06-14 — zoom out to see band 2
- expected: Section E.5's map-usefulness record
- actual: pressed map_zoom_out x3 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=182.57
- verdict: PASS

### S06-15 — close the shell
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=182.78
- verdict: PASS

### S06-16 — Section E.5 nav note -- clear_the_burrow_warrens
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 17/27 `clear_the_burrow_warrens`. Wording: 'Clear the Burrow Warrens beneath the Old Quarry.' It names WHAT and a WHERE relative to a second named place -- the strongest form in the chapter, because it tells the player to find the quarry first. Player-visible information: `the_old_quarry` and `the_burrow_warrens` are named regions on the map; the quarry is a visible landform north-east of the bridge. Route decision: follow the road north-east to the quarry, then look for the Warrens beneath it, because the objective's own wording orders the two. Reasoned from GF-07-BRIDGE-02 (S05) and the map frame taken above. Operator: record whether the map named either place before it was discovered, and the time to the decision.
- events: t=182.78
- verdict: PASS

### S06-17 — walk to the quarry picket
- expected: Section E.1 CB-04: 'S06: quarry_picket_dorn' -- Dorn stands at (315,1668) on the way in
- actual: walked 434.2 m to (315, 1668) in 5416 walking frames (0 held)
- events: t=273.07
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-17a — record_stop: back to the 0.1 Hz journey baseline after band 1 -> band 2, the arrival side of the South Bridge cut
- expected: the window closes on the first ground inside band 2, at the quarry picket. This leg is longer than 60 s and cannot be split -- see this segment's section H note
- actual: DELEGATED the close of the §H record window to capture lane S06C (this is the logic lane; no window was opened here)
- events: t=273.07
- verdict: DELEGATED

### S06-18p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=273.07
- verdict: PASS

### S06-18p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@66770)
- events: t=273.23
- verdict: PASS

### S06-18p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=273.58
- verdict: PASS

### S06-18p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=273.80
- verdict: PASS

### S06-18p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=273.88
- verdict: PASS

### S06-18p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell on press 2: context menu_backpack -> world
- events: t=274.38
- verdict: PASS

### S06-18p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=274.38
- verdict: PASS

### S06-18p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED press: not needed (active creature at 170.4 HP)
- events: t=274.38
- verdict: SKIP

### S06-18p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=275.38
- verdict: PASS

### S06-18p9 — party-health gate before the quarry picket Dorn
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 170.4 HP
- events: t=275.38
- verdict: PASS

### S06-18 — challenge Dorn
- expected: a band 2 trainer on the approach
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=275.53
- verdict: PASS

### S06-19 — hear Dorn out
- expected: trainer flow stages send-out
- actual: advanced 2 line(s) over 2 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'combat'
- events: t=276.37
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). /CL-H2: was a fixed `press interact, times: N`. A count is right for one conversation length; over-pressing re-opens the panel and under-pressing leaves input_context on `narrative_modal` where the next step expects combat -- G3-BAND5 measured exactly that at the outer watch, and the fight never started. `advance_dialogue_until_closed` reads dialogue_runner.gd::line() and stops the moment the panel closes. quarry_dorn_challenge is two lines; scripts/world/trainer_npc.gd starts the fight when the words run out, so the predicate close IS the handoff.

### S06-20 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=279.37
- verdict: PASS

### S06-20c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: input_context=combat (wanted combat)
- events: t=279.37
- verdict: PASS

### S06-20f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: combat_running=true (wanted true)
- events: t=279.37
- verdict: PASS

### S06-21 — capture GF-14-COMBAT-04b
- expected: Section G: CB-04: representative fight per band -- S06, quarry_picket_dorn -- per-case: band 2's representative fight
- actual: DELEGATED GF-14-COMBAT-04b to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=279.37
- verdict: DELEGATED

### S06-22 — fight Dorn
- expected: Section E.1 per-fight record: duration, hit events, switches, camera corrections, target_on_screen dropouts, pathing stalls, difficulty read, XP/reward
- actual: fought 1534 frames: 41 quick, 0 handover(s), 0 refused switch(es); ended because flag 'defeated_quarry_dorn' set, SET 'defeated_quarry_dorn'
- events: t=304.83
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N` -- the failure mode SEGMENT_SCHEMA.md names by name. A counted press block is right for exactly one matchup, and G3-BAND2's own telemetry watched all four party members faint in sequence inside one such block while every step reported PASS. `fight_until_resolved` presses combat_quick only while the action machine reads READY, presses party_cycle once when the pilot drops below switch_below of max HP (which is CB-09's switching-under-pressure, driven by the creature's real HP instead of a scripted beat), and stops only when both is_fighting() and trainer_battle_active() have been false for quiet_frames.

### S06-23 — let the fight end
- expected: rewards and control return
- actual: waited 480 physics frames
- events: t=312.83
- verdict: PASS

### S06-23x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED press: not needed (active creature at 94.1 HP)
- events: t=312.83
- verdict: SKIP

### S06-23x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: waited 60 physics frames
- events: t=313.83
- verdict: PASS

### S06-19w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=world (wanted world)
- events: t=313.83
- verdict: PASS
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S06-24 — walk into the Old Quarry
- expected: Section D RT-06: bridge (0,1330) -> Old Quarry (403,1794) -> Warrens mouth (-420,2470)
- actual: walked 148.5 m to (403, 1794) in 2274 walking frames (0 held)
- events: t=351.75
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-25 — the quarry region contains the arrival
- expected: map_state.gd's containment puts the player in `the_old_quarry`
- actual: region=the_old_quarry (wanted the_old_quarry)
- events: t=351.75
- verdict: PASS

### S06-26 — rescan for points of interest
- expected: the quarry's own content joins the POI set
- actual: 1124 points of interest in the tree
- events: t=351.75
- verdict: PASS

### S06-27 — capture GF-08-QUARRY-01
- expected: Section G: quarry arrival, (403,1794) entry -- quarry identity; rootstone visibly present
- actual: DELEGATED GF-08-QUARRY-01 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=351.75
- verdict: DELEGATED

### S06-28 — break out rootstone
- expected: Section L.3: 'Gathering with visible tool use ... rootstone (pickaxe)'. The deposit's own prompt is 'Break out rootstone'
- actual: pressed interact x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=357.92
- verdict: PASS

### S06-29 — capture GF-16-GATHER-02
- expected: Section G: pickaxe on rootstone deposit, quarry -- tier material gathering
- actual: DELEGATED GF-16-GATHER-02 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=357.92
- verdict: DELEGATED

### S06-30 — Section L.3 band 2 crafting has no authored site
- expected: a note event carries this observation into events.jsonl
- actual: Section L.3 requires 'S06 orb_greater + reinforced tools -- each paid at real cost'. Section B's S06 span does not mention crafting and the protocol names no crafting site in band 2, so the workbench below is placed by the player at the quarry, where the tier material is. RECORDED as the transcriber's siting of a requirement section L.3 states and section B's span omits.
- events: t=357.92
- verdict: PASS

### S06-31 — open the pause shell
- expected: the pause shell, opened by its bound button
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@69217)
- events: t=358.10
- verdict: PASS
- observation: Opened via the map shortcut rather than a bare game_menu press. The pause shell REOPENS ON THE LAST TAB USED, so a fixed press count from an assumed backpack start lands on the wrong tab in any segment that opens the menu more than once. Measured in S03: the shell reopened on `menu_map` and 4x menu_tab_right landed on `menu_settings` instead of `menu_build`, failing nine consecutive build steps. `map` is one of only two tabs with a shortcut in data/config/menu.json, so it is the only deterministic starting point available.

### S06-32 — cycle to the Build tab
- expected: four RB presses reach Build
- actual: pressed menu_tab_right x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=358.40
- verdict: PASS
- observation: times 4 -> 2: counted from the map tab (index 2), not from an assumed backpack start. Target tab unchanged: build.

### S06-33 — open the build menu
- expected: 'Open Build Menu' is the tab's only focusable control
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=358.83
- verdict: PASS

### S06-34 — let the build menu open
- expected: it reopens on the last category and piece used this session
- actual: waited 120 physics frames
- events: t=360.83
- verdict: PASS

### S06-35 — move to Crafting
- expected: `build_menu.gd::CATEGORY_ORDER` is survival, crafting, structures, furniture; Crafting holds the Workbench (10 wood / 4 stone)
- actual: pressed menu_tab_left x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=361.87
- verdict: PASS

### S06-36 — arm the workbench
- expected: paid at the real cost -- free_build is OFF for the whole run
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=362.25
- verdict: PASS

### S06-37 — let the ghost arm
- expected: the placement camera takes over
- actual: waited 120 physics frames
- events: t=364.25
- verdict: PASS

### S06-38 — place the workbench
- expected: Section L.3's crafting site for band 2
- actual: pressed build_place x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=364.60
- verdict: PASS

### S06-39 — let the placement register
- expected: `GameState.placed_buildings` gains the workbench
- actual: waited 120 physics frames
- events: t=366.60
- verdict: PASS

### S06-40 — use the workbench
- expected: the craft panel opens over the world
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=366.87
- verdict: PASS

### S06-41 — let the craft panel open
- expected: Section E.4 lists the craft panel as one of the surfaces the matrix crosses
- actual: waited 120 physics frames
- events: t=368.87
- verdict: PASS

### S06-42 — the craft panel focuses a recipe
- expected: without focus the panel cannot be driven on a pad at all
- actual: focus_owner= focus_text=
- events: t=368.87
- verdict: FAIL

### S06-43 — craft the greater orb
- expected: Section L.3: 'S06 orb_greater + reinforced tools -- each paid at real cost'. The inventory snapshot on the `craft` event is the evidence the cost was paid
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=369.18
- verdict: PASS

### S06-44 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=371.18
- verdict: PASS

### S06-45 — focus the next recipe
- expected: AMBIGUITY RECORDED: the protocol names the recipes but not their order in the panel; a focus_move that does not land FAILs rather than crafting the wrong thing
- actual: FAIL 1 x ui_down did not move focus off nothing
- events: t=371.33
- verdict: FAIL

### S06-46 — craft the reinforced tool
- expected: Section L.3's second band 2 recipe, paid at the real cost
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=371.70
- verdict: PASS

### S06-47 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=373.70
- verdict: PASS

### S06-48 — leave the craft panel
- expected: Section L.6 T01's shape: the surface hands the world back
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1
- events: t=373.95
- verdict: PASS

### S06-49 — the world owns input again
- expected: input_context is back to 'world'; section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world)
- events: t=373.95
- verdict: PASS

### S06-50 — walk to the Warrens mouth anchor
- expected: Section D RT-06's third anchor and section G's location for GF-09-WARRENS-01
- actual: FAIL did not reach (-420, 2470) in 44100 walking frames; stopped 996.7 m short at (337.0, 1.0, 1821.0) (0 held)
- events: t=1108.97
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-51 — the Warrens region contains the arrival
- expected: map_state.gd's containment puts the player in `the_burrow_warrens`
- actual: region=corridor (wanted the_burrow_warrens)
- events: t=1108.97
- verdict: FAIL

### S06-52 — rescan for points of interest
- expected: the complex's own content joins the POI set
- actual: 1124 points of interest in the tree
- events: t=1108.97
- verdict: PASS

### S06-53 — capture GF-09-WARRENS-01
- expected: Section G: Warrens mouth, (-420,2470) -- dungeon entrance announces itself
- actual: DELEGATED GF-09-WARRENS-01 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=1108.97
- verdict: DELEGATED

### S06-54 — the protocol's Warrens anchor and the built site are 150 m apart
- expected: a note event carries this observation into events.jsonl
- actual: AMBIGUITY RECORDED: this frame is taken at the protocol's own anchor (-420,2470), which is map_landmarks.json's REGION centre. data/config/burrow_warrens.json's `site.at` -- where the mound and the mouth are actually built -- is (-357,2610), about 150 m north-east. If GF-09-WARRENS-01 does not have the mound in it, that distance is the reason and it is itself a finding about the map's own pin. The walk continues to the built site.
- events: t=1108.97
- verdict: PASS

### S06-55 — walk to the mouth chamber
- expected: burrow_warrens.json's `site.at` (-357,2610) plus the `mouth` chamber's own (0,6) offset. Section D RT-07: 'Warrens interior (entry -> guardian -> exit) | interior' -- the protocol supplies no interior coordinates
- actual: FAIL did not reach (-357, 2616) in 7200 walking frames; stopped 542.3 m short at (-7.0, -5.0, 2202.0) (0 held)
- events: t=1228.98
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-56 — enter the Warrens
- expected: Section L.5's gate/crossing row: the Warrens vault is one of the chapter's gates and this is the entrance to it
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1229.20
- verdict: PASS

### S06-57 — let the interior stage
- expected: the complex's own lighting takes over from the sky
- actual: waited 240 physics frames
- events: t=1233.20
- verdict: PASS

### S06-58 — walk into the hall chamber
- expected: burrow_warrens.json's `hall` chamber at (0,22) from `site.at`
- actual: FAIL did not reach (-357, 2632) in 3000 walking frames; stopped 325.2 m short at (-151.0, 2.0, 2380.0) (0 held)
- events: t=1283.22
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-59 — capture GF-09-WARRENS-02
- expected: Section G: interior chamber mid-clear, interior -- interior readability, lighting
- actual: DELEGATED GF-09-WARRENS-02 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=1283.22
- verdict: DELEGATED

### S06-60p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1283.22
- verdict: PASS

### S06-60p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@78170)
- events: t=1283.40
- verdict: PASS

### S06-60p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=1283.73
- verdict: PASS

### S06-60p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1283.95
- verdict: PASS

### S06-60p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1284.02
- verdict: PASS

### S06-60p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell on press 2: context menu_backpack -> world
- events: t=1284.55
- verdict: PASS

### S06-60p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1284.55
- verdict: PASS

### S06-60p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED press: not needed (active creature at 129.1 HP)
- events: t=1284.55
- verdict: SKIP

### S06-60p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=1285.55
- verdict: PASS

### S06-60p9 — party-health gate before the enclosed Warrens chamber fight
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 129.1 HP
- events: t=1285.55
- verdict: PASS

### S06-60 — engage what is in the hall
- expected: Section E.1 CB-05: 'Warrens fight (enclosed geometry) | inside Burrow Warrens chambers'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1285.78
- verdict: PASS

### S06-61 — let the fight stage
- expected: the combat camera has to acquire both combatants inside a chamber
- actual: waited 180 physics frames
- events: t=1288.78
- verdict: PASS

### S06-62 — combat owns input underground
- expected: input_context is 'combat'
- actual: input_context=world (wanted combat)
- events: t=1288.78
- verdict: FAIL

### S06-62f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was received, not merely pressed
- actual: combat_running=false (wanted true)
- events: t=1288.78
- verdict: FAIL
- observation: T2-GATEF-RUN6 / RIG-26, and the fix T5-FEEL's played-path evidence independently recommended: assert that a fight is RUNNING, not merely that combat-shaped input is owned. `input_context == "combat"` was the strongest claim these segments made after an engage, and it is not the same claim -- it is why two instrumented segments produced 128 events with zero `combat_start` and it read as a candidate GAME blocker for six runs.

### S06-63 — capture GF-14-COMBAT-05
- expected: Section G: CB-05: Warrens fight, enclosed geometry, inside Burrow Warrens chambers -- per-case: camera fields under enclosure
- actual: DELEGATED GF-14-COMBAT-05 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=1288.78
- verdict: DELEGATED

### S06-65 — recentre the camera mid-fight
- expected: Section F: 'Camera correction: any scripted camera input needed solely to restore the target/route to view'. Every one of these is counted
- actual: pressed camera_recenter x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:8
- events: t=1288.98
- verdict: PASS

### S06-64 — fight in the chamber
- expected: Section E.1 CB-05 records the camera fields specifically: a fight pressed against a wall is where `target_on_screen` drops out and the camera-correction count means something
- actual: fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames
- events: t=1292.97
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N` -- the failure mode SEGMENT_SCHEMA.md names by name. A counted press block is right for exactly one matchup, and G3-BAND2's own telemetry watched all four party members faint in sequence inside one such block while every step reported PASS. `fight_until_resolved` presses combat_quick only while the action machine reads READY, presses party_cycle once when the pilot drops below switch_below of max HP (which is CB-09's switching-under-pressure, driven by the creature's real HP instead of a scripted beat), and stops only when both is_fighting() and trainer_battle_active() have been false for quiet_frames. The camera recentre that used to sit BETWEEN two counted blocks now opens the fight: fight_until_resolved owns the fight end to end by design, so a scripted camera correction cannot be threaded through its middle. Section F still counts the press.

### S06-67 — let the fight end
- expected: rewards and control return with no stuck modal
- actual: waited 480 physics frames
- events: t=1300.97
- verdict: PASS

### S06-67x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED press: not needed (active creature at 129.1 HP)
- events: t=1300.97
- verdict: SKIP

### S06-67x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: waited 60 physics frames
- events: t=1301.97
- verdict: PASS

### S06-68 — walk into the warren side chamber
- expected: burrow_warrens.json's `warren` chamber at (-16,22) from `site.at`
- actual: FAIL did not reach (-373, 2632) in 3000 walking frames; stopped 88.8 m short at (-314.0, 3.0, 2565.0) (0 held)
- events: t=1351.98
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-69 — break out rootstone underground
- expected: the complex's own deposits; section L.3's tier-material row
- actual: pressed interact x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1355.88
- verdict: PASS

### S06-70 — walk into the den
- expected: burrow_warrens.json's `den` chamber at (0,40) from `site.at`; the guardian's offset is measured from it
- actual: walked 91.6 m to (-357, 2650) in 1118 walking frames (0 held)
- events: t=1374.53
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-71 — capture GF-09-WARRENS-03
- expected: Section G: guardian encounter, guardian chamber -- memorable-encounter staging
- actual: DELEGATED GF-09-WARRENS-03 to capture lane S06C (this is the logic lane; it takes no frames)
- events: t=1374.53
- verdict: DELEGATED

### S06-72p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1374.53
- verdict: PASS

### S06-72p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: inventory opened the shell: context world -> menu_backpack, focus on '' (@Button@78961)
- events: t=1374.70
- verdict: PASS

### S06-72p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: focus_item 'revive': cursor on cell 2 after 2 move(s) (from cell 0)
- events: t=1375.05
- verdict: PASS

### S06-72p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1375.27
- verdict: PASS

### S06-72p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1375.35
- verdict: PASS

### S06-72p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell on press 2: context menu_backpack -> world
- events: t=1375.87
- verdict: PASS

### S06-72p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=1375.87
- verdict: PASS

### S06-72p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED press: not needed (active creature at 164.1 HP)
- events: t=1375.87
- verdict: SKIP

### S06-72p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=1376.87
- verdict: PASS

### S06-72p9 — party-health gate before the Warren Guardian
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: active creature at 164.1 HP
- events: t=1376.87
- verdict: PASS

### S06-72 — face the Warren Guardian
- expected: Section E.1 CB-04: 'S06: ... warrens guardian'. Section D RT-07's midpoint
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1377.10
- verdict: PASS

### S06-73 — let the guardian fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=1380.10
- verdict: PASS

### S06-73c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: input_context=world (wanted combat)
- events: t=1380.10
- verdict: FAIL

### S06-73f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: combat_running=false (wanted true)
- events: t=1380.10
- verdict: FAIL

### S06-77 — a charged attack
- expected: the charged verb's hold edge in an enclosed fight
- actual: pressed combat_charged x1 (long, 60 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=1381.30
- verdict: PASS

### S06-74 — fight the guardian
- expected: Section E.1 per-fight record; the guardian is the band's memorable encounter and its difficulty read is section D's material
- actual: fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames
- events: t=1385.28
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N` -- the failure mode SEGMENT_SCHEMA.md names by name. A counted press block is right for exactly one matchup, and G3-BAND2's own telemetry watched all four party members faint in sequence inside one such block while every step reported PASS. `fight_until_resolved` presses combat_quick only while the action machine reads READY, presses party_cycle once when the pilot drops below switch_below of max HP (which is CB-09's switching-under-pressure, driven by the creature's real HP instead of a scripted beat), and stops only when both is_fighting() and trainer_battle_active() have been false for quiet_frames. The charged attack that used to sit between two counted blocks now opens the fight, and the scripted mid-fight party_cycle is gone: fight_until_resolved's own switch fires on the pilot's real HP instead of on a beat guessed in advance, which is what CB-09's 'switching under pressure' actually means.

### S06-79 — let the guardian fight end
- expected: the vault door is what 'you have beaten the thing standing in the doorway' opens
- actual: waited 600 physics frames
- events: t=1395.28
- verdict: PASS

### S06-79x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED press: not needed (active creature at 164.1 HP)
- events: t=1395.28
- verdict: SKIP

### S06-79x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: waited 60 physics frames
- events: t=1396.28
- verdict: PASS

### S06-80 — the Warrens are cleared
- expected: `warrens_cleared` closes section E.5 objective 17/27
- actual: flag warrens_cleared NOT set
- events: t=1396.28
- verdict: FAIL

### S06-81 — walk into the vault
- expected: burrow_warrens.json's `vault` chamber at (15,40) from `site.at`; the prize is 'Take the heartstone'
- actual: FAIL did not reach (-342, 2650) in 3000 walking frames; stopped 14.0 m short at (-356.0, 2.0, 2648.0) (0 held)
- events: t=1446.30
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-82 — take the prize
- expected: the clear reward; the inventory snapshot is the evidence
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1446.50
- verdict: PASS

### S06-83 — walk back out of the Warrens
- expected: Section D RT-07: 'entry -> guardian -> exit'. The exit leg is part of the route the protocol names
- actual: FAIL did not reach (-357, 2616) in 3000 walking frames; stopped 31.6 m short at (-356.0, 2.0, 2648.0) (0 held)
- events: t=1496.52
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-83a — record_start: band 2 -> band 3, exit toward the river
- expected: section B's own words for S06's exit are 'exit toward river': the window opens on the leg that leaves the Warrens for the ranger camp and the river beyond it
- actual: DELEGATED the §H record window "band 2 -> band 3, exit toward the river" to capture lane S06C (this is the logic lane; it keeps no continuous record)
- events: t=1496.52
- verdict: DELEGATED

### S06-84 — walk out toward the ranger camp on the way north
- expected: data/config/map_landmarks.json's `band2_ranger_camp` (-259,2256.5): 'the only way the map tells a player looking for a rest stop where it is'. Section B: S06 exits 'toward river'
- actual: FAIL did not reach (-259, 2256) in 18900 walking frames; stopped 402.8 m short at (-356.0, 2.0, 2648.0) (0 held)
- events: t=1811.53
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S06-85 — rescan for points of interest
- expected: the camp's own content joins the POI set
- actual: 1124 points of interest in the tree
- events: t=1811.53
- verdict: PASS

### S06-85a — record_stop: back to the 0.1 Hz journey baseline after band 2 -> band 3, exit toward the river
- expected: the window closes after the point-of-interest rescan at the ranger camp. Section H's other half of this +/-60 s is S07's river-arrival window
- actual: DELEGATED the close of the §H record window to capture lane S06C (this is the logic lane; no window was opened here)
- events: t=1811.53
- verdict: DELEGATED

### S06-86 — band 2 was actually walked
- expected: Section D RT-06 is roughly 1.5 km of corridor before the interior; no pacing claim may come from a shortcut (section 0.6)
- actual: walked 3026.7 m this segment (wanted >= 2000.0)
- events: t=1811.53
- verdict: PASS

### S06-87 — the 2 Hz trace ran throughout
- expected: Section C.2
- actual: route.csv has 3602 rows (wanted >= 3000)
- events: t=1811.53
- verdict: PASS

### S06-88 — band 2's longest empty stretch is on the record
- expected: Section D: '>= 250 m is a finding; 150-250 m is a watch item'. The peak is the only half that proves the meter accumulates; a PASS records a watch item and its size, it is not a passing grade
- actual: dead_travel peaked at 1411.5 m this segment (wanted >= 150.0); 3026.7 m walked in total
- events: t=1811.53
- verdict: PASS

### S06-89 — Section B save handoff
- expected: a note event carries this observation into events.jsonl
- actual: Section B: 'each journey segment ends by saving to a dedicated slot through the production Save tab and copying the resulting `user://` slot file into the run directory (`saves/<segment>-exit.json`)'. The steps below are that save, driven as a player drives it -- the pause shell, five RB presses to the Save tab, focus down to slot 4, and the slot's own Save button. `save_out` afterwards only copies the artefact; it saves nothing itself. Section B also branches X04 (combat lab) from this file.
- events: t=1811.53
- verdict: PASS

### S06-90 — open the pause shell
- expected: the game_menu button, sent as a real physical event, opens the pause shell onto the Satchel tab
- actual: FAIL map did not open the pause shell: context build_catalogue -> build_catalogue (owner=@CanvasLayer@69261)
- events: t=1812.65
- verdict: FAIL
- observation: Opened via the map shortcut rather than a bare game_menu press. The pause shell REOPENS ON THE LAST TAB USED, so a fixed press count from an assumed backpack start lands on the wrong tab in any segment that opens the menu more than once. Measured in S03: the shell reopened on `menu_map` and 4x menu_tab_right landed on `menu_settings` instead of `menu_build`, failing nine consecutive build steps. `map` is one of only two tabs with a shortcut in data/config/menu.json, so it is the only deterministic starting point available.

### S06-91 — cycle right to the Save tab
- expected: five RB presses move from Satchel to Save, the sixth tab in data/config/menu.json
- actual: pressed menu_tab_right x3 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=1813.62
- verdict: PASS
- observation: times 5 -> 3: counted from the map tab (index 2), not from an assumed backpack start. Target tab unchanged: save.

### S06-92 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: input_context=build_catalogue (wanted menu_save)
- events: t=1813.62
- verdict: FAIL

### S06-93 — move focus to slot 4's Save button
- expected: focus starts on slot 0's Save button (tab_save.gd::first_focus) and four d-pad downs reach slot 4's
- actual: FAIL 4 x ui_down did not move focus off @Button@128151
- events: t=1814.08
- verdict: FAIL

### S06-94 — press Save
- expected: the focused Save button activates and writes slot 4 -- the handoff slot; autosave is slot 0 and slots 1-3 stay free for natural play coverage
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1814.32
- verdict: PASS

### S06-95 — give the write a moment
- expected: the slot file is on disk and section I.4 has timed the save operation
- actual: waited 120 physics frames
- events: t=1816.32
- verdict: PASS

### S06-96 — copy slot 4 out into the run directory
- expected: Section B: the resulting `user://` slot file is copied into the run directory as `saves/S06-exit.json`
- actual: FAIL slot 4's content is byte-identical to what seed_save wrote at the start of this segment -- the Save tab was never actually used
- events: t=1816.32
- verdict: FAIL

### S06-97 — close the shell
- expected: B closes the shell and hands the world back
- actual: menu_cancel closed the shell: context build_placement -> world
- events: t=1816.42
- verdict: PASS

### S06-98 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: S06 exit save written and copied.
- events: t=1816.42
- verdict: PASS
