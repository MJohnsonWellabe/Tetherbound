# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Resume here

**Resume:** 2026-09-25..27 lanes wound down (owner, 2026-09-27 22:30), pushing all WIP. Batch 67 consolidated every branch, Codex/Vess included, on `tb/integration`; landed via one PR/unit/CI run. Phase 1: self-landing biome lanes (`CLAUDE_START_HERE.md`). Verify batch 67 on main (`git merge-base --is-ancestor <sha> origin/main`); otherwise land it.

**Stale-for-acceptance warning (coordinator, 2026-09-29 12:58Z):** main's combat timings changed after this lane's captures (#448/#450: player windup/recovery/cooldown x0.85, charged arc +15 degrees, strike re-aim up to 45 degrees for charged, enemy attack cooldown 0.9 s, back-off 0.5 s, enemy baseline recovery 0.75 s). Every C2 number and judge capture this lane took on the older timings (Meadows C2 for terrapup and galewisp, the F10#6 r7 explore frames, the F14#1 Nerissa rounds) must be re-taken on the merged main before it counts toward a criterion; the Tess F14#0 C3 round was also judged before #448 and its framing has not been re-checked on the new timings (the coordinator did not list it; flagged here, not decided). Nothing in this lane's STATE lines should be read as acceptance evidence on current main. The owner asked this lane to wrap up before the coordinator's request to open one PR and continue; that PR is not opened.

**Serial closer lane WRAPPED UP at the owner's request (2026-09-29 ~12:00Z); nothing is running under this lane and its scheduled check-ins are deleted.** Everything is pushed on `tb/closer`; #444 (F14#0 Tess) and #447 (Nerissa evidence, `--stand=south` flag) are merged, the rest of this branch is evidence and STATE only and has no open PR (a docs-only PR is the next landing step; open it with the template, not full-ci). **In flight, unharvested:** Meadows C2 batch 3 for `stronghold_elite` and `warden_aldis` at 12 seeds (render.yml runs 36560328967 terrapup, 36560332306 galewisp, dispatched 11:12Z, about 2 h each; artifacts keep 7 days: extract `MEADOWS_C2C3` lines from `run.log` into `ralph/reports/CLOSER/meadows_c2/*_b3.txt`, then write the seven-fight x two-starter table; batches 1-2 and warrens are already in that folder, all PASS, reader wins 1.00). **Prepared, not run** (each folder's file has the exact commands): F04#6 `ralph/reports/CLOSER/f04_6/BAR.md`; F04#2/#7 `f04_2_7/BAR.md` (12 captures, captains first); F10#6 named-fight frames `f10_6_fight/PLAN.md` with the script copied to `tools/capture_named_fights_f10_6.gd`. **Still open, single next step each:** F04#1/#2/#6/#7 render and judge from those BARs; F10#6 capture the two named fights, rebuild the sheet, judge twice, strict re-check; F14#1 not attempted again (two rounds used, residue in `f14_1_nerissa/BAR.md`); cards M2 (needs the coordinator's approval of a test-only heal-and-retry aid), M3 (waits on F04 and F10#6 and Phase 2 Bars A/B), T2, S2 unchanged. **Not done:** the piloting check on Tess's Mirejaw 70 degree yaw (no pad in this lane). Combat numbers were not changed.

**Serial closer lane outcomes (one line each).** Item 1 (spacing): landed via #442; the harness strike-gate regression was fixed there. Item 3, F14#0 (Tess): **passed** on the strict re-check (one render, code change: Tess's Mirejaw `camera_composition_yaw_deg` 70 and `camera_trainer_beside_ally`, presentation only, `tests/test_combat_spaced_camera.gd`). F14#1 (Nerissa): round 1 FAILED by 0.7 points on the ordinary-side placement (judge A 89.3%, judge B 92.5%, markings 12/12; `ralph/reports/CLOSER/f14_1_nerissa/`); the old shortcut placement stands the player on the crystal side, which is where the crate frames came from, so the crates do not occur on the ordinary route. Attempt 2 (Nerissa's Cannonback yaw 20) FAILED: judge B 80.0%, and the yaw is reverted; two attempts are used, F14#1 stays open. Recurring residue (`ralph/reports/CLOSER/f14_1_nerissa/BAR.md`): Cannonback's opening crop and head cover, Riverdrake's head under the enemy panel, Riptusk rear-on under the ability panel, the trainer over a head near the opening. Judge variance is large (92.5% then 80.0%). Items 4 and 5 not started. South Bridge guardian fix: **proof 3 of 3 met on current main** (runs 2 and 3 on main 81d34e67, `smoke_four_biome_continuous --world-seed=15 --reload-at-transitions --through-bridge`, both exit 0 with no failures: run 2 two wins, 30 hits, key spent, crossed depth -11.55 to 9.41; run 3 two wins, 29 hits, crossed -11.56 to 9.43; `ralph/reports/CLOSER/bridge_proof/`; run 3's log also shows one non-failing 'CONTENT WALK FAILURE' line in a stage that still passed). One world seed (15) only; F04#2 and #7 criteria are not marked by this. F10#6 (Stormwood handheld HUD): **NOT met; r7 judged on the six explore frames only, twice** (`ralph/reports/STORMWOOD/f10_6/r7/JUDGE_A.md`, `JUDGE_B.md`; sheet built as recorded, 586x330 x3 columns). The two judges CONTRADICT on device Q1: A says NO (clock faint, FOOD label tan on tan, Map/Satchel/Build labels and glyphs tiny), B says yes for what is visible (objective card, bars and Map/Satchel/Build read; clock marginal, FOOD dim, five move glyphs indistinguishable); recorded as a contradiction, not chased. Q2 (tells and ring), Q3 (piloted creature and opponent) and Q4 (fight action) are NOT JUDGEABLE: the r7 named-fight captures (`--ids=hollows_alpha,crown_guardian`, about 30 min on llvmpipe) were never taken, and no r7 strike frames exist. Trainer legible in 4 of 6 frames, hard to find in forest_break (dark on dark) per both judges. Both judges also reported that the Bar A reference files named in the prompt were missing, so Bar A is unjudged. **Correction:** the files exist in the repo (`docs/reference/tetherbound-meadows-keyart.png` and the two stormwood boards) but a partial clone (`blob:limit=1048576`) skipped every file over 1 MB and marked them skip-worktree, so a container shows only the README. Restore in any fresh container with `git ls-files -v docs/reference | grep '^S' | cut -c3- | xargs git update-index --no-skip-worktree` then `git checkout -- docs/reference`; the judges saw the images this session only after that. Next: capture the two named fights for r7 when a render slot is free, rebuild the sheet with them, then a judge round plus strict re-check; the coordinator's cap of one judge round plus a re-check then hands F10#6 to the shared HUD-legibility lane with T2's device profile. Cards M2/M3 status and options (`ralph/reports/CLOSER/cards_m2_m3/REPORT.md`, read-only): **M3 stays failing** and cannot close this session (waits on F04#1, #2, #6, #7, on F10#6, and on Phase 2 Bars A/B; ACCEPTANCE section 4 does not allow declaring it without Bars A/B; the `chapter_cards` M3 note about '2 conditional activities' is stale because F03 is 8 of 8). **M2** is blocked on Keeper Hald only: the South Bridge is proven, but `_fight_named` in `tests/helpers/meadows_earned_hall_segment.gd` treats the first loss as fatal with no retry, and the party reaches Hald at about L15-17 with no potions against his L18-19 (the pilot is the weaker SPACER, switching off). **Decisions needed from the coordinator, not taken by this lane:** (1) approve option (a), a test-only heal-and-retry aid in the Hall segment with a disclosed-aid line, and the run budget (about 2 h for one fresh full M2, Godot only in CI); (2) option (b) a READER pilot only if Hald still wins after a healed retry; (3) option (c), a balance change, needs an owner decision and release of the frozen combat numbers and is not proposed here. The closing M2 run must be fresh (no `--resume-from`; the debug checkpoint counts_as_proof false and is not in CI).

**Criteria:** 95 of the 101 ACCEPTANCE §6.1 criteria are met (batch 67 plus Stormwood F09#3, F10#3 and F10#4, Cloudreach F08#3 and F08#4, Tidewake F13#3 and F13#5, Meadows F03#0, F04#3, F01#2 and F01#3, Stormwood F10#2). No chapter is accepted.

**Stormwood Phase 2c is winding down at the owner’s request.** Stormwood Phase 2c wind-down (tb/x04-stormwood), owner requested no new experiments. P2-042 remains fixed/enabled by1ed0259e5. P2-082 portraits and P2-084 eleven NPC openings passed96 native1920 captures, independent evidence audit and fresh blind review; enabled on branch bya53f158c9/8f5c25445. They remain catalog-open until full regression and landing finish. Full unit suite on8f5c25445 is still running at checkpoint: session46696, console12232/native9904, log .tmp/stormwood-phase2/people-accepted-full-suite.log. Reattach/check terminal result; do not restart merely for elapsed time. Scoped people Bars A/B YES/YES do not close chapter bars. Duplicate named cast identities, Fenn post-view obstruction and rough close-range materials remain separate findings. P2-037 remains open and all geometry/material candidates stay off; latest22 native frames/14 pairs prefer construction readability but complete crown/core/arena fails, scoped ancient-tree A YES/B NO. Production chapter matrix30 native frames plus derived720 review remains Bars A/B NO/NO; ordinary combat/HUD, adequate settlement coverage and wholechapter acceptance remain open. P2-041 confirmed by78-frame baseline; P2-043 glass candidate stays off after partial five-pair review. P2-045 candy, P2-081 trainer dialogue and P2-110 roster refresh remain off. P2-081 audit matches19 trainer plates; four missing profile recipes cover seven trainers. Reviewed scratch helpere0c5866ac was cancelled before native launch; no plates generated. P2-092 deferred to gameplay for collision/contact/lunge separation. P2-093 fade/HUD source hypothesis needs live measurement. P2-111 concerns persistent quick bindings. All remaining owned impact>=12 work stays open/needs_capture/deferred as catalogued. No regional or Phase1 criterion closure. See phase2/catalog.csv and stormwood/fixes/.

**The board is the source of truth.**

**Tidewake Phase 2d wind-down**, `tb/x04-tidewake`. Owner directed landing all work on `main` and stopping for now. P2-032 remains fixed/enabled (`8c5009e09`, independent PASS). P2-008 remains **OPEN**: gray-skirt/green-carpet symptom clear at 8/8 fixed stands, owner-photo match PARTIAL, whole-frame photo/Bar A/Bar B/Palworld-quality pass **0/8**. Shellwatch's dry grass-framed passage lacks a sea sightline and layered relief. The two solid Sluice pumps are visible and its patrol passed 32/32 checks over 850.3 m, but its sand flank and Veilfall mass remain below the board. Accepted eight-pair native evidence is now tracked under `ralph/reports/VISUAL/phase2/tidewake/fixes/P2-008/phase2d-review/`; the full issue, pass table, failed probes and pickup practices are in `fixes/P2-008/phase2d-shore-profile-review.md`. Do not sign off P2-008 or start later visual queue items from this checkpoint. P2-103 and P2-029 remain off/open as previously recorded; chapter matrix and regional acceptance remain open.

- **Meadows Phase 2c crafting:** P2-095 and P2-096 have a scoped independent blind PASS at three 1080p realm views and four 720p Meadows stress states. The enabled crafting UI and focused current-main controller checks are in `54b189254`; evidence is `ralph/reports/VISUAL/phase2/meadows/fixes/P2-095/accepted-ui-comparison/`. Their catalog rows are fixed for the stated UI defects. Regional Bars A/B and the rest of the Meadows catalog remain open. This checkout does not contain the board files referenced below; restore the existing board source on main and record these two IDs there rather than treating this STATE note as a replacement board.
- `ralph/reports/COORDINATOR/dashboard/criteria.json` holds every criterion and card, with its evidence and gap.
- `status.json` holds batches, lane FINAL SHAs and the authoritative **`wip` pickup list**, with each unfinished item's location and next step.
- `ralph/reports/COORDINATOR/README.md` gives the scoring rule and how to rebuild and republish the board.

**Chapter cards** (ACCEPTANCE §6):

| Card | State |
|---|---|
| M4, C1, T3, S3, T1, S1 | **Complete.** M4, C1 and T3 in batches 59, 65 and 67. S3 and T1 had their integrated runs in batch 63 and all feeders (F11, F12) met, and are recorded as complete in batch 67. S1 (Stormwood Phase 1 landing): the integrated chapter run re-run after F09#3 landed passes with its reload at 0068c542, strict re-check MET (`ralph/reports/STORMWOOD/s1/`). |
| M1 | **Complete (Cards lane).** Integrated run on main e35e2611: a fresh seed-15 game from the title through the tournament win, with a production reload, exit 0; composite with the F01 feeders. Strict re-check MET (`ralph/reports/CARDS/m1/`). |
| M2 | Partial, **blocked** (Cards lane, `ralph/reports/CARDS/m2/ROUTE_FINDINGS.md`). On main the earned five fails the South Bridge guardian 0/3; `trainer_ally_lateral_m` 0.0 (3f04ece8) passes 3/3. Past the bridge, the Warrens, the relay (after a harness fix for the captain's new victory lines) and the Sigils pass, but Keeper Hald wins 0/3 after the harder captains (b20d23ab); the route harness cannot heal and retry. Owner: Meadows lane (bridge fix; then a heal-and-retry aid or reader pilot). Waits on F04#1, #2, #6, #7. Solvency is ruled and the Hall-exit walk is exempt. |
| S2 | Partial (Cards lane re-score). Met: six activities (F10#0, Bryn's chain included), lightning and phase cues without HUD (F10#3), night phase merge retired (hour-invariant look test plus P2-042). Audio: the phase beds and strike chain fire on time (19/0), but no Stormwood audio asset exists, so no phase is audible (asset gap, owner decision). Open: F10#6 (Stormwood lane); Bars A/B → Phase 2. |
| C2, C3 | **Complete (Cloudreach Phase 1 landing).** C2: earned chapter run (longest travel gap 98 s, same five, no new catch) plus the six-activities witness, frame matrix by the F08#3/#4 code-blind verdicts; C3: two-peer co-op and Solmane aftermath, ALL CHECKS PASSED. Evidence `ralph/reports/CLOUDREACH/c2-card/`, `c3-card/`. |
| M3 | Failing: named-fight framing and Bars A/B. |
| T2 | Failing (Cards lane re-score). Islands, loops, shortcuts, pockets, six chains, four-character ledgers, currents/docks/Veilfall on function and restoration are met. Device profile FAILS at 7 inches (`ralph/reports/CARDS/t2_device/`): current direction unreadable (owner: Tidewake lane) and small HUD text illegible (owner: HUD, with F10#6). Tess and Nerissa C3 (F14#0/#1) wait on contact spacing landing (`tb/combat-spacing`). |

**Open criteria (10):**
- **Meadows:** F04#1, #2, #6, #7. F01#2 and F01#3 are met (`ralph/reports/MEADOWS/f01-walks/day_d41ff2f0`, `night_d41ff2f0`, `RECHECK_F01_2.md`, `RECHECK_F01_3.md`: the controller day and night walks reach all 11 targets; code-blind PASS on the gates, the lived-in camp and the key, which hangs glowing on its post at night). F04#3 is met (`ralph/reports/MEADOWS/f04/RECHECK_F04_3.md`: the Warden's HEAVY question reads at the normal camera; victory lines frame him clear with the HUD down). F03#0 is met (`ralph/reports/MEADOWS/f03/`: six ordinary-input lure walks to each prompt, the herd's night fire, the Hall pack on a road sightline with its nameplate depth-tested; strict re-check MET).
  - **Meadows lane handoff (2026-09-28 ~23:20; coordinator consolidated the open criteria into one serial lane, this lane stopped).** No criterion is newly MET; F04#1, #2, #6, #7 stay open.
    - **Branches.** `tb/meadows` (PR #437, head `08c3982f`, origin/main merged in for the relay-harness victory-read fix of #440; auto-merge enabled, full-ci labelled). `tb/meadows-bridge` (`6e76f203`, pushed; holds #437's commits plus the bridge fix, so cut a clean branch from main for the bridge PR after #437 merges).
    - **#437 carries (verified by unit tests and CI on the earlier head, engine behavior judged in renders):** camera occluders (stronghold, interior structure, relay gate arch), bystander step-aside, CHARGE/DIVE tell text, victory shot and trainer aftermath (strike when the lines are seen, stand-down on the last line, single hand-over), the freed-safe `hand_over`. The earlier `verify-regions-relay` failure on `547e7126` was the stale relay harness (the panel stayed open after the victory lines); the merged head has main's fix and CI is re-running on it (unverified locally: a local run was blocked by the running seed-15 harness). `verify-gate-b-full-known-red` is non-gating and commented on.
    - **South Bridge guardian fix (Cards M2, `BRIDGE_GUARDIAN_REGRESSION.md`), branch `tb/meadows-bridge`.** F04#2's lateral ally seat now applies only to officer, captain and warden ranks (`combat.json` `arena.trainer_ally_lateral_ranks`, `combat_manager.gd::trainer_seats_aside`, the director tags each trainer body with `trainer_rank`); the bridge guardian is a grunt and keeps the in-line seat, the six named fights still sit aside. Unit test `tests/test_trainer_ally_lateral_ranks.gd` (two tests) passes. Seed-15 continuous run with `--reload-at-transitions --through-bridge`: run 1 PASSED (tournament wins 2, bridge hits 38, `south_bridge_crossed`, `failures: []`, exit 0). Run 2 was in flight at handoff (`bridge_rank_r2.txt` in the lane scratchpad; not recorded, outcome unknown); run 3 not started. Not proven: 3 of 3 runs, so M2 is not re-run.
    - **Single next step.** Let #437 merge (drive CI to green on `08c3982f`), then open the bridge PR from a clean `tb/` branch cut from main with the same commit's five-file change, run proof runs 2 and 3 (about 30 minutes each; clear `four_biome_*`, `worlds`, `saves` and the coverage jsonl between runs, the disk allowance is about 300 MB), and re-run M2.
    - **In flight, none decided yet.** No render job is running. No judge is running. Final-round rules (coordinator 22:04): one round per criterion against `ralph/reports/MEADOWS/f04/final_F04_{1,2,6,7}/BAR.md` (written, unchanged); F04#6 renders on main after #437 merges; F04#1, #2 and #7 C3 render on main after the Combat Spacing PR merges; at most 2 render jobs at a time; a fail records the exact defects and ends the criterion's rounds.
    - **Open defects.** F04#1: the last judge (`JUDGE_F04_1_relay_ccecb414.md`) failed framing on the player's creature overlapping the opponent at contact range (Combat Spacing owns it). F04#2 and F04#7 C3: same contact-range separation; F04#7 C3 also carries the Vance face occlusion (a person or prop standing in the fight covering the head) noted by the small-body judge (`JUDGE_C3_small_257839f5.md`). F04#6: r5 judge failed (`JUDGE_F04_6_aftermath_r5.md`); #437 carries the fixes for its listed defects, not yet re-judged.
  - Other defect, not this lane's: `smoke_party_strip_reflow` fails before this lane's changes and is not in CI (owner: HUD).
- **Cards lane done** (`tb/cards`, 2026-09-28): M1 complete (#435). M2 is blocked (see the card table; re-run it once the Meadows lane fixes the bridge and chooses a heal-and-retry aid or a reader pilot). T2 and S2 notes are current. The earned relay harness now reads the relay captain's victory lines. **Paused by the coordinator until the Meadows bridge fix merges** (no runs are active; do not poll). Restart, once on the merged main commit: `TB_WORLD_SEED=15 godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --route-ledger --m4-finale --through-meadows --resume-from=user://four_biome_checkpoints/relay_disabled_and_mill_crossed_19623` (the relay checkpoint on the seed-15 save; it exists only in the Cards container, so on a fresh container start from the title without `--resume-from`). **Still needed:** M2: the Meadows bridge fix (owner: Meadows lane), then Keeper Hald/Captain Field (heal-and-retry aid or reader pilot), then one continuous earned run; waits on F04#1, #2, #6, #7. S2: F10#6 and F10#2 C3 (Stormwood lane), a Stormwood audio asset (owner decision), Bars A/B to Phase 2. T2: current direction at 7 inches (Tidewake lane), small HUD text (HUD owner), F14#0/#1 Tess and Nerissa C3 (contact spacing), Bars A/B to Phase 2.
  - Defects found, not fixed here: the bridge guardian regression (Meadows lane, 3f04ece8); Keeper Hald beats the earned-route pilot 0/3 after b20d23ab (Meadows lane / Balance, F04#7); Tidewake current flow direction unreadable at 7 inches (Tidewake lane); small HUD text (clock, hotbar numbers, key glyphs, FOOD label) illegible at 7 inches (HUD owner); no `assets/audio/stormwood/` files, so the Surge phases are silent (owner decision: audio assets, no placeholders allowed).
- **Cloudreach lane done** (2026-09-28): complete for Phase 1 (every row and card C1-C3 met), and the owned-carrier Fly debt is closed (#411). F08#3 (`ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/`) and F08#4 (`f08-4-settlements/`) closed on function; their Bars A/B clauses → Phase 2 catalog. F08#4 changed the game: working residents at Galefoot and Cliffhold, Cliffhold's settlement ambience on Cliffhold, and the Broken Causeways crown carved down to the causeway climb (it ran inside the crown). Owned-carrier Fly closed (`ralph/reports/CLOUDREACH/owned-carrier-fly/`): the five's healthy active carrier flies (WORLD §4.2), and the Galewisp starter gains Fly at the unlock (CREATURES §7). Maela's loaner serves her trial and, after the unlock, only a five with no healthy carrier, until the chapter ends. A five whose healthy carrier is not out gets a refusal naming it; an unwell carrier keeps the loaner's safety net. The carrier's ground follower is recalled for the flight, and LB/recall wait for touchdown. Earned c1_arrival flight leg on an owned Galecrest (disclosed swap): the trial flew on the loaner, one refusal, 4 owned launches, party 5. Open: Cliffhold reads thin (Phase 2).
  - **Phase 2c disposition pass (`tb/x04-cloudreach`).** All 20 owned impact >=12 catalog rows are explicitly deferred with reason, owner and follow-up; **zero fixes are claimed**. P2-021 skyline and P2-022 crown-arcade candidates remain off after failed native paired reviews. The 37-row chapter matrix and four summit views were captured before/after; regional Bars A/B are **No / No**, so F08#3/#4 visual debt remains open. Evidence: `ralph/reports/VISUAL/phase2/cloudreach/catalog-disposition-audit.json`, `disposition-code-review.md`, and `p2-022/{regional-baseline-judge,paired-visual-judge}.md`. Obstructed views remain inadequate; stills do not prove motion or earned traversal. The separate P2-053 baseline is 9/12 and retains its failures. P2-069 explicitly distinguishes historical loaner evidence from newer owned-carrier follower restoration.
- **Stormwood:** F10#6; card S1 complete. F10#2 met: C2 by Balance #413, C3 on the current fight camera (`STORMWOOD/f10_2/c3_p1/`, code-blind all six PASS, strict re-check MET). F10#6 (`STORMWOOD/f10_6/` r2–r5): the combat HUD meets the `hud_scale.gd` floors, the target plate sits top-right and fight panels fade over a covered subject, but UX §1.4 still fails where the left fight column covers the trainer and attack lanes; r4's pass was withdrawn (its prompt exempted the trainer); identical explore frames read legible in r4 and illegible in r5. Next: a compact fight column. F10#3/#4 and F09#3 met (`f10_3/r6/`, `f10_4/r7/`, `f09_3_r8/`).
- **Tidewake:** F14#0 is met (serial closer lane, 2026-09-29: Tess C3 A 94.4% / B 94.4% after the strict re-check, tell markings 6/6, `ralph/reports/CLOSER/f14_0_tess/r1/`; the margin rests on borderline HUD and ally-overlap calls). F14#1 (Nerissa) is open; T2 waits on it. **Piloting check, not done:** the coordinator asked whether stick-to-world piloting in Tess's Mirejaw fight feels wrong with the 70 degree camera yaw (the code reviewer flagged an extra 35 degree mapping shift). Nobody has piloted it by hand: this lane has no game window or controller, only headless and xvfb renders, so the answer is unknown. It needs a person with a pad in that fight. F14#0 stays counted on the judged frames only; that caveat is here so it is not read as verified.
- **Stormwood:** F10#6; card S1 complete. F10#2 met: C2 by Balance #413, C3 on the current fight camera (`STORMWOOD/f10_2/c3_p1/`, code-blind all six PASS, strict re-check MET). F10#6 (`STORMWOOD/f10_6/` r2–r7) **HANDOFF (Stormwood lane stopped 2026-09-28 22:55Z; serial lane continues).** Branch `tb/stormwood`, PR #439 (full-ci, auto-merge on; main merged in, board files taken from main, CI re-running on the merge). PR carries the HUD work: compact portrait fight column (232 px pips, 280 px card), HUD text at UX §8 raster floors (glance 28, HP/food numbers 33, badges 40), roster portraits, and the trainer kept out of the left column by the camera's HUD-safe cap (`combat.json` `hud_safe.trainer`). **Verified:** full unit suite at 29295e77 (5271 tests, 0 failed); the HUD unit and smoke files pass except `smoke_party_strip_reflow` and `smoke_progression_feedback`, which fail identically on the baseline; independent code review PASS after fixes (per-body trainer cap). **Unverified:** the r7 code-blind judge and strict re-check. r6 FAILED 3/4 (`f10_6/r6/JUDGE.md`: text below its own threshold, unnamed pips, trainer under the faded ally card, HUD covering subjects in H0/Hi/H2b/H2e). r7 explore frames (6) are re-rendered on the final code; the two named-fight captures (`--ids=hollows_alpha,crown_guardian`) were still running when the lane stopped. **Single next step:** build the 7-inch sheet from the r7 frames, run ONE code-blind judge round with the r6 prompt (`f10_6/r7/JUDGE_PROMPT.md`), then a strict re-check. Mark F10#6 met only if both pass; if r7 fails, record the exact failures (panel, frame, what could not be read) here and move F10#6 to the shared HUD-legibility lane with T2's device profile (coordinator, owner-approved). Judge variance: identical frames read legible in r4 and illegible in r5/r6; note a contradiction rather than chase it. **Open defects (owners):** legend hints (Map/Satchel/Build) still 26 px, UX §8 wants 30 for prompts (owner: shared HUD lane); forest trunks pure black near the lens and the Break trainer nearly invisible in the forest (owner: Phase 2 catalog); hit-burst disc covers the target's face (owner: Phase 2 catalog). Card S2's F10#6 clause waits on this. F10#3/#4 and F09#3 met (`f10_3/r6/`, `f10_4/r7/`, `f09_3_r8/`).
- **Tidewake:** F14#0 is met (see above); F14#1 is open; T2 waits on it, and on its device Q1 (current direction at 7 inches, below).
  - F13#3 and F13#5 are met (`ralph/reports/TIDEWAKE/phase1/f13_3/`, `f13_5/`).
  - **Rubric.** C3 framing is judged under a rubric fixed before judging (`ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`). Two code-blind judges score each round, and both must reach 90%.
  - **Passed under it:**
    - Aquaryn on the ordinary route, r6: 100% / 100%.
    - Tidecoil r12: 100% / 91.7%.
    - Aquaryn C2 with all three starters, under the named-wild ruling.
  - **Still open:**
    - Tess on the ordinary route: r5 scored 97% / 84% (r4 about 86% strict).
    - Nerissa r17: 98% / 83%.
  - **The residue in both** is contact-range occlusion. After a strike the two bodies overlap, and the ally stands in front of the opponent's head. The camera cannot separate touching bodies.
  - **Contact spacing is on `tb/combat-spacing`, not yet on main** (see the Combat spacing handoff below; `ralph/reports/COMBAT_SPACING/REPORT.md`). Fighters are held apart by their rendered extents. The opponent's spacing and every reach floor at that separation, so C2 still passes. Once it lands, the Tidewake lane re-judges its C3 rows on main.
    - The lane's own capture: judge A gives Tess r7 92% and Nerissa r19 91%; judge B gives them 82% and 87%.
    - Nerissa: no ally-over-head failures remain for either judge.
    - Tess: judge B still fails 4 Mirejaw frames at the full 8 m separation. That is camera composition along a long body, not interpenetration.
    - Other residue: the Heart Chamber crates hide heads, and the trainer stands between the fighters.
  - **Preview on the unlanded spacing commit** (`f14_0/tess_spacing_preview_9b3d0cca/`): Tess scores 79% on one code-blind judge. The gap holds at 6.99 m or more, yet Ripplet's head still covers Mirejaw's snout at the rule's 0.6 m margin, and after Mirejaw lunges past the ally the player trainer stands in front of its head. As committed, the rule does not bring Tess to the C3 bar.
  - **T2 device Q1, current direction at 7 inches** (Cards lane assigned it to Tidewake): **blocked, nothing shipped** (`ralph/reports/TIDEWAKE/phase1/t2_current_direction/`). Rock wakes and downstream-pointing foam darts each scored WEAK twice with a code-blind 7-inch judge. Seen end-on from the dock, flat water marks foreshorten to slivers; darts read correctly at full size only. The untried next approach is a vertical cue (standing-wave ridges).
  - **Tidewake lane handoff (2026-09-28 22:55, coordinator: work consolidates into one serial lane; this lane stops here).** Everything is pushed to `tb/tidewake` and merged to main; no run or judge is in flight.
    - **Final F14#0/#1 C3 round, needs:** the Combat Spacing PR merged to main (not merged as of 22:55). Run on that merge commit, with `tb/tidewake` merged up to it and no other change. Do not preview against the unlanded branch.
    - **Fixed before rendering:** `f14_0/tess_final/BAR.md` and `f14_1/nerissa_final/BAR.md` hold the exact render command, frame list, rubric rules and pass line. Pass = both judges ≥ 90% framing under `C3_RUBRIC.md` and every tell-start marked. Last results: Tess r5 97% / 84%, Nerissa r17 98% / 83%. The Tess preview on the unlanded spacing commit scored 79% (one judge).
    - **Captures (1280x720, opengl3, xvfb, `tests/capture_tidewake_named_fights.gd`, `--pilot=READER --level=43 --render-only-saves`):** Tess `--trainer=water_trainer_tess --approach=sluice_isle_to_deep_watch_arrival --interval=12 --tells-per-opponent=2 --max-frames=48 --cap-s=500`; Nerissa `--trainer=water_trainer_nerissa --interval=16 --tells-per-opponent=3 --max-frames=90 --cap-s=700` (placed at Nerissa in the Heart Chamber, a disclosed shortcut). Full commands are in each `BAR.md`.
    - **Judges:** two fresh code-blind subagents per round, one sonnet and one default model, using `JUDGE_PROMPT.md` in each `*_final` folder verbatim, then one strict re-check by an independent agent (arithmetic, every frame judged, rubric as written). Run once each; on a fail, record the exact remaining defects in STATE and stop (coordinator's rule).
    - **Cost (estimates, not measured):** each render is capped at 500 s (Tess) or 700 s (Nerissa) of game time, so about 10-25 minutes wall clock; about 150 MB of PNGs per render, so free disk first (the disk was at 100% this session) and convert to JPG as it goes; at most 2 render jobs at once. Each judge takes a few minutes; the strict re-check about as long.
    - **T2 device Q1, current direction at 7 inches:** four rounds, blocked, nothing shipped (`t2_current_direction/README.md`). Rock wakes ×2 and foam darts ×2 all WEAK; earlier chevrons and comets also failed. Do not repeat flat water marks. The one untried idea is a vertical cue: standing-wave ridges with foam spilling down the downstream face (a finer displaced ribbon mesh with lit normals). It is a larger change to `water_current_flow_view.gd` and `water_current_flow.gdshader`, with no evidence yet that it reads at 7 inches. Judge it on the 586x330 sheet from `tools/capture_tidewake_f13_5.gd --only=currents`.
  - **Landed as progress:** the Heart Chamber arena bound, the tell and head camera swings, and Riptusk's lunge opt-in. All are presentation-only, apart from the smaller ring.
  - **C2 met for both rows under option (c) (main 1e0ddd39).**
    - Tess, Calder and Venn: reader win 1.00, masher lead-faint 1.00. Venn's lane now locks at 0.25 of the tell.
    - Nerissa at the 9 m ring: 144 in-world fights, reader win 1.00 x3, party cost 0.13-0.24.
    - Aquaryn and Tidecoil pass under the named-wild ruling.
  - **Card T2's non-fight clauses** were re-scored by the CARDS lane (see the card table): all met except the device profile. Its 1920x1080 opengl3 capture reads docks, Veilfall and restoration at 7 inches, but not the current's flow direction or the small HUD text.
    - This lane's prep is on main for it to use: `tests/card_t2_tidewake_islands.sh`, and `phase1/card_t2/device/` with a first 7-inch read of FAIL 2/4.
    - The dock and current capture stands missed their subjects.
  - Other defects, recorded, not fixed:
    - The travelling-lane "locked" visual (`wild_creature.gd:853/972`) reads the global `charger_lunge.face_lock_fraction` (0.5), while a per-body `face_lock_fraction` (Venn 0.25; the Stormwood CHARGERs) freezes the heading earlier. The lane shows as locked later than it is. Owner: shared combat.
    - the fight HUD's move panel drops out while "it missed you" or "it's open" shows;
    - the ordinary tell ring marks the attacker's feet, not a landing spot.

**Batch 67 unjudged visuals:** off/unwired under the wind-down rule; enable only after code-blind Bars A/B PASS.
- `stormwood_glass_field.json` `scorched_scars=false`.
- `camera.body_clear.ignore_lunging_foe` and the Vance move are re-applied on `tb/meadows` (F04#1).
- The Meadows camp firepit is back on and judged on function (F01#2 code-blind PASS); its Bars A/B read → Phase 2 catalog.

**Batch 67 reverts:** Stormwood-B F10#2 C3 `07bc9cad`, `45927814`, `85ba1c57` (Elder cone/heading, guard cone). Re-apply for F10#2 C3 recapture.

**Branches.** Batch 67 took every head; newer landed work won conflicts: Venn's move without the pad, judged Stormwood r5 lightning, cleaned docs. Omitted Codex doc facts live in ART_DIRECTION §7 and `ralph/reports/VISUAL/AUDIT.md`. Unjudged Cloudreach towers/occupied terrace are merged, flagged off.

**To resume work:**
1. Pick an item from the `wip` list or an open criterion.
2. Work on a `tb/<lane>` branch from current main, following WORKFLOW §8 and `CLAUDE_START_HERE.md`.
3. Land each closed criterion through the lane's own PR (re-check, unit suite once, board and STATE, auto-merge). There is no coordinator and no channel.

**Combat spacing lane: handed off (2026-09-28, owner). Lands through the consolidated PR (`tb/consolidated`) with #437, the bridge fix, #439 and Codex #414/#428/#430.**
- **Where it is.** Branch `tb/combat-spacing`, head `0b42ec91`: round-2 code `b2ce4df6`, merged with main `c68af1c1`, plus evidence and this STATE. Evidence and numbers: `ralph/reports/COMBAT_SPACING/REPORT.md`.
- **The rule.**
  - Code: `scripts/combat/contact_spacing.gd`, `creature_body.gd::_hold_contact_spacing`, `combat.json` `contact_spacing`.
  - Separation = the two directional rendered half-extents + 0.6 m. The ally yields; the opponent holds.
  - The opponent's `preferred_range` floors at the separation. Every reach floors at the longest separation + 0.5 m: `floor_reach_for_bodies`, `host_move_profile` with its 3 host call sites, and `spaced_config_for`.
  - Round 1 (`9b3d0cca`) capped the separation at 2.75 × radii and was superseded.
- **Verified on `b2ce4df6`** (before the merge with main):
  - Full unit suite, 4 shards: 5,274 tests, 0 failed.
  - Net smokes `shared_wild_fight` and `cloudreach_riding`: ALL CHECKS PASSED.
  - C2 before/after (before = rule disabled, main's path):
    - Capacitor Alpha ratios 0.42/0.50/0.41 → 0.22/0.28/0.21, reader win 1.00.
    - Oreth: every row passes. Masher win: ripplet 0.04 → 0.46, galewisp 0.17 → 0.67, terrapup 0.00 → 0.00.
    - All seven Meadows fights for **ripplet only**: every row passes, chapter bar 0.68 (was 0.97; bar 0.25).
    - Nerissa in-world, 12 seeds per cell: reader win 1.00, masher wipe 1.00. Reader party cost 0.18/0.26/0.24 on main → 0.21/0.30/0.30 at the new reach (bar ≤ 0.55).
  - Reader check at the new reach: the reader passes in all three harnesses above.
  - Independent code review PASS (round 1 code; round 2 not re-reviewed).
- **Unverified.**
  - The combat subset after merging main `c68af1c1`; that run was interrupted.
  - All seven Meadows fights for terrapup and galewisp at round 2.
  - A code review of the round-2 diff.
  - CI on a PR.
- **C3 (evidence only).**
  - Judge A: Tess r7 92.1%, Nerissa r19 91.3%.
  - Judge B: Tess r7 81.6% (4 Mirejaw ally-over-head frames at the full 8.0 m separation, which is camera composition); Nerissa r19 87.0% (0 ally-over-head; failures are crates, a Riptusk crop and the trainer).
  - Judge B round 2 is **complete**. Its Tess pass ran in two parts because images failed to load.
  - Verdicts: `ralph/reports/COMBAT_SPACING/c3/ROUND{1,2}_JUDGES.md`. Frames: `c3/tess_route_r7/`, `c3/nerissa_r19/`. The prompt is the fixed `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md` text, frames-only and code-blind.
- **Runs in flight: none.** Every dispatched render.yml run finished and was harvested: C3 36483953554 and 36483957865; Nerissa C2 cells 36483962218–36483985793, plus the round-1 and before cells.
- **Single next step.** Run the combat test subset on `0b42ec91`. Then open the PR `tb/combat-spacing` → main: fill in the template, check it with `tools/check_pr_traceability.mjs`, mark it as a shared combat file edit, and enable auto-merge.
- **Open defects, not this lane's.**
  - Tess/Mirejaw: ally over the opponent's head at full separation. Fight-camera composition against long opponents (camera owner, with Tidewake).
  - Heart Chamber crates hide heads (Tidewake).
  - Riptusk is cropped after its heavy (camera).
  - The trainer stands between the fighters (camera or placement).
  - Low-severity review notes: the guest ally is not exempt during the host's lunge; the tunnel-undo ray uses the full collision mask.

**Open lanes (2026-09-28).** Three Phase 1 biome lanes (`tb/meadows`, `tb/tidewake`, `tb/stormwood`; `CLAUDE_START_HERE.md`; the Cloudreach lane is done) and one Codex capture-and-catalog lane (`tb/x04-capture`; `CODEX_START_HERE.md` §2a–2b). The Balance lane lands the F04#7 and F10#2 C2 halves through PR #413, then stops; the C3 halves stay with the Meadows and Stormwood lanes.

**Not covered by the open lanes; do these after:**
1. **Biome reorder (Phase 1b).** After all four biome lanes finish, one lane follows `CLAUDE_START_HERE.md` §6: Meadows → Tidewake → Cloudreach → Stormwood; gates/keys, levels, Stormwood ending, swim-before-Fly, ledgers, regenerated checkpoints, save migration. Only Cloudreach requires Fly; Tidewake water seals/Stormwood canopy merely register no-fly volumes. Fix old-order assumptions:
   - `scripts/save/realm_reward_migration.gd` retargets a Cloudreach-awarded `realm_key_water` to Stormwood whenever `cloudreach_chapter_complete` is set. In the new order Tidewake's water key comes first, so this must not rewrite it.
   - `data/config/water_crafting.json` skill candies offer "Flying" in Tidewake, before Fly exists in the new order.
   - Stale old-order notes: `tools/net/proof_scenarios/x05_f13_5_no_swimmer_reach.json` and `tools/gate_f/capture_four_biome_road_creatures.gd` (its Cloudreach → Stormwood → Water flag list).
2. **Four-chapter earned run** in the new order, then a **human play pass** per chapter.
3. **Codex Phase 2c.** Four biome fix lanes after reorder (`CODEX_START_HERE.md` §2c). Re-shoot top catalog items: baseline predates Phase 1/reorder. Regional Bars A/B verdicts clear `Bars A/B → Phase 2`. Known items: aerie art, Stormheart tree, waterfall, Glass Field (off), Pump Hall (machinery placed; identity WEAK), Cloudreach towers/terrace (off).
4. **Debt that no queue covers:**
   - Stormwood-B's reverted 07bc9cad, 45927814 and 85ba1c57, if F10#2 C3 needs them.
5. **Release (owner).**
   - Internet co-op by invite: Steam AppID, partner access and four accounts.
   - Download, install, launch and update.
   - Licence, provenance and credits audit, and store-claim accuracy.
   None of these is on the board.
6. **Housekeeping.**
   - Republish the board to its link in `ralph/reports/COORDINATOR/README.md`. Lanes rebuild the HTML, but the owner's account holds the link.
   - Delete each lane branch after its last landing.

**Final step (owner, 2026-09-27).** After all 13 cards pass and reorder lands: one checkpointed, new-game-to-ending earned run on one save (`smoke_four_biome_continuous`) retires chapter-boundary fixture debt; short human passes per chapter retire harness-input debt.

### Open owner decisions

1. **Internet co-op proof needs:** real Steam AppID/partner access, four accounts, ≥2 on separate home networks. `steam_api64.dll` redistribution approved; packaging (`ship_steam_runtime`) off until AppID exists.
2. **Owner 23:55 decisions, implementing in batch 68:** harder Meadows trainers (F04#7), starter parity (F10#2), female officer Vess, aerie art; ruling 11.
3. **Consolidated landing (owner, 2026-09-28 23:55): PR #442 (`tb/consolidated`) carries everything open** (Combat Spacing, Meadows #437, the bridge fix, Stormwood #439, Codex #414/#428/#430, plus the relay and Nysa CI fixes). #414, #428, #430, #437 and #439 are closed as superseded, branches untouched. No criterion is marked met by it. The serial lane validates on #442 and resumes its queue (F14#0/#1 residual camera fixes, F04#2/#7, F10#6 r7 judge) after it merges. Look development, HUD-legibility and Stormwood-audio lanes are approved but archived, not started.
   - **Balance lane:** F10#2 and F04#7 C2 halves met (ruling 12; `ralph/reports/BALANCE/`). C3 halves stay open.

4. **Settled by the owner, 2026-09-28 (superseded in part by item 3: the look-development, HUD-legibility and audio lanes were approved, then archived before doing any work; Cards is paused):** (a) a **shared look-development pass** comes before further per-biome Phase 2 work (lane `tb/lookdev`; see CODEX_START_HERE §0); (b) **one shared handheld HUD-legibility lane** (`tb/hud-legibility`) takes F10#6's device profile and T2's small-HUD-text clause from the Stormwood and Tidewake lanes; (c) the **Cards lane is paused** until the Meadows bridge-guardian fix merges, then re-runs M2 once. Still open: whether to author the nine missing `assets/audio/stormwood/*.wav` from installed sources under AUDIO §10 (blocks S2). Agents cannot listen, so acceptance would rest on spectral/loop checks plus an owner listen.

5. **Owner playtest answers, 2026-09-29:** (a) power attacks: re-aim before the hit, plus a wider charged arc, landed on `tb/combat-feel` (`combat.json` `strike_reaim`, `player_pace.charged_cone_bonus_degrees`); (b) combat pace: faster on BOTH sides (player wind-up/recovery x0.85 (cooldown stays x1.0 because the hosted net smokes time against the authored 1.2 s lock); opponent baseline attack cooldown 0.9 and back-off 0.5 s; recovery stays 0.75 s because BOSSES requires Meadows named fights at least .9/.75 s); measured with `smoke_combat_baseline.gd` (12 seeds): ordinary wild now costs the lead 16-22% (target 15-30%), the old timings failed 4 of 5 bands as too easy; W-1 (Warden 51% vs elite 63%) fails on the old and new timings alike. (c) village shape: a before/after sketch came first; the owner picked option B (main street plus small green); it is built in PR #455 (`tb/village-main-street`, pinned by `tests/test_village_main_street.gd`; the green is plain lawn plus the well's apron, and Oskar's and Tam's trainer fight spots moved, awaiting the owner's OK); (d) Meadows river (P2-006) waits for the full look-development pass. Running animation and branch deletion were not asked; the mouse fix needs the owner to confirm on a real PC. (e) Running animation, asked later the same day ("running is weird and too fast"): the run lean/cadence fix (`gait_feel.run_lean_max_deg`, `sprint_cadence_scale`; existing clip, no new art) landed in #449; owner to feel it on a pad.
**Settled by the owner (2026-09-27, 23:55):** the Capacitor Alpha no-stagger ruling and the storm strike sparing a trainer in a fight are **kept**. They are no longer interim.

**Owner, 2026-09-27 23:55:** Capacitor Alpha no-stagger and storm strikes sparing trainers in fights are **kept**, no longer interim.

## 1. Rulings in force

**Owner and coordinator, 2026-09-27.** Nothing may contradict these.
1. **Counting and proofs.** Criteria count at merge; post-batch full CI is a safety net. Disclosed fixtures/declared starts, teleports, flag/party writes, harness fights and skipped sub-parts are allowed (ACCEPTANCE §6.1, WORKFLOW §8), as are earned checkpoints. Held Fly is lawful; tap pulse optional.
2. **Solmane.** Like Meadows' Veridian, Cloudreach's legendary is freed after Veyra, with a once-only offer per participant; never wild/catchable. Summit wild tables use tempestwing. **Implemented:** F08#5 met, C3 rerun passed.
3. **Device profile.** A computer capture at 1920×1080 on Compatibility/`opengl3`, judged code-blind for 7-inch readability. No Ally hardware (#356 5857144944; ACCEPTANCE §6.1).
4. **Visual bar.** Bars A/B apply to every visual row. "Beauty matters." **Owner update (2026-09-28):** Phase 1 mixed rows close on function/readability (`CLAUDE_START_HERE.md`); Bars A/B move to the Phase 2 catalog (`CODEX_START_HERE.md`) for regional verdicts.
5. **Build the game, not proof machinery.** Every round is player-visible. The two-strike harness rule applies, and each READY/FINAL post carries a `Balance: game N / tests-tools M` line (WORKFLOW §8).
6. **Return route.** The homeward return after Tidewake is exempt from A7 (T3/F15).
7. **Art split.** Claude may kitbash, dress, shade and light scenes using installed families; new meshes/Meshy stay with Codex. Partly supersedes 2026-09-26 "all art to Codex".
8. **Capacitor Alpha** does not stagger during the route cue (F10#2 option a). Kept by the owner. A Stormwood storm strike spares a trainer whose creature is in a fight (`stormwood_surge.json` `strike.spare_trainer_in_fight=true`). Also kept by the owner.
9. **Process.**
   - Every branch uses the `tb/` prefix, with one reused `tb/<lane>` branch per lane and no lane PRs.
   - Lanes self-land PRs with re-check/one unit run (owner, 2026-09-28); no coordinator or lane channel.
   - **Wind-down:** push everything, including WIP; unjudged visuals land default-off/unwired. Coordinator consolidates, runs units once and CI once.
   - READY means a criterion fully closes, with an attached strict re-check, one criterion at a time. Codex-queue IDs are lane-prefixed and append-only.
10. **F04 split.** Wound-down lanes: Meadows core #0/#1/#7; bosses #2/#3/#6. Bosses round1: `ralph/reports/MEADOWS/f04_bosses/r1/`.
11. **Owner decisions, 23:55.**
   - **Meadows named trainers are made harder** until C2 passes: team-wipe rate at or above the 0.25 bar (F04#7). The bar is restated by ruling 12.
   - **Galewisp and ripplet are tuned to match terrapup in skill and strength**, so starter C2 difficulty is even (F10#2, CREATURES).
   - **The 326 m walk from the Hall exit after the finale is acceptable** (exempt from A7 and WORLD §3.1 spacing; M2).
   - **Codex does the Cloudreach aerie art** (F08#3). The Codex lane is shut down; the owner assigns this when the next round of work starts.
   - **Vess, the female officer,** gets the female officer body and portrait. Add a `defeated` clip to `officer_b`.
12. **Meadows top-fight bar (owner 2026-09-28, F04#7 option c; delegated to the Balance lane, coordinator agreed).** Per top fight and starter, 24 seeds: reader win ≥75%, masher loses its lead every run, reader party cost ≤55% of the masher's. Chapter reading (the lane's reading of the owner's intent, not the owner's words): a masher loses ≥1 named trainer fight in ≥25% of playthroughs; measured 1.00/0.97/0.94, observed 24/24, 24/24, 22/24. Per-fight masher loss: Oreth 100/96/83%, Halder 8/25/29%, Warden 0/4/33%, Hald 0/0/25%, Vance and Vess 0% (L12 pin; DIVER ending). Fixed harness party ends on Trailpup (conservative bias). Owner option: raise the Band 3 pin for Vance for a per-fight 25%. The form applies to Tidewake F14#0 (Tidewake lane measures). COMBAT §7, BOSSES §9, ACCEPTANCE C2.

**Owner, 2026-09-26 (still in force):**
- The tournament creature grant is a non-starter species; starters stay player-exclusive.
- F11#2: an old-build Stormheart receipt with no answer is **undecided**. That character is re-offered once and never granted twice. This supersedes the 2026-09-25 coordinator reading.
- The Cloudreach cliff palette is a code-blind judge pick.
- Team Tether palette stays: explicit oxblood exception; audit H2/H3 and M7's red portions closed.
- "Guardian C2/C3" in the Tidewake BOSSES means the Nerissa fight.
- Rook's Deepwood Circuit reward is `tm_thunder_break`, paid once per character through the `reward_grant` receipt.
- Co-op matches single player: live co-op keeps road shoulders. A same-host rejoin returns the character to its exact saved pose; any other world uses the authored regional spawn (MULTIPLAYER).
- Stormwood is always a purple storm with no day/night, stays purple after release and uses one always-on encounter table.

**Coordinator rulings (owner-delegated, still in force):**
- **Meadows**
  - The healed Meadows land is a runtime regreen to green grass: the herd returns and the pylons fall, with no re-bake.
  - Practice-wild supply is raised so level 5 is reachable at the South Bridge.
  - The village and spine roads are widened for the roughly 2 m/texel control map.
  - F03 lure cue option (a); the Juno escort is kept; the X03 beacon is kept; the Xbox B glyph is neutral.
- **Cloudreach**
  - The Cliff Circuit keeps a one-time Tavi rematch (ace tier, 90 coins plus great_candy). This differs from WORLD §11's deferred rematch tier.
  - Waycamp upgrades Galefoot; there is no sixth camp.
  - Windscar's local beat is the aerie-repair supply run.
  - F07#2 keeps both criteria through route XP option (a).
- **Tidewake**
  - Legacy worlds offer the Guardian to every participant named in the delivery journal.
  - The top-trainer damage tunable also covers Venn and Nerissa.
  - F14 named wilds are judged by the named-wild rule.
- **Shared**
  - Client-run trainer wins pay every participant through the host.
  - Bramblebun sheet 06 is approved for one Meshy redo with rust/ochre thorns; this is Codex's work.
  - X05 may use `teleport_to` in test harnesses only.
  - Only the coordinator edits `.github/workflows/ci.yml`.
  - Criteria are numbered from zero within each F row.

## 2. Product decisions

- This pass is a four-chapter creature expedition action RPG: solo/required 1–4 co-op, at most five owned companions, directly piloted real-time fights, camps supporting journeys, ending in Tidewake victory/homecoming. Eight good hours can ship; no 12–16-hour floor. Eight biomes remain the long-term plan.
- Keeping the same five through the ending is success; rewards deepen them, catches optional. Water's critical path must not require an owned swimmer.
- Minimal mechanics testing: short existing-loop checks before new systems. L4 skill, normalized poise, revised bond and Strain parked (ACCEPTANCE §3).
- No new investment: code/existing tools/assets, including held Meshy licence. Agents may draft references and submit scoped Meshy work (AGENTS art rule; ART_DIRECTION §7).
- Co-op is required through invitation, with no router setup or typed address. LAN or direct-IP alone is insufficient for release.
- Owner: "personal / friends — I just want it good". PRODUCT price/positioning do not authorize publishing or spending; commercial launch needs a separate owner decision.
- **Legendary rule:** each participant in the freeing fight receives their own once-only offer, bound to their stable character; non-participants get none (AGENTS, WORLD §2.3).

## 3. What exists

| Domain | Current fact | Open against the plan |
|---|---|---|
| Combat | Wind, poise, burst and quick/charged geometry; per-body named-fight overrides; the hitstop attack buffer. | C2/C3 on named fights (F04#7, F10#2, F14#0/#1), large-body camera framing. |
| Creatures | 57 base species, individual IVs and bond, and limited evolution. Galecrest was rebuilt from a reference; its `companion_presence` head-tracking override did not land because main lacks that code. | Creature finish for Bars A/B, and attack-pose clipping (AUDIT §A). |
| Meadows | Opening, route, activities, Hall and finale. F02 and F05 are fully met; M4 is complete. | F01 walks, F03#0 lures, F04 presentation, Bars A/B. |
| Cloudreach | Six regions, Fly and remount, six activities (F07 met), Veyra, and Solmane's per-participant offer. C1 is complete. | Aerie art (F08#3, Codex), settlements and cliffs (F08#4, Codex). Owned-carrier Fly closed. |
| Stormwood | Earned six-region route, Arches, Dynamo, Stormheart and aftermath. F09, F11 and cards S1/S3 are met. | F10#2 C3, F10#6 device profile. Open risk (owner: Stormwood lane): no perf measurement of the dense Deepwood bake (3d5fb0e6). Phase 2: aftermath under the canopy brighter than the owner's ruling. Findings (owner: Stormwood lane, after S2): pools_west_loop crosses the lit b_pools arch; a 1.11 m curb on b2's landing side; a 0.4–0.67 m step behind d_giant. Defect (owner: Tidewake, F14 C3): the top band's `Camera3D.v_offset` lens lift renders Stormwood's lit fight world black on Compatibility (`STORMWOOD/f10_6/r3/ab_top_band/`). Defect (owner: X03): `interaction_arbiter.gd` does not gate on a starting wild fight, so `interact` can open a nearby NPC mid-fight (`STORMWOOD/s1/phase1_rerun/`). Residual (owner: X01 combat): a named CHARGER strike reads "it missed you" while the ally stands inside the drawn lane (`STORMWOOD/f10_2/c3_p1/` W tell4). |
| Tidewake | Human swim route (F12 met), eight pockets, six local chains with map leads (F13#3), dock residents and current comets (F13#5), dock exchange, return, Grandpa and credits (F15 met, T3 complete). Veilfall rooms show their pumps, sluices and banners. | Named-fight C3 framing: Aquaryn and Tidecoil pass. Tess and Nerissa are blocked on contact-range occlusion, which needs a shared combat spacing rule. Bars A/B looks go to Phase 2. |
| Multiplayer | ENet authority, portable characters, ledgers and receipts, the exact-pose rejoin, and an optional default-off Steam lobby path. | Internet relay and four accounts (owner resources), host plus 3, device. |
| Save | Save version 27 with world format 2 and character format 6; atomic split saves; refusal of corrupt or absent halves without live mutation. | Legacy peer-ID receipt and slot-rename ambiguity (not recovered). |
| Visual/audio | Compatibility renderer with directional shadows; installed asset families; generated audio managers. | Bars A/B on every visual row; final music and mix. The Codex queue is `ralph/reports/VISUAL/AUDIT.md`. |

## 4. Risks and evidence boundaries

- **Wayfinding.** Owner's highest-impact complaint: corridor feel. Beacon/map reveals landed; judge geography/detours from whole paths, not beams.
- **Fixture debt.** Most met criteria use disclosed fixtures/teleports/harness fights, not fresh-play proof. Final earned four-chapter run and human passes retire this debt.
- **Shared-fight geometry.** The proxy-body divergence behind a guest's non-landing blow is fixed at root (`tests/test_remote_proxy_snap.gd`; MEADOWS-PAYOFFS/proxy-ground-plane). Re-check guest-hit smokes after any follow or collision change.
- **Legacy receipts.** Ambiguous peer-ID receipts are not auto-recovered. Corrupt legacy saves must stay inspectable without mutating live runs.
- **Steam packaging.** Windows rolling download lacks GodotSteam until an AppID exists; invitation co-op cannot yet work. Simultaneous two-client ENet disconnect may log a harmless native error.
- **Visual verdicts.** Software-GL proves composition/scale/colour, not fine lighting/performance. After two rounds without progress, change asset/approach, not tint (ART_DIRECTION §9).
- **Accepted art:** camp set, pickups, South Bridge gate and lost rigs retain ART_DIRECTION §7 dispositions unless gameplay evidence reopens them.
- **Owner reports.** Fresh owner repros reopen ledger-fixed items; first check the played build.

## 5. Dependencies and still-open design questions

- **Owner resources:** the Steam AppID and partner access, and the four accounts (§0).
- **Meshy:** Meshy runs through Codex on the owner's machine. Claude sessions hold no key.
- **Design questions** (keep current behaviour conservatively until settled):
  - the wild defeat persistence policy;
  - which replacement subjects the reference/Meshy workflow takes;
  - a Burrowback contrast treatment that keeps its identity;
  - a grass clump redesign beyond the approved settings.
- **Validate:** ACCEPTANCE §7 release performance on owner-provided Ally hardware; fair late-catch bond; shared encounter scaling. Failures require retuning, not relaxed bars.

## 6. Owner direction carried forward

- **Standing feedback:**
  - Content off the trail and visuals matter, and combat depth continues.
  - No held inputs, except Fly.
  - Grow smaller creatures rather than shrink larger ones.
  - Five total, with no storage.
  - The human never fights, and there is no starvation.
  - No street villagers beyond the five-street-resident arrangement.
  - The Pond is a local lush reference.
  - Use actual-game captures, not bad survey shots.
  - No hour-long CI fan-out.
  - Outside co-op and device proof are required.
- **Usage/stop direction:** the owner overrode the 10% usage stop rule for P2-008 on 2026-09-29, then explicitly requested landing the work on `main` and stopping for now. The current stop request governs; resume P2-008 only at the owner's direction. Never consume a usage reset automatically.
- Record owner feedback here; it overrides other documents on its subject.
