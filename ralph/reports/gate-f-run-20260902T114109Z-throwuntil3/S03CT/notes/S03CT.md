# S03CT — S03 catch-loop single-attempt test (fast iteration slice of S03, not part of the real segment chain)

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 123 s over 20766 frames at 0.0059 s/frame (re-priced after each boot)

### S03-01 — how this segment is entered
- expected: a note event carries this observation into events.jsonl
- actual: Section B: this segment's entry save is `S02-exit`. The three steps below are the handoff's own mechanics: the live save directory is emptied first so the title's Load list has exactly one non-empty slot and auto-focuses it (`title_screen.gd` focuses the FIRST non-empty slot), then slot 4 is seeded from the run directory, then the load is driven through the production title-screen Load path by synthetic input. Section B names the seed and the Load path; the wipe is not named there and is recorded here as an added mechanical step, needed because an autosave left in slot 0 would take the auto-focus and the segment would load the wrong state.
- events: t=0.23
- verdict: PASS

### S03-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 2 files from /root/.local/share/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.23
- verdict: PASS

### S03-03 — seed slot 4 from the previous segment's exit save
- expected: Section B: 'The next segment boots fresh, restores that file into `user://`, and loads it through the production title-screen Load path'
- actual: seeded slot 4 from ralph/reports/gate-f-run-20260902T114109Z-throwuntil3/S02/saves/S02-exit.json (1418492 bytes)
- events: t=0.23
- verdict: PASS

### S03-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled, because a save now exists
- actual: booted title in 485 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 20733 frames left + 0 s boot = 136 s against 14399 s of budget left
- events: t=0.87
- verdict: PASS

### S03-05 — the title focuses something
- expected: the title focuses its first button; without focus a controller cannot reach Load Game at all
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.87
- verdict: PASS

### S03-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.92
- verdict: PASS

### S03-07 — open the slot list
- expected: Section B: 'driven with synthetic input -- this is itself save/load coverage'. Load Game opens the slot list and auto-focuses the first non-empty slot, which is the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.00
- verdict: PASS

### S03-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows; section I.4 records the load duration
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.58
- verdict: PASS

### S03-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90 s of CPU on this container -- 466k scattered props and a terrain build -- and every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.58
- verdict: PASS

### S03-09a — deploy the active creature after load
- expected: RIG-13 (extending RIG-11 to the segments RIG-11's own fix never reached): a load restores the party and deploys nothing -- encounter_director.gd::can_challenge() returns false on a null/undeployed ally before checking whether a trainer is already beaten, so trainer_npc.gd falls back to its 'defeated' conversation line instead of the 'challenge' line that leads to combat. No trainer fight downstream of a load -- including this segment's Bryn practice match -- can start without this. creature_recall (RB) summons the active creature so this segment's fights can actually start.
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=181.82
- verdict: PASS

### S03-10 — the load restored the village arrival
- expected: S02 ended at the village center; the load has to bring the player back there, not to a fresh spawn
- actual: 2.3 m from (10, -10), wanted within 12.0
- events: t=181.82
- verdict: PASS

### S03-11 — the party travelled
- expected: the starter and the first catch: two of five
- actual: party size 3 (wanted >= 2)
- events: t=181.82
- verdict: PASS
- observation: RIG-15: equals -> min. Catching is probabilistic; a script's single throw can miss on a real, non-buggy roll, and a team that ends up BIGGER than the milestone is still a team that reached it. `equals` failed both directions for no reason a real player's outcome should fail on.

### S03-12 — the ladder's next rung is tracked
- expected: Section E.5 objective 6/27 `village_tools`, 'Meet Tam in the village and take his tools.'
- actual: tracked objective id=tam_tools_given text=Meet Tam in the village and take his tools. (wanted village_tools = flag_id tam_tools_given) [matched on entry id -> flag_id]
- events: t=181.82
- verdict: PASS

### S03-13 — Section H cadence for this segment
- expected: a note event carries this observation into events.jsonl
- actual: Section H: this segment is outside the mandatory 0.5 Hz list, so it 'runs at 0.1 Hz (one frame per 10 s) plus event-forced frames, to keep the record continuous without drowning the run directory'. The vocabulary has no background-recorder action; recorded here as a gap.
- events: t=181.82
- verdict: PASS

### S03-14 — open the Map tab
- expected: Section E.5: 'full-map usefulness (open Map tab, zoom in/out with LT/RT, verify pan/centering behavior and zoom persistence across close/reopen)'. The `map` shortcut opens the shell straight onto the tab
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@66821)
- events: t=182.00
- verdict: PASS

### S03-15 — the Map tab is up
- expected: input_context names the live tab: menu_map
- actual: input_context=menu_map (wanted menu_map)
- events: t=182.00
- verdict: PASS

### S03-17 — zoom the map in
- expected: Section E.5: zoom in/out with LT/RT
- actual: pressed map_zoom_in x3 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=182.30
- verdict: PASS

### S03-18 — zoom the map back out
- expected: Section E.5: zoom in/out with LT/RT
- actual: pressed map_zoom_out x3 (tap, 1 frames each) on the default device, resolved to JoyAxis:4:1.0
- events: t=182.62
- verdict: PASS

### S03-19 — close the shell
- expected: B closes the shell and hands the world back
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=182.83
- verdict: PASS

### S03-20 — reopen the Map tab
- expected: Section E.5: 'zoom persistence across close/reopen' -- the level the map reopens at is the finding
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@66840)
- events: t=183.02
- verdict: PASS

### S03-21 — close the shell again
- expected: B closes the shell and hands the world back
- actual: menu_cancel closed the shell: context menu_map -> world
- events: t=183.20
- verdict: PASS

### S03-22 — Section E.5 nav note -- village_tools
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 6/27 `village_tools`. Wording: 'Meet Tam in the village and take his tools.' It names WHAT (Tam, tools) and a WHERE only as specific as 'in the village'; it does not say which building or which side. Player-visible information: the fresh-save reveal shows the village and its roads, and GF-18-MAP-01 is the record of what that map actually offers -- whether Tam is a pin at all. Route decision: cross the village square westward along the spine, because the objective names no landmark and the square is the only place the map marks. Reasoned from GF-18-MAP-01 and GF-03-VILLAGE-01 (S02). Operator: record time-to-route-decision and whether the map named Tam.
- events: t=183.20
- verdict: PASS

### S03-23 — walk to Tam
- expected: Section D RT-02: village traversal, Tam (8,-16) -> Oskar (22,-6) -> Mira (19,-1) -> tournament ground (20,12)
- actual: walked 4.4 m to (8, -16) in 56 walking frames (0 held)
- events: t=184.15
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S03-24 — talk to Tam
- expected: the ladder's rung: 'take his tools'
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=184.32
- verdict: PASS

### S03-25 — hear him out
- expected: his conversation gives the axe and pickaxe
- actual: pressed interact x16 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=190.30
- verdict: PASS

### S03-26 — Tam's tools were given
- expected: `tam_tools_given` is the rung's own contract flag
- actual: flag tam_tools_given set
- events: t=190.30
- verdict: PASS

### S03-28 — the chain advanced
- expected: Section E.5 objective 7/27 `tournament_build_team`
- actual: tracked objective id=tournament_team_ready text=Build your full team of five for the village tournament. (wanted tournament_build_team = flag_id tournament_team_ready) [matched on entry id -> flag_id]
- events: t=190.30
- verdict: PASS

### S03-29 — Section E.5 nav note -- tournament_build_team
- expected: a note event carries this observation into events.jsonl
- actual: Section E.5 navigation record, objective 7/27 `tournament_build_team`. Wording: 'Catch and raise a team for the village tournament.' It names WHAT and no WHERE at all -- there is nowhere named to go. Player-visible information: the minimap and the world itself; wild creatures are visible individuals on the meadow south-east of the village (the practice meadow the opening already used). Route decision: return to the practice meadow because it is the only ground the player has already seen wild creatures on. Reasoned from GF-18-MAP-01 and GF-03-VILLAGE-02. Operator: record whether an objective that names no place left the player uncertain, and for how long.
- events: t=190.30
- verdict: PASS

### S03-25w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=narrative_modal (wanted world)
- events: t=190.30
- verdict: FAIL
- observation: T2-GATEF-RUN6 modal-holds-locomotion audit. A walk that begins while a narrative modal still owns input does not fail as 'a modal is open' -- it fails as 'did not reach', many steps and sometimes many minutes later, which is how X04 lost its whole combat block to 3601 held frames. This assert is diagnostic and changes no behaviour: it turns that silent cascade into one named cause at the point of origin. RIG-25's rule, applied to narrative modals rather than to shop panels.

### S03-30 — walk out to the practice meadow
- expected: `data/config/tournament.json`'s `entry.min_party_size` is 3: 'a team, not a favourite'
- actual: walked 29.3 m to (30, -40) in 430 walking frames (120 held)
- events: t=199.68
- verdict: PASS
- observation: answer_prompts turned ON for this journey walk. TRADE RECORDED EXPLICITLY: the schema says this flag must stay off in any segment whose subject is whether something blocks travel, so these segments can no longer evidence 'a narrative modal blocked the player from travelling'. That finding is already captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md -- three press counts, identical 7201-frame holds. What it buys is everything downstream: measured in S03 and S04, an unanswered modal at a walk's end left input_context='narrative_modal' where the next step expected combat, so no fight started, no catch resolved, the team never reached three, and every tournament entry check then failed on team size. Without this the journey produces no combat, catching, building or progression evidence at all.

### S03-31 — rescan for points of interest
- expected: Section F's POI set for the dead-travel meter
- actual: 1097 points of interest in the tree
- events: t=199.68
- verdict: PASS

### S03-32a — walk to a live bramblebun (attempt 1)
- expected: RIG-16: tracks a live bramblebun's own position every frame instead of a fixed cluster-centre coordinate.
- actual: walked 5.6 m to bramblebun (species_id, nearest of 64 (Wild_bramblebun_0_1, Wild_bramblebun_0_2, Wild_bramblebun_0_3, Wild_bramblebun_1003_1, Wild_bramblebun_1003_2, Wild_bramblebun_1006_1, ...)) in 64 walking frames (0 held)
- events: t=200.77
- verdict: PASS
- observation: RIG-F5/GAME-F3. `within: 4.5` is what handed the interact button to a harvest node: prompt_arbiter.gd is 'highest priority first, then NEAREST', engage and gather are both priority 0, and from 4.5 m out a node at half a metre wins every time. Four of the twenty authored village nodes sit inside the practice cluster's own 15 m disc, deliberately -- harvest.json's own _why_gate_b_three_beds put them on 'the practice-path loop the first day already walks' -- so the collision is structural and the fix is to stand at the creature, which is what a player does. 2.0 rather than 1.8: RIG-F5 measured a bramblebun 0.22 m up a slope failing a 1.8 m close_3d check at 1.81 m in 3D, and named 2.0 as the floor.

### S03-32a2 — challenge it (attempt 1)
- expected: RIG-17: matched on the prompt's own text (EncounterDirector, not the bramblebun, owns it) rather than entity relatedness, so this presses a real engage offer and refuses a fainted-ally message like "Ripplet is out of the fight"/"Put Moss away" instead of misfiring into it.
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Engage Bramblebun" (provider 'EncounterDirector'): context world -> combat
- events: t=201.22
- verdict: PASS

### S03-33a — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=204.22
- verdict: PASS

### S03-35a — trim it with quick attacks (do not kill it)
- expected: the target is WEAKENED as close to zero HP as this fight will safely bear -- not defeated, a defeated wild cannot be caught -- computed from the fight's own real per-hit damage rather than a guessed hit count or a guessed HP-fraction floor.
- actual: 6 x combat_quick: enemy hp 11.1/93.7 (11.9%), hits dealt [14.0, 14.5, 13.1, 12.5, 14.2, 14.3], largest 14.5
- events: t=207.42
- verdict: PASS
- observation: RIG, 2026-08-31: combat_quick x20 KILLED a 106 HP target, so a fixed times: 3 (S02's own proven opener) replaced it -- correctly avoiding a kill, but measured directly (gate-f-run-20260902T053310Z-s03enginefix) landing anywhere from 57% to 75% of max HP depending on the creature's own defence, the FLAT part of hp_factor's curve. A fixed enemy_hp_fraction 0.3 floor (this step's own immediately-prior version) fixed that but was still a guessed number, not a computed one -- called out directly by the owner in this session, 2026-09-02 ('if 5 presses took 70 health you could do another 2 without killing it. why wouldnt you? ... you can surely calculate what needs to be done'). chip_to_floor (operator_harness.gd, added for this) reads the live enemy hp before and after every swing and learns the actual per-hit damage this fight is dealing -- combat_math.gd::rolled_damage()'s only per-swing randomness against a fixed target is its +/-10% variance roll, so one real hit already bounds every later one -- and refuses the next swing only once the largest hit seen so far, scaled by safety_factor (1.25, past the 1.1/0.9=1.222 worst-case roll swing), would not survive. No fixed floor anywhere in this step; it chips exactly as far as the specific creature in front of it allows.

### S03-36a — aim and throw until caught, or out of tries (attempt 1)
- expected: the target is caught, or every allotted throw against it is spent -- a missed throw does not end the fight (catching.json's own cooldown exists so a failed catch can be re-thrown once the wobble clears; combat_manager.gd re-engages the same target on a miss), so this keeps throwing at the SAME chipped-down target instead of treating one orb as the whole attempt.
- actual: FAIL throw_until_caught: could not arm aim for throw 2 (FAIL 15 x interact did not reach it; last saw input_context=world (wanted combat_aim)) -- prior: throw 1 (tracked)
- events: t=219.10
- verdict: FAIL
- observation: Owner directive, this session: "we should chip down then throw orbs til we catch." The ladder used to spend exactly one orb per numbered attempt (arm aim, track, throw once, wait) and then move on regardless of outcome -- discarding real, intended-to-be-retried catch chances the moment a single throw missed, even though nothing about the game ends the fight on a miss. throw_until_caught (operator_harness.gd, added for this) re-arms the aim, re-tracks the live target and throws again, up to max_throws times, stopping the instant the party actually grows.

### S03CT-END — end of the single-attempt catch test
- expected: a note event carries this observation into events.jsonl
- actual: Chip then throw-until-caught, one target only, for fast iteration. Check party_size (S03-11 confirmed 2 at entry) and the last catch_result/party grew observation in telemetry/events.jsonl for the outcome.
- events: t=219.10
- verdict: PASS
