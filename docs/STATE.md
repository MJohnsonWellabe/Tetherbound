# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Resume here

**Resume:** 2026-09-25..27 lanes wound down (owner, 2026-09-27 22:30), pushing all WIP. Batch 67 consolidated every branch, Codex/Vess included, on `tb/integration`; landed via one PR/unit/CI run. Phase 1: self-landing biome lanes (`CLAUDE_START_HERE.md`). Verify batch 67 on main (`git merge-base --is-ancestor <sha> origin/main`); otherwise land it.

**Criteria:** 91/101 ACCEPTANCE §6.1 met: batch 67 plus Meadows F03#0/F04#3, Stormwood F09#3/F10#3/F10#4, Cloudreach F08#3/F08#4, Tidewake F13#3/F13#5. No chapter accepted.

**Stormwood Phase 2c active**, `tb/x04-stormwood`. P2-042 fixed/enabled by `1ed0259e5`: native/small-size blind PASS, all four phases at both catalog stands, readability preserved; enabled surge tests 55/762. Regional Bars A/B NO: character, Stormheart and landscape gaps. P2-037 paired review confirms grounded seams, but cylindrical form, sparse crown and construction detail still fail landmark/Bars A/B; off. Separately off canopy-atlas correction preserves the installed leaf mask: six native pairs show slight distant contrast gain, flatter cutouts, unchanged near views, Bars A/B NO/NO. P2-084 eleven-opening NPC candidate stays off; source review/existing NPC checks pass, panel acceptance open. The 78-frame landmark baseline confirms P2-041 open. P2-043 partial (less obstruction, weak scar integration, lost glass identity); off. P2-045 candy tiers, P2-081 dialogue and P2-110 roster vitals stay off pending complete native review. P2-092 `deferred` to `tb/stormwood` gameplay for collision/contact/lunge separation; P2-111 identifies persistent quick bindings, not rewards. Evidence/work: `ralph/reports/VISUAL/phase2/stormwood/fixes/`, `phase2/catalog.csv`. No regional completion or Phase 1 closure.

**The board is the source of truth.**

**Tidewake Phase 2d first-item review**, `tb/x04-tidewake`. P2-032 fixed/enabled `8c5009e09`: 24 native frames at `0930716ac`, independent PASS, tests 8/36. P2-008 shore profile/sand/grass is enabled and ready for owner review: eight final native before/after pairs at `.artifacts/phase2/P2-008-phase2d-before-after.html`; scoped defect self-review PASS, supplied-photo match PARTIAL, full Bars A/B NO/NO. Physical shore rebake has 31 matched regions; encounter elevations regrounded; Brine loop and encounter scene smokes pass. The full report is `ralph/reports/VISUAL/phase2/tidewake/fixes/P2-008/phase2d-shore-profile-review.md`. P2-008 stays open until owner judgment; do not work the rest of the visual queue yet. Older colony-08-only review at `fixes/P2-008/colony-08/phase2d-native-review.md` is historical partial evidence. P2-103 off; recorder 12/63 pass, capped Venn correctly rejected; win pairs pending. P2-029 off; 44/709 pass; native01/02 rejected,02 isolates one-float-step camera drift. Chapter matrix, regional acceptance, owned dispositions and CI landings remain open.

- `ralph/reports/COORDINATOR/dashboard/criteria.json` holds every criterion and card, with its evidence and gap.
- `status.json` holds batches, lane FINAL SHAs and the authoritative **`wip` pickup list**, with each unfinished item's location and next step.
- `ralph/reports/COORDINATOR/README.md` gives the scoring rule and how to rebuild and republish the board.

**Chapter cards** (ACCEPTANCE §6):

| Card | State |
|---|---|
| M4, C1, T3, S3, T1 | **Complete.** M4/C1/T3: batches 59/65/67. S3/T1: batch 63 integrated runs, F11/F12 feeders met, recorded complete in batch 67. |
| S1 | Integrated run passed (batch 64); F09#3 is met, so every feeder is met. |
| M1 | In progress: F01#2/#3 day and night walks need a render and a judge. |
| M2, S2 | Partial. M2 needs the Hall-exit ruling below; S2 needs F10#2/#6. |
| C2, C3 | **Complete (Cloudreach Phase 1).** C2: earned run (98 s maximum gap, same five, no catch), six activities, F08#3/#4 code-blind frame verdicts. C3: two-peer co-op/Solmane aftermath, ALL CHECKS PASSED. `ralph/reports/CLOUDREACH/c2-card/`, `c3-card/`. |
| M3 | Failing: named-fight framing and Bars A/B. |
| T2 | Failing: waits on F14#0 and F14#1 (F13#3 and F13#5 met on function; Aquaryn and Tidecoil C3 pass; Tess and Nerissa C3 are blocked on contact-range occlusion). |

**Open criteria (10):**
- **Meadows:** F01#2, F01#3; F04#1, #2, #6, #7. F04#3 is met (`ralph/reports/MEADOWS/f04/RECHECK_F04_3.md`: the Warden's HEAVY question reads at the normal camera; victory lines frame him clear with the HUD down). F03#0 is met (`ralph/reports/MEADOWS/f03/`: six ordinary-input lure walks to each prompt, the herd's night fire, the Hall pack on a road sightline with its nameplate depth-tested; strict re-check MET).
  - `tb/meadows` WIP: F01 practice camp (fire/tent/bedroll), arrival-clear beacon. F04: wilds excluded from named grounds; wider CHARGER opening stops before geometry; victory shots clear fallen ace, ally behind lens. Captains strike standards, stand down, give sigils; Warden shows key/heart.
  - Other defect, not this lane's: `smoke_party_strip_reflow` fails before this lane's changes and is not in CI (owner: HUD).
- **Cloudreach lane done** (2026-09-28): Phase 1 rows/C1-C3 met; owned-carrier Fly closed (#411). F08#3 (`ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/`) and F08#4 (`f08-4-settlements/`) met on function; Bars A/B → Phase 2. F08#4 adds Galefoot/Cliffhold workers, Cliffhold ambience and a Broken Causeways crown cut to expose the climb formerly inside it. Fly proof (`ralph/reports/CLOUDREACH/owned-carrier-fly/`): the five's healthy active carrier flies (WORLD §4.2); Galewisp gains Fly at unlock (CREATURES §7). Maela's loaner serves the trial, then only a five without a healthy carrier until chapter end. A healthy inactive carrier prompts a named refusal; an unwell carrier retains the loaner safety net. Flight recalls its ground follower; LB/recall wait for touchdown. Earned c1_arrival used owned Galecrest (disclosed swap): loaner trial, one refusal, 4 owned launches, party 5. Open: thin Cliffhold (Phase 2).
- **Stormwood:** F10#2, #6. F10#4 met (`ralph/reports/STORMWOOD/f10_4/r7/`: denser Deepwood reads as deep forest at every judged stand). F10#3 met (`ralph/reports/STORMWOOD/f10_3/r6/`: Break-only crawler lightning named from a single still). F09#3 met (`ralph/reports/STORMWOOD/f09_3_r8/`: loops, shortcuts and alternate road walked 72/0, pockets 102/0).
- **Tidewake:** F14#0 and F14#1 are open; T2 waits on both.
  - F13#3 and F13#5 are met (`ralph/reports/TIDEWAKE/phase1/f13_3/`, `f13_5/`).
  - **C3 rubric**, fixed before judging: `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`; both code-blind judges must score ≥90% each round.
  - **Passed:** ordinary-route Aquaryn r6 100%/100%; Tidecoil r12 100%/91.7%; Aquaryn C2, all three starters under named-wild ruling.
  - **Open:** ordinary-route Tess r5 97%/84% (r4 ~86% strict); Nerissa r17 98%/83%. Both retain post-strike body overlap: ally occludes foe head; camera cannot separate touching bodies. **Blocked** on shared combat contact spacing, affecting C2 balance and other lanes' named fights.
  - **Landed progress:** Heart Chamber arena bound, tell/head camera swings, Riptusk lunge opt-in; presentation-only except smaller ring.
  - **Rerun Nerissa's 144-fight in-world C2** for the new 9 m ring. Local READER 5/5 wins, 24-33% party cost; MASHER wipes.
  - **Unfixed:** move panel disappears during "it missed you"/"it's open"; ordinary tell ring marks attacker feet, not landing spot.

**Batch 67 unjudged visuals:** off/unwired under the wind-down rule; enable only after code-blind Bars A/B PASS.
- `stormwood_glass_field.json` `scorched_scars=false`.
- `camera.body_clear.ignore_lunging_foe` and the Vance move are re-applied on `tb/meadows` (F04#1).
- The Meadows camp firepit is re-applied on `tb/meadows` (F01#2/#3).

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
| Stormwood | Earned six-region route, Arches, Dynamo, Stormheart and aftermath. F09 and F11 are met; the S1 and S3 runs passed. | Named-fight C3 (F10#2), device profile (F10#6). Open risk (owner: Stormwood lane): the denser Deepwood bake (3d5fb0e6) has no perf measurement. Phase 2: aftermath under the canopy is brighter than the owner's 'only lighter rain, no lightning, scars' ruling. Findings (owner: Stormwood lane, after S2): pools_west_loop runs through the lit b_pools arch; a 1.11 m curb on b2's (verge_road footing) landing side; a 0.4–0.67 m step behind d_giant. |
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
