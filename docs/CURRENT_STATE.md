# Current state — evidence-backed, 2026-09-02

**Status:** the live status document. Replaces `ralph/BACKLOG.md`, `ralph/STATUS.md` and
the coordinator handovers (all under `archive/ralph/`). Update it when evidence changes;
do not let it accrete layers — rewrite the section.

Every claim here was verified in this session on `main` at `cf535cce` (2026-09-02
22:05 UTC) with Godot 4.7-stable headless in a clean container, unless marked
*(reported)*.

## 1. Git truth

- `origin/main` is `cf535cce`. All five remaining remote branches
  (`claude/backlog-coordinator-setup-3y0jr4`, `claude/coordination-subagents-3fhz1x`,
  `ralph/CONSOLIDATE-0902-EVENING`, `ralph/GATE-F-S03-CATCH-LOOP`,
  `ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2`) are 0 commits ahead of `main`:
  **nothing meaningful is stranded off `main`.** They can be deleted from GitHub.
- No stashes, no worktrees, no uncommitted work at session start.
- The last two CI runs on `main` that executed code jobs were green (fdc34025, 50 min;
  d0906654, 37 min). Five of the day's earlier `main` runs concluded *failure* and were
  papered over by later docs-only pushes; see §4.
- 25 pull requests to date. PRs #20–#25 (2026-09-02) landed the visual-parity program
  and the last lanes. Before that the loop landed branches via fast-forward without PRs.

## 2. Verified system status

Method: 1728 unit tests (`tests/run_tests.gd`, 28.5 min, **0 failures**) and the
player-path smoke chain run one test at a time. Classification per the audit brief.

| System | Status | Evidence |
|---|---|---|
| Title / new game / load game | Working | `smoke_title_new_game`, `smoke_title_load_game` pass |
| Opening (wake → Grandpa → starter → first catch → exit house) | **Working but rough** | `smoke_opening` passes; `smoke_gate_a_opening_segment` **failed** on `main`: the tutorial orb floor was gated on the enemy being a Bramblebun, and the real interact press engaged a Mudsnout, so a player who throws their last orb before the first catch dead-ends. Fixed this session in `scripts/story/sequence_director.gd` (gate on the opening beat, not species); re-run pending at time of writing |
| Menus, modal stacking, post-modal control | Working | `smoke_post_modal_control`, `smoke_modal_stacking`, `smoke_menu` pass; the input-owner group contract is the mechanism (`scripts/ui/input_owner.gd`) |
| Building (house, camp split into tent/campfire/bedroll) | Working | `smoke_gate_a_build_house` passes; camp split verified by real placement probe on 2026-09-02 *(reported)* |
| Rest (creature bed, player bedroll, torch) | Working | `smoke_gate_a_rest_torch` passes; rest-progress indicator landed `c98998fa` |
| Catching (aim, throw, slow-mo on target) | Working | `smoke_catching`, `smoke_party_count_after_catches` pass |
| Combat (real-time piloted) | Working | `smoke_combat` passes; `test_combat_*` green |
| Tournament | Working | `smoke_tournament_bracket` passes: enter, lose, retry, three rounds fought, win (194 s) |
| Village, NPC dialogue, trade | Working | `smoke_gate_b_continuous` reaches "visited the village and came away with tools" |
| Objective chain after tournament readiness | **Broken (harness-confirmed)** | `smoke_gate_b_continuous` fails: with `tournament_team_ready` and `tournament_training_ready` set, the tracked objective still reads "Gather supplies for your team's camp." instead of advancing to the "Gather wood" beat |
| Gather route navigation | **Working but rough** | same smoke: the controller could not reach authored wood at (16, −28), stopped 23 m short. Walker or authoring issue; the harness walker is known to fail on village walls |
| Traversal / South Bridge | **Sound; the entombment was the harness, not the crossing** | Re-opened and then explained on 2026-09-03. `smoke_traversal`'s new site guard (`_assert_south_bridge_site_sound`) was intermittent — 1 failure in 3 locally, 3 in 3 on CI — and once it printed coordinates the red run resolved to a body resting at (7.90, −3.60, 1319.0) against a `ground_height_at` of −2.90: sunk 0.7 m INTO the ground it was placed a metre above, which is why all eight compass probes were correctly sealed. The cause is the teleport. `playground_world.gd` runs Terrain3D in Dynamic/Game, so collision shapes exist only in a radius around the camera; the guard drops the body 1.3 km from the previous check and the camera rig follows the player rather than snapping to it, so for the frames while it catches up there is no terrain under the site and the body falls through before the shapes arrive around it. Slower hardware loses that race every time. No player reaches that state on the real path — they walk to the bridge and the collision radius travels with them — so the guard now holds the body at the placement until a downward `test_move` finds ground, then settles and asks the original question. 4 of 4 runs green after, 2 of 3 before. The crossing's geometry was never changed and never needed to be |
| Burrow Warrens | Working | `smoke_warrens` passes (379 s) |
| Tether Relay (captain, captive, Gear, village follow-up) | Working | `smoke_relay` passes (402 s) |
| Stronghold and Gate E finale (Warden, legendary, ceremony) | Working (scripted) | `smoke_stronghold` (404 s) and `smoke_gate_e_finale` (486 s) pass; never played as a continuous chapter (Gate F S04–S10 unverified) |
| World stand-up, riding, settings | Working | `smoke_playground` (334 s), `smoke_riding` (336 s), `smoke_settings` (358 s) pass |

Smoke chain total: 22 run, 20 pass, 2 fail (`gate_a_opening_segment` on `main`, fixed on
this branch and re-run green; `gate_b_continuous`, open).

Smoke isolation finding: `smoke_title_new_game` fails whenever an earlier smoke has left a
real `user://saves/slot_0.json`, because the title then shows the returning-player
confirmation and the test never answers it. It passed on a clean profile and again once
the other smokes' saves were moved aside. Smokes that write real saves should use their
own `user://` subdirectory (most already do) or the title smoke should answer the prompt.
| Save / load | Working | `test_save_format`, `smoke_save_persistence`, `test_autosave_fallback` green |
| Day/night | Working in engine | three real-frame probes pass *(reported 2026-09-02)*; owner reported it stuck on hardware — see §3 |
| Bond milestones, level-up feedback, party cycle, riding, map | Working (unit level) | unit tests green; not exercised by this session's smokes |
| Performance on the ROG Ally | Unable to verify | no container can measure it; perf proxy: band1_open 6847 draws / 11.7M prims under provisional budget |

Content that exists: 25 species (1 evolution line with 2 branches, 1 legendary), 48
moves, 14 TMs, 56 items, 16 recipes, 11 buildables, 20 building prefabs, 131 harvest
nodes, 19 village NPCs (13 present at once), 130 conversations / 339 lines, 29 field
trainers, 283 spawn-table entries across 5 bands, 12 landmarks, 33 objectives, 3
tournament rounds, 1 boss. Full tables: `docs/WORLD_AND_CONTENT.md`.

## 3. Known issues, ranked by player impact

P0 blocks normal play. P1 major. P2 significant quality. P3 polish.

| Pri | Issue | Where | State |
|---|---|---|---|
| **P0** | **The released Windows build has no vegetation scatter at all.** The pack built 2026-09-02 22:12 contains `data/scatter/playground/manifest.json` (a `.json` is a Godot resource, so `all_resources` exported it) and **none of the 256 `region_*.bin` files** (not resources; `include_filter` was empty). `scatter_bake.gd::is_fresh()` saw the manifest and said fresh; `load_all()` failed to open every region and returned empty layers; the world built with no tree, bush or rock anywhere. This is the owner's "empty meadow in every direction" and very likely the earlier "no trees" and "grass didn't render" reports too. Every in-editor test passes because the editor tree has the files; `tools/verify_export.sh` checked the terrain bake and two JSON files were packed, not the scatter. Confirmed by downloading the release asset and reading its pack (`region_` strings: 0; `manifest.json`: 1). | `export_presets.cfg`, `scripts/world/scatter_bake.gd`, `tools/verify_export.sh` | fixed 2026-09-03: `include_filter="data/scatter/*.bin"` on both presets; `is_fresh()` now requires every region file the manifest names to exist (otherwise the live-compute path runs); `verify_export.sh` fails when the pack holds fewer region files than the manifest names or the build logs a missing region. Local `Linux Test` export after the fix packs 256 of 256 region files (the release had 0); `tools/verify_export.sh` passes on the fixed export: the exported binary reports `scattered 385191 props in 35 batches`, where the released build scattered none |
| P0 | Tutorial catch can dead-end with zero orbs if the first wild fight is not the Bramblebun | `scripts/story/sequence_director.gd` | fixed this session, pending re-run and landing |
| P0 *(owner, hardware)* | Interact works "about half the time" on the Ally | unknown; 0 misses / 439 scripted attempts in-container | needs an owner reproduction with the on-screen context; cannot be closed here |
| P0 *(owner, hardware)* | ~10 FPS with grass on | `grass_field.json` on at 75k tufts | needs an Ally measurement; perf proxy is under budget |
| P1 | Objective chain stalls on "Gather supplies for your team's camp" after tournament readiness | `scripts/world/quest_log.gd`, `data/progression/objectives.json` | open (Gate 1.x) |
| P1 | South Bridge entombment at (7.9, −3.4, 1319) | `tests/smoke_traversal.gd`, not the terrain | **closed 2026-09-03 — a measurement defect, not a world defect.** The site guard teleported the body 1.3 km ahead of Terrain3D's camera-following Dynamic/Game collision and judged it before any ground existed under it; it now waits for the ground to arrive. See the §2 row for the measurement. Reopen on any reproduction from a real walked path |
| P1 | The tutorial catch is unstable across KO/re-engage rounds | `tests/helpers/gate_a_opening_drive.gd`, `scripts/story/sequence_director.gd` | **open, found 2026-09-03 on the merged tree.** `smoke_gate_b_continuous` fails inside the opening in two different ways on two consecutive runs of the same commit: once with "catch returned to exploration with 3 party members, expected two", once with "launch 6 left the satchel empty during the tutorial catch ... catch_orb_floor did not apply". Both follow two Bramblebun knockouts and re-engagements, so the suspect is the gap between fights, where `_is_tutorial_catch()` reads `enemy() == null` and neither assist applies. `smoke_opening` and `smoke_gate_a_opening_segment` both pass, so the short path is unaffected and this is not gating CI (`verify-continuous-core-known-red` is a skipped job). Both failure messages now name the roster / the launch, so the next run says which. Not chased further this session — the PR's own red jobs came first |
| P1 *(owner)* | Player sleep "impossible" | Grandpa's loft bed and the bedroll both verified in-engine; owner played a build without the bedroll | needs owner confirmation on the current build |
| P1 *(owner)* | Day counter stuck / night reads as dusk | in-engine probes pass | needs the action that preceded it on hardware |
| P2 | ~~Bram's shop exit clips furniture~~ | `scripts/world/shop_interior.gd` | **closed (Gate 1.3), BRAM-EXIT-0903** — misfiled: Bram is the innkeeper in `scripts/world/inn_interior.gd`, a room `probe_shop_exit_clearance.gd` (Mira's cottage only) never covered. A real player driven by genuine single-direction stick input clears every furnished pocket in the inn (bar, both guest tables, bed nook, barrels, doorway — `tools/gate_f/probe_inn_exit_clearance.gd`, 6/6), and `gate_a_npc_gather_segment.gd::_exit_through`'s existing regain-door-axis shape reaches Oskar's leg from every realistic post-dialogue position. Confirmed live in `tests/smoke_gate_b_continuous.gd`: all three Bram cycles exit and resume movement in ~1s each (GATE A NPC/GATHER +53–58s), no clipping. The underlying fix (regain the door axis before departing) already existed from an earlier session; it was never verified against the real site. Closed by adding that verification, not by a code change. |
| P2 | Gather-route walker cannot reach authored wood at (16, −28) | harness walker / authoring | open (Gate 1.x) |
| P2 | MAIN STORY objective label truncates at 1280×800 | `scripts/ui/playground_hud.gd` | open (Gate 1.4) |
| P2 | Small creatures vanish into grass | creature material value, contact shadow | open (Gate 2.4) |
| P2 | Villagers read too small in dialogue | camera depth at conversation distance, not a scale bug | owner decision pending on a dialogue camera |
| P2 | `data/terrain/playground` has no freshness guard (scatter does) | tests/CI | open (Gate 1.5) |
| P2 | Harness fixed-slot inventory lookups | `tools/gate_f/`, `tests/helpers/` | open (Gate 1.6) |
| P3 | Title screen `has_save` null-call at boot (self-heals) | `autoload/game_state.gd:1101` via `title_screen.gd` | open, add a null guard |
| P3 | `prop missing: Stool` in Grandpa's house and the inn | `assets/props/quaternius_fantasy/` has no Stool | open, pick an installed prop |
| P3 | Tournament banners are flat placeholder rectangles; signpost text unreadable; one near-black world site | see `docs/VISUAL_BIBLE.md` §4 | open |
| P3 | Ralph sweep workflow failed on 2026-09-02 and is dispatch-only | `.github/workflows/ralph-sweep.yml` | pull requests are the working path |

Two questions put to the owner and not answered: whether the grass clump-card blade
redesign proceeds; whether Grandpa's loft bed was ever tried.

## 4. Process findings that changed how work is verified

- CI showed green over red or unverified code by three mechanisms in one day: a
  docs-only commit after a red one; `[skip ci]` code followed by a report push (the
  `changes` job diffed against the previous push, not `main` — **fixed this session in
  `ci.yml`**); and `RETRIES: 3` rescuing a deterministic first-attempt failure.
- Three same-day "landed" fixes from the 2026-09-01 playtest were found still broken by
  the owner the next day. "Landed" and "confirmed by play" are tracked separately.
- The owner has playtested stale release builds; check the release asset time.
- 49 % of commits in the last three days were evidence dumps; 2.8 GB of screenshots and
  telemetry were tracked. Evidence hygiene is now in `docs/AGENT_WORKFLOW.md` §8 and
  `.gitignore`.
- Six harness failures in a day were the same bug: fixed-slot inventory lookups.

## 4b. Landed on the reset branch from the 2026-09-03 lanes

Each verified here (tests re-run in this container on the merged tree) before merging
into `claude/do-this-2t7fny`, which feeds PR #26.

| Lane | What the player gets | Verified by |
|---|---|---|
| OBJECTIVE-CAMP | the gather rung retires once the camp exists, however it was built | `test_quest_log` 38/38; `smoke_gate_b_continuous` now passes the village and tournament-readiness beats (its remaining failure is the gather-route walker, GATHER-ROUTE lane) |
| WARRENS-ONCE | elders, alphas and the Warrens guardian can be fought, caught or KO'd once; persisted | `test_spawn_tables` 27/27, `test_wild_once` 13/13 |
| HARNESS-HYGIENE | terrain-bake freshness guard (`test_terrain_bake_freshness`, CI job), harness slot-offset sweep, MAIN STORY label fits at 1280×800 and 1080p | rig 49/49, instrumentation 18/18, HUD widgets 33/33; terrain guard green after the manifest was written (`0702ad4c`; 63 of 64 regions byte-identical, so the bake was not stale) |
| TOURNAMENT-FLOW | signup in one visit when ready; begin-round choice; win and next-round announcements; flat banners gone | `test_tournament` 60/60 |
| WORLD-CONTENT | two Band 1 field trainers (the shepherd on the Rise, the wanderer at the trail camp), 8 harvest nodes, Pond fisher and camp prop, bridge fence line, Rise TM cache | `test_trainers_data` 50/50, `test_harvest` 22/22, `test_band_dialogue` 3/3, `test_band_content` 6/6, `test_chapter_content_map` 4/4 |
| HUD-INPUT | health stacked above food at the lower left; a direct pad and key shortcut to Build beside Map in the always-visible legend | `test_hud_widgets` 34/34, `test_world_verb_input_owner_enforcement` 4/4; frame at 1280×800 read by eye (`ralph/reports/HUD-INPUT-0903/_sheet_hud.png`); `smoke_menu`, `smoke_post_modal_control`, `smoke_build_wins_while_hammer_is_out` pass on the merged tree |
| OPENING-BED | a person visibly lies in Grandpa's loft bed at the wake beat instead of a floating backpack (the skin collapsed on a bad X rotation) | frame read by eye (`ralph/reports/OPENING-BED-0903/_sheet_bed.png`); `smoke_opening` passes on the merged tree |
| SOUTH-BRIDGE-HOLE | no player-facing change, and now with a cause rather than a shrug: the entombment is the site guard's own teleport outrunning Terrain3D's Dynamic/Game collision radius, not the crossing. The guard waits for the ground before judging it | 4/4 green after the wait, 2/3 before; the red run's coordinates are in the §2 row. **Closed as a harness defect** — reopen on any reproduction from a walked path rather than a placement |
| BRAM-EXIT | no code change: the item was misfiled. Bram is the innkeeper (`inn_interior.gd`), not the shop (`shop_interior.gd`, which is Mira's), and the existing door-axis exit fix already covers his room; it had simply never been probed there | new `tools/gate_f/probe_inn_exit_clearance.gd` clears the doorway from 6 of 6 furnished pockets; all three Bram cycles in `smoke_gate_b_continuous` exit cleanly |
| WORLD-RULES | gathered harvest nodes stay gone permanently (a progression flag per node, restored on load); the three starters are removed from every band trainer roster and replaced with same-type non-starters. D72 records both | verification in progress at time of writing; the lane reported one unnamed failing smoke and was asked for it |

## 5. Gate status

- **Gate 0 (reset):** this session; see `docs/CLEANUP_MANIFEST.md`.
- **Gate 1 (first session):** open. Green: title, opening, menus, build, rest, catch,
  combat, tournament, village. Red: opening orb floor (fix pending landing), objective
  chain after tournament readiness, gather route, South Bridge traversal on first attempt.
- **Gate 2 (core world complete):** not started. Fresh survey frames and the blind
  critique are in `docs/VISUAL_BIBLE.md` §4.
- **Gate 3 / 4:** not started. Gate F S03 reached 6 failures outside its lane's scope;
  S04–S10 unverified as a chain.
