# S08_fixed — G3-BAND4 PROPOSED FIX: Upper Meadows / Band 4: crossing -> ironwood -> saddle & riding -> three captains -> three Sigils

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 1884 s over 317889 frames at 0.0059 s/frame (re-priced after each boot)

### S08-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S07-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.23
- verdict: PASS

### S08-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 2 files from /root/.local/share/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.23
- verdict: PASS

### S08-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/G3-BAND4-0903/gate-f-s08-run/saves/S07-exit.json (1420270 bytes)
- events: t=0.23
- verdict: PASS

### S08-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 481 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 317856 frames left + 0 s boot = 2075 s against 14399 s of budget left
- events: t=0.85
- verdict: PASS

### S08-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.85
- verdict: PASS

### S08-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.90
- verdict: PASS

### S08-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.00
- verdict: PASS

### S08-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.65
- verdict: PASS

### S08-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.65
- verdict: PASS

### S08-09a — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing -- encounter_director.gd::_engageable() returns null on a null ally before any distance check, so no combat/catch/gate-flag assertion downstream of a load can mean anything without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=182.13
- verdict: PASS

### S08-10 — the team travelled
- expected: three entrants across the crossing
- actual: party size 5 (wanted >= 3)
- events: t=182.13
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-11 — the captains are tracked
- expected: Section E.5 objective 22/27 `defeat_the_captains`, 'Defeat the Upper Meadows captains.' with the n/3 count appended -- one of only two counted entries in the chain
- actual: tracked objective id=hall_approach_open text=Defeat the Upper Meadows captains. 0/3 (wanted defeat_the_captains = flag_id hall_approach_open) [matched on entry id -> flag_id]
- events: t=182.13
- verdict: PASS

### S08-12 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 0.1 Hz segment plus event-forced frames, with the band 3 -> band 4 handoff window inside it. No background-recorder action exists in the vocabulary; recorded as a gap.
- events: t=182.13
- verdict: PASS

### S08-12a — record_start: band 3 -> band 4, the Upper Meadows arrival across the crossing
- expected: S07 saved at the crossing, so this segment loads on the band 3/4 boundary: the window opens at the load's own first step, which is GF-11-UPPER-01, the frame section G triggers on 'Upper Meadows entry across the crossing'
- actual: DELEGATED the §H record window "band 3 -> band 4, the Upper Meadows arrival across the crossing" to capture lane S08C (this is the logic lane; it keeps no continuous record)
- events: t=182.13
- verdict: DELEGATED

### S08-12b — Section H band-handoff windows in this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: 'Mandatory for the highest-risk segments: ... every band handoff +/-60 s (region transitions)'. The pairs in this segment raise the background recorder from the 0.1 Hz journey baseline to 0.5 Hz across each band boundary this segment crosses, and `record_stop` returns to the baseline rather than switching the recorder off, so the record stays continuous either side. AMBIGUITY RECORDED: +/-60 s cannot be sized exactly from a step script. A `move_to` leg's duration is not known before the run and a leg cannot be split, so each window is placed to contain the crossing plus as much of its approach and its settle as the surrounding steps allow -- erring long, because the schema's own measurement makes a 0.5 Hz window affordable as a window (1.05 ms/frame for its length) while a window that missed the transition would cost the evidence.
- events: t=182.13
- verdict: PASS

### S08-13 — capture GF-11-UPPER-01
- expected: Section G: Upper Meadows entry across the crossing, RT-09 end -- region shift is felt
- actual: DELEGATED GF-11-UPPER-01 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=182.13
- verdict: DELEGATED

### S08-14 — open the Map tab
- expected: Section G GF-18-MAP-02 wants both zoom extremes at S08, and section E.5 wants the map opened at every major objective
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65443)
- events: t=182.30
- verdict: PASS

### S08-15 — zoom the map all the way in
- expected: Section G: 'both zoom extremes'
- actual: pressed map_zoom_in x6 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=182.90
- verdict: PASS

### S08-16 — zoom the map all the way out
- expected: Section G: 'both zoom extremes'
- actual: pressed map_zoom_out x8 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=183.70
- verdict: PASS

### S08-17 — capture GF-18-MAP-02
- expected: Section G: Map tab at S08 (late chapter), both zoom extremes -- reveal growth, zoom behavior
- actual: DELEGATED GF-18-MAP-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=183.70
- verdict: DELEGATED

### S08-18 — close the shell
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=183.92
- verdict: PASS

### S08-19 — reopen the Map tab
- expected: Section E.5: 'zoom persistence across close/reopen' -- checked again late, where the revealed map is large
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@65456)
- events: t=184.10
- verdict: PASS

### S08-20 — close the shell again
- expected: B closes the shell
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=184.30
- verdict: PASS

### S08-21 — Section E.5 nav note -- defeat_the_captains
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 22/27 `defeat_the_captains`. Wording: 'Defeat the Upper Meadows captains. n/3' -- it names WHAT, a count, and a WHERE only as wide as a whole region. Player-visible information: `the_ironwood_grove` and `the_ridgeline_watch` are named regions on the late map (GF-18-MAP-02), the ground climbs north from the crossing into high pasture, and the count tells the player there are three of something to find. Route decision: work north through the grove and then the high pasture, letting the named regions be the waypoints, because three captains spread over a region cannot be routed to any more precisely than that. Reasoned from GF-11-UPPER-01 and GF-18-MAP-02. Operator: record whether 'n/3' actually helped, and how long the player spent not knowing where a captain was.
- events: t=184.30
- verdict: PASS

### S08-22 — walk to the Ironwood Grove
- expected: Section D RT-10's first anchor (-345,5060): 'the region's whole material tier, its one special encounter, and a night-ecology pocket, all one place'
- actual: walked 839.5 m to (-345, 5060) in 11210 walking frames (0 held)
- events: t=371.15
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-23 — the grove region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ironwood_grove`
- actual: region=the_ironwood_grove (wanted the_ironwood_grove)
- events: t=371.15
- verdict: PASS

### S08-23a — record_stop: back to the 0.1 Hz journey baseline after band 3 -> band 4, the Upper Meadows arrival across the crossing
- expected: the window closes after the region assert puts the player in `the_ironwood_grove`, band 4's first named region
- actual: DELEGATED the close of the §H record window to capture lane S08C (this is the logic lane; no window was opened here)
- events: t=371.15
- verdict: DELEGATED

### S08-24 — rescan for points of interest
- expected: the grove's own content joins the POI set
- actual: 1123 points of interest in the tree
- events: t=371.15
- verdict: PASS

### S08-25 — harvest ironwood
- expected: Section L.3: 'Gathering with visible tool use ... rootstone (pickaxe), ironwood'
- actual: pressed interact x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=384.67
- verdict: PASS

### S08-26 — walk to the grove's pipwing
- expected: Section E.1 CB-12: 'fight smallest (pipwing/bramblebun class) and largest (meadowhart/tuskroot class) wilds; melee vs ranged movesets'. This is the small half; the large half is the meadowhart below
- actual: walked 13.3 m to (-334, 5055) in 286 walking frames (0 held)
- events: t=389.45
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-27 — engage the pipwing
- expected: CB-12's small-body case
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=390.40
- verdict: PASS

### S08-28 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=393.40
- verdict: PASS

### S08-29 — fight the pipwing
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: fought 694 frames: 16 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames
- events: t=407.08
- verdict: PASS

### S08-30 — begin the aim
- expected: Section E.2: the throw is aimed
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=407.78
- verdict: PASS

### S08-31 — the aim owns input
- expected: input_context is `combat_aim`
- actual: input_context=world (wanted combat_aim)
- events: t=407.78
- verdict: FAIL

### S08-32 — throw the orb
- expected: Section E.2 CT-08: 'Party-not-full -> catch -> count'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=408.42
- verdict: PASS

### S08-33 — let the catch resolve
- expected: the `catch_result` event carries the outcome
- actual: waited 360 physics frames
- events: t=414.42
- verdict: PASS

### S08-34 — the fourth slot filled
- expected: Section E.2 CT-08: 'verify party count increments'. Four of five
- actual: party size 5 (wanted >= 4)
- events: t=414.42
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-35 — walk to the meadowhart herd
- expected: the high pasture herd; section L.4's riding row needs a Meadowhart in the belt
- actual: walked 611.1 m to (12, 5561) in 7640 walking frames (0 held)
- events: t=541.77
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-36 — capture GF-05-MEADOW-02
- expected: Section G: same class, band 4 high pasture, RT-10 -- upper meadow identity differs from lower
- actual: DELEGATED GF-05-MEADOW-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=541.77
- verdict: DELEGATED

### S08-37 — rescan for points of interest
- expected: the herd joins the POI set
- actual: 1123 points of interest in the tree
- events: t=541.77
- verdict: PASS

### S08-38 — engage a meadowhart
- expected: Section E.1 CB-12's large-body case
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=542.27
- verdict: PASS

### S08-39 — let the fight stage
- expected: the combat camera has to frame a much larger body
- actual: waited 180 physics frames
- events: t=545.27
- verdict: PASS

### S08-40 — capture GF-14-COMBAT-12
- expected: Section G: CB-12: size/range spread -- the large half (meadowhart/tuskroot class) -- per-case: the camera and the melee/ranged read at the other end of the size range
- actual: DELEGATED GF-14-COMBAT-12a to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=545.27
- verdict: DELEGATED

### S08-41 — fight the meadowhart
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames
- events: t=549.25
- verdict: PASS

### S08-42 — begin the aim
- expected: Section E.2: the throw is aimed
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=549.55
- verdict: PASS

### S08-43 — throw the orb
- expected: Section E.2 CT-08 again, this time filling the belt
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=549.87
- verdict: PASS

### S08-44 — let the catch resolve
- expected: the `catch_result` event carries the outcome
- actual: waited 360 physics frames
- events: t=555.87
- verdict: PASS

### S08-45 — the belt is full
- expected: five of five. CLAUDE.md: the player can own only five creatures, ever -- no storage, no reserve box, no hidden sixth slot
- actual: party size 5 (wanted >= 5)
- events: t=555.87
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S08-46 — capture GF-19-UI-09
- expected: Section G: party strip at 5/5, world -- exactly five slots, no sixth implied
- actual: DELEGATED GF-19-UI-09 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=555.87
- verdict: DELEGATED

### S08-47 — the five-creature rule, on screen
- expected: a note event carries this observation into events.jsonl
- actual: Section E.2 CT-08's own words: the HUD 'shows exactly five slots maximum -- nothing may imply a sixth'. GF-19-UI-09 is that frame. Section B branches X03's party-full study (CT-09) from this segment's exit save, so the 5/5 state has to travel through the handoff intact.
- events: t=555.87
- verdict: PASS

### S08-48 — Section L.3 band 4 crafting has no authored site
- expected: a note event carries this observation into events.jsonl
- actual: Section L.3 requires 'S08 saddle + orb_prime -- each paid at real cost' and section L.4 requires 'Riding (saddle, mount, dismount, speed, no stamina cost)'. Section B's S08 span names 'saddle & riding' and the protocol names no crafting site in band 4, so the workbench below is placed by the player on the high pasture. RECORDED as the transcriber's siting.
- events: t=555.87
- verdict: PASS

### S08-49 — open the pause shell
- expected: the pause shell, opened by its bound button
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@67004)
- events: t=556.03
- verdict: PASS
- observation: Opened via the map shortcut rather than a bare game_menu press. The pause shell REOPENS ON THE LAST TAB USED, so a fixed press count from an assumed backpack start lands on the wrong tab in any segment that opens the menu more than once. Measured in S03: the shell reopened on `menu_map` and 4x menu_tab_right landed on `menu_settings` instead of `menu_build`, failing nine consecutive build steps. `map` is one of only two tabs with a shortcut in data/config/menu.json, so it is the only deterministic starting point available.

### S08-50 — cycle to the Build tab
- expected: four RB presses reach Build
- actual: pressed menu_tab_right x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=556.38
- verdict: PASS
- observation: times 4 -> 2: counted from the map tab (index 2), not from an assumed backpack start. Target tab unchanged: build.

### S08-51 — open the build menu
- expected: 'Open Build Menu' is the tab's only focusable control
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=556.73
- verdict: PASS

### S08-52 — let the build menu open
- expected: it reopens on the last category and piece used this session
- actual: waited 120 physics frames
- events: t=558.73
- verdict: PASS

### S08-53 — move to Crafting
- expected: `build_menu.gd::CATEGORY_ORDER` -- Crafting holds the Workbench
- actual: pressed menu_tab_left x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=559.70
- verdict: PASS

### S08-54 — arm the workbench
- expected: paid at the real cost; free_build is OFF
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=560.03
- verdict: PASS

### S08-55 — let the ghost arm
- expected: the placement camera takes over
- actual: waited 120 physics frames
- events: t=562.03
- verdict: PASS

### S08-56 — place the workbench
- expected: Section L.3's crafting site for band 4
- actual: pressed build_place x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=562.40
- verdict: PASS

### S08-57 — let the placement register
- expected: `GameState.placed_buildings` gains the workbench
- actual: waited 120 physics frames
- events: t=564.40
- verdict: PASS

### S08-58 — use the workbench
- expected: the craft panel opens over the world
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=564.80
- verdict: PASS

### S08-59 — let the craft panel open
- expected: Section E.4 lists the craft panel among the surfaces the matrix crosses
- actual: waited 120 physics frames
- events: t=566.80
- verdict: PASS

### S08-60 — the craft panel focuses a recipe
- expected: without focus the panel cannot be driven on a pad
- actual: focus_owner=@Button@67532 focus_text=
- events: t=566.80
- verdict: PASS

### S08-61 — craft the saddle
- expected: Section L.3: 'S08 saddle + orb_prime -- each paid at real cost'. The inventory snapshot on the `craft` event is the evidence
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=567.22
- verdict: PASS

### S08-62 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=569.22
- verdict: PASS

### S08-63 — focus the prime orb recipe
- expected: AMBIGUITY RECORDED: the protocol names the recipes but not their order in the panel
- actual: FAIL 1 x ui_down did not move focus off @Button@67532
- events: t=569.43
- verdict: FAIL

### S08-64 — craft the prime orb
- expected: Section L.3's second band 4 recipe, paid at the real cost
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=569.82
- verdict: PASS

### S08-65 — let the craft resolve
- expected: the `craft` event carries the full slot snapshot
- actual: waited 120 physics frames
- events: t=571.82
- verdict: PASS

### S08-66 — leave the craft panel
- expected: the surface hands the world back
- actual: pressed menu_cancel x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:1
- events: t=572.23
- verdict: PASS

### S08-67 — the world owns input again
- expected: input_context is back to 'world'; input leakage after a surface closes is the target
- actual: input_context=world (wanted world)
- events: t=572.23
- verdict: PASS

### S08-68 — mount the meadowhart
- expected: Section L.4: 'Riding (saddle, mount, dismount, speed, no stamina cost) | S08: craft saddle, mount Meadowhart, ride RT-10 leg, dismount, remount'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=572.62
- verdict: PASS

### S08-69 — let the mount stage
- expected: the riding camera and the mounted locomotion take over
- actual: waited 180 physics frames
- events: t=575.62
- verdict: PASS

### S08-70 — capture GF-11-UPPER-02
- expected: Section G: riding on Meadowhart, RT-10 -- riding payoff exists and stages correctly
- actual: DELEGATED GF-11-UPPER-02 to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=575.62
- verdict: DELEGATED

### S08-71 — ride RT-10's leg to Captain Halder
- expected: Section D RT-10's second anchor (170,5590) is captain_field. Section L.4: 'ride RT-10 leg'. Riding must not cost stamina
- actual: walked 163.1 m to (170, 5590) in 1919 walking frames (2602 held)
- events: t=650.98
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-72 — dismount
- expected: Section L.4: 'mount, dismount, speed, no stamina cost'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=651.37
- verdict: PASS

### S08-73 — let the dismount settle
- expected: control returns to the player on foot
- actual: waited 120 physics frames
- events: t=653.37
- verdict: PASS

### S08-74 — remount
- expected: Section L.4: '... dismount, remount'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=653.72
- verdict: PASS

### S08-75 — let the remount settle
- expected: the riding camera takes over again
- actual: waited 120 physics frames
- events: t=655.72
- verdict: PASS

### S08-76 — dismount for the fight
- expected: the human never fights, and a captain fight is piloted
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=656.03
- verdict: PASS

### S08-77 — let the dismount settle
- expected: control returns to the player on foot
- actual: waited 120 physics frames
- events: t=658.03
- verdict: PASS

### S08-78 — challenge Captain Halder
- expected: Section E.1 CB-04: 'S08: captain_field, captain_ridge, captain_riverwatch'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=658.40
- verdict: PASS

### S08-80 — let the fight stage
- expected: Section L.6 T05: the combat camera acquires both combatants at fight start
- actual: waited 180 physics frames
- events: t=661.40
- verdict: PASS

### S08-81 — capture GF-14-COMBAT-04d
- expected: Section G: CB-04: representative fight per band -- S08, captain_field -- per-case: band 4's representative fight
- actual: DELEGATED GF-14-COMBAT-04d to capture lane S08C (this is the logic lane; it takes no frames)
- events: t=661.40
- verdict: DELEGATED

### S08-82 — fight Captain Halder
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: FAIL fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames, NOT SET 'defeated_captain_field'
- events: t=665.38
- verdict: FAIL

### S08-85 — let the fight end
- expected: rewards and control return with no stuck modal
- actual: waited 600 physics frames
- events: t=675.38
- verdict: PASS

### S08-86 — the field captain is beaten
- expected: `defeated_captain_field`, the first of the objective's three `count_flags`
- actual: flag defeated_captain_field NOT set
- events: t=675.38
- verdict: FAIL

### S08-87 — Section D RT-10's third anchor is south of its second
- expected: a note event carries this observation into events.jsonl
- actual: Section D RT-10's third anchor is (-100,4350), which is captain_riverwatch -- 1240 m back south, below the grove the segment already passed. Walked in the order section D lists rather than the order the ground would produce, because reordering coverage is exactly what the transcription rule forbids. The distance this costs is real and lands in section D's own figures for RT-10, which is the honest place for it.
- events: t=675.38
- verdict: PASS

### S08-79w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=narrative_modal (wanted world)
- events: t=675.38
- verdict: FAIL
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S08-88 — walk south to Captain Oreth
- expected: Section D RT-10's third anchor (-100,4350) is captain_riverwatch
- actual: walked 1268.9 m to (-100, 4350) in 16126 walking frames (80 held)
- events: t=945.80
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-89 — challenge Captain Oreth
- expected: Section E.1 CB-04's second band 4 captain
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=946.13
- verdict: PASS

### S08-91 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=949.13
- verdict: PASS

### S08-92 — fight Captain Oreth
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: FAIL fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames, NOT SET 'defeated_captain_riverwatch'
- events: t=953.12
- verdict: FAIL

### S08-95 — let the fight end
- expected: rewards and control return
- actual: waited 600 physics frames
- events: t=963.12
- verdict: PASS

### S08-96 — the riverwatch captain is beaten
- expected: `defeated_captain_riverwatch`, the second of the three `count_flags`
- actual: flag defeated_captain_riverwatch NOT set
- events: t=963.12
- verdict: FAIL

### S08-96a — record_start: band 4's northern region transition, into the Ridgeline Watch
- expected: AMBIGUITY RECORDED: the band 4 -> band 5 handoff is NOT a spatial crossing inside S08. Section B ends this segment on the third captain -- the Sigils open the gate, and the walk through it happens in S09. So this pair sits on the last region transition S08 actually crosses, into `the_ridgeline_watch`, which is the ground the sigil gate stands beyond; the band boundary itself is covered by S09's first window
- actual: DELEGATED the §H record window "band 4's northern region transition, into the Ridgeline Watch" to capture lane S08C (this is the logic lane; it keeps no continuous record)
- events: t=963.12
- verdict: DELEGATED

### S08-90w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=narrative_modal (wanted world)
- events: t=963.12
- verdict: FAIL
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S08-97 — walk north to Captain Vess on the ridgeline
- expected: Section D RT-10's fourth anchor (-280,6460) is captain_ridge, in `the_ridgeline_watch`
- actual: walked 2111.3 m to (-280, 6460) in 26196 walking frames (80 held)
- events: t=1401.33
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-98 — the ridgeline region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ridgeline_watch`
- actual: region=the_ridgeline_watch (wanted the_ridgeline_watch)
- events: t=1401.33
- verdict: PASS

### S08-99 — rescan for points of interest
- expected: the watch's own content joins the POI set
- actual: 1123 points of interest in the tree
- events: t=1401.33
- verdict: PASS

### S08-99a — record_stop: back to the 0.1 Hz journey baseline after band 4's northern region transition, into the Ridgeline Watch
- expected: the window closes after the point-of-interest rescan inside the watch
- actual: DELEGATED the close of the §H record window to capture lane S08C (this is the logic lane; no window was opened here)
- events: t=1401.33
- verdict: DELEGATED

### S08-100 — walk to the ridgeline patrol first
- expected: Section L.4: 'Required trainer fights + representative optional | optional: old_champion_bram (195,905), patrol_ridgeline'
- actual: walked 43.5 m to (-235, 6470) in 635 walking frames (0 held)
- events: t=1411.93
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-101 — challenge the ridgeline patrol
- expected: the second of the journey's two named optional trainers
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1412.22
- verdict: PASS

### S08-103 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=1415.22
- verdict: PASS

### S08-104 — fight the patrol
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: FAIL fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames, NOT SET 'defeated_patrol_ridgeline'
- events: t=1419.20
- verdict: FAIL

### S08-105 — let the fight end
- expected: rewards and control return
- actual: waited 480 physics frames
- events: t=1427.20
- verdict: PASS

### S08-102w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=narrative_modal (wanted world)
- events: t=1427.20
- verdict: FAIL
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S08-106 — walk to Captain Vess
- expected: captain_ridge, the third of the three the objective counts
- actual: FAIL did not reach (-280, 6460) in 3000 walking frames; stopped 39.2 m short at (-242.0, 4.0, 6469.0) (80 held)
- events: t=1478.85
- verdict: FAIL
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S08-107 — challenge Captain Vess
- expected: Section E.1 CB-04's third band 4 captain
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=1479.10
- verdict: PASS

### S08-109 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=1482.10
- verdict: PASS

### S08-110 — fight Captain Vess
- expected: G3-BAND4 harness fix proposal: fight_until_resolved auto-switches the active creature below 35% HP (tools/gate_f/operator_harness.gd::_step_fight) instead of the blind combat_quick press count this step used to be -- see ralph/reports/G3-BAND4-0903/REPORT.md's addendum for why the original press-count sequence let a fainted lead creature sit through every subsequent captain challenge with no real fight ever starting.
- actual: FAIL fought 239 frames: 0 quick, 0 handover(s), 0 refused switch(es); ended because no fight running for 240 frames, NOT SET 'defeated_captain_ridge'
- events: t=1486.08
- verdict: FAIL

### S08-113 — let the fight end
- expected: rewards and control return
- actual: waited 600 physics frames
- events: t=1496.08
- verdict: PASS

### S08-114 — the ridge captain is beaten
- expected: `defeated_captain_ridge`, the third of the three `count_flags`
- actual: flag defeated_captain_ridge NOT set
- events: t=1496.08
- verdict: FAIL

### S08-115 — the Hall approach is open
- expected: `hall_approach_open` is objective 22/27's own flag: three Sigils, three captains. Section B: S08's span ends at 'three Sigils'
- actual: flag hall_approach_open NOT set
- events: t=1496.08
- verdict: FAIL

### S08-116 — the chain turns toward the Hall
- expected: Section E.5 objective 23/27 `fight_through_the_hall`, 'Fight through the guard inside Meadows Hall.'
- actual: tracked objective id=hall_approach_open text=Defeat the Upper Meadows captains. 0/3 (wanted fight_through_the_hall = flag_id defeated_stronghold_elite)
- events: t=1496.08
- verdict: FAIL

### S08-117 — band 4 was actually walked and ridden
- expected: Section D RT-10 as listed is a circuit of well over 4 km; no pacing claim may come from a shortcut (section 0.6)
- actual: walked 5272.5 m this segment (wanted >= 4000.0)
- events: t=1496.08
- verdict: PASS

### S08-118 — the 2 Hz trace ran throughout
- expected: Section C.2
- actual: route.csv has 2959 rows (wanted >= 4000)
- events: t=1496.08
- verdict: FAIL

### S08-119 — band 4's longest empty stretch is on the record
- expected: Section D: '>= 250 m is a finding; 150-250 m is a watch item'. The peak is the half that proves accumulation; a PASS records a watch item and its size
- actual: dead_travel peaked at 964.4 m this segment (wanted >= 150.0); 5272.5 m walked in total
- events: t=1496.08
- verdict: PASS

### S08-120 — Section B save handoff
- expected: a note event carries this observation into events.jsonl
- actual: Section B: 'each journey segment ends by saving to a dedicated slot through the production Save tab and copying the resulting `user://` slot file into the run directory (`saves/<segment>-exit.json`)'. The steps below are that save, driven as a player drives it -- the pause shell, five RB presses to the Save tab, focus down to slot 4, and the slot's own Save button. `save_out` afterwards only copies the artefact; it saves nothing itself. Section B also branches X01 (riding/late menus) and X03 (party-full catch, 5/5) from this file.
- events: t=1496.08
- verdict: PASS

### S08-121 — open the pause shell
- expected: the game_menu button, sent as a real physical event, opens the pause shell onto the Satchel tab
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@72038)
- events: t=1496.27
- verdict: PASS
- observation: Opened via the map shortcut rather than a bare game_menu press. The pause shell REOPENS ON THE LAST TAB USED, so a fixed press count from an assumed backpack start lands on the wrong tab in any segment that opens the menu more than once. Measured in S03: the shell reopened on `menu_map` and 4x menu_tab_right landed on `menu_settings` instead of `menu_build`, failing nine consecutive build steps. `map` is one of only two tabs with a shortcut in data/config/menu.json, so it is the only deterministic starting point available.

### S08-122 — cycle right to the Save tab
- expected: five RB presses move from Satchel to Save, the sixth tab in data/config/menu.json
- actual: pressed menu_tab_right x3 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=1497.08
- verdict: PASS
- observation: times 5 -> 3: counted from the map tab (index 2), not from an assumed backpack start. Target tab unchanged: save.

### S08-123 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: input_context=menu_save (wanted menu_save)
- events: t=1497.08
- verdict: PASS

### S08-124 — move focus to slot 4's Save button
- expected: focus starts on slot 0's Save button (tab_save.gd::first_focus) and four d-pad downs reach slot 4's
- actual: 4 x ui_down moved focus 'Save' (@Button@72090) -> 'Save' (@Button@72110)
- events: t=1497.67
- verdict: PASS

### S08-125 — press Save
- expected: the focused Save button activates and writes slot 4 -- the handoff slot; autosave is slot 0 and slots 1-3 stay free for natural play coverage
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1498.00
- verdict: PASS

### S08-126 — give the write a moment
- expected: the slot file is on disk and section I.4 has timed the save operation
- actual: waited 120 physics frames
- events: t=1500.00
- verdict: PASS

### S08-127 — copy slot 4 out into the run directory
- expected: Section B: the resulting `user://` slot file is copied into the run directory as `saves/S08-exit.json`
- actual: slot 4 copied to saves/S08-exit.json (1420417 bytes)
- events: t=1500.00
- verdict: PASS

### S08-128 — close the shell
- expected: B closes the shell and hands the world back
- actual: menu_cancel closed the shell: context menu_save -> world
- events: t=1500.22
- verdict: PASS

### S08-129 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: S08 exit save written and copied, with the belt at 5/5.
- events: t=1500.22
- verdict: PASS
