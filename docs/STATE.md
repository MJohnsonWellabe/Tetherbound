# State — live status against the release plan

Read this first. Update it in place and keep it under 25KB. No dated status, goal, directive or handoff documents. Evidence lives in `ralph/reports/<LANE>/`; history lives in Git and `archive/`.

## 0. Resume here

**Where the game is.** All lanes of the 2026-09-25..27 concurrent run are wound down (owner, 2026-09-27 22:30). Each lane pushed everything, including work in progress. Batch 67 consolidated every lane head and every remaining branch, including the full Codex branch and Vess, onto `tb/integration`, and landed it through one PR after one unit run and one CI run. **Next is Phase 1 (`CLAUDE_START_HERE.md`):** one self-landing lane per biome. **Check that batch 67 is on `main` before you start** (`git merge-base --is-ancestor <sha> origin/main`). If it is not, landing it is the first job.

**Criteria:** 94 of the 101 ACCEPTANCE §6.1 criteria are met (batch 67 plus Stormwood F09#3, F10#3 and F10#4, Cloudreach F08#3 and F08#4, Tidewake F13#3 and F13#5, Meadows F03#0, F04#3, F01#2 and F01#3, Stormwood F10#2). No chapter is accepted.

**Stormwood Phase 2c is active** on `tb/x04-stormwood`. P2-042 is fixed by `1ed0259e5`: fresh native/small-size blind review passes all four phases at both original catalog stands and readability preservation. The accepted presentation is enabled; actual enabled surge suites pass 55 tests / 762 assertions. Regional Bars A/B remain NO because character, Stormheart landmark and landscape gaps remain. P2-037 native paired review confirms grounded wall seams, but the full landmark and Bars A/B still fail on cylindrical form, sparse crown and construction detail; its candidate remains off. A separately disabled canopy-atlas correction preserves the installed leaf mask; six native pairs show a small distant contrast gain with flatter cutout foliage, unchanged near views and Bars A/B NO/NO. It remains off. P2-084 has a separately disabled eleven-opening NPC candidate with source review and existing NPC checks passing; panel acceptance remains open. The current 78-frame landmark baseline establishes P2-041 as an open visible defect. P2-043 native comparison is partial: improved obstruction but weak scar integration and lost glass identity; its candidate stays off. P2-045 candy tiers, P2-081 trainer dialogue and P2-110 roster-vitals refresh remain disabled pending complete native review. P2-092 stays open with a `tb/stormwood` gameplay dependency for collision/contact/lunge separation; P2-111 identifies persistent quick bindings rather than reward tiles. Evidence and remaining work are in `ralph/reports/VISUAL/phase2/stormwood/fixes/` and `phase2/catalog.csv`. The disabled branching-crown geometry candidate passes 7 tests / 166 assertions and source review. Fourteen native pairs confirm stronger distant tree recognition, but crude joins, pale fragmented canopy and the full landmark still fail; Bars A/B remain NO/NO. Ground-level interior pairs do not prove upper-arena visibility. The current chapter environment batch has 30 verified native1920 frames, three compact pages and ten reviewed derived720 stress views. Fresh blind Bars A/B are NO/NO for creature material/readability, landscape depth and Stormheart architecture. Ordinary combat/HUD, adequate key-settlement coverage and complete chapter acceptance remain open; see stormwood/fixes/chapter-matrix/. No regional completion or Phase 1 criterion closure is claimed. P2-082 has a separately disabled installed-portrait mapping candidate covering nine catalogued speakers plus the same-profile Fenn/Neri and synthetic side conversations; independent source review and7 tests/613 assertions pass. Actual paired identity/panel review is still required; see stormwood/fixes/P2-082/candidate-review.md. The further disabled articulated-trunk/platform candidate at417739037 landed through PR424. Clean geometry11/188 and mounted-scene4/0 checks plus22 native frames and14 eligible pairs verify the candidate and actual raised-deck coverage. Fresh blind review prefers its constructed routes, but crown/core/arena presentation still fails the complete landmark: scoped Bar A YES / Bar B NO. It remains off; this does not close the chapter bars. See stormwood/fixes/P2-037/ancient-pair-verdict.md.

**The board is the source of truth.**
- **Meadows Phase 2c crafting:** P2-095 and P2-096 have a scoped independent blind PASS at three 1080p realm views and four 720p Meadows stress states. The enabled crafting UI and focused current-main controller checks are in `54b189254`; evidence is `ralph/reports/VISUAL/phase2/meadows/fixes/P2-095/accepted-ui-comparison/`. Their catalog rows are fixed for the stated UI defects. Regional Bars A/B and the rest of the Meadows catalog remain open. This checkout does not contain the board files referenced below; restore the existing board source on main and record these two IDs there rather than treating this STATE note as a replacement board.
- `ralph/reports/COORDINATOR/dashboard/criteria.json` holds every criterion and card, with its evidence and gap.
- `status.json` holds the batches, the lane FINAL SHAs and the **`wip` list**. The `wip` list is the authoritative pickup list for unfinished work: each item says where the work is and the next step.
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
| T2 | Failing (Cards lane re-score). Islands, loops, shortcuts, pockets, six chains, four-character ledgers, currents/docks/Veilfall on function and restoration are met. Device profile FAILS at 7 inches (`ralph/reports/CARDS/t2_device/`): current direction unreadable (owner: Tidewake lane) and small HUD text illegible (owner: HUD, with F10#6). Tess and Nerissa C3 (F14#0/#1) wait on contact spacing. |

**Open criteria (10):**
- **Meadows:** F04#1, #2, #6, #7. F01#2 and F01#3 are met (`ralph/reports/MEADOWS/f01-walks/day_d41ff2f0`, `night_d41ff2f0`, `RECHECK_F01_2.md`, `RECHECK_F01_3.md`: the controller day and night walks reach all 11 targets; code-blind PASS on the gates, the lived-in camp and the key, which hangs glowing on its post at night). F04#3 is met (`ralph/reports/MEADOWS/f04/RECHECK_F04_3.md`: the Warden's HEAVY question reads at the normal camera; victory lines frame him clear with the HUD down). F03#0 is met (`ralph/reports/MEADOWS/f03/`: six ordinary-input lure walks to each prompt, the herd's night fire, the Hall pack on a road sightline with its nameplate depth-tested; strict re-check MET).
  - In progress on `tb/meadows`: for F04, wilds are kept off the named grounds, a widened CHARGER opening now stops short of geometry, and the victory shots clear the fallen ace and stand the ally behind the lens. Captains strike their standards, stand down and hand over their sigils; the Warden shows the key and heart. Judge r4 (`ralph/reports/MEADOWS/f04/JUDGE_r4_7121d40c.md`): each captain's Sigil now shows its own emblem beside them, the Warden's Heart reads, the victory shot stays within 6 m of a far speaker, and a CHARGER's or DIVER's wind-up names its question on the HUD; aftermath re-renders are running (F04#6). F04#2 and F04#7 C3 wait on `tb/combat-spacing` (coordinator, 2026-09-28: that lane owns contact-range separation; the ally covering the foe and the lane under touching bodies are its defects).
  - Other defect, not this lane's: `smoke_party_strip_reflow` fails before this lane's changes and is not in CI (owner: HUD).
- **Cards lane done** (`tb/cards`, 2026-09-28): M1 complete (#435). M2 is blocked (see the card table; re-run it once the Meadows lane fixes the bridge and chooses a heal-and-retry aid or a reader pilot). T2 and S2 notes are current. The earned relay harness now reads the relay captain's victory lines. **Paused by the coordinator until the Meadows bridge fix merges** (no runs are active; do not poll). Restart, once on the merged main commit: `TB_WORLD_SEED=15 godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --route-ledger --m4-finale --through-meadows --resume-from=user://four_biome_checkpoints/relay_disabled_and_mill_crossed_19623` (the relay checkpoint on the seed-15 save; it exists only in the Cards container, so on a fresh container start from the title without `--resume-from`).
  - Defects found, not fixed here: the bridge guardian regression (Meadows lane, 3f04ece8); Keeper Hald beats the earned-route pilot 0/3 after b20d23ab (Meadows lane / Balance, F04#7); Tidewake current flow direction unreadable at 7 inches (Tidewake lane); small HUD text (clock, hotbar numbers, key glyphs, FOOD label) illegible at 7 inches (HUD owner); no `assets/audio/stormwood/` files, so the Surge phases are silent (owner decision: audio assets, no placeholders allowed).
- **Cloudreach lane done** (2026-09-28): complete for Phase 1 (every row and card C1-C3 met), and the owned-carrier Fly debt is closed (#411). F08#3 (`ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/`) and F08#4 (`f08-4-settlements/`) closed on function; their Bars A/B clauses → Phase 2 catalog. F08#4 changed the game: working residents at Galefoot and Cliffhold, Cliffhold's settlement ambience on Cliffhold, and the Broken Causeways crown carved down to the causeway climb (it ran inside the crown). Owned-carrier Fly closed (`ralph/reports/CLOUDREACH/owned-carrier-fly/`): the five's healthy active carrier flies (WORLD §4.2), and the Galewisp starter gains Fly at the unlock (CREATURES §7). Maela's loaner serves her trial and, after the unlock, only a five with no healthy carrier, until the chapter ends. A five whose healthy carrier is not out gets a refusal naming it; an unwell carrier keeps the loaner's safety net. The carrier's ground follower is recalled for the flight, and LB/recall wait for touchdown. Earned c1_arrival flight leg on an owned Galecrest (disclosed swap): the trial flew on the loaner, one refusal, 4 owned launches, party 5. Open: Cliffhold reads thin (Phase 2).
- **Stormwood:** F10#6; card S1 complete. F10#2 met: C2 by Balance #413, C3 on the current fight camera (`STORMWOOD/f10_2/c3_p1/`, code-blind all six PASS, strict re-check MET). F10#6 (`STORMWOOD/f10_6/` r2–r5): the combat HUD meets the `hud_scale.gd` floors, the target plate sits top-right and fight panels fade over a covered subject, but UX §1.4 still fails where the left fight column covers the trainer and attack lanes; r4's pass was withdrawn (its prompt exempted the trainer); identical explore frames read legible in r4 and illegible in r5. Next: a compact fight column. F10#3/#4 and F09#3 met (`f10_3/r6/`, `f10_4/r7/`, `f09_3_r8/`).
- **Tidewake:** F14#0 and F14#1 are open; T2 waits on both, and on its device Q1 (current direction at 7 inches, below).
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
  - **Blocked** on the shared contact-spacing rule, now owned by the COMBAT SPACING lane (`tb/combat-spacing`, coordinator 16:28). When it lands on main, Tidewake merges it and re-judges Tess and Nerissa C3 under `C3_RUBRIC.md`. This lane builds no spacing fix of its own.
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

**Switched off or unwired in batch 67.** This is unjudged visual work, landed as the wind-down rule requires. Flip each item on only after a code-blind Bars A/B pass.
- `stormwood_glass_field.json` `scorched_scars=false`.
- `camera.body_clear.ignore_lunging_foe` and the Vance move are re-applied on `tb/meadows` (F04#1).
- The Meadows camp firepit is back on and judged on function (F01#2 code-blind PASS); its Bars A/B read → Phase 2 catalog.

**Reverted in batch 67.** Stormwood-B's F10#2 C3 commits `07bc9cad`, `45927814` and `85ba1c57` (the Elder cone and heading, and the guard cone) are reverted. Re-apply them when F10#2's C3 is re-captured.

**Branches.** Batch 67 took every branch head, older branches included. Where an older branch conflicted with newer landed work, the newer work won: Venn's move without the fight pad, Stormwood's judged r5 lightning, and the cleaned docs. Codex's doc edits were not taken; their facts are in ART_DIRECTION §7 and `ralph/reports/VISUAL/AUDIT.md`. Codex's unjudged Cloudreach towers and occupied terrace are merged but flagged off.

**To resume work:**
1. Pick an item from the `wip` list or an open criterion.
2. Work on a `tb/<lane>` branch from current main, following WORKFLOW §8 and `CLAUDE_START_HERE.md`.
3. Land each closed criterion through the lane's own PR (re-check, unit suite once, board and STATE, auto-merge). There is no coordinator and no channel.

**Open lanes (2026-09-28).** Three Phase 1 biome lanes (`tb/meadows`, `tb/tidewake`, `tb/stormwood`; `CLAUDE_START_HERE.md`; the Cloudreach lane is done) and one Codex capture-and-catalog lane (`tb/x04-capture`; `CODEX_START_HERE.md` §2a–2b). The Balance lane lands the F04#7 and F10#2 C2 halves through PR #413, then stops; the C3 halves stay with the Meadows and Stormwood lanes.

**Not covered by the open lanes; do these after:**
1. **Biome reorder (Phase 1b).** Once all four biome lanes are complete, start one lane on `CLAUDE_START_HERE.md` §6: order Meadows → Tidewake → Cloudreach → Stormwood, gates and keys, levels, ending after Stormwood, swim-before-Fly, ledgers, regenerated checkpoint saves, and save migration. Nothing outside Cloudreach requires Fly (Tidewake's water seals and Stormwood's canopy only register no-fly volumes). Old-order assumptions to fix in the reorder:
   - `scripts/save/realm_reward_migration.gd` retargets a Cloudreach-awarded `realm_key_water` to Stormwood whenever `cloudreach_chapter_complete` is set. In the new order Tidewake's water key comes first, so this must not rewrite it.
   - `data/config/water_crafting.json` skill candies offer "Flying" in Tidewake, before Fly exists in the new order.
   - Stale old-order notes: `tools/net/proof_scenarios/x05_f13_5_no_swimmer_reach.json` and `tools/gate_f/capture_four_biome_road_creatures.gd` (its Cloudreach → Stormwood → Water flag list).
2. **Four-chapter earned run** in the new order, then a **human play pass** per chapter.
3. **Codex Phase 2c.** Four biome fix lanes (`CODEX_START_HERE.md` §2c), started after the reorder. Re-shoot the top catalog items first, since the baseline catalog predates Phase 1 and the reorder. Each biome closes with a regional Bars A/B verdict, which clears the `Bars A/B → Phase 2` notes. Known items: aerie art, the Stormheart tree, the waterfall, the Glass Field (flag off), the Pump Hall (machinery placed; room identity WEAK), and the Cloudreach towers and terrace (off).
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

**Final step (owner, 2026-09-27).** After all 13 cards pass and the reorder has landed, make one checkpointed four-chapter earned run on one save, from a new game through the last chapter (`smoke_four_biome_continuous`). It retires the chapter-boundary fixture debt. Harness-input debt needs a short human play pass per chapter.

### Open owner decisions

1. **Internet co-op resources:** a real Steam AppID with Steamworks partner access, and four Steam accounts, two or more on separate home networks, for the internet co-op proof. `steam_api64.dll` redistribution is approved. Packaging (`ship_steam_runtime`) stays off until an AppID exists.
2. **Four decisions made by the owner at 23:55 and now in implementation (batch 68):** F04#7 difficulty (the Meadows named trainers get harder), F10#2 (starter parity), female officer Vess, and aerie art. See ruling 11 below.
   - **Balance lane:** F10#2 and F04#7 C2 halves met (ruling 12; `ralph/reports/BALANCE/`). C3 halves stay open.

**Settled by the owner (2026-09-27, 23:55):** the Capacitor Alpha no-stagger ruling and the storm strike sparing a trainer in a fight are **kept**. They are no longer interim.

## 1. Rulings in force

**Owner and coordinator, 2026-09-27.** Nothing may contradict these.
1. **Counting and proofs.** Criteria count at merge; the full CI after a batch is a safety net. Relaxed proofs are allowed if disclosed: fixture or declared starts, teleports, flag and party writes, harness fights, and skipped sub-parts (ACCEPTANCE §6.1, WORKFLOW §8). Earned checkpoints are allowed starts. Held Fly input is lawful; the tap pulse is optional.
2. **Solmane.** Solmane is Cloudreach's freed legendary, handled like Meadows' Veridian. It is freed after Veyra, and each participant gets a once-only offer. It is never wild or catchable, and the summit wild tables use tempestwing. This is **implemented** (F08#5 met; C3 rerun passed).
3. **Device profile.** A computer capture at 1920×1080 on Compatibility/`opengl3`, judged code-blind for 7-inch readability. No Ally hardware (#356 5857144944; ACCEPTANCE §6.1).
4. **Visual bar.** The full visual bar (Bars A/B) applies to every visual row. "Beauty matters." **Updated by the owner (2026-09-28):** in Phase 1 (`CLAUDE_START_HERE.md`), a mixed row closes on its functional and readability clauses, and its Bars A/B clause moves to the Phase 2 Codex catalog (`CODEX_START_HERE.md`), which closes it with a regional Bars A/B verdict.
5. **Build the game, not proof machinery.** Every round is player-visible. The two-strike harness rule applies, and each READY/FINAL post carries a `Balance: game N / tests-tools M` line (WORKFLOW §8).
6. **Return route.** The homeward return after Tidewake is exempt from A7 (T3/F15).
7. **Art split.** Claude lanes may do scene-level art from installed asset families: kitbash, materials, shaders, lighting and dressing. New meshes and Meshy work stay with Codex. This partly supersedes the 2026-09-26 "all art to Codex" ruling.
8. **Capacitor Alpha** does not stagger during the route cue (F10#2 option a). Kept by the owner. A Stormwood storm strike spares a trainer whose creature is in a fight (`stormwood_surge.json` `strike.spare_trainer_in_fight=true`). Also kept by the owner.
9. **Process.**
   - Every branch uses the `tb/` prefix, with one reused `tb/<lane>` branch per lane and no lane PRs.
   - Lanes land their own work through their own PR, with a re-check and the unit suite once (owner, 2026-09-28). There is no coordinator and no lane channel.
   - **Wind-down:** lanes finish and push everything, work in progress included, and unjudged visual work in progress lands behind a config flag that defaults to off, or unwired. The coordinator consolidates, then runs the unit tests once and CI once.
   - READY means a criterion fully closes, with an attached strict re-check, one criterion at a time. Codex-queue IDs are lane-prefixed and append-only.
10. **F04 split.** Meadows core had F04#0, #1 and #7; Meadows F04 bosses had F04#2, #3 and #6. Both lanes are wound down. The F04 bosses round-1 evidence is `ralph/reports/MEADOWS/f04_bosses/r1/`.
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
- The Team Tether palette stays as built. This is an explicit exception to the oxblood wording; audit H2/H3 and the red parts of M7 are closed.
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

- Tetherbound is a four-chapter creature expedition action RPG in this pass: solo or required 1–4 co-op, at most five owned companions, and directly piloted real-time fights. Camps support the journeys, and the pass ends in a regional victory and homecoming in Tidewake. Eight good hours can ship, with no 12–16-hour floor. Eight biomes remain the longer-term plan.
- Keeping the same beloved five through the ending is success. Later rewards deepen that team, and new catches are optional. The Water critical path must not require an owned swimmer.
- Keep mechanics testing minimal: use a short existing-loop check before adding proposed systems. L4 skill, normalized poise, revised bond and Strain are parked (ACCEPTANCE §3).
- There is no new investment: coding plus existing tools and assets, including the held Meshy licence. Agents may draft reference art and submit scoped Meshy work (AGENTS art rule; ART_DIRECTION §7).
- Co-op is required through invitation, with no router setup or typed address. LAN or direct-IP alone is insufficient for release.
- The owner's earlier answer, "personal / friends — I just want it good", stands. PRODUCT's price and positioning are a plan, not permission to publish or spend. A commercial launch is a separate owner decision.
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

- **Wayfinding.** A straight-corridor feel is the owner's highest-impact complaint. Beacon and map reveals landed; judge geography and voluntary detours on whole-path evidence, not a beam.
- **Fixture debt.** Most met criteria used disclosed fixtures, teleports or harness fights. The final four-chapter earned run and short human play passes retire that debt; do not claim fresh-play proof from them.
- **Shared-fight geometry.** The proxy-body divergence behind a guest's non-landing blow is fixed at root (`tests/test_remote_proxy_snap.gd`; MEADOWS-PAYOFFS/proxy-ground-plane). Re-check guest-hit smokes after any follow or collision change.
- **Legacy receipts.** Legacy peer-ID receipts are ambiguous and are not recovered automatically. A corrupt legacy save must stay inspectable and never mutate the live run.
- **Steam packaging.** The rolling Windows download has no GodotSteam runtime until an AppID exists, so invitation co-op cannot work in it yet. ENet teardown may log a harmless native error on a simultaneous two-client disconnect.
- **Visual verdicts.** Software-GL captures are trustworthy for composition, scale and colour, not fine lighting or performance. Two rounds with no movement mean change the asset or the approach, not the tint (ART_DIRECTION §9).
- **Accepted art dispositions.** The camp set, pickups, South Bridge gate and lost rigs keep their ART_DIRECTION §7 dispositions unless gameplay evidence reopens them.
- **Owner reports.** A fresh owner reproduction reopens any item a ledger calls fixed. Check which build the owner played first.

## 5. Dependencies and still-open design questions

- **Owner resources:** the Steam AppID and partner access, and the four accounts (§0).
- **Meshy:** Meshy runs through Codex on the owner's machine. Claude sessions hold no key.
- **Design questions** (keep current behaviour conservatively until settled):
  - the wild defeat persistence policy;
  - which replacement subjects the reference/Meshy workflow takes;
  - a Burrowback contrast treatment that keeps its identity;
  - a grass clump redesign beyond the approved settings.
- **Targets to validate, not blanks:** the ACCEPTANCE §7 release performance numbers on Ally hardware, when the owner provides hardware; fair late-catch bond; shared encounter scaling. A failure triggers retuning, not a quietly relaxed bar.

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
- **Usage guardrail:** check seven-day remaining usage between batches. Below 20%, stop starting work and wind down. Stop before 10%, and never consume a reset automatically.
- Record new owner feedback here; it outranks every other document for what it covers.
