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

## Next run preparation and route blocker

The ordinary late diagnostic now physically approaches the surviving follower
and requires the real Ride offer before the Sluice-to-Veilfall crossing. At the
Veilfall landing it uses the authored camp and creature bed to recover through
ordinary UI. Cave entry intentionally dismisses the follower, so controller
input redeploys it before Nerissa. The measured prefix reaches Sluice completion
at about 690 seconds; the remaining exterior route is about 1.27 km. The
whole-path watchdog is therefore 30 minutes because the old 15-minute ceiling
was impossible even when every remaining interaction succeeded.

One intended-route gap must be resolved before spending that full runtime.
Officer Venn currently resolves to world XZ `(182, 4100)`, while the complete
authored `veilfall_exploration_spine` remains at least 213.95 m away (nearest at
spine point 3, `(-14.774, 4016)`). The story contract says Venn holds the
waterfall approach. A continuous witness must not silently replace that missing
connection with an ungraded 214 m navigator chord. The Veilfall footing lane is
measuring a reachable late-spine/approach placement; no production placement
was guessed in this harness commit.

Once that ordinary approach is present, the run will fight Venn, enter the
waterfall through its production prompt, activate the intake and return sluice
controls, fight Captain Nerissa, release the Guardian tether, settle the
Guardian through its prompt, and require the durable
`water_currents_restored` result. No post-departure fixture write is permitted.

A passing future run will prove only that disclosed late-route span. Fresh-save
composition with the preceding Alpha/saddle milestone remains separately
required.
