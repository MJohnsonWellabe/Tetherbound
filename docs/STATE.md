# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Resume here

**Resume:** 2026-09-25..27 lanes wound down (owner, 2026-09-27 22:30), pushing all WIP. Batch 67 consolidated every branch, Codex/Vess included, on `tb/integration`; landed via one PR/unit/CI run. Phase 1: self-landing biome lanes (`CLAUDE_START_HERE.md`). Verify batch 67 on main (`git merge-base --is-ancestor <sha> origin/main`); otherwise land it.

**Criteria:** 94 of the 101 ACCEPTANCE §6.1 criteria are met (batch 67 plus Stormwood F09#3, F10#3 and F10#4, Cloudreach F08#3 and F08#4, Tidewake F13#3 and F13#5, Meadows F03#0, F04#3, F01#2 and F01#3, Stormwood F10#2). No chapter is accepted.

**Stormwood Phase 2c is active** on `tb/x04-stormwood`. P2-042 is fixed by `1ed0259e5`: fresh native/small-size blind review passes all four phases at both original catalog stands and readability preservation. The accepted presentation is enabled; actual enabled surge suites pass 55 tests / 762 assertions. Regional Bars A/B remain NO because character, Stormheart landmark and landscape gaps remain. P2-037 native paired review confirms grounded wall seams, but the full landmark and Bars A/B still fail on cylindrical form, sparse crown and construction detail; its candidate remains off. A separately disabled canopy-atlas correction preserves the installed leaf mask; six native pairs show a small distant contrast gain with flatter cutout foliage, unchanged near views and Bars A/B NO/NO. It remains off. P2-084 has a separately disabled eleven-opening NPC candidate with source review and existing NPC checks passing; panel acceptance remains open. The current 78-frame landmark baseline establishes P2-041 as an open visible defect. P2-043 native comparison is partial: improved obstruction but weak scar integration and lost glass identity; its candidate stays off. P2-045 candy tiers, P2-081 trainer dialogue and P2-110 roster-vitals refresh remain disabled pending complete native review. P2-092 is `deferred` to the `tb/stormwood` gameplay lane for collision/contact/lunge separation; P2-111 identifies persistent quick bindings rather than reward tiles. Evidence and remaining work are in `ralph/reports/VISUAL/phase2/stormwood/fixes/` and `phase2/catalog.csv`. The disabled branching-crown geometry candidate passes 7 tests / 166 assertions and source review. Fourteen native pairs confirm stronger distant tree recognition, but crude joins, pale fragmented canopy and the full landmark still fail; Bars A/B remain NO/NO. Ground-level interior pairs do not prove upper-arena visibility. The current chapter environment batch has 30 verified native1920 frames, three compact pages and ten reviewed derived720 stress views. Fresh blind Bars A/B are NO/NO for creature material/readability, landscape depth and Stormheart architecture. Ordinary combat/HUD, adequate key-settlement coverage and complete chapter acceptance remain open; see stormwood/fixes/chapter-matrix/. No regional completion or Phase 1 criterion closure is claimed. P2-082 has a separately disabled installed-portrait mapping candidate covering nine catalogued speakers plus the same-profile Fenn/Neri and synthetic side conversations; independent source review and7 tests/613 assertions pass. Actual paired identity/panel review is still required; see stormwood/fixes/P2-082/candidate-review.md. The further disabled articulated-trunk/platform candidate at417739037 landed through PR424. Clean geometry11/188 and mounted-scene4/0 checks plus22 native frames and14 eligible pairs verify the candidate and actual raised-deck coverage. Fresh blind review prefers its constructed routes, but crown/core/arena presentation still fails the complete landmark: scoped Bar A YES / Bar B NO. It remains off; this does not close the chapter bars. See stormwood/fixes/P2-037/ancient-pair-verdict.md.

**The board is the source of truth.**

**Tidewake Phase 2c active**, `tb/x04-tidewake`. P2-032 fixed/enabled `8c5009e09`:24native frames at `0930716ac`, independent PASS, tests8/36. Evidence: `ralph/reports/VISUAL/phase2/tidewake/fixes/`. P2-008 dunes-05/colony-06 rejected, Bars No/No; fuller colony-08 off at `ef9df4c12`, actualmesh47checks and focused34tests/87990assertions pass; native pending. Noise03 rules out noise as necessary for Gull teeth; maskspace04 unapplied after CPU coverage expansion. Geometry deferred to Tidewake Phase1 world/route (historical tb/tidewake-b/F13; no live ID). Full units at `1f3e6397e`:5307tests/3961736assertions/0failed,647files; retained diagnostics, predates later changes. P2-103 off; recorder12/63 pass, capped Venn correctly rejected; win pairs pending. P2-029 off;44/709 pass; native01/02 rejected,02 isolates one-float-step camera drift. Chapter matrix, regional acceptance, owned dispositions and CI landings remain open.

- `ralph/reports/COORDINATOR/dashboard/criteria.json` holds every criterion and card, with its evidence and gap.
- `status.json` holds batches, lane FINAL SHAs and the authoritative **`wip` pickup list**, with each unfinished item's location and next step.
- `ralph/reports/COORDINATOR/README.md` gives the scoring rule and how to rebuild and republish the board.

**Chapter cards** (ACCEPTANCE §6):

| Card | State |
|---|---|
| M4, C1, T3, S3, T1, S1 | **Complete.** M4, C1 and T3 in batches 59, 65 and 67. S3 and T1 had their integrated runs in batch 63 and all feeders (F11, F12) met, and are recorded as complete in batch 67. S1 (Stormwood Phase 1 landing): the integrated chapter run re-run after F09#3 landed passes with its reload at 0068c542, strict re-check MET (`ralph/reports/STORMWOOD/s1/`). |
| M1 | Feeders met: F01#2 and F01#3 (day and night walks, code-blind PASS). The card's integrated run is next. |
| M2, S2 | Partial. M2 needs the Hall-exit ruling below; S2 needs F10#6 (F10#2 met). |
| C2, C3 | **Complete (Cloudreach Phase 1 landing).** C2: earned chapter run (longest travel gap 98 s, same five, no new catch) plus the six-activities witness, frame matrix by the F08#3/#4 code-blind verdicts; C3: two-peer co-op and Solmane aftermath, ALL CHECKS PASSED. Evidence `ralph/reports/CLOUDREACH/c2-card/`, `c3-card/`. |
| M3 | Failing: named-fight framing and Bars A/B. |
| T2 | Failing: waits on F14#0 and F14#1 (F13#3 and F13#5 met on function; Aquaryn and Tidecoil C3 pass; Tess and Nerissa C3 are blocked on contact-range occlusion). |

**Open criteria (10):**
- **Meadows:** F04#1, #2, #6, #7. F01#2 and F01#3 are met (`ralph/reports/MEADOWS/f01-walks/day_d41ff2f0`, `night_d41ff2f0`, `RECHECK_F01_2.md`, `RECHECK_F01_3.md`: the controller day and night walks reach all 11 targets; code-blind PASS on the gates, the lived-in camp and the key, which hangs glowing on its post at night). F04#3 is met (`ralph/reports/MEADOWS/f04/RECHECK_F04_3.md`: the Warden's HEAVY question reads at the normal camera; victory lines frame him clear with the HUD down). F03#0 is met (`ralph/reports/MEADOWS/f03/`: six ordinary-input lure walks to each prompt, the herd's night fire, the Hall pack on a road sightline with its nameplate depth-tested; strict re-check MET).
  - In progress on `tb/meadows`: for F04, wilds are kept off the named grounds, a widened CHARGER opening now stops short of geometry, and the victory shots clear the fallen ace and stand the ally behind the lens. Captains strike their standards, stand down and hand over their sigils; the Warden shows the key and heart. Judge r4 (`ralph/reports/MEADOWS/f04/JUDGE_r4_7121d40c.md`): each captain's Sigil now shows its own emblem beside them, the Warden's Heart reads, the victory shot stays within 6 m of a far speaker, and a CHARGER's or DIVER's wind-up names its question on the HUD; aftermath re-renders are running (F04#6). F04#2 and F04#7 C3 wait on `tb/combat-spacing` (coordinator, 2026-09-28: that lane owns contact-range separation; the ally covering the foe and the lane under touching bodies are its defects).
  - Other defect, not this lane's: `smoke_party_strip_reflow` fails before this lane's changes and is not in CI (owner: HUD).
- **Cloudreach lane done** (2026-09-28): complete for Phase 1 (every row and card C1-C3 met), and the owned-carrier Fly debt is closed (#411). F08#3 (`ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/`) and F08#4 (`f08-4-settlements/`) closed on function; their Bars A/B clauses → Phase 2 catalog. F08#4 changed the game: working residents at Galefoot and Cliffhold, Cliffhold's settlement ambience on Cliffhold, and the Broken Causeways crown carved down to the causeway climb (it ran inside the crown). Owned-carrier Fly closed (`ralph/reports/CLOUDREACH/owned-carrier-fly/`): the five's healthy active carrier flies (WORLD §4.2), and the Galewisp starter gains Fly at the unlock (CREATURES §7). Maela's loaner serves her trial and, after the unlock, only a five with no healthy carrier, until the chapter ends. A five whose healthy carrier is not out gets a refusal naming it; an unwell carrier keeps the loaner's safety net. The carrier's ground follower is recalled for the flight, and LB/recall wait for touchdown. Earned c1_arrival flight leg on an owned Galecrest (disclosed swap): the trial flew on the loaner, one refusal, 4 owned launches, party 5. Open: Cliffhold reads thin (Phase 2).
- **Stormwood:** F10#6; card S1 complete. F10#2 met: C2 by Balance #413, C3 on the current fight camera (`STORMWOOD/f10_2/c3_p1/`, code-blind all six PASS, strict re-check MET). F10#6 (`STORMWOOD/f10_6/` r2–r5): the combat HUD meets the `hud_scale.gd` floors, the target plate sits top-right and fight panels fade over a covered subject, but UX §1.4 still fails where the left fight column covers the trainer and attack lanes; r4's pass was withdrawn (its prompt exempted the trainer); identical explore frames read legible in r4 and illegible in r5. Next: a compact fight column. F10#3/#4 and F09#3 met (`f10_3/r6/`, `f10_4/r7/`, `f09_3_r8/`).
- **Tidewake:** F14#0 and F14#1 are open; T2 waits on both.
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
  - **Landed as progress:** the Heart Chamber arena bound, the tell and head camera swings, and Riptusk's lunge opt-in. All are presentation-only, apart from the smaller ring.
  - **C2 met for both rows under option (c) (main 1e0ddd39).**
    - Tess, Calder and Venn: reader win 1.00, masher lead-faint 1.00. Venn's lane now locks at 0.25 of the tell.
    - Nerissa at the 9 m ring: 144 in-world fights, reader win 1.00 x3, party cost 0.13-0.24.
    - Aquaryn and Tidecoil pass under the named-wild ruling.
  - **Card T2's non-fight clauses** belong to the CARDS lane (`tb/cards`, coordinator 18:13): islands, loops, shortcuts, pockets, activities, currents and docks, ledgers, and the device profile.
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

**Open lanes (2026-09-28).** Phase 1: `tb/meadows`, `tb/tidewake`, `tb/stormwood` (`CLAUDE_START_HERE.md`); Cloudreach done. Capture/catalog: `tb/x04-capture` (`CODEX_START_HERE.md` §2a–2b). Balance lands F04#7/F10#2 C2 via #413, then stops; Meadows/Stormwood keep C3.

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
   - **Balance lane:** F10#2 and F04#7 C2 halves met (ruling 12; `ralph/reports/BALANCE/`). C3 halves stay open.

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
- **Usage guardrail:** check seven-day remaining usage between batches. Below 20%, stop starting work and wind down. Stop before 10%, and never consume a reset automatically.
- Record owner feedback here; it overrides other documents on its subject.
