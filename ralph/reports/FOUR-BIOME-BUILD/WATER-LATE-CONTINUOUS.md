# Water late-chapter continuous-path harness

Date: 2026-09-08
Branch: `codex/four-biome-wave0`

## Evidence boundary

`tests/smoke_water_continuous.gd` is a late-route traversal diagnostic, not a
fresh-save acceptance test. It starts at Tidal Cradle with one deliberately
synthetic fixture:

- an owned, healthy level-60 Aquaryn;
- `water_aquaryn_resolved`, `water_swim_stone_earned`, and
  `water_swim_saddle_recipe_learned` already set;
- one Swim Saddle already in inventory; and
- the player placed at the authored Tidal-to-Salt departure anchor.

Those facts and the initial pose are established before the harness prints
`DEPARTED`. After that boundary it does not teleport an actor, set progression
flags, add materials, or repair health/stamina. The established Alpha runtime
smoke instead defeats Aquaryn with a level-49 Mosshell; it does not earn the
owned level-60 Aquaryn used here. This harness therefore cannot prove the
ordinary Alpha/catch/party composition or the fresh-save opening-to-Water path.

## Continuous traversal evidence so far

The instrumented run in
`%TEMP%\water-continuous-calder-instrumented.log` physically traversed the
authored Tidal-to-Salt crossing, Salt exploration spine, Salt chart action,
Salt-to-Sluice crossing, and the Sluice route. It then:

- defeated Bex's two opponents at +409.8 seconds;
- disabled the western control at +410.7 seconds;
- assigned Aquaryn through the focused production creature-bed UI, advanced
  one ordinary overnight rest, restored full health without an HP write, and
  redeployed through controller input by +417.8 seconds;
- walked the graded Sluice ascent and departure waypoints;
- defeated Calder's three opponents at +687.4 seconds; and
- activated the eastern control, published the combined-control completion,
  and removed the final barrier by +690.4 seconds.

The mount call was refused at the east-control position; the harness had not
approached the surviving follower. Proximity is the leading explanation, not a
cause proven by that log. The run ended with 21 checks and one failure. The
result proves the bounded route through the Sluice barrier, not a complete
Water chapter.

## Copied-save mount diagnostic

`tests/probe_water_saved_suffix.gd` copies, then loads, the test-owned
`user://water_continuous_late_3915153/` save. The source save is not modified.
It contains the Aquaryn/Bex/west-control results but explicitly lacks the
Calder/east/combined-control flags. The probe is therefore a pre-Calder shortcut
and not continuity evidence.

The run in `%TEMP%\probe-water-saved-suffix.log` loaded that copy through the
production save path, resumed at `(807.5703, 18.53305, 3155.541)`, deployed the
saved healthy Aquaryn with controller input, walked to Sluice waypoints 4 and 5,
defeated Calder's three opponents, and completed the east/combined controls.
It then physically approached the follower, received an actionable production
Ride offer, activated it, and mounted at +194.6 seconds.

This was not a clean run: the new diagnostic string called
`_mount_surface_distance` with the wrong argument count and emitted two script
errors. The gameplay action still mounted, but the failed diagnostic output is
not evidence for which predicate caused the earlier refusal. The call now passes
both the player position and body, and
`tests/test_water_continuous_mount_diagnostic.gd` exercises that exact helper
contract without constructing a Terrain3D world. Its focused result is:

```text
1 tests, 1 assertions, 0 failed
```

## Venn route repair and first full attempt

The original production encounter reused Officer Venn's NPC body at
`(200, 619.079, 4152)`, stranded above the graded approach. The focused
production repair placed that same body at `(311.779, 141.188, 3894.433)`,
exactly on the final spine leg. From point 3, real stick travel covered 349.49 m
with zero navigator resets and zero of 349 grade samples above 24 degrees. The
first grounded stance received actionable `Challenge Officer Venn` at 2.02 m.
This focused evidence is in `%TEMP%\water-venn-approach-final.log`.

The subsequent uninterrupted run in
`%TEMP%\water-continuous-full-20260908-0358.log` had no script errors or freeze.
After the disclosed `DEPARTED` boundary it passed both crossings, Bex, both
Sluice controls, the final barrier, both authored exterior camp rests, Venn's
three-creature fight, the waterfall entry, controller redeploy after entry's
intentional dismissal, and both interior controls. Venn completed at +1329.1
seconds with Aquaryn at 250.9/708.4 HP; both Veilfall controls completed at
+1359.8 seconds.

The run then reproduced a bounded recovery problem in this one-creature
diagnostic: Aquaryn fainted during Nerissa's second opponent (Cannonback then
Mirejaw), leaving two of the captain's four creatures unseen and
`water_captain_nerissa_defeated` unset. It ended with 33 checks and one failure.
This does not prove an ordinary five-creature campaign party is underpowered.

`water_camp_veilfall` at spine point 1 is the authored exterior recovery service;
the compact Veilfall interior defines controls, grilles and an exit but no camp
or bed. The next harness revision therefore uses only ordinary player actions:
recall after Venn, retrace the same graded spine from point 3 to point 1, assign
Aquaryn to the camp bed, pass one night, recall the freshly redeployed ally to
protect it on the return hike, retrace points 2-4, enter the cave, and deploy by
controller input for Nerissa. No party member, item, HP, stamina, position or
progression flag is injected. The measured extra 2.54 km round trip requires a
50-minute whole-path watchdog; individual interaction and fight deadlines are
unchanged.

The prepared next run will then fight Captain Nerissa, release the Guardian
tether, settle the Guardian through its prompt, and require the durable
`water_currents_restored` result.

A passing future run will prove only that disclosed late-route span. Fresh-save
composition with the preceding Alpha/saddle milestone remains separately
required.
