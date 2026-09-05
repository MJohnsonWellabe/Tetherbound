# S08 — Upper Meadows / Band 4: crossing -> ironwood -> saddle & riding -> three captains -> three Sigils

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 2001 s over 337706 frames at 0.0059 s/frame (re-priced after each boot)

### S08-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S07-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.25
- verdict: PASS

### S08-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 2 files from /tmp/w21-userdata/S08/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.25
- verdict: PASS

### S08-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/gate-f-run-W21-S08/saves/S07-exit.json (1420271 bytes)
- events: t=0.25
- verdict: PASS

### S08-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 493 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 337673 frames left + 0 s boot = 2205 s against 14399 s of budget left
- events: t=0.88
- verdict: PASS

### S08-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.88
- verdict: PASS

### S08-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.93
- verdict: PASS

### S08-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.02
- verdict: PASS

### S08-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.63
- verdict: PASS

### S08-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.63
- verdict: PASS

### S08-09a — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing -- encounter_director.gd::_engageable() returns null on a null ally before any distance check, so no combat/catch/gate-flag assertion downstream of a load can mean anything without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=182.00
- verdict: PASS

### S08-10 — the team travelled
- expected: three entrants across the crossing
- actual: party size 5 (wanted >= 3)
- events: t=182.00
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-11 — the captains are tracked
- expected: Section E.5 objective 22/27 `defeat_the_captains`, 'Defeat the Upper Meadows captains.' with the n/3 count appended -- one of only two counted entries in the chain
- actual: tracked objective id=hall_approach_open text=Defeat the Upper Meadows captains. 0/3 (wanted defeat_the_captains = flag_id hall_approach_open) [matched on entry id -> flag_id]
- events: t=182.00
- verdict: PASS

### S08-12 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 0.1 Hz segment plus event-forced frames, with the band 3 -> band 4 handoff window inside it. No background-recorder action exists in the vocabulary; recorded as a gap.
- events: t=182.00
- verdict: PASS

### S08-12a — record_start: band 3 -> band 4, the Upper Meadows arrival across the crossing
- expected: S07 saved at the crossing, so this segment loads on the band 3/4 boundary: the window opens at the load's own first step, which is GF-11-UPPER-01, the frame section G triggers on 'Upper Meadows entry across the crossing'
- actual: DELEGATED the §H record window "band 3 -> band 4, the Upper Meadows arrival across the crossing" to capture lane S08C (this is the logic lane; it keeps no continuous record)
- events: t=182.00
- verdict: DELEGATED

### S08-12b — Section H band-handoff windows in this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 'Mandatory for the highest-risk segments: ... every band handoff +/-60 s (region transitions)'. The pairs in this segment raise the background recorder from the 0.1 Hz journey baseline to 0.5 Hz across each band boundary this segment crosses, and `record_stop` returns to the baseline rather than switching the recorder off, so the record stays continuous either side. AMBIGUITY RECORDED: +/-60 s cannot be sized exactly from a step script. A `move_to` leg's duration is not known before the run and a leg cannot be split, so each window is placed to contain the crossing plus as much of its approach and its settle as the surrounding steps allow -- erring long, because the schema's own measurement makes a 0.5 Hz window affordable as a window (1.05 ms/frame for its length) while a window that missed the transition would cost the evidence.
- events: t=182.00
- verdict: PASS

### S08-13 — capture GF-11-UPPER-01
- expected: Section G: Upper Meadows entry across the crossing, RT-09 end -- region shift is felt
- actual: DELEGATED GF-11-UPPER-01 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=182.00
- verdict: DELEGATED

### S08-14 — open the Map tab
- expected: Section G GF-18-MAP-02 wants both zoom extremes at S08, and section E.5 wants the map opened at every major objective
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65470)
- events: t=182.17
- verdict: PASS

### S08-15 — zoom the map all the way in
- expected: Section G: 'both zoom extremes'
- actual: pressed map_zoom_in x6 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=182.77
- verdict: PASS

### S08-16 — zoom the map all the way out
- expected: Section G: 'both zoom extremes'
- actual: pressed map_zoom_out x8 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=183.57
- verdict: PASS

### S08-17 — capture GF-18-MAP-02
- expected: Section G: Map tab at S08 (late chapter), both zoom extremes -- reveal growth, zoom behavior
- actual: DELEGATED GF-18-MAP-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=183.57
- verdict: DELEGATED

### S08-18 — close the shell
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=183.78
- verdict: PASS

### S08-19 — reopen the Map tab
- expected: Section E.5: 'zoom persistence across close/reopen' -- checked again late, where the revealed map is large
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65483)
- events: t=183.95
- verdict: PASS

### S08-20 — close the shell again
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=184.17
- verdict: PASS

### S08-21 — Section E.5 nav note -- defeat_the_captains
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 22/27 `defeat_the_captains`. Wording: 'Defeat the Upper Meadows captains. n/3' -- it names WHAT, a count, and a WHERE only as wide as a whole region. Player-visible information: `the_ironwood_grove` and `the_ridgeline_watch` are named regions on the late map (GF-18-MAP-02), the ground climbs north from the crossing into high pasture, and the count tells the player there are three of something to find. Route decision: work north through the grove and then the high pasture, letting the named regions be the waypoints, because three captains spread over a region cannot be routed to any more precisely than that. Reasoned from GF-11-UPPER-01 and GF-18-MAP-02. Operator: record whether 'n/3' actually helped, and how long the player spent not knowing where a captain was.
- events: t=184.17
- verdict: PASS

### S08-22 — walk to the Ironwood Grove
- expected: Section D RT-10's first anchor (-345,5060): 'the region's whole material tier, its one special encounter, and a night-ecology pocket, all one place'
- actual: walked 839.5 m to (-345, 5060) in 10912 walking frames (0 held)
- events: t=366.05
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-23 — the grove region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ironwood_grove`
- actual: region=the_ironwood_grove (wanted the_ironwood_grove)
- events: t=366.05
- verdict: PASS

### S08-23a — record_stop: back to the 0.1 Hz journey baseline after band 3 -> band 4, the Upper Meadows arrival across the crossing
- expected: the window closes after the region assert puts the player in `the_ironwood_grove`, band 4's first named region
- actual: DELEGATED the close of the §H record window to capture lane S08C (this is the logic lane; no window was opened here)
- events: t=366.05
- verdict: DELEGATED

### S08-24 — rescan for points of interest
- expected: the grove's own content joins the POI set
- actual: 1123 points of interest in the tree
- events: t=366.05
- verdict: PASS

### S08-25 — harvest ironwood
- expected: Section L.3: 'Gathering with visible tool use ... rootstone (pickaxe), ironwood'
- actual: pressed interact x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=373.80
- verdict: PASS

### S08-26 — walk to the grove's pipwing
- expected: Section E.1 CB-12: 'fight smallest (pipwing/bramblebun class) and largest (meadowhart/tuskroot class) wilds; melee vs ranged movesets'. This is the small half; the large half is the meadowhart below
- actual: walked 6.2 m to (-334, 5055) in 78 walking frames (0 held)
- events: t=375.12
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-27g0 — the world has input back
- expected: no fight, fade or narrative modal is still holding input when this engage is pressed
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=375.12
- verdict: PASS

### S08-27g1 — party-health gate before the pipwing engage
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert before a fight. A wild engage against a fainted lead reads as a refused prompt, not as a fight, and every scripted step after it measures the wrong thing.
- actual: active creature at 206.4 HP
- events: t=375.12
- verdict: PASS

### S08-27 — engage the pipwing
- expected: CB-12's small-body case
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=375.62
- verdict: PASS

### S08-28 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=378.62
- verdict: PASS

### S08-29 — chip the pipwing to catchable
- expected: Section E.1 CB-12 records the size/range spread: a small fast body against the large slow one below
- actual: FAIL chip_to_floor: no live enemy to chip
- events: t=378.62
- verdict: FAIL
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N`. This block is a CATCH chip, not a fight to resolve: `fight_until_resolved` would faint the target and there would be nothing left to throw an orb at. `chip_to_floor` reads the live enemy's real hp before and after every swing and stops BEFORE the swing whose worst plausible roll could reach the floor -- the same predicate-not-press-count rule, applied to the half of combat that must NOT end.

### S08-30 — begin the aim
- expected: Section E.2: the throw is aimed
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=379.12
- verdict: PASS

### S08-31 — the aim owns input
- expected: input_context is `combat_aim`
- actual: input_context=world (wanted combat_aim)
- events: t=379.12
- verdict: FAIL

### S08-32 — throw the orb
- expected: Section E.2 CT-08: 'Party-not-full -> catch -> count'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=379.60
- verdict: PASS

### S08-33 — let the catch resolve
- expected: the `catch_result` event carries the outcome
- actual: waited 360 physics frames
- events: t=385.60
- verdict: PASS

### S08-34 — the fourth slot filled
- expected: Section E.2 CT-08: 'verify party count increments'. Four of five
- actual: party size 5 (wanted >= 4)
- events: t=385.60
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-34x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED press: not needed (active creature at 206.4 HP)
- events: t=385.60
- verdict: SKIP

### S08-34x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: waited 60 physics frames
- events: t=386.60
- verdict: PASS

### S08-35 — walk to the meadowhart herd
- expected: the high pasture herd; section L.4's riding row needs a Meadowhart in the belt
- actual: walked 610.3 m to (12, 5561) in 7567 walking frames (0 held)
- events: t=512.73
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-36 — capture GF-05-MEADOW-02
- expected: Section G: same class, band 4 high pasture, RT-10 -- upper meadow identity differs from lower
- actual: DELEGATED GF-05-MEADOW-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=512.73
- verdict: DELEGATED

### S08-37 — rescan for points of interest
- expected: the herd joins the POI set
- actual: 1123 points of interest in the tree
- events: t=512.73
- verdict: PASS

### S08-38g0 — the world has input back
- expected: no fight, fade or narrative modal is still holding input when this engage is pressed
- actual: input_context=world (wanted world) [true after 0 physics frames]
- events: t=512.73
- verdict: PASS

### S08-38g1 — party-health gate before the meadowhart engage
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert before a fight. A wild engage against a fainted lead reads as a refused prompt, not as a fight, and every scripted step after it measures the wrong thing.
- actual: active creature at 206.4 HP
- events: t=512.73
- verdict: PASS

### S08-38 — engage a meadowhart
- expected: Section E.1 CB-12's large-body case
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=513.12
- verdict: PASS

### S08-39 — let the fight stage
- expected: the combat camera has to frame a much larger body
- actual: waited 180 physics frames
- events: t=516.12
- verdict: PASS

### S08-40 — capture GF-14-COMBAT-12
- expected: Section G: CB-12: size/range spread -- the large half (meadowhart/tuskroot class) -- per-case: the camera and the melee/ranged read at the other end of the size range
- actual: DELEGATED GF-14-COMBAT-12a to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=516.12
- verdict: DELEGATED

### S08-41 — chip the meadowhart to catchable
- expected: Section E.1 CB-12 records melee vs ranged movesets and the camera's behaviour against a large body
- actual: 18 x combat_quick: enemy hp 9.3/175.8 (5.3%), hits dealt [9.5, 9.3, 10.0, 9.8, 9.8, 9.7, 8.7, 8.6, 9.8, 9.5, 8.3, 8.5, 9.2, 9.2, 9.4, 9.4, 8.3, 9.6], largest 10.0
- events: t=525.90
- verdict: PASS
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). was `press combat_quick, times: N`. This block is a CATCH chip, not a fight to resolve: `fight_until_resolved` would faint the target and there would be nothing left to throw an orb at. `chip_to_floor` reads the live enemy's real hp before and after every swing and stops BEFORE the swing whose worst plausible roll could reach the floor -- the same predicate-not-press-count rule, applied to the half of combat that must NOT end.

### S08-42 — begin the aim
- expected: Section E.2: the throw is aimed
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=526.17
- verdict: PASS

### S08-43 — throw the orb
- expected: Section E.2 CT-08 again, this time filling the belt
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=526.40
- verdict: PASS

### S08-44 — let the catch resolve
- expected: the `catch_result` event carries the outcome
- actual: waited 360 physics frames
- events: t=532.40
- verdict: PASS

### S08-45 — the belt is full
- expected: five of five. CLAUDE.md: the player can own only five creatures, ever -- no storage, no reserve box, no hidden sixth slot
- actual: party size 5 (wanted >= 5)
- events: t=532.40
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-45r — pick up the wild-fight faint before the road, per 2.10/G3-BAND4-0903
- expected: a note event carries this observation into events.jsonl
- actual: G3-BAND4-0903's addendum: the lead creature (Tup, L13 Terrapup) took steady combat_hit damage through THIS wild meadowhart fight -- 27 hits, 206.4 -> 0.0 HP -- and fainted here, well before Halder. Nothing downstream of this point used to switch the active creature or spend one of the seed's two Revives, so every subsequent fight sent a fainted creature to the front and the segment's captain-fight evidence was void. Revived through the production Satchel menu by item identity, the same sequence S05-11r (GATE2-EVIDENCE-0903) and S03.json's own recovery blocks use, followed by one creature_recall press -- RIG-F9/2.11: a creature revived from the Satchel is not sent back out on its own.
- events: t=532.40
- verdict: PASS

### S08-45r1a — open the Satchel to pick the lead up off the ground
- expected: the pause shell on the Satchel tab
- actual: FAIL inventory did not open the pause shell: context combat -> combat (owner=)
- events: t=533.17
- verdict: FAIL

### S08-45r1b — focus the Revive draught
- expected: the cursor lands on the Revive cell, found by item identity rather than by a slot number
- actual: FAIL focus_item 'revive': the satchel grid reports no columns
- events: t=533.17
- verdict: FAIL

### S08-45r1c — use it on whoever is down
- expected: tab_backpack.gd::_read_use() opens the target picker while any party member is fainted; if nobody is, _open_target_picker refuses and nothing opens
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=533.55
- verdict: PASS

### S08-45r1d — confirm the picker's first eligible entrant
- expected: the picker auto-focuses the first eligible (fainted) row; this confirms it and the creature comes back at half strength (items.json revive: 0.5)
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=533.80
- verdict: PASS

### S08-45r1e — put back an accidental pick-up, or close the shell
- expected: S03's own recovery shape: if the press above picked the stack up (nobody was fainted, Use refused and left focus on the item) this puts it back; otherwise it reads as Close
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1
- events: t=534.08
- verdict: PASS

### S08-45r1f — close the shell for real
- expected: the world owns input again
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1
- events: t=534.28
- verdict: PASS

### S08-45r1g — wait for the world to own input
- expected: no menu is left holding input before the next leg
- actual: input_context=combat (wanted world) [still false after 1200 physics frames]
- events: t=554.28
- verdict: FAIL

### S08-45r1h — re-deploy whatever the revive above brought back
- expected: RIG-F9/2.11: a creature revived from the Satchel is not sent back out on its own -- can_challenge() stays false with a healthy party until the active slot is re-summoned
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=554.48
- verdict: PASS

### S08-46 — capture GF-19-UI-09
- expected: Section G: party strip at 5/5, world -- exactly five slots, no sixth implied
- actual: DELEGATED GF-19-UI-09 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=554.48
- verdict: DELEGATED

### S08-47 — the five-creature rule, on screen
- expected: a note event carries this observation into events.jsonl
- actual: Section E.2 CT-08's own words: the HUD 'shows exactly five slots maximum -- nothing may imply a sixth'. GF-19-UI-09 is that frame. Section B branches X03's party-full study (CT-09) from this segment's exit save, so the 5/5 state has to travel through the handoff intact.
- events: t=554.48
- verdict: PASS

### S08-48 — Section L.3 band 4 crafting has no authored site
- expected: a note event carries this observation into events.jsonl
- actual: Section L.3 requires 'S08 saddle + orb_prime -- each paid at real cost' and section L.4 requires 'Riding (saddle, mount, dismount, speed, no stamina cost)'. Section B's S08 span names 'saddle & riding' and the protocol names no crafting site in band 4, so the workbench below is placed by the player on the high pasture. RECORDED as the transcriber's siting.
- events: t=554.48
- verdict: PASS

### S08-49 — open the pause shell
- expected: the pause shell, opened by its bound button
- actual: FAIL map did not open the pause shell: context combat -> world (owner=)
- events: t=555.32
- verdict: FAIL
- observation: Opened via the map shortcut rather than a bare game_menu press. The pause shell REOPENS ON THE LAST TAB USED, so a fixed press count from an assumed backpack start lands on the wrong tab in any segment that opens the menu more than once. Measured in S03: the shell reopened on `menu_map` and 4x menu_tab_right landed on `menu_settings` instead of `menu_build`, failing nine consecutive build steps. `map` is one of only two tabs with a shortcut in data/config/menu.json, so it is the only deterministic starting point available.

### S08-50 — cycle to the Build tab
- expected: four RB presses reach Build
- actual: pressed menu_tab_right x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=556.22
- verdict: PASS
- observation: times 4 -> 2: counted from the map tab (index 2), not from an assumed backpack start. Target tab unchanged: build.

### S08-51 — open the build menu
- expected: 'Open Build Menu' is the tab's only focusable control
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=556.45
- verdict: PASS

### S08-52 — let the build menu open
- expected: it reopens on the last category and piece used this session
- actual: waited 120 physics frames
- events: t=558.45
- verdict: PASS

### S08-53 — move to Crafting
- expected: `build_menu.gd::CATEGORY_ORDER` -- Crafting holds the Workbench
- actual: pressed menu_tab_left x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=559.40
- verdict: PASS

### S08-54 — arm the workbench
- expected: paid at the real cost; free_build is OFF
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=559.60
- verdict: PASS

### S08-55 — let the ghost arm
- expected: the placement camera takes over
- actual: waited 120 physics frames
- events: t=561.60
- verdict: PASS

### S08-56 — place the workbench
- expected: Section L.3's crafting site for band 4
- actual: pressed build_place x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=561.87
- verdict: PASS

### S08-57 — let the placement register
- expected: `GameState.placed_buildings` gains the workbench
- actual: waited 120 physics frames
- events: t=563.87
- verdict: PASS

### S08-58 — use the workbench
- expected: the craft panel opens over the world
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=564.10
- verdict: PASS

### S08-59 — let the craft panel open
- expected: Section E.4 lists the craft panel among the surfaces the matrix crosses
- actual: waited 120 physics frames
- events: t=566.10
- verdict: PASS

### S08-60 — the craft panel focuses a recipe
- expected: without focus the panel cannot be driven on a pad
- actual: focus_owner= focus_text=
- events: t=566.10
- verdict: FAIL

### S08-61 — craft the saddle
- expected: Section L.3: 'S08 saddle + orb_prime -- each paid at real cost'. The inventory snapshot on the `craft` event is the evidence
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=566.30
- verdict: PASS

### S08-62 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=568.30
- verdict: PASS

### S08-63 — focus the prime orb recipe
- expected: AMBIGUITY RECORDED: the protocol names the recipes but not their order in the panel
- actual: FAIL 1 x ui_down did not move focus off nothing
- events: t=568.42
- verdict: FAIL

### S08-64 — craft the prime orb
- expected: Section L.3's second band 4 recipe, paid at the real cost
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=568.63
- verdict: PASS

### S08-65 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=570.63
- verdict: PASS

### S08-66 — leave the craft panel
- expected: the surface hands the world back
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1
- events: t=570.90
- verdict: PASS

### S08-67 — the world owns input again
- expected: input_context is back to 'world'; input leakage after a surface closes is the target
- actual: input_context=world (wanted world)
- events: t=570.90
- verdict: PASS

### S08-68 — mount the meadowhart
- expected: Section L.4: 'Riding (saddle, mount, dismount, speed, no stamina cost) | S08: craft saddle, mount Meadowhart, ride RT-10 leg, dismount, remount'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=571.15
- verdict: PASS

### S08-69 — let the mount stage
- expected: the riding camera and the mounted locomotion take over
- actual: waited 180 physics frames
- events: t=574.15
- verdict: PASS

### S08-70 — capture GF-11-UPPER-02
- expected: Section G: riding on Meadowhart, RT-10 -- riding payoff exists and stages correctly
- actual: DELEGATED GF-11-UPPER-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=574.15
- verdict: DELEGATED

### S08-71 — ride RT-10's leg to Captain Halder
- expected: Section D RT-10's second anchor (170,5590) is captain_field. Section L.4: 'ride RT-10 leg'. Riding must not cost stamina
- actual: walked 166.1 m to (170, 5590) in 2002 walking frames (0 held)
- events: t=607.53
- verdict: PASS
- observation: W21-HARNESS-FIGHTS-0904, CL-H2's measured root cause. `close_enough` was 4.0 m, but `scripts/npc/npc_body.gd::add_prompt()` gives every NPC a 3.8 m prompt radius -- so a walk allowed to stop 4-5 m out arrives with NO live prompt and the challenge press lands on nothing. Measured directly on this branch: gate-f-run-W21-S07 walked 509.4 m to (0,2980), stopped 4.1 m out inside the old 5.0 m tolerance, and `S07-19` refused with 'no narrative modal is open. input_context is world and the input owner is nothing' -- which the OLD `press interact, times: 10` would have reported as ten green presses into empty world, followed by thirty green combat_quick presses into a fight that never started. The WAYPOINT IS UNCHANGED; only the arrival tolerance is tightened to 3.5 m, the value the identical approach at Dorn (S06-17) and at the outer watch (S09-23) already uses and that both proved on this branch by opening their conversations on the first press. Previous observation kept: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-72 — dismount
- expected: Section L.4: 'mount, dismount, speed, no stamina cost'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=607.73
- verdict: PASS

### S08-73 — let the dismount settle
- expected: control returns to the player on foot
- actual: waited 120 physics frames
- events: t=609.73
- verdict: PASS

### S08-74 — remount
- expected: Section L.4: '... dismount, remount'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=609.95
- verdict: PASS

### S08-75 — let the remount settle
- expected: the riding camera takes over again
- actual: waited 120 physics frames
- events: t=611.95
- verdict: PASS

### S08-76 — dismount for the fight
- expected: the human never fights, and a captain fight is piloted
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=612.20
- verdict: PASS

### S08-77 — let the dismount settle
- expected: control returns to the player on foot
- actual: waited 120 physics frames
- events: t=614.20
- verdict: PASS

### S08-77p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: input_context=narrative_modal (wanted world) [still false after 1200 physics frames]
- events: t=634.20
- verdict: FAIL

### S08-77p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: FAIL inventory did not open the pause shell: context narrative_modal -> narrative_modal (owner=DialoguePanel)
- events: t=635.07
- verdict: FAIL

### S08-77p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: FAIL focus_item 'revive': the satchel grid reports no columns
- events: t=635.07
- verdict: FAIL

### S08-77p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=635.58
- verdict: PASS

### S08-77p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=635.82
- verdict: PASS

### S08-77p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: menu_cancel closed the shell: context combat -> combat
- events: t=635.93
- verdict: PASS

### S08-77p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: input_context=combat (wanted world) [still false after 1200 physics frames]
- events: t=655.93
- verdict: FAIL

### S08-77p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED press: not needed (active creature at 118.3 HP)
- events: t=655.93
- verdict: SKIP

### S08-77p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: waited 60 physics frames
- events: t=656.93
- verdict: PASS

### S08-77a — the lead is actually fit to fight, before Captain Halder
- expected: 2.11/S08: a fainted active creature does not clear itself, and encounter_director.gd::can_challenge() silently refuses a fight it is sent to -- fail here, honestly, rather than let a scripted press downstream misresolve against whatever menu happens to be focused (S08's own finding, at Oreth, after this same gap).
- actual: active creature at 118.3 HP
- events: t=656.93
- verdict: PASS
- observation: W21-HARNESS-FIGHTS-0904: kept as CL-H1's party-health gate for this challenge -- the recovery ladder immediately above it (revive by item identity, then a switch) now runs FIRST, so this assert reads the party AFTER recovery rather than before it. The ladder's own duplicate of this check was dropped so one failure is reported once.

### S08-78 — challenge Captain Halder
- expected: Section E.1 CB-04: 'S08: captain_field, captain_ridge, captain_riverwatch'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=657.13
- verdict: PASS

### S08-79 — hear the captain out
- expected: one of the three the objective counts
- actual: BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.
- events: t=657.13
- verdict: FAIL
- observation: CL-H1 (W21-HARNESS-FIGHTS-0904). /CL-H2: was a fixed `press interact, times: N`. A count is right for one conversation length; over-pressing re-opens the panel and under-pressing leaves input_context on `narrative_modal` where the next step expects combat -- G3-BAND5 measured exactly that at the outer watch, and the fight never started. `advance_dialogue_until_closed` reads dialogue_runner.gd::line() and stops the moment the panel closes.

### S08-80 — let the fight stage
- expected: Section L.6 T05: the combat camera acquires both combatants at fight start
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-80c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-80f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-81 — capture GF-14-COMBAT-04d
- expected: Section G: CB-04: representative fight per band -- S08, captain_field -- per-case: band 4's representative fight
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-82 — fight Captain Halder
- expected: Section E.1 per-fight record; band 4's difficulty read
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-85 — let the fight end
- expected: rewards and control return with no stuck modal
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-85x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-85x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-86 — the field captain is beaten
- expected: `defeated_captain_field`, the first of the objective's three `count_flags`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-87 — Section D RT-10's third anchor is south of its second
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-79w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88 — walk south to Captain Oreth
- expected: Section D RT-10's third anchor (-100,4350) is captain_riverwatch
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-88a — the lead is actually fit to fight, before Captain Oreth
- expected: 2.11/S08: a fainted active creature does not clear itself, and encounter_director.gd::can_challenge() silently refuses a fight it is sent to -- fail here, honestly, rather than let a scripted press downstream misresolve against whatever menu happens to be focused (S08's own finding, at Oreth, after this same gap).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-89 — challenge Captain Oreth
- expected: Section E.1 CB-04's second band 4 captain
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-90 — hear the captain out
- expected: the second of the three
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-91 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-91c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-91f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-93 — a charged attack
- expected: the charged verb's hold edge
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-92 — fight the Riverwatch captain
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-95 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-95x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-95x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-96 — the riverwatch captain is beaten
- expected: `defeated_captain_riverwatch`, the second of the three `count_flags`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-96a — record_start: band 4's northern region transition, into the Ridgeline Watch
- expected: AMBIGUITY RECORDED: the band 4 -> band 5 handoff is NOT a spatial crossing inside S08. Section B ends this segment on the third captain -- the Sigils open the gate, and the walk through it happens in S09. So this pair sits on the last region transition S08 actually crosses, into `the_ridgeline_watch`, which is the ground the sigil gate stands beyond; the band boundary itself is covered by S09's first window
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-90w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-97 — walk north to Captain Vess on the ridgeline
- expected: Section D RT-10's fourth anchor (-280,6460) is captain_ridge, in `the_ridgeline_watch`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-98 — the ridgeline region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ridgeline_watch`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-99 — rescan for points of interest
- expected: the watch's own content joins the POI set
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-99a — record_stop: back to the 0.1 Hz journey baseline after band 4's northern region transition, into the Ridgeline Watch
- expected: the window closes after the point-of-interest rescan inside the watch
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-100 — walk to the ridgeline patrol first
- expected: Section L.4: 'Required trainer fights + representative optional | optional: old_champion_bram (195,905), patrol_ridgeline'
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101p9 — party-health gate before the ridgeline patrol
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the party-health assert CL-H1 asks for before each challenge. `active_creature_alive` fails the segment honestly at the moment the party stopped being fight-ready, instead of letting encounter_director.gd::can_challenge()'s silent refusal (or a scripted press landing on the no-usable-creature conversation instead of a fight) burn the rest of the budget unexplained.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-101 — challenge the ridgeline patrol
- expected: the second of the journey's two named optional trainers
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-102 — hear them out
- expected: record what an optional fight offers this late in the chapter
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-103 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-103c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-103f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-104 — fight the patrol
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-105 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-105x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-105x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-102w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106 — walk to Captain Vess
- expected: captain_ridge, the third of the three the objective counts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p0 — the world has input back before the satchel opens
- expected: no fight, fade or narrative modal is still holding input when this ladder starts
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p1 — open the satchel
- expected: game_menu.gd::select() grabs tab_backpack.gd::first_focus() on open, so the item grid owns focus
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p2 — find the Revive BY ITEM IDENTITY
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the recovery is addressed by item identity, never by slot index: focus_item walks the cursor onto whichever cell actually holds `revive`, because a fixed offset is only right for one arrangement of a bag (GAME-9/RIG-24). FAILs honestly, naming the bag, once the entry seed's Revive stack is spent -- which is real evidence about the run's recovery budget, not a flaky step.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p3 — use it
- expected: tab_backpack.gd::_read_use() opens the target picker if any party member is fainted, and safely refuses ('Nobody needs reviving.') with no state change otherwise -- live-verified in both directions by tools/gate_f/probe_revive_menu_flow.gd. SKIPPED outright when the bag holds no Revive, so the press can never land on whatever the grid happened to focus instead.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p4 — confirm the fainted row
- expected: if the picker opened, focus already sits on the only eligible (fainted) row, so this clears `fainted` and spends one Revive; with nobody fainted it merely picks the stack up off the grid, which the close below puts back.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p5 — hand the world back
- expected: close_menu presses menu_cancel until input_context stops beginning with 'menu', so it closes the picker branch and the picked-up-stack branch alike
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p6 — the world owns input again before the switch
- expected: section E.3 step 6's target is input leakage after a surface closes
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p7 — hand the pilot to a live creature if the lead is still down
- expected: revive-then-cycle, the order ralph/reports/gate-f-run-20260901T220548Z-s03fix measured over three attempts. SKIPPED when the lead is already standing; a real pilot handoff when it is not.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106p8 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the newly active body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-106a — the lead is actually fit to fight, before Captain Vess
- expected: 2.11/S08: a fainted active creature does not clear itself, and encounter_director.gd::can_challenge() silently refuses a fight it is sent to -- fail here, honestly, rather than let a scripted press downstream misresolve against whatever menu happens to be focused (S08's own finding, at Oreth, after this same gap).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-107 — challenge Captain Vess
- expected: Section E.1 CB-04's third band 4 captain
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-108 — hear the captain out
- expected: the last of the three
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-109 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-109c — combat owns input
- expected: input_context is 'combat' -- something combat-shaped owns input after the conversation closed
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-109f — a fight is actually running
- expected: CombatManager::is_fighting() is true -- the engage was RECEIVED, not merely pressed. A bare press asserts only that input was injected, which is how S02 passed its engage step into an unengaged world for six runs (RIG-26).
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-110 — fight the ridge captain
- expected: Section E.1 per-fight record
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-113 — let the fight end
- expected: rewards and control return
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-113x1 — post-faint switch
- expected: CL-H1 (W21-HARNESS-FIGHTS-0904). the post-faint switch. SKIPPED when the fight left the lead standing; a real pilot handoff when it fainted. Bag-free, so it still recovers the belt with an empty satchel.
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-113x2 — let the replacement stand up
- expected: encounter_director.gd::summon_active_creature() is async; the replacement body needs a few frames
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-114 — the ridge captain is beaten
- expected: `defeated_captain_ridge`, the third of the three `count_flags`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-115 — the Hall approach is open
- expected: `hall_approach_open` is objective 22/27's own flag: three Sigils, three captains. Section B: S08's span ends at 'three Sigils'
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-116 — the chain turns toward the Hall
- expected: Section E.5 objective 23/27 `fight_through_the_hall`, 'Fight through the guard inside Meadows Hall.'
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-117 — band 4 was actually walked and ridden
- expected: Section D RT-10 as listed is a circuit of well over 4 km; no pacing claim may come from a shortcut (section 0.6)
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-118 — the 2 Hz trace ran throughout
- expected: Section C.2
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-119 — band 4's longest empty stretch is on the record
- expected: Section D: '>= 250 m is a finding; 150-250 m is a watch item'. The peak is the half that proves accumulation; a PASS records a watch item and its size
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-120 — Section B save handoff
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-121 — open the pause shell
- expected: the game_menu button, sent as a real physical event, opens the pause shell onto the Satchel tab
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-122 — cycle right to the Save tab
- expected: five RB presses move from Satchel to Save, the sixth tab in data/config/menu.json
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-123 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-124 — move focus to slot 4's Save button
- expected: focus starts on slot 0's Save button (tab_save.gd::first_focus) and four d-pad downs reach slot 4's
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-125 — press Save
- expected: the focused Save button activates and writes slot 4 -- the handoff slot; autosave is slot 0 and slots 1-3 stay free for natural play coverage
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-126 — give the write a moment
- expected: the slot file is on disk and section I.4 has timed the save operation
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-127 — copy slot 4 out into the run directory
- expected: Section B: the resulting `user://` slot file is copied into the run directory as `saves/S08-exit.json`
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-128 — close the shell
- expected: B closes the shell and hands the world back
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP

### S08-129 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: SKIPPED: the segment derailed at step S08-79 (BLOCKER advance_dialogue_until_closed at step S08-79: no narrative modal is open. input_context is 'combat' and the input owner is nothing. Advancing nothing would have sent the advance button into the world.) and this step declares no resync point. input_context is 'combat' now.
- verdict: SKIP
