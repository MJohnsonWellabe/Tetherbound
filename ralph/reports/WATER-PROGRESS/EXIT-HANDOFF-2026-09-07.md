# Water exit handoff — owner stopped implementation, 2026-09-07

## Read this first

The owner explicitly requested: stop where you are and write an exit document for someone else. Implementation is stopped. Water is incomplete; the last evidence score is **35/100**, not a finished fourth chapter. No additional playability points were earned in the resumed period. This document supersedes stale delivery/entry claims in `FINAL-REPORT-AND-FRESH-SESSION-TAIL.md`; that report remains useful for the full census, placeholders, smokes and historical stop.

Work only in **D:\Tetherbound-Water**, branch **ralph/water-foundation-0906**. The owner explicitly changed the original instructions: use an isolated folder, work on your branch, and leave merging to the owner later. Do not reset or edit the shared D:\Tetherbound-source or C:\Users\mattj\Documents\Tetherbound checkouts. Do not merge main or other in-flight branches. Do not ask permission questions; full access and approval policy never are already established.

## Exact recovery state

- Pre-handoff HEAD: `9e011ed6c1216c8b33191c1a9ca31b32d13ba24b`. A local preservation commit following this SHA contains this document and the unfinished changes listed below; find it with `git log -1`.
- This branch was successfully rebased onto main `4562268dee581d2f2ce167a4670bbf752f139310` (Stormwood PR76). The merge base with the currently observed origin/main is still that commit.
- At exit, local origin/main has advanced to `ba8a66fbfe823c439a3adea268d00fce0199fff7` (PR77, Stormwood Dynamo). **That new merge is not incorporated.** Recheck its actual finale/handoff behavior before implementing the earlier audit recommendations.
- Remote Water branch remains `f454349bb62f14e1f3e2dee1f5ebdb3fc1701f9f`. Rebased/local exit work has not been pushed. Draft PR69: https://github.com/MJohnsonWellabe/Tetherbound/pull/69 . Do not treat its older CI as validating the local branch.
- Backup `scratch/water-before-resume-0907-1251` preserves the pre-rebase branch. Original source scratch was `scratch/pre-water-20260906-0015`.
- A future push of this rebased branch requires checking the remote tip and an explicit force-with-lease; never overwrite intervening collaborator work. No push or merge is part of this exit.
- Local `override.cfg` and import-generated `.gd.uid` files are intentionally untracked. The override isolates the test save directory and limits worker threads to two. Do not stage all untracked files indiscriminately.
- At exit inspection there were no live child agents and no Godot process listed. Do not assume old agent tasks continue running.

## What the resumed period actually accomplished

The resumed period began at 12:51:53 UTC on September 7, at 35/100. Its next checkpoint would have been 14:51:53 UTC, but the owner stopped it before that point. The earlier eight-hour execution gap and progress-rule stop remain recorded in the historical report/scorecard. Do not claim twelve hours of productive unattended execution or schedule further work from this handoff.

The rebase preserved both Stormwood and Water recipe loaders, world-ledger dispatch cases, dynamic quest selection, save version 23, and both `realm_environment` and `water_capture_claims` partitions. The focused rebase suite passed **127 tests / 1,673 assertions / zero failures** (`D:\water-resume-rebase-seams.log`). This is integration evidence, not new chapter completion.

Two unfinished delegated changes are preserved, not accepted as shipped:

1. **Save integrity:** `scripts/save/atomic_save_file.gd`, changes to `world_save.gd`, `character_save.gd`, `save_game.gd`, and `tests/test_atomic_save_file.gd`. Writes a sibling pending file, verifies bytes, moves the existing canonical file to `.previous`, installs the pending file into the now-empty canonical path, and attempts rollback on refusal. Readers fall back to `.previous` when the canonical file is absent. Intended to fix the demonstrated disk-full/truncated-save false-success bug. Logs inspected at exit report **10 tests / 49 assertions / zero failures** (`D:\water-atomic-save-focused.log`) and **69 tests / 410 assertions / zero failures** (`D:\water-atomic-save-regressions.log`). The final diff has not received complete independent review or the required full suite. Per-file replacement is not a world/character/slot transaction or power-loss durability guarantee. Review listing/deletion behavior with backup-only files, corrupt canonical files, failure propagation from split saves, and journal interaction before accepting this change. Do not fill a user's disk to reproduce errors; the tests inject bounded IO failures.
2. **Named encounters:** only the static `named_spawn_plan()` helper was added to `scripts/combat/water_encounter_director.gd`. It validates matching named/site references and returns spawn options. **It is not wired into spawning, has no new delivered test, and does not make the five named encounters playable.** Host ownership and completion replication were unresolved when work stopped. Do not present the helper as completed content.

No physical Waterward gate, reveal emitter, late-join attunement, or amphibious Alpha route was implemented during this resumed period.

## Corrected blockers — inspect these before further polishing

### 1. Ordinary Stormwood-to-Water entry is missing on the rebased Water HEAD

The previous final report incorrectly said the existing transition seam consumed the Water key. On inspected HEAD `9e011ed6c`, `stormwood_world.gd::_build_return_gate` creates only the Cloudreach return. `stormwood_world.json.transition_points` contains only Cloudreach entry/return. Water also has no physical return RealmGate. Generic `realm_gate.gd::try_unlock` retains keys intentionally; Water needs its explicitly required one-time consumption without changing other realms.

`stormwood_chapter.json` objective `stormwood_waterward_revealed` requires `stormwood:spark_placed`, listens for `aftermath:waterward_view`, and grants `realm_key_water`, `waterward_route_revealed`, and `stormwood:chapter_complete`. The audit found no production emitter of that event. Reproduce with normal play after the Spark prerequisite; there is no physical reveal/gate path. PR77 may change upstream availability: inspect it before assuming the same upstream finale gaps remain.

Use the existing realm transition and host-ledger seams. Reveal must leave the player looking at water; only the subsequent explicit key spend unlocks entry. Validate actual host-observed player realm/proximity and atomically apply key=false/unlocked=true. Preserve return arrival on the built platform rather than grounding the player below it. Useful geometry: Stormheart base is approximately (-100, terrain height, 5470), core floor height is +150, annular floor radius 9–44; inspect ramp/stair geometry before placing a gate.

### 2. Late joiners can be permanently denied Swim Stone

`water_alpha_rewards.resolve()` returns early when the shared Alpha is already resolved. Only recorded stable-character participants receive Stone entitlements. The Alpha then cannot be fought again; Iona and riding require the personal Stone. Reproduce with a fresh character joining a world after Alpha completion. Conservative next implementation: host-validated physical Iona attunement after shared victory, granting the missing personal unlock once while preserving the unique Aquaryn capture claim. This is a recommendation, not implemented behavior.

### 3. Alpha fight is still dry

Aquaryn's configured spawn is approximately XZ (601.574, 1389.434), Y 33.934; `surface_route` is empty. Existing health phases cannot produce the intended surface-water encounter. The real 33-check attacks-to-saddle smoke proves a dry battle subpath with travel/material/party fixtures, not the required amphibious fight. Compose a reachable shoreline arena, author a real surface route and validate physical phase transitions before spending time on creature meshes.

### 4. Network and save claims remain narrower than chapter acceptance

Host Alpha pose/HP/hit/disconnect, split-island swimmers and mounted replication have focused evidence. Actual network capture/reconnect, four-player finale, simultaneous offers and remote durable receipt acknowledgment remain unproven. The named-encounter lane found inherited once-only completion written locally in `_on_combat_exited`; inspect host arbitration and `EncounterRpc` before wiring named actors. Never introduce a single-player swimming/encounter shortcut.

## Proven scope and its limits

The historical report contains detailed counts and exact smoke paths. Broadly: twelve Terrain3D islands, seven dock actions, eight camps, human swimming/drowning subpaths, five distinct swim-mount species, Skills/menu/Candy systems, streamed placeholder encounters, a dry Alpha-to-saddle path, and physical Veilfall interior/captain/Guardian/shrine subpaths exist. Evidence is composed of isolated tests with disclosed fixtures, not a continuous fourth chapter. There is no accepted blind visual frame and no target-device performance acceptance. Zero Meshy generations/meshes landed.

Existing density: 18 NPCs; 24 trainer definitions with three shared bodies; 240 wild sites; 200 pickups, including 182 harvest nodes; five resources; ten recipes. Five optional named encounters remain incomplete. Twelve main objectives fall short of the BUILD target of 28–32 plus six local chains. Consult `density-census-wave2.md` and the previous final report rather than inventing runtime coverage from data counts.

First-half intended route: Pell briefing and actual swim lesson → First Shore to Reedhaven (~82m sheltered) → repair with six reed/four drift → Brine Steps (~107m) → Tovin trial → Shellwatch (~93m) → Solm resident release and Irva pump action → Tidal Court (~112m) → Alpha → Stone → Iona → saddle with eight reed/six drift/four reef. First mounted crossing to Salt Crown is ~462m along its authored route. Minimum relevant raw materials are fourteen reed, ten drift and four reef before optional supplies. These lengths are route-data observations, not successful whole-route traversal evidence.

## Testing and environment

Godot: `D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe`.

For tests, set `$env:APPDATA='D:\WaterTestAppData'` and write logs to D:. C: previously ran out of space and exposed the partial-save bug. Example, when development is resumed:

```powershell
$env:APPDATA='D:\WaterTestAppData'
& 'D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path 'D:\Tetherbound-Water' --log-file 'D:\water-resume-check.log' --script res://tests/run_tests.gd -- --only=test_atomic_save_file
```

Serialize heavy world smokes to avoid memory pressure. Visual work uses `tools/survey.sh` and independent blind judgment against the owner boards and VISUAL_BIBLE; never combine headless mode with a rendering driver.

The last full-suite attempt was incomplete: 2,128 methods marked OK, two failures, later files not run. Failures were a Gate F Bash invocation/environment problem and a scatter fingerprint test sensitive to Windows CRLF. A subsequent Git Bash retry hit fork/cygheap resource failure. Do not repeat an identical retry a third time; inspect the environment/new evidence. See `D:\water-final-full-suite-D.log` and the previous report. Old CI run 34079878893 passed enabled code jobs on an older pre-rebase commit; it is not current-head acceptance.

## Next five bounded tasks, in order

1. Review the preserved save changes and tests; incorporate latest main PR77 safely on the isolated branch and run the required shared-state regression wave. Keep owner merge separate.
2. Build and prove physical Spark-gated Waterward reveal, consumable-key Water entry and safe return. Then run the first-half route with real stamina, dock actions and resource collection, labeling any upstream Stormwood fixture explicitly.
3. Fix late-join Stone attunement and build the real amphibious Alpha arena; prove victory/catch alternatives, personal unlocks, craft and mount through a continuous route.
4. Wire named encounters through verified host authority and finish second-half travel, combat/remount, Veilfall approach and the complete captain-to-ceremony multiplayer/save path. Prioritize the broad path over individual asset polish.
5. Finish aftermath, density gaps, shoreline/current/island presentation and independent visual acceptance; then authorized Meshy replacements, full regressions and controller/performance evidence. Advance roadmap to Stage C only after Water's actual exit bar passes.

## Canon and continuation discipline

Read CLAUDE.md, the Stage B routing docs, Stormwood execution policy, the full Water design directive, owner boards and `BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md`. Owner casting and conservative decisions remain settled: Aquaryn Alpha/premium mount; Abyssal Guardian captive legendary; Tidecoil never a mount; five explicit swim mounts; Tidal Guard 10% tunable; one active named realm relic, not another Heart; no boats as core traversal, oxygen meter, diving, underwater building, thirst or fishing minigame. Preserve multiplayer-native architecture and five-creature ownership.

The owner stopped this run. No unattended continuation is scheduled by this report. If a successor is instructed to resume, use the original 100-point scorecard and evidence-only two-hour windows, record a fresh start time, and preserve the historical failures honestly.
