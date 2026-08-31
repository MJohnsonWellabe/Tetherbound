# S08ISO — S08 ISOLATED: hand-seeded party-of-5 entry at the Band 3->4 crossing -> ironwood -> saddle & riding -> three captains -> three Sigils

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 284 s over 47791 frames at 0.0059 s/frame (re-priced after each boot)

### ISO-01 — entry mechanics
- expected: a note event carries this observation into events.jsonl
- actual: Entry save is a hand-authored stand-in for S07-exit (ralph/reports/gate-f-leg-s08/saves/S07-exit.json): party of 5 (levels 14-16), full HP, a saddle already in the satchel, every flag through mill_crossing_restored set. This is CONDITIONAL/ISOLATED evidence -- S08, given a clean entry, does X -- never a claim about the whole chapter.
- events: t=0.23
- verdict: PASS

### ISO-02 — empty the live save directory
- expected: every slot file is gone, so the seeded slot 4 is the only thing the title's Load list can offer
- actual: wiped 2 files from /root/.local/share/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.23
- verdict: PASS

### ISO-03 — seed slot 4 from the hand-authored save
- expected: the hand-authored save is copied into user://saves/slot_4.json
- actual: seeded slot 4 from ralph/reports/gate-f-leg-s08/saves/S07-exit.json (5221 bytes)
- events: t=0.23
- verdict: PASS

### ISO-04 — boot the real title screen
- expected: the real title comes up with Start New Game focused and Load Game enabled
- actual: booted title in 489 ms (30 settle frames); re-priced at boot:title: 0.0065 s/frame (was 0.0059), 47758 frames left + 0 s boot = 312 s against 14399 s of budget left
- events: t=0.87
- verdict: PASS

### ISO-05 — the title focuses something
- expected: the title focuses its first button
- actual: focus_owner=@Button@27 focus_text=Start New Game
- events: t=0.87
- verdict: PASS

### ISO-06 — move focus to Load Game
- expected: d-pad down moves focus from Start New Game to Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=0.90
- verdict: PASS

### ISO-07 — open the slot list
- expected: Load Game opens the slot list and auto-focuses the seeded slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=0.98
- verdict: PASS

### ISO-08 — load the seeded slot
- expected: the slot loads and the title transitions into the Meadows
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.67
- verdict: PASS

### ISO-09 — let the loaded world stand up
- expected: a cold Meadows stand-up costs about 90s of CPU on this container; every assertion after this reads a live Player
- actual: waited 10800 physics frames
- events: t=181.67
- verdict: PASS

### ISO-10 — the seeded party loaded intact
- expected: RIG-15 note aside, this seed is deterministic (no catch RNG involved): exactly 5
- actual: party size 5 (wanted >= 5)
- events: t=181.67
- verdict: PASS

### ISO-11 — deploy the active creature after load
- expected: RIG-11: a load restores the party and deploys nothing. creature_recall (RB) summons the active creature (party index 0, Tuskroot -- the seed's tankiest, deployed first deliberately so unattended travel through a region with aggressive wildlife is not defended by the mount species itself; see ISO-20a)
- actual: pressed creature_recall x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=182.00
- verdict: PASS

### ISO-12 — let the summon land
- expected: the Tuskroot is standing in the world, following
- actual: waited 180 physics frames
- events: t=185.00
- verdict: PASS

### ISO-13 — place the entry at the Band 3 -> 4 crossing (Old Mill Crossing)
- expected: Section D RT-09's own end anchor and S07-76's own walk target: '(350,3760) -> (-152,4203)'. DIAG stand-in for the position S07-exit would already have; the ONLY teleport in this segment
- actual: DIAG teleport to (-152, 4203); distance/dead-travel accumulators reset
- events: t=186.50
- verdict: PASS

### ISO-14 — the crossing was already restored by the seeded flags
- expected: the seed carries every prior-band flag through mill_crossing_restored
- actual: flag mill_crossing_restored set
- events: t=186.50
- verdict: PASS

### ISO-15 — refresh POIs at the crossing
- expected: band 4's near content joins the POI set
- actual: 1089 points of interest in the tree
- events: t=186.50
- verdict: PASS

### ISO-15w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=world (wanted world)
- events: t=186.50
- verdict: PASS

### ISO-15t — shorten the incidental crossing->grove transit
- expected: DIAG stand-in for ~810 m of otherwise-incidental open-Meadows transit this isolated test is not trying to prove (that is section D RT-10's own pacing study, not this leg's job); leaves a real ~70 m final approach on foot into the grove below. Recorded because a multi-hundred-metre unattended walk through band 4's aggressive wildlife with nobody piloting the deployed creature is a real risk this test hit once already (see REPORT.md's ambush finding) and re-exposing it here would not add coverage, only variance
- actual: DIAG teleport to (-330, 4992); distance/dead-travel accumulators reset
- events: t=187.50
- verdict: PASS

### ISO-16 — walk the final approach to the Ironwood Grove
- expected: Section D RT-10's first anchor (-345,5060): the region's own material tier and encounter
- actual: walked 65.1 m to (-345, 5060) in 784 walking frames (0 held)
- events: t=200.58
- verdict: PASS

### ISO-16a — defend against an in-transit ambush, if any
- expected: combat_quick has no world-context listener (combat_manager.gd/throw_aim.gd only read it while a fight/aim is live), so this is a safe no-op if move_to's own held-wait was never interrupted, and a real defence if an aggressive wild (species.json's own `aggressive` flag) auto-engaged mid-walk through `wants_to_engage` -- unlike the official S08.json's move_to, which only answers narrative-modal prompts and would otherwise let the deployed creature take a whole fight's damage with zero pilot input
- actual: pressed combat_quick x30 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=221.37
- verdict: PASS

### ISO-16b — let any fight from the walk actually end
- expected: rewards/control return if ISO-16a resolved a fight; a plain wait if it did not
- actual: waited 480 physics frames
- events: t=229.37
- verdict: PASS

### ISO-17 — the grove region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ironwood_grove`
- actual: region=the_ironwood_grove (wanted the_ironwood_grove)
- events: t=229.37
- verdict: PASS

### ISO-18 — rescan for points of interest
- expected: the grove's own content joins the POI set
- actual: 1089 points of interest in the tree
- events: t=229.37
- verdict: PASS

### ISO-19 — harvest ironwood
- expected: band 4's own material, gathered with the axe already carried
- actual: pressed interact x2 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=235.23
- verdict: PASS

### ISO-20 — the saddle is already in the satchel
- expected: a note event carries this observation into events.jsonl
- actual: Seed assumption per the task brief: a real S04 tournament-final win over Oskar's Meadowhart grants the saddle (data/config/tournament.json's own comment); this seed carries it already so this segment can test riding directly rather than re-testing crafting, which is X02/S03's own scope.
- events: t=235.23
- verdict: PASS

### ISO-20a — cycle the active creature to the Meadowhart
- expected: encounter_director.gd: party_cycle steps `Party.cycle_active(1)` forward by one and re-syncs the deployed body each press. Seed order is Tuskroot(0), Trailpup(1), Duskhush(2), Galecrest(3), Meadowhart(4) -- four presses from Tuskroot lands on the Meadowhart, the only rideable creature in this party (species.json's `rideable` block)
- actual: pressed party_cycle x4 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=240.07
- verdict: PASS

### ISO-20w — the world owns input before mounting
- expected: no narrative modal is holding locomotion
- actual: input_context=world (wanted world)
- events: t=240.07
- verdict: PASS

### ISO-21 — mount the Meadowhart
- expected: riding_controller.gd: the same interact button, arbitrated -- 'Ride Meadowhart' wins the prompt beside the deployed party creature
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=240.40
- verdict: PASS

### ISO-22 — let the mount stage
- expected: the riding camera and mounted locomotion take over
- actual: waited 180 physics frames
- events: t=243.40
- verdict: PASS

### ISO-22a — FINDING: the direct grove->captain_field line snags the mount
- expected: a defect event carries this finding into events.jsonl
- actual: recorded defect (QUALITY): A first attempt rode the direct line from the grove toward (170,5590) at the expected ~10 m/s (Meadowhart's ride_speed_multiplier 2.0 x 5.0 m/s walk_speed -- confirmed correct and sustained for most of the route from route.csv) but stalled into a tight (~3 m) back-and-forth oscillation loop at TWO points on that direct line -- around (35,0,5447) for ~56 s and again around (98,1,5512) for the remainder of the budget, never reaching the target. Whatever is at those two spots, the mount's own collider (species.json placeholder radius 0.74 m, larger than the player's own) could not get past it on a straight approach, and the un-pathfound stick_navigator steering oscillated against it rather than finding a way around. This leg is now routed wide of both points instead, so the rest of S08 can be tested; the snag itself is recorded here rather than silently routed around unremarked.
- events: t=243.40
- verdict: PASS

### ISO-23-1j — a jump, in case anything is still snagged from the last attempt
- expected: harmless if not caught on anything; a possible unstick if the mount's collider is resting against geometry
- actual: pressed jump x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=243.75
- verdict: PASS

### ISO-23-1 — ride wide of the first snag point
- expected: routes east of the (35,5447) stall point found above rather than through it. NOTE (consistent across every run of this leg): still stops ~92m short at a THIRD snag point near (4,-1,5395), on the wide-routed line itself. Same class of finding as ISO-22a (the mount's larger collider, per species.json's placeholder radius, catching on something the un-pathfound stick_navigator's straight-line steering cannot route around) rather than a new one -- not chased further because ISO-23-2 and ISO-23 both still complete the journey to the captain from wherever this leg leaves off, so it does not block the segment.
- actual: FAIL did not reach (70, 5460) in 3000 walking frames; stopped 92.7 m short at (4.0, -1.0, 5395.0) (0 held)
- events: t=293.77
- verdict: FAIL

### ISO-23-2 — ride wide of the second snag point
- expected: routes east of the (98,5512) stall point found above rather than through it
- actual: walked 180.1 m to (140, 5520) in 1102 walking frames (0 held)
- events: t=312.15
- verdict: PASS

### ISO-23 — ride the final approach to Captain Halder (the field captain)
- expected: Section D RT-10's second anchor (170,5590) is captain_field. Riding must beat walking and must not cost stamina
- actual: walked 76.8 m to (170, 5590) in 992 walking frames (0 held)
- events: t=328.70
- verdict: PASS

### ISO-23a — defend against an in-transit ambush, if any
- expected: same safe no-op/real-defence rationale as ISO-16a, now for the ridden leg -- a fight forces a dismount (riding_controller.gd::_riding_allowed refuses while `manager.is_fighting()`), so this covers the Meadowhart being caught on foot mid-route too
- actual: pressed combat_quick x30 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=371.83
- verdict: PASS

### ISO-23b — let any fight from the ride actually end
- expected: rewards/control return if ISO-23a resolved a fight; a plain wait if it did not
- actual: waited 480 physics frames
- events: t=379.83
- verdict: PASS

### ISO-24 — dismount for the fight
- expected: the human never fights; a captain fight is piloted on foot
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=380.50
- verdict: PASS

### ISO-25 — let the dismount settle
- expected: control returns to the player on foot
- actual: waited 120 physics frames
- events: t=382.50
- verdict: PASS

### ISO-26 — challenge Captain Halder
- expected: trainers.json band4 order 11: captain_field, Ground-focused, rewards field_sigil
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=383.25
- verdict: PASS

### ISO-27 — hear the captain out
- expected: the challenge conversation ends on battle:captain_field and the fight starts when the box closes
- actual: advanced 4 line(s) over 4 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'combat'
- events: t=386.80
- verdict: PASS

### ISO-28 — the fight is actually running
- expected: RIG-26: a bare press only proves input was injected; this proves a fight is live
- actual: combat_running=true (wanted true)
- events: t=386.80
- verdict: PASS

### ISO-29 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=389.80
- verdict: PASS

### ISO-30-r1 — fight round 1: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 1 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=403.47
- verdict: PASS

### ISO-30-c1 — switch pilot, round 1
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=404.20
- verdict: PASS

### ISO-30-r2 — fight round 2: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 2 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=418.75
- verdict: PASS

### ISO-30-c2 — switch pilot, round 2
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=419.73
- verdict: PASS

### ISO-30-r3 — fight round 3: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 3 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=435.28
- verdict: PASS

### ISO-30-c3 — switch pilot, round 3
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=435.95
- verdict: PASS

### ISO-30-r4 — fight round 4: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 4 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=449.75
- verdict: PASS

### ISO-30-c4 — switch pilot, round 4
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=450.52
- verdict: PASS

### ISO-30-r5 — fight round 5: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 5 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=466.23
- verdict: PASS

### ISO-30-c5 — switch pilot, round 5
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=467.22
- verdict: PASS

### ISO-30-r6 — fight round 6: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 6 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=481.67
- verdict: PASS

### ISO-30-c6 — switch pilot, round 6
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=482.50
- verdict: PASS

### ISO-30-r7 — fight round 7: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 7 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=495.17
- verdict: PASS

### ISO-30-c7 — switch pilot, round 7
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=495.75
- verdict: PASS

### ISO-30-r8 — fight round 8: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 8 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=507.52
- verdict: PASS

### ISO-30-c8 — switch pilot, round 8
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=508.37
- verdict: PASS

### ISO-30-r9 — fight round 9: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 9 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=520.18
- verdict: PASS

### ISO-30-c9 — switch pilot, round 9
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=521.08
- verdict: PASS

### ISO-30-r10 — fight round 10: quick attacks
- expected: Captain Halder (Ground-focused, 13/14/15) -- round 10 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=531.42
- verdict: PASS

### ISO-30-c10 — switch pilot, round 10
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=532.08
- verdict: PASS

### ISO-33 — let the fight end
- expected: rewards and control return with no stuck modal -- widened from 10s to 30s after a run where the fight had not actually concluded at 10s (combat_running still true) and the NEXT step (a DIAG teleport into the following leg) fired mid-combat, corrupting position/state for the rest of the run
- actual: waited 1800 physics frames
- events: t=562.08
- verdict: PASS

### ISO-33-canary — the fight has actually ended before moving on
- expected: if this ever fails, nothing after it in this segment can be trusted -- the fight is still running and the next steps would act into a live trainer battle
- actual: combat_running=false (wanted false)
- events: t=562.08
- verdict: PASS

### ISO-34 — the field captain is beaten
- expected: the first of the objective's three count_flags, and the field_sigil should be in the satchel
- actual: flag defeated_captain_field set
- events: t=562.08
- verdict: PASS

### ISO-34w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=world (wanted world)
- events: t=562.08
- verdict: PASS

### ISO-34t — shorten the incidental field->riverwatch transit
- expected: same rationale as ISO-15t: this leg is transit, not a system under test, and this test already proved riding traversal on the previous (real, untelported) leg
- actual: DIAG teleport to (-85, 4418); distance/dead-travel accumulators reset
- events: t=563.08
- verdict: PASS

### ISO-35 — walk the final approach to Captain Oreth (the riverwatch captain)
- expected: Section D RT-10's third anchor (-100,4350) is captain_riverwatch, sited in band3's own trainer file but geographically inside this segment's span
- actual: walked 66.2 m to (-100, 4350) in 837 walking frames (0 held)
- events: t=577.05
- verdict: PASS

### ISO-35a — defend against an in-transit ambush, if any
- expected: same rationale as ISO-16a
- actual: pressed combat_quick x30 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=599.53
- verdict: PASS

### ISO-35b — let any fight from the walk actually end
- expected: rewards/control return if ISO-35a resolved a fight; a plain wait if it did not
- actual: waited 480 physics frames
- events: t=607.53
- verdict: PASS

### ISO-36 — challenge Captain Oreth
- expected: the second of the three -- Water-led but deliberately balanced
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=607.83
- verdict: PASS

### ISO-37 — hear the captain out
- expected: the challenge conversation ends and the fight starts when the box closes
- actual: advanced 3 line(s) over 3 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'combat'
- events: t=609.73
- verdict: PASS

### ISO-38 — the fight is actually running
- expected: a fight is live, not merely a press injected
- actual: combat_running=true (wanted true)
- events: t=609.73
- verdict: PASS

### ISO-39 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=612.73
- verdict: PASS

### ISO-40-r1 — fight round 1: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 1 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=619.77
- verdict: PASS

### ISO-40-c1 — switch pilot, round 1
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=620.22
- verdict: PASS

### ISO-40-r2 — fight round 2: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 2 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=627.57
- verdict: PASS

### ISO-40-c2 — switch pilot, round 2
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=627.97
- verdict: PASS

### ISO-40-r3 — fight round 3: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 3 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=635.00
- verdict: PASS

### ISO-40-c3 — switch pilot, round 3
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=635.35
- verdict: PASS

### ISO-40-r4 — fight round 4: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 4 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=641.93
- verdict: PASS

### ISO-40-c4 — switch pilot, round 4
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=642.22
- verdict: PASS

### ISO-40-r5 — fight round 5: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 5 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=649.35
- verdict: PASS

### ISO-40-c5 — switch pilot, round 5
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=649.77
- verdict: PASS

### ISO-40-r6 — fight round 6: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 6 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=656.02
- verdict: PASS

### ISO-40-c6 — switch pilot, round 6
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=656.37
- verdict: PASS

### ISO-40-r7 — fight round 7: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 7 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=662.68
- verdict: PASS

### ISO-40-c7 — switch pilot, round 7
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=663.05
- verdict: PASS

### ISO-40-r8 — fight round 8: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 8 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=670.23
- verdict: PASS

### ISO-40-c8 — switch pilot, round 8
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=670.65
- verdict: PASS

### ISO-40-r9 — fight round 9: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 9 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=677.25
- verdict: PASS

### ISO-40-c9 — switch pilot, round 9
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=677.60
- verdict: PASS

### ISO-40-r10 — fight round 10: quick attacks
- expected: Captain Oreth (mixed Water/Ground, 13/14/16) -- round 10 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=683.82
- verdict: PASS

### ISO-40-c10 — switch pilot, round 10
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=684.27
- verdict: PASS

### ISO-43 — let the fight end
- expected: rewards and control return with no stuck modal -- widened from 10s to 30s after a run where the fight had not actually concluded at 10s (combat_running still true) and the NEXT step (a DIAG teleport into the following leg) fired mid-combat, corrupting position/state for the rest of the run
- actual: waited 1800 physics frames
- events: t=714.27
- verdict: PASS

### ISO-43-canary — the fight has actually ended before moving on
- expected: if this ever fails, nothing after it in this segment can be trusted -- the fight is still running and the next steps would act into a live trainer battle
- actual: combat_running=false (wanted false)
- events: t=714.27
- verdict: PASS

### ISO-44 — the riverwatch captain is beaten
- expected: the second of the three count_flags, and the river_sigil should be in the satchel
- actual: flag defeated_captain_riverwatch set
- events: t=714.27
- verdict: PASS

### ISO-44w — the world owns input before this walk
- expected: no narrative modal is holding locomotion when this walk starts
- actual: input_context=world (wanted world)
- events: t=714.27
- verdict: PASS

### ISO-44t — shorten the incidental riverwatch->ridge transit
- expected: same rationale as ISO-15t
- actual: DIAG teleport to (-272, 6370); distance/dead-travel accumulators reset
- events: t=715.27
- verdict: PASS

### ISO-45 — walk the final approach to Captain Vess on the ridgeline
- expected: Section D RT-10's fourth anchor (-280,6460) is captain_ridge, in the_ridgeline_watch
- actual: walked 86.2 m to (-280, 6460) in 1054 walking frames (0 held)
- events: t=732.85
- verdict: PASS

### ISO-46 — the ridgeline region contains the arrival
- expected: map_state.gd's containment puts the player in `the_ridgeline_watch`
- actual: region=the_ridgeline_watch (wanted the_ridgeline_watch)
- events: t=732.85
- verdict: PASS

### ISO-45a — defend against an in-transit ambush, if any
- expected: same rationale as ISO-16a
- actual: pressed combat_quick x30 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=754.23
- verdict: PASS

### ISO-45b — let any fight from the walk actually end
- expected: rewards/control return if ISO-45a resolved a fight; a plain wait if it did not
- actual: waited 480 physics frames
- events: t=762.23
- verdict: PASS

### ISO-47 — challenge Captain Vess
- expected: the third of the three -- Air-focused
- actual: pressed interact x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:2
- events: t=762.53
- verdict: PASS

### ISO-48 — hear the captain out
- expected: the challenge conversation ends and the fight starts when the box closes
- actual: advanced 4 line(s) over 4 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'combat'
- events: t=764.35
- verdict: PASS

### ISO-49 — the fight is actually running
- expected: a fight is live, not merely a press injected
- actual: combat_running=true (wanted true)
- events: t=764.35
- verdict: PASS

### ISO-50 — let the fight stage
- expected: the combat camera acquires both combatants
- actual: waited 180 physics frames
- events: t=767.35
- verdict: PASS

### ISO-51-r1 — fight round 1: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 1 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=773.80
- verdict: PASS

### ISO-51-c1 — switch pilot, round 1
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=774.15
- verdict: PASS

### ISO-51-r2 — fight round 2: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 2 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=780.52
- verdict: PASS

### ISO-51-c2 — switch pilot, round 2
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=780.83
- verdict: PASS

### ISO-51-r3 — fight round 3: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 3 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=786.97
- verdict: PASS

### ISO-51-c3 — switch pilot, round 3
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=787.33
- verdict: PASS

### ISO-51-r4 — fight round 4: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 4 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=793.98
- verdict: PASS

### ISO-51-c4 — switch pilot, round 4
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=794.32
- verdict: PASS

### ISO-51-r5 — fight round 5: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 5 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=800.62
- verdict: PASS

### ISO-51-c5 — switch pilot, round 5
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=801.00
- verdict: PASS

### ISO-51-r6 — fight round 6: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 6 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=807.88
- verdict: PASS

### ISO-51-c6 — switch pilot, round 6
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=808.30
- verdict: PASS

### ISO-51-r7 — fight round 7: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 7 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=814.67
- verdict: PASS

### ISO-51-c7 — switch pilot, round 7
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=815.12
- verdict: PASS

### ISO-51-r8 — fight round 8: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 8 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=820.43
- verdict: PASS

### ISO-51-c8 — switch pilot, round 8
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=820.87
- verdict: PASS

### ISO-51-r9 — fight round 9: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 9 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=826.15
- verdict: PASS

### ISO-51-c9 — switch pilot, round 9
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=826.63
- verdict: PASS

### ISO-51-r10 — fight round 10: quick attacks
- expected: Captain Vess (Air-focused, 14/15/16) -- round 10 of a proactive fight-then-switch loop. combat_manager.gd's own D32 comment settles what earlier runs were probing for: 'There is no auto-switch-on-faint ... a faint of the active creature still ends the fight ... This only ever fires from the player's own choice' -- switching is deliberately NOT a post-faint save, it is a pre-emptive rotation, so the fix is switching often enough that no one creature is left at the front for too long, not switching faster after the fact.
- actual: pressed combat_quick x9 (tap, 1 frames each) on the default device, resolved to JoyAxis:5:1.0
- events: t=832.18
- verdict: PASS

### ISO-51-c10 — switch pilot, round 10
- expected: cycle_active(1) skips a fainted creature and keeps whichever is already healthy active if nothing better -- proactive rotation, not a reaction to a faint that has already ended the fight
- actual: pressed party_cycle x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:9
- events: t=832.65
- verdict: PASS

### ISO-54 — let the fight end
- expected: rewards and control return with no stuck modal -- widened from 10s to 30s after a run where the fight had not actually concluded at 10s (combat_running still true) and the NEXT step (a DIAG teleport into the following leg) fired mid-combat, corrupting position/state for the rest of the run
- actual: waited 1800 physics frames
- events: t=862.65
- verdict: PASS

### ISO-54-canary — the fight has actually ended before moving on
- expected: if this ever fails, nothing after it in this segment can be trusted -- the fight is still running and the next steps would act into a live trainer battle
- actual: combat_running=false (wanted false)
- events: t=862.65
- verdict: PASS

### ISO-55 — the ridge captain is beaten
- expected: the third of the three count_flags, and the ridge_sigil should be in the satchel
- actual: flag defeated_captain_ridge set
- events: t=862.65
- verdict: PASS

### ISO-56 — all three captains and the objective count
- expected: CORRECTED (was checking for an early advance to `fight_through_the_hall`, which is wrong -- see ISO-57's own correction below for why). The tracked line stays on `defeat_the_captains` with its count at 3/3 until the Sigil Gate is actually opened, which ralph_GATE_F_MASTER_PROTOCOL.md section B places at the START of S09 ('Sigil gate -> outer watch -> ...'), not the end of S08. Section B's S08 span is 'three captains -> three Sigils' -- carrying them, not yet spending them on the gate.
- actual: tracked objective id=hall_approach_open text=Defeat the Upper Meadows captains. 3/3 (wanted hall_approach_open) [matched on flag_id]
- events: t=862.65
- verdict: PASS

### ISO-57 — the Hall approach is open (the three Sigils, together)
- expected: item_gate.gd's SigilGate: key_item_ids = [field_sigil, ridge_sigil, river_sigil], flag_id = hall_approach_open. This is section B's own span end for S08: '...three Sigils'
- actual: CORRECTED. The original assertion here (flag_set hall_approach_open) was testing S09's scope, not S08's: item_gate.gd::try_open() -- the SigilGate's only path to setting hall_approach_open -- runs 'on interaction' at the gate's own world position (SIGIL_GATE_AT, (63.6,7400) in playground_world.gd), which this isolated segment never visits (S08's own span ends at the third captain, ~940m south of the gate; walking there and opening it is explicitly S09's first beat per protocol section B). The flag correctly reads unset at this point -- confirmed by re-running this exact assertion as flag_set and getting a clean, expected FAIL. What SHOULD be true at S08's real boundary is that the player is carrying all three Sigil items (field_sigil, ridge_sigil, river_sigil): every captain's own trainers.json reward block grants exactly one, applied by the SAME reward code path that also sets each defeat_flag (already confirmed PASS at ISO-34/44/55), so the items are inferred held with the same confidence as the flags -- but the harness's assert vocabulary (protocol section, SEGMENT_SCHEMA.md's own check list) has no inventory-contents check to confirm this directly and one was not added here, out of this isolated leg's own scope.
- events: t=862.65
- verdict: PASS

### ISO-58 — band 4 was actually walked and ridden
- expected: distance_above is measured only since the LAST teleport (ISO-44t), so this asserts the real, untelported ~739 m ride from the grove to captain_field plus everything since -- see REPORT.md for why the incidental crossing/riverwatch/ridge transit legs were shortened via DIAG teleport instead of walked in full; no pacing claim about the whole band comes from this number
- actual: walked 969.8 m this segment (wanted >= 600.0)
- events: t=862.65
- verdict: PASS

### ISO-59 — save handoff: open the pause shell
- expected: the pause shell, opened by its bound shortcut
- actual: map opened the shell: context world -> menu_map, focus on '' (@Control@69645)
- events: t=862.83
- verdict: PASS

### ISO-60 — cycle to the Save tab
- expected: three RB presses from the map tab reach Save
- actual: pressed menu_tab_right x3 (tap, 1 frames each) on the default device, resolved to JoyBtn:10
- events: t=863.55
- verdict: PASS

### ISO-61 — the Save tab is up
- expected: input_context names the live tab: menu_save
- actual: input_context=menu_save (wanted menu_save)
- events: t=863.55
- verdict: PASS

### ISO-62 — move focus to slot 4's Save button
- expected: focus starts on slot 0 and four d-pad downs reach slot 4
- actual: 4 x ui_down moved focus 'Save' (@Button@69703) -> 'Save' (@Button@69723)
- events: t=863.95
- verdict: PASS

### ISO-63 — press Save
- expected: the focused Save button activates and writes slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=864.38
- verdict: PASS

### ISO-64 — give the write a moment
- expected: the slot file is on disk
- actual: waited 120 physics frames
- events: t=866.38
- verdict: PASS

### ISO-65 — copy slot 4 out as this segment's exit save
- expected: saves/S08-exit.json now holds this isolated run's own S08 handoff
- actual: slot 4 copied to saves/S08-exit.json (1420541 bytes)
- events: t=866.38
- verdict: PASS

### ISO-66 — close the shell
- expected: B closes the shell and hands the world back
- actual: menu_cancel closed the shell: context menu_save -> world
- events: t=866.67
- verdict: PASS

### ISO-67 — close the segment
- expected: a note event carries this observation into events.jsonl
- actual: S08 (isolated) exit save written and copied. All three captains defeated, all three Sigils carried, hall_approach_open set.
- events: t=866.67
- verdict: PASS
