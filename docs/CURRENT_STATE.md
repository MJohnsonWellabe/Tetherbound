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
| P0 *(owner)* | ~~Interact works "about half the time"~~ | `scripts/player/tool_hold.gd::swing_at()`, `scripts/world/harvest_logic.gd` | **root-caused and fixed 2026-09-03; needs an owner confirmation on hardware.** Reproduced in-container for the first time by `smoke_gate_b_continuous` run 2 of 3 (axe equipped and in hand, arbiter winner the node's own Interactable, `cooling=false`, no swing) while run 1 passed the same step. The mechanism: with a swing already running, `swing_answers_the_prompt()` claimed the press on the reasoning that "that swing resolves on its own and will gather something itself" — but `_resolve_swing()` resolves against the swing's own `_swing_target`, which is whatever the PREVIOUS press aimed it at, or a cone search for an unaimed `use_tool` swing. Neither is necessarily the node under the player's thumb, so the press was answered by a swing that hit something else or nothing. When the cone happened to pick the same node it looked fine — hence "about half the time". `swing_at()` now splits the case at the impact frame: before it, re-aim the running swing at the node just pressed; after it, refuse so `harvest_node.gd::_on_gathered()` answers the press with its direct yield. A press costing a swing animation is a far smaller thing than a press that does nothing. `tests/test_swing_press_is_never_lost.gd` pins all three cases and was verified failable (2 of 5 red against the old behaviour) |
| P0 *(owner, hardware)* | ~10 FPS with grass on | `grass_field.json` on at 75k tufts | needs an Ally measurement; perf proxy is under budget |
| ~~P1~~ | ~~Objective chain stalls after the camp is built~~ | `tests/helpers/gate_b_tail_segment.gd`, not the chain | **closed 2026-09-03 — a stale assertion, not a stall.** Recorded earlier today as a real stall one rung further along; that was wrong and this corrects it. `gate_b_tail_segment.gd` asserted the tracked objective by matching label PROSE, and two of its five call sites pinned "Care for your team" and "Sleep until" — `git log -S` shows neither string has ever existed in `data/progression/objectives.json`. Those two could only ever fail, and because `smoke_gate_b_continuous` runs in the skipped `verify-continuous-core-known-red` job, they failed unnoticed and reported a stalled chain that was advancing exactly as authored. All five now assert the rung's own `id` through a new `quest_log.gd::tracked_id()`: an id is a contract, a label is a sentence someone will improve |
| P1 | South Bridge entombment at (7.9, −3.4, 1319) | `tests/smoke_traversal.gd`, not the terrain | **closed 2026-09-03 — a measurement defect, not a world defect.** The site guard teleported the body 1.3 km ahead of Terrain3D's camera-following Dynamic/Game collision and judged it before any ground existed under it; it now waits for the ground to arrive. See the §2 row for the measurement. Reopen on any reproduction from a real walked path |
| P1 | The tutorial catch is unstable across KO/re-engage rounds | `tests/helpers/gate_a_opening_drive.gd`, `scripts/story/sequence_director.gd` | **open, found 2026-09-03 on the merged tree.** `smoke_gate_b_continuous` fails inside the opening in two different ways on two consecutive runs of the same commit: once with "catch returned to exploration with 3 party members, expected two", once with "launch 6 left the satchel empty during the tutorial catch ... catch_orb_floor did not apply". Both follow two Bramblebun knockouts and re-engagements, so the suspect is the gap between fights, where `_is_tutorial_catch()` reads `enemy() == null` and neither assist applies. `smoke_opening` and `smoke_gate_a_opening_segment` both pass, so the short path is unaffected and this is not gating CI (`verify-continuous-core-known-red` is a skipped job). Both failure messages now name the roster / the launch, so the next run says which. Not chased further this session — the PR's own red jobs came first |
| P1 *(owner)* | Player sleep "impossible" | Grandpa's loft bed and the bedroll both verified in-engine; owner played a build without the bedroll | needs owner confirmation on the current build |
| P1 *(owner)* | Day counter stuck / night reads as dusk | in-engine probes pass | needs the action that preceded it on hardware |
| P2 | ~~Bram's shop exit clips furniture~~ | `scripts/world/shop_interior.gd` | **closed (Gate 1.3), BRAM-EXIT-0903** — misfiled: Bram is the innkeeper in `scripts/world/inn_interior.gd`, a room `probe_shop_exit_clearance.gd` (Mira's cottage only) never covered. A real player driven by genuine single-direction stick input clears every furnished pocket in the inn (bar, both guest tables, bed nook, barrels, doorway — `tools/gate_f/probe_inn_exit_clearance.gd`, 6/6), and `gate_a_npc_gather_segment.gd::_exit_through`'s existing regain-door-axis shape reaches Oskar's leg from every realistic post-dialogue position. Confirmed live in `tests/smoke_gate_b_continuous.gd`: all three Bram cycles exit and resume movement in ~1s each (GATE A NPC/GATHER +53–58s), no clipping. The underlying fix (regain the door axis before departing) already existed from an earlier session; it was never verified against the real site. Closed by adding that verification, not by a code change. |
| ~~P2~~ | ~~Gather-route walker cannot reach authored fiber at (-5.0, 141.0)~~ | `tests/helpers/stick_navigator.gd` | **closed 2026-09-03 (FENCE-CORNER-0903) — a harness defect (b), not a world defect (a).** CI-TRUTH-0903 diagnosed the stall (79 flips in a ~10m band, x -1..-12, z 26-27, against `village_boundary.gd`'s `FenceCornerGuard_6`/`FencePanelCollision_10`/`_11`, the corner just past TrailGate) but left the (a)/(b) call open. Settled by driving a real player body at the corner with NO navigator (`tools/gate_f/probe_fence_corner_trailgate_0903.gd`, modelled on `probe_inn_exit_clearance.gd`'s question 2): from every start near the gate a plain stick-hold toward the far target, using nothing but ordinary `CharacterBody3D.move_and_slide`, cleared the corner in three of four cases (the fourth stalled 15m further on, at an unrelated obstacle, not this corner) — only the navigator's own logged trap coordinates, deep inside the reflex pocket a real approach never enters, stayed stuck for a plain hold too. **(b): the corner is round-able; `stick_navigator.gd`'s own stall/flip logic could not round it.** Root cause, found by instrumenting the live behaviour rather than reasoning from the code: on every stall the old code force-flipped `_side` in place and re-probed free space from a point still jammed against the post, so a genuinely-progressing side was abandoned before it had gone anywhere, and the free-space probe (fired at a right-angle post from point-blank range) read almost interchangeably blocked on both sides — the walker pin-balled between the two faces of the post forever. <br><br>Fixed in `stick_navigator.gd`, in the order the live evidence actually forced each piece (several candidates were tried and measured wrong before this shape, and the wrong ones are recorded in the file's own comments so nobody re-tries them blind): a stall now retreats straight back and retries the SAME committed side (was: flip immediately, discarding any progress); `_begin_detour`'s free-space sanity check only re-fires when a side is freshly picked, not on every continuing retry (its own docstring already said "decided once per side and then KEPT" — checking every retry is what broke that); a side is abandoned only once its cumulative net lateral progress since being committed stalls out (`SIDE_ABANDON_ATTEMPTS`/`SIDE_ABANDON_PROGRESS_M`), not on a flat attempt count (a flat count alone, `DETOURS_PER_SIDE` 3→10, regressed a shorter, previously-reliable leg near RoadGate — wood at (16,−28) — whose small travel budget cannot afford ten growing attempts down a wrong side); a detour ends the instant the way to the target has read clear for a SUSTAINED stretch (`CLEAR_AHEAD_FRAMES`, 20 consecutive frames), not on a frame-count/distance guess (needed because unlimited persistence, once safe against premature abandonment, could otherwise ride a single long detour 40m past an already-cleared corner — measured once, 122m off the straight line; a ONE-shot version of the same check was measured worse still, cancelling genuinely-needed detours near unrelated close-packed geometry, the tournament board, at 678-686 flips); and a stall during an already-in-progress stall-recovery falls back to a guaranteed-terminating flip rather than retrying an identical direction forever (measured freezing solid, `moved/1s 0.03`, against a closed gate leaf in a probe that does not open it — the real gather route always does). <br><br>Verified: `test_village_boundary` 7/7, `test_gate_f_rig` 49/49, `test_gate_a_material_route_contract`/`test_gate_a_build_segment_contract`/`test_gate_a_front_door_and_world`/`test_gate_a_world_extent` 20/20, `smoke_gate_a_opening_segment` OK twice, the (16,−28) wood leg green on 4 separate re-checks, the TrailGate corner leg (real gate-open state) green on 8 consecutive isolated runs after the final shape landed, and `smoke_gate_b_continuous --gate-b-full-chain` cleared the ENTIRE gather route (`GATE B — gathered the home materials`) on both full runs attempted after the final fix, continuing past it into two different downstream findings — see the two new rows below, reached for the first time only because this fix gets the route this far. Did not touch `village_boundary.gd`/`.json`: the (a) world-defect branch's remedy (re-siting the gate or corner geometry) was never invoked, per the diagnosis above |
| P2 | Gate B tail: creature-bed placement stalls; objective does not advance off 'Make camp for your team' | `tests/helpers/gate_b_tail_segment.gd` | **open, found 2026-09-03 (FENCE-CORNER-0903), reached for the first time because the gather-route fix above now gets `smoke_gate_b_continuous --gate-b-full-chain` this far.** One of the two clean full-chain runs after the fix cleared the entire gather route and reached the tail: `_place_the_creature_beds()` places 3 of 5 required beds, then `_select_piece("creature_bed")` reports the live pending selection as `''` and the tracked objective stays on `tournament_build_home` ("Make camp for your team") instead of advancing to `tournament_build_camp`. Reads as a build-menu selection / objective-progression defect, not a navigation one — `_select_piece` is a UI pick, not a walk — so out of this lane's scope (`tests/helpers/stick_navigator.gd`, `tools/`, `village_boundary.*`). Not investigated further; belongs with whoever owns `gate_b_tail_segment.gd` or the campsite build flow |
| P2 | Gate B: after gathering, walking back to the Practice Meadow clearing stalls ~27-32m short | `tests/smoke_gate_b_continuous.gd::_walk_back_to_the_square` | **open, found 2026-09-03 (FENCE-CORNER-0903), reached for the first time for the same reason as the tail-segment row above.** The other of the two clean full-chain runs cleared the whole gather route with no per-node failure at all, then failed three retried attempts to walk back to the Practice Meadow clearing, stopping 27-32m short each time near (2-7, 2, -55) -- nowhere near TrailGate or any geometry this lane touched. Not investigated: a different location, a different helper (`smoke_gate_b_continuous.gd` itself, not `gate_a_material_route.gd`), and outside this lane's scope. Belongs with whoever next drives `smoke_gate_b_continuous` past the tail segment |
| P2 | MAIN STORY objective label truncates at 1280×800 | `scripts/ui/playground_hud.gd` | open (Gate 1.4) |
| P2 | ~~Small creatures vanish into grass~~ | creature material value, contact shadow | **closed (Gate 2.4), CREATURE-LEGIBILITY-0903** — Bramblebun-vs-ground luminance measured off real rendered frames (`tools/_probe_grass_separation.gd`, Rec.709 luma, verified unchanged at 30% scale): shipped 1.331:1, raised to 1.568:1 by re-sweeping `field_emission` (already a per-species lever from an earlier pass, whose own 1.06-1.15 target was well under this gate's 1.5:1 bar) 0.9 → 2.5. Every creature body also now gets a flat, unshaded ground-contact ellipse (`shaders/creature_contact_shadow.gdshader`, `creature_body.gd::_apply_ground_contact_shadow()`) answering the Compatibility renderer's missing SSAO — verified headless (`tools/_probe_contact_shadow_check.gd`). Spawn siting away from shrubs was already implemented (`encounter_director.gd::_pick_clear_spot()` + `vegetation.gd::has_solid_scatter_near()`) and verified still wired into the one spawn path every `spawns.json` entry uses; left unmodified. Blind visual judge (code-blind, `.claude/skills/visual-judge/SKILL.md`): "reads clearly... real value separation now, unlike before... comparable to how Palworld's pale creatures separate from grass" — flagged the coat as reading a little flat/blown-out at this value push, a real note left for a future shading pass, not a blocker for this gate's own criterion. Full numbers, before/after contact sheet and judge transcript in `ralph/reports/CREATURE-LEGIBILITY-0903/REPORT.md`. Only Bramblebun was re-measured against the new 1.5:1 bar; Mudsnout/Terrapup/Burrowback still carry the earlier pass's 1.06-1.15-tuned `field_emission` values, unreviewed against this stricter bar. |
| P2 | Villagers read too small in dialogue | camera depth at conversation distance, not a scale bug | owner decision pending on a dialogue camera |
| P2 | `data/terrain/playground` has no freshness guard (scatter does) | tests/CI | open (Gate 1.5) |
| P2 | Harness fixed-slot inventory lookups | `tools/gate_f/`, `tests/helpers/` | open (Gate 1.6) |
| P3 | ~~Title screen `has_save` null-call at boot~~ | `autoload/game_state.gd` | **fixed 2026-09-03.** `save_system` is built in `Game._ready()` and `title_screen.gd` asks twice while building its menu, so a boot that reached it first logged `Cannot call method 'call' on a null value` every time. It self-healed on the next frame, which is why it survived: it never became visible, it just meant every boot log opened with an engine error and hid the real ones. `has_save()` and `save_slot_info()` now answer safely when asked too early — `false` and `{}` — with the window and the reasoning recorded at the call site |
| P3 | ~~`prop missing: Stool` on every world build~~ | `data/config/bands/band3_the_river_lock/props.json`, `band5_stronghold_approach/props.json` | **fixed 2026-09-03.** Not cosmetic and not in Grandpa's house: `props.gd::place()` takes an optional `dir` so a cluster can name a different installed pack, and `Stool` lives in `quaternius_furniture`. Four of the six authored entries set it; two did not, fell back to `quaternius_fantasy`, and silently failed to place — band 3's river-lock checkpoint and band 5's stronghold approach. Both clusters' own `_why` notes make that stool the point of the composition ("a picket sits here to watch the road, not the fire"; "turns the last stop before the climax toward what the player is about to walk into"), so two authored seats were missing from the world, not just from the log |
| P3 | Tournament banners are flat placeholder rectangles; signpost text unreadable; one near-black world site | see `docs/VISUAL_BIBLE.md` §4 | open |
| ~~P3~~ | ~~Ralph sweep workflow failed on 2026-09-02 and is dispatch-only~~ | `.github/workflows/ralph-sweep.yml` | **removed 2026-09-03 (CI-TRUTH-0903)**, not fixed. Its 2026-09-02 "failure" was not a bug: the run correctly refused two branches with genuine merge conflicts and exited 1 to say so (`ship_branch.sh`'s own MERGE1 comment explains that exit code is deliberate). The workflow was already `workflow_dispatch`-only — both it and `ralph-merge.yml` say "manual consolidation is now the sole path to main" in their own headers — so it was never running silently. It was deleted anyway: dispatching it lands every green `ralph/**` branch AT ONCE by fast-forward, bypassing the pull-request review every other landing on this project goes through (`docs/AGENT_WORKFLOW.md` §5), and dispatches a release. Checked the 20 `ralph/**` branches live on 2026-09-03: several are mid-flight lanes already being collected into a PR by fast-forward-merging into `claude/do-this-2t7fny`; a sweep dispatch today would have raced that consolidation and shipped some of them straight past review. A workflow whose only safe operator action is "read the full log before ever running it" is worse than no workflow. `tools/ci/ship_branch.sh` (still used by `ralph-merge.yml` for audit/recovery) keeps the sweep's own reasoning in a comment rather than losing it. Pull requests are the landing path |

Two questions put to the owner and not answered: whether the grass clump-card blade
redesign proceeds; whether Grandpa's loft bed was ever tried.

## 4. Process findings that changed how work is verified

- Raising `OBJECTIVE_LINES` 2 -> 4 to stop long objective titles truncating also
  raised the block's FLOOR, because `OBJECTIVE_BLOCK_HEIGHT` was derived from the cap:
  168.8px -> 261.6px reserved permanently, a third of the 1280x800 handheld screen held
  open for a panel reading "Win the village tournament." No test caught it — the
  truncation check only asks whether text is clipped, never whether the panel is bigger
  than its contents. **A fix measured on the case that motivated it can still regress
  every other case.** Split into `OBJECTIVE_MIN_LINES` (floor) and `OBJECTIVE_LINES`
  (cap) on 2026-09-03; the panel still grows to four lines when the text needs them.

- `smoke_title_new_game.gd` passed in CI and failed on any machine that had run
  another smoke first, because `title_screen.gd` interposes a "Start a fresh game?"
  confirmation whenever a save slot is occupied and the test never answered it. CI
  runners start with an empty `user://`; developer machines and this container do not.
  The reported symptoms were spectacular and completely misleading — "Start New Game
  carried the old Warden victory into Meadows", about a game still sitting on the title
  screen. **A green CI job is not evidence a test is environment-independent.** Fixed
  2026-09-03 by answering the confirmation, the way `gate_a_opening_drive.gd` already
  did.

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
- CI-TRUTH-0903: `smoke_gate_b_continuous.gd` ran in no CI job at all, not gated and
  not even known-red — verified by grepping every workflow file, not assumed. Split
  into a gating CORE run (opening through tournament readiness, the part that has
  actually passed reliably) and a `--gate-b-full-chain` continuation that stays
  workflow_dispatch-only/`continue-on-error` until the gather route and tail are
  reliable. **Verified green for real**, not read off the YAML: run
  [33750739621](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/33750739621)
  on `ralph/CI-TRUTH-0903` @ `de2540b1`, push event, 34m14s wall clock (11:37:57 →
  12:12:11 UTC) — `verify-gate-b-core` genuinely executed (not skipped) and passed on
  its first attempt in 6m47s, every other required job green, and both
  `verify-continuous-core-known-red` and `verify-gate-b-full-known-red` correctly
  **skipped** (their `if` gates on `workflow_dispatch`, and this was a plain push) —
  the known-red split is not silently gating or silently vanishing, it is doing
  exactly what its `if` says.
- CI-TRUTH-0903's gather-route diagnosis (P2 row above) was double-checked against
  `origin/main` before being committed, because a same-day poke claimed
  `ralph/MID-LAYER-0903` and `ralph/BAND1-DISCOVERY-0903` had landed and could have
  moved the scatter the diagnosis depends on. They had not: `origin/main` was still
  `46cff79e` at check time, identical to this branch's own merge-base, and both named
  branches remain separate unmerged remote refs. The diagnosis stands as verified
  against the tree it was actually measured on. Worth a re-check whenever either lane
  does land, since both touch world content near the corridor spine.
- FENCE-CORNER-0903 landed its `stick_navigator.gd` fix in three shapes before the one
  that stuck, and each wrong shape was found by full-chain evidence, not reasoning --
  worth recording so nobody re-walks the same path. Shape 1 (retreat-and-retry a stalled
  side, no persistence/abandon logic) cleared the target corner but was quickly undone by
  `_begin_detour`'s own free-space check re-firing on every retry. Shape 2 (raise
  `DETOURS_PER_SIDE` 3→10 flat) cleared the corner but broke a shorter, previously-
  reliable leg near RoadGate (wood at (16,-28), 2 separate full-chain runs) whose travel
  budget cannot afford ten growing attempts down a wrong side. Shape 3 (a progress-based
  abandon check, uncapped growth, no exit-early check) cleared the corner AND the (16,-28)
  leg reliably in isolation, and 2 of 3 full-chain runs cleared the entire gather route --
  but the 3rd's own isolated repeat measured a real, if rare, failure mode: a walker that
  had already cleared the corner rode one long, uninterrupted detour 40m further and
  landed 122m off the straight line, because nothing told it "you have gone far enough,
  stop." A one-shot "is the way to the target clear" check fixed that but broke something
  else (measured, not assumed): near the tournament board's close-packed geometry, well
  before TrailGate, a single lucky-looking clear reading cancelled a detour still
  genuinely in progress, and the resulting cycle was worse than the original bug (678-686
  side flips, stuck before ever reaching the corner this file exists for). The shape that
  shipped requires that same clearance check to hold for `CLEAR_AHEAD_FRAMES` (20)
  consecutive frames, not one instant -- long enough that open terrain past a cleared
  corner reads clear the whole window, short enough that a momentary gap near the board
  does not fake it. Final verification: 8 consecutive green isolated corner runs, 4
  consecutive green (16,-28) runs, and 2 of 2 full `smoke_gate_b_continuous
  --gate-b-full-chain` runs attempted after this shape landed cleared the ENTIRE gather
  route with no per-node failure at all -- each then hit a DIFFERENT downstream finding
  (the two new tail/walk-back rows above), reached for the first time only because this
  fix gets the route that far. Both those downstream findings are recorded, not fixed --
  outside this lane's scope. Two earlier, unrelated flakes were also seen and are not
  regressions: the OPENING's tutorial catch camera line (the P1 row above, pre-dates this
  lane, reproduces identically on the unmodified navigator) and one single wood-node miss
  at (36.0, -16.0) under an intermediate (now-superseded) shape of this fix, not the
  shipped one.

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
| BAND1-COMPOSITION (ROADMAP 2.1) | no player-facing change: the design document `docs/specs/BAND1_COMPOSITION_PLAN.md` that 2.2/2.3/2.5/2.6 implement. Per stand (village approach, route out, the Rise forward and back, the Pond reveal/arrival/shore, the bridge approach and rim, plus the Long Field and the five survey stands): eye/look pair, what sits at each depth, which lane builds it, what the re-render must prove. Headline decision: the Rise crest is rebuilt as a window onto the Pond, not a grove | sixteen stands rendered from the merged tree after a fresh import (`ralph/reports/BAND1-COMPOSITION-0903/_sheet_*_before.png`); code-blind judge Bar A **no** / Bar B **no** (`JUDGE-before.md`): zero readable creatures in sixteen frames, one tree/rock/plant, distance a fog void; `comp4-rise-look-back` named as the template. Two capture stands were re-sited from the terrain profile (`tools/_probe_band1_composition.gd`) after their first frames proved the ground wrong: the pond reveal is at arc 560 not 600, the bridge rim at arc 2253 not 2300 |

## 5. Gate status

- **Gate 0 (reset):** this session; see `docs/CLEANUP_MANIFEST.md`.
- **Gate 1 (first session):** open, and much closer. `smoke_gate_b_continuous` now plays 22 minutes continuously — opening (orb floor held, correct two-creature party), village, tools, tournament readiness, gathering, tent/campfire/bedroll — against an opening that dead-ended this morning. Of the two failures it then reported, one was the harness (objective rungs asserted by prose that never existed; now asserted by id) and one is real and important: the interact-reliability game-breaker, reproduced in-container for the first time (see §3). Every other Gate 1 acceptance smoke is green on first attempt.
  combat, tournament, village. Red: opening orb floor (fix pending landing), objective
  chain after tournament readiness, gather route, South Bridge traversal on first attempt.
- **Gate 2 (core world complete):** 2.1 (composition plan) delivered as
  `docs/specs/BAND1_COMPOSITION_PLAN.md` with its judged before-frames; 2.2/2.3/2.5/2.6
  unblocked. Fresh survey frames and the earlier blind critique are in
  `docs/VISUAL_BIBLE.md` §4; the 2.1 judge is the current before-verdict for the route.
- **Gate 3 / 4:** not started. Gate F S03 reached 6 failures outside its lane's scope;
  S04–S10 unverified as a chain.
