# Meadows earned Warden, ending and Rift — Wave 2

## Required chain and scope before implementation

Current production requires: the Hall's actual Warden-arena entry → read `StrongholdClimax/TetherReadout/ReadoutPrompt` (`stronghold_reveal`, environmental reveal before the fight) → challenge `StrongholdClimax.warden_body()` / `warden_aldis` → defeat his exact five creatures and receive configured items, 400 bonus XP, `realm_key_cloudreach` and `realm_heart_meadows_earned` → the actual `defeated_warden` shutter opens → walk its passage toward the real `machine_foot` marker → Interact with `StrongholdClimax/MachineControl/MachinePrompt` → production chamber/free/join conversations → production-created pending Veridian level 22 → real five-slot farewell ceremony → machinery-failure conversation and `legendary_settled` → actual post-win NPC acknowledgement → ordinary RiftCrossing trigger into Cloudreach.

Reusable earned seams: Hall `_fight_named` already binds arbitrary exact production trainer IDs and current payout/XP, under 9000 actual physics frames. Relay `_press_prompt` and `_talk` use actual provider admission and physical Interact. `earned_roster_replacement_segment.gd::_ceremony_tap` safely emits GUI input while the menu pauses the world, but its whole `replace_existing` cannot be used: the legendary voluntarily offers to join and is not caught through combat/orbs. The new segment will use only that process-frame input primitive. Parent explicitly chose to keep the existing earned five: select the already-focused pending legendary row, confirm release, and prove all five owned identities unchanged. This is a valid production ending (`stronghold_climax.gd:908–986`, `tab_creatures.gd:1758–1838`), not a skipped ceremony.

The machine auto-starts successive conversations as each closes. Its new observer must record each actual finished ID and stop at the pending-choice seam, rather than call dialogue start/advance or accidentally consume the following conversation under a previous-ID assertion. Story callbacks alone create the pending creature and set the ending flags.

## Acknowledgement / travel audit: concrete dead travel

All current `meadows_freed.json` acknowledgement effects are reached through Grandpa or current village NPCs. Kell (`VillageNPCs/Kell`, `village_npcs.json:221–237`) is at `[184.2,52.6]`, outside the village boundary, and is placed after `legendary_freed`. There is no near-Hall remapping in `village_npcs.gd::_spawn`: it uses the authored position directly. Kell avoids an extra village-boundary/cottage route, but still requires the chapter-length backtrack. His old dialogue also says the bridge is still gone, despite the current rebuilt Rift crossing; this is an additional stale aftermath-content finding, not permission for a harness to rewrite the story.

The current five-band road spine measures **11,518.662m one way** before choosing the precise acknowledgement junction and bridge/Relay-loop detours. A return journey is therefore approximately **23km**, roughly **77–96 minutes at 5–4m/s**, excluding combat, pauses and care. This is an authored-route estimate, not a runtime timing or shortest-terrain-path proof. It conflicts with a concise, playable final acknowledgement before the adjacent Hall-to-Cloudreach handoff and consumes a substantial part of the whole 3–4-hour chapter target. Root was notified for an explicit product backlog entry. No NPC relocation or automatic objective bypass is authorized in this source task.

Ordinary fast-travel audit: current `tab_map.gd` changes map view/realm display, explicitly independently of the player's realm, and has no destination travel action. Searches of current species/controller/map code found no earned teleport/warp/blink action. C1's Ripplet teleport is a later-biome presentation promise, not a learned Meadows ability. The available direct destination relocation APIs are Settings debug teleport or actual realm crossings. Neither an unearned ability nor Settings debug travel will be used.

Implementation scope: own new helper, focused test and this report only; retain separate callable finale and acknowledgement/crossing tails. No world test, production/shared/driver edits, commits, grants, actor poses, reload or debug travel. Actual readiness, geometry, story sequence and full travel remain unproved until serialized runtime.

## Implemented continuation and review closure

`tests/helpers/meadows_earned_warden_segment.gd` now exposes `run(tree, world, game)`, `run_finale(...)`, and `run_after_finale(...)`. The first composes both tails. Finale requires the preceding actual arena arrival, retained five unique creatures, closed Warden shutter, and absent next-story rewards. It uses the inherited earned trainer pilot and configured rewards; the exact machine conversation sequence is observed from real finished callbacks. The ceremony navigates the real paused Creatures UI, releases the pending legendary, and proves the owned five stay identical and in order. It then requires the real machinery-failure conversation, settled flags, and visibly freed legendary.

The aftermath tail physically leaves each already-open Hall passage, follows the authored road with actual SouthBridge/Mill/Sigil crossing points and the Relay approach loop, speaks to actual Kell, returns along the road, and crosses the actual Rift trigger. It observes the exact player's `body_entered` and waits for production Cloudreach readiness; the helper never calls realm travel itself. The retained-party observer stays connected through travel and is safely disconnected even when the outgoing world destroys its signal owners. The composed road fixture measures **11,415.7155m one way** before the exact Kell connector and the final Hall/Storm Road joins. This refines the earlier whole-spine estimate; it does not establish runtime duration or an optimal route.

Independent root review found and corrected two issues before freeze: Godot RefCounted instance IDs can be negative, so a pending ID must be nonzero and not already owned; the regression includes an actual `CREATURE.new().get_instance_id()`. Each complete final-room crossing now shares one 600-physics-frame budget across its intermediate doorway and final marker, in both directions. The other existing combat, story, admission, identity and travel assertions remain unchanged.

## Validation and limits

Focused command:

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --log-file "$env:TEMP/meadows-earned-warden-tests-20260908.log" --script tests/run_tests.gd -- --only=test_meadows_earned_warden_segment.gd
```

Terminal result: **8 tests, 73 assertions, 0 failed**, exit 0, no engine script errors. Coverage includes missing-context refusal for all entrypoints, current Warden and machine configuration, exact dialogue ordering, negative real creature IDs and unchanged-five ceremony receipts, the real Kell acknowledgement effect, authored road and safe crossing fixtures, exact-player Rift observation, and cleanup after an outgoing signal owner is freed. These are focused source/fixture and callback tests, not a production gate or full-world runtime.

Final `--check-only` parser run for the helper also exited 0 without errors; log: `$env:TEMP/meadows-earned-warden-parse-20260908.log`. Full-world RAM remained reserved for other work. **Warden combat, machine/ceremony input, the long acknowledgement journey, and the actual composed Cloudreach transition are implemented but remain runtime-unproved.** No production, driver or shared-helper file was edited in this task. The acknowledgement dead travel and stale Kell text remain product findings for the integration owner; no bypass was introduced.
