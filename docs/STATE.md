# State — live status against the release plan

Read this first. Update it in place and keep it under 25KB. No dated status, goal, directive or handoff documents. Evidence lives in `ralph/reports/<LANE>/`; history lives in Git and `archive/`.

## 0. Resume here

**Where the game is.** All lanes of the 2026-09-25..27 concurrent run are wound down (owner, 2026-09-27 22:30). Each lane pushed everything, including work in progress. Batch 67 consolidated every lane head and every remaining branch, including the full Codex branch and Vess, onto `tb/integration`, and landed it through one PR after one unit run and one CI run. **Next is Phase 1 (`CLAUDE_START_HERE.md`):** one self-landing lane per biome. **Check that batch 67 is on `main` before you start** (`git merge-base --is-ancestor <sha> origin/main`). If it is not, landing it is the first job.

**Criteria:** 89 of the 101 ACCEPTANCE §6.1 criteria are met (batch 67 plus Stormwood F09#3, F10#3 and F10#4, Cloudreach F08#3 and F08#4, Tidewake F13#3 and F13#5). No chapter is accepted.

**Stormwood Phase 2c is active** on `tb/x04-stormwood`. P2-042 is fixed by `1ed0259e5`: fresh native/small-size blind review passes all four phases at both original catalog stands and readability preservation. The accepted presentation is enabled; actual enabled surge suites pass 55 tests / 762 assertions. Regional Bars A/B remain NO because character, Stormheart landmark and landscape gaps remain. P2-037 bark grounding, P2-045 candy tiers, P2-081 trainer dialogue and P2-110 roster-vitals refresh remain disabled pending complete native review. P2-092 is `deferred` to the `tb/stormwood` gameplay lane for collision/contact/lunge separation; P2-111 identifies persistent quick bindings rather than reward tiles. Evidence and remaining work are in `ralph/reports/VISUAL/phase2/stormwood/fixes/` and `phase2/catalog.csv`. No regional completion or Phase 1 criterion closure is claimed.

**The board is the source of truth.**

**Tidewake Phase 2c (`tb/x04-tidewake`) remains active.** P2-032 selected-map-tab clarity is fixed/enabled by `8c5009e09`: six native boots/24 frames on source `0930716ac`, independent visual PASS and strict item recheck, enabled tests 8/36. See `ralph/reports/VISUAL/phase2/tidewake/fixes/P2-032/map-01-{validation,visual-judge}.md`. This accepts only the catalog item, not chapter bars. Dunes-04 remains item PARTIAL (direction PASS; ecology/transitions PARTIAL; limited Bars A/B No/No); its paired stands, remaining defects and shared-grass/Veilfall scope are documented in `fixes/P2-008/dunes-04-{capture-validation,visual-judge}.md`. Dunes-05 `e22fdbcb2` remains off, source review clean, focused tests 35/87970, native evidence pending. P2-103 victory hierarchy `0930716ac` remains off; 720p lifecycle passes 99 checks, source review clean, native Venn/Nerissa comparison pending. Full unit results are in `fixes/validation.md`. Chapter matrix, regional acceptance, remaining owned dispositions and CI landings remain outstanding.

- `ralph/reports/COORDINATOR/dashboard/criteria.json` holds every criterion and card, with its evidence and gap.
- `status.json` holds the batches, the lane FINAL SHAs and the **`wip` list**. The `wip` list is the authoritative pickup list for unfinished work: each item says where the work is and the next step.
- `ralph/reports/COORDINATOR/README.md` gives the scoring rule and how to rebuild and republish the board.

**Chapter cards** (ACCEPTANCE §6):

| Card | State |
|---|---|
| M4, C1, T3, S3, T1 | **Complete.** M4, C1 and T3 in batches 59, 65 and 67. S3 and T1 had their integrated runs in batch 63 and all feeders (F11, F12) met, and are recorded as complete in batch 67. |
| S1 | Integrated run passed (batch 64); F09#3 is met, so every feeder is met. |
| M1 | In progress: F01#2/#3 day and night walks need a render and a judge. |
| M2, S2 | Partial. M2 needs the Hall-exit ruling below; S2 needs F10#2/#6. |
| C2, C3 | **Complete (Cloudreach Phase 1 landing).** C2: earned chapter run (longest travel gap 98 s, same five, no new catch) plus the six-activities witness, frame matrix by the F08#3/#4 code-blind verdicts; C3: two-peer co-op and Solmane aftermath, ALL CHECKS PASSED. Evidence `ralph/reports/CLOUDREACH/c2-card/`, `c3-card/`. |
| M3 | Failing: named-fight framing and Bars A/B. |
| T2 | Failing: waits on F14#0 and F14#1 (F13#3 and F13#5 met on function). |

**Open criteria (14):**
- **Meadows:** F01#2, F01#3; F03#0; F04#1, #2, #3, #6, #7.
- **Cloudreach: complete for Phase 1** (every row and card C1-C3 met). F08#3 (`ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/`) and F08#4 (`f08-4-settlements/`) closed on function; their Bars A/B clauses → Phase 2 catalog. F08#4 changed the game: working residents at Galefoot and Cliffhold, Cliffhold's settlement ambience on Cliffhold, and the Broken Causeways crown carved down to the causeway climb (it ran inside the crown). Owned-carrier Fly closed (`ralph/reports/CLOUDREACH/owned-carrier-fly/`): the five's healthy active carrier flies (WORLD §4.2), and the Galewisp starter gains Fly at the unlock (CREATURES §7). Maela's loaner serves her trial and, after the unlock, only a five with no carrier, until the chapter ends. A five whose healthy carrier is not out gets a refusal naming it; an unwell carrier keeps the loaner's safety net. The carrier's ground follower is recalled for the flight, and LB/recall wait for touchdown. Earned c1_arrival flight leg on an owned Galecrest (disclosed swap): the trial flew on the loaner, one refusal, 4 owned launches, party 5. Open: Cliffhold reads thin (Phase 2).
- **Stormwood:** F10#2, #6. F10#4 met (`ralph/reports/STORMWOOD/f10_4/r7/`: denser Deepwood reads as deep forest at every judged stand). F10#3 met (`ralph/reports/STORMWOOD/f10_3/r6/`: Break-only crawler lightning named from a single still). F09#3 met (`ralph/reports/STORMWOOD/f09_3_r8/`: loops, shortcuts and alternate road walked 72/0, pockets 102/0).
- **Tidewake:** F14#0, #1.
  - F13#3 is met (`ralph/reports/TIDEWAKE/phase1/f13_3/`): six chains in one real-swim run (619/0), and a lead now pins its destination on the map.
  - F13#5 is met on function (`phase1/f13_5/`): dock residents at every mandatory dock, current comets, and the Veilfall distance read.
  - F14#1 next. Nerissa's C2 regressed with dbe43195's Riptusk lane (render bisect in `phase1/f14_1/c2_bisect/`). Her ring spills south of the Heart Chamber lip into the 1 m sluice channel, and a sidestepping ally is pinned there.
  - F14#0: Tidecoil still fails C3 at the cliff foot; a Deep Watch arrival-beach stand is probed.
  - Other defects: after Tidecoil, a swimmer-less player may be left in the cliff-foot shallows (harness pose).

**Switched off or unwired in batch 67.** This is unjudged visual work, landed as the wind-down rule requires. Flip each item on only after a code-blind Bars A/B pass.
- `stormwood_glass_field.json` `scorched_scars=false`.
- `camera.body_clear.ignore_lunging_foe=false`. The Vance move is reverted.
- The Meadows camp firepit is unwired (re-apply `631b8390`).

**Reverted in batch 67.** Stormwood-B's F10#2 C3 commits `07bc9cad`, `45927814` and `85ba1c57` (the Elder cone and heading, and the guard cone) are reverted. Re-apply them when F10#2's C3 is re-captured.

**Branches.** Batch 67 took every branch head, older branches included. Where an older branch conflicted with newer landed work, the newer work won: Venn's move without the fight pad, Stormwood's judged r5 lightning, and the cleaned docs. Codex's doc edits were not taken; their facts are in ART_DIRECTION §7 and `ralph/reports/VISUAL/AUDIT.md`. Codex's unjudged Cloudreach towers and occupied terrace are merged but flagged off.

**To resume work:**
1. Pick an item from the `wip` list or an open criterion.
2. Work on a `tb/<lane>` branch from current main, following WORKFLOW §8 and `CLAUDE_START_HERE.md`.
3. Land each closed criterion through the lane's own PR (re-check, unit suite once, board and STATE, auto-merge). There is no coordinator and no channel.

**Open lanes (2026-09-28).** Four Phase 1 biome lanes (`tb/meadows`, `tb/tidewake`, `tb/cloudreach`, `tb/stormwood`; `CLAUDE_START_HERE.md`) and one Codex capture-and-catalog lane (`tb/x04-capture`; `CODEX_START_HERE.md` §2a–2b). The Balance lane (`tb/balance`: harder Meadows trainers, starter parity) lands itself, then stops. Meadows F04#7 and Stormwood F10#2 wait on it.

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
   - **Meadows named trainers are made harder** until C2 passes: team-wipe rate at or above the 0.25 bar (F04#7).
   - **Galewisp and ripplet are tuned to match terrapup in skill and strength**, so starter C2 difficulty is even (F10#2, CREATURES).
   - **The 326 m walk from the Hall exit after the finale is acceptable** (exempt from A7 and WORLD §3.1 spacing; M2).
   - **Codex does the Cloudreach aerie art** (F08#3). The Codex lane is shut down; the owner assigns this when the next round of work starts.
   - **Vess, the female officer,** gets the female officer body and portrait. Add a `defeated` clip to `officer_b`.

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
| Stormwood | Earned six-region route, Arches, Dynamo, Stormheart and aftermath. F09 and F11 are met; the S1 and S3 runs passed. | Named-fight C3 (F10#2), device profile (F10#6). Open risk (owner: Stormwood lane): the denser Deepwood bake (3d5fb0e6) has no perf measurement. Phase 2: aftermath under the canopy is brighter than the owner's 'only lighter rain, no lightning, scars' ruling. Findings (owner: Stormwood lane, after S2): pools_west_loop runs through the lit b_pools arch; a 1.11 m curb on b2's (verge_road footing) landing side; a 0.4–0.67 m step behind d_giant. |
| Tidewake | Human swim route (F12 met), eight pockets, six local chains with map leads (F13#3), dock residents and current comets (F13#5), dock exchange, return, Grandpa and credits (F15 met, T3 complete). Veilfall rooms show their pumps, sluices and banners. | Veilfall and named-fight C2/C3 (F14#0/#1); Bars A/B looks go to Phase 2. |
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
