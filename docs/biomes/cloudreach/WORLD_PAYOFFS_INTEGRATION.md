# Cloudreach side-chain and regional aftermath payoffs

Implemented in the shared working tree on `codex/cloudreach-cliffs`, uncommitted
for root integration. This is a production-component checkpoint, not chapter,
balance, target-performance or visual acceptance.

`cloudreach_world_runtime.gd` mounts one `cloudreach_world_payoffs.gd` after the
chapter, finale presentation and atmosphere. The helper projects the existing
ProgressionState into visible people, props and audio. It grants no quests,
inventory, realm access or creatures and owns no save store. Its tuning and
authored placements live under `cloudreach_npc_runtime.json.world_payoffs`.

## What the player sees

- Completing Three Bells reveals two travelers using the installed courier and
  wandering-trainer rigs. They walk short supported sections of the existing
  bridge deck, pause at the ends and stop near the player for conversation.
  The real lower signal position plays a spatial three-note route cue every
  24 seconds while nearby. It reuses the installed `craft_done.wav` at a lower
  pitch; this is not a newly sourced bespoke bell recording.
- The ravine shelter now contains its two stranded people, using the installed
  lost-traveler and courier bodies. Completing Neri's delivery report relocates
  both existing bodies to Galefoot, beside Neri. Their return greeting explains
  the result. Neri's existing delivery/report state machine is preserved.
- Each of the three completed aerial surveys independently reveals a cream
  streamer pair, pale landing ring, named landing marker and functional shared
  rest prompt at the surveyed ground. These do not unlock other surveys or
  movement abilities. Shared rest behavior supplies recovery; no crafting
  station or new hunger policy is introduced.
- Completing the Cliff Circuit reveals a timber board beside Tavi with five
  linked places as the team's mark. It also enables the separate **Circuit
  Mastery** rematch on Tavi's same canonical body. This has the same three
  species, three additional levels per member and the existing ace payout
  (90 coins and one Great Candy). Winning adds the mastery seal.
- Regional restoration visibly removes the compressed teal wind from all
  eight bound anchor/relay sites: two lower anchors, two upper anchors, the
  summit feed and three final relays. Their replacement natural wind ribbons
  reuse the installed cloth motion shader with pale natural colors and no
  Team Tether device. Existing standard-material pylon overrides also lose
  emission and take a weathered neutral tint. Restoration adds two upper-road
  travelers and preserves the existing finale audio, reward, shrine-light,
  Aila relocation and non-enterable Waterward view.

All humanoid bodies, wood materials, cloth motion and sound sources already
exist in the project. No character/creature generation or asset download was
performed. Maela's trial dialogue additionally explains the root-owned temporary
Galecrest loan when the active companion cannot carry the player.

## Rematch and persistence contract

`cloudreach_encounter_director.gd::_install_circuit_rematch` copies Tavi's
authored production team into one distinct encounter ID:
`young_trainer_tavi_rematch`. It requires `side_cliff_circuit_complete` and
`cloudreach_upper_route_unlocked`. `rechallenge` remains false.

The durable defeat flag is `defeated_cloudreach_tavi_rematch`. Normal production
round completion and trainer payout record and reward this victory exactly once.
The original circuit victory does not consume this tier; replaying a victory or
reloading cannot pay it again. No separate reward implementation exists. The
scene adapter sees eight encounter entries on seven people, and retargets both
Tavi prompts to the same canonical body after the physical cast reloads.

World payoffs listen to normal progression revision/load hooks. Loading an
earlier save removes later travelers, hides the board and survey prompts,
silences the route signal, and restores bottled anchor presentation. No world
payoff infers a captain win, Heart, Water key or side-chain completion.

## Verification

```powershell
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_cloudreach_world_payoffs.gd,test_cloudreach_encounters.gd,test_cloudreach_cast_dialogue.gd
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/smoke_cloudreach_world_payoffs.gd
```

Focused unit result: **11 tests, 1,213 assertions, zero failures**. Production
smoke: **57 checks, zero failures**, exit 0 and no engine/script errors in
`ralph/reports/CLOUDREACH-WORLD-PAYOFFS-0905/smoke.log`.

The existing `smoke_cloudreach_production_integration.gd` also completed **PASS**,
exit 0, without engine/script errors. Its log is
`ralph/reports/CLOUDREACH-WORLD-PAYOFFS-0905/finale-regression.log`. It retains
the production captain/relay/aftermath/reward/disk-reload path while checking
eight encounter entries (seven trainers plus the shared-body rematch).

The smoke instantiates the actual Cloudreach scene and explicitly seeds quest
checkpoints. It verifies traveler movement/audio, pair identity and relocation,
three real-floor usable rest prompts, all eight anchor presentations, normal
Tavi deployment/three combat rounds/victory callback/payout, isolated disk save
and reload, no repeat payout, earlier-save rollback and Waterward refusal.
Only lethal combat resolution is accelerated; this does not prove difficulty,
catching, every side-route approach or continuous chapter play.

The first production run passed 56 of 57 checks and found a real placement
defect: the second returned traveler at `(-299,180,537)` had no supported floor.
Its authored return position moved to `(-292,180,536)`. The corrected full
replay passed; the failed attempt is not represented as a first-attempt pass.

For five current production checkpoint frames, run the smoke without
`--headless`, using `--rendering-method gl_compatibility --resolution 1280x800`
and trailing `-- --capture`. It writes under
`ralph/reports/CLOUDREACH-WORLD-PAYOFFS-0905/shots/`. Coordinate the single GPU
slot first. Independent blind visual judgment and root's integrated route
acceptance remain outstanding until those frames are rendered and reviewed.
