# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git, `archive/`.

## 0. Current integration (coordinators: Claude and Codex)

**Status (13 Oct 2026, 08:37 CT):** PR #681 (`122682ad`) and #682 (`1f6d7e2108`) are on main. Decisions remain in `status.json`; board and delivery plan own live counts. Persistent parallel lanes: Tidewake, Cloudreach, Stormwood, creatures and GPU; native writers serialize. Verified obsolete checkout cleanup reclaimed ~11.6 GiB. Catalog evidence moved to D: through a C: junction (4,175 hashes verified); shared Git and unique evidence preserved. Disk floors: C 10/D 20 GiB.

**Queue:** the Delivery plan tab (`ralph/reports/COORDINATOR/dashboard/plan.json`) schedules Routes (F19#5 → F11#0/F09#0 → F49#0/#3), Fights (F22#4 → F10#2 → F33#2 → M2), Systems (F42#2 → F21#5 → T2 device profile → release reliability), Visuals (F36#1 r3 → F04#6 → F17#6 → F08#3/F13#5/M3), and Codex service (F36#0 remainder → F29#3 → F21#5/F25#4/F26#3 GPU matrices, plus F19#5 named-wild detours, P2-092 and P2-041). F38–F41 catalog work is ordered top 20 first, then impact >12, on the Visual catalog tab (`visual_catalog.json`, `visual_plan.json`): Codex owns world/scene/mesh/material/light/camera rows; Claude owns cross-biome UI and creature poses and code-blind judging. Only the human playtest (F49#1) and ROG Ally runs (F26#5, F49#2) wait on the owner. Parked rows remain as shown on the board.

**Codex creature proof:** source `1f6d7e2108`; Iona/Orsen/Otto retries were used and rejected (no further generations); Solmane wing root and giant fit remain open; Mirejaw 3.55 m fit candidate stays OFF after stage full-bar FAIL. Stormursa support IK2 failed and is parked; side-faint 5+5 is WEAK/full FAIL (proof `c78a3afb7d`, `ralph/reports/F29/stormursa-sidefaint/`); RD-26 ledger: six generations used.

**F38 Meadows catalog:** service branch `tb/codex-visual-meadows` is at `47664f992d`. P2-003's four matched existing High/Medium pairs FAIL the stronghold landmark/dressing defect; no candidate or closure (`ralph/reports/F38/p2-003-rescore/`). P2-017's five named Meadows subjects measured above the 1.8 m trainer (Brooktail 2.10, Pipwing 1.90, Bramblebun 2.05, Trailpup 2.30, Riftfrill 2.15 m); apparent scale was PASS for three and WEAK for Pipwing and Bramblebun, while the full art bar remains unmet (`ralph/reports/F38/p2-017-stage/`). These installed standing-stage receipts do not establish gameplay scale or close other-biome sightings. The raw High/Medium survey remains 354/528 each and 353 matched IDs: its ≥200 numeric floor is met, but catalog rescore is incomplete; the neutral 24-pair survey is WEAK/WEAK, both bars NO, and unreviewed subjects stay UNKNOWN (`ralph/reports/F38/service-recapture/`).

P2-033's clearing/glow and narrower treatments both failed; the all-preset close/16m/32m review was WEAK with full bar FAIL, so the approach remains PARKED and both flags OFF (`ralph/reports/F38/p2-033-narrow/`). P2-034 Basic Orb height remains OFF: Low OFF 2/2 passed, ON 2/2 saved but teardown exited -1 at the C: 11 GiB floor; blind diagnosis FAIL and the distant reward still reads generic (`ralph/reports/F38/p2-034-orb/`). The named-fight baseline also FAILS on foliage intrusion, trainer occlusion and attack indicators; High/Medium 1080p 14-live-frame and Low 720p 9-live-frame captures exited 0 but do not establish earned-path, four-player or performance acceptance (`ralph/reports/F38/fight-camera/`). West-wall ivy placement candidate remains OFF pending review (`ralph/reports/F38/ivy-wall-candidate/`). No F38 catalog row closes from these results.

**GPU/device evidence:** F26 High/Medium matrices contain 20/48/24/25 frames for Meadows/Tidewake/Cloudreach/Stormwood; blind results are WEAK/FAIL/WEAK/WEAK. F21/F25 four-peer proof remains memory-blocked.

**Native/carryover status:** F19 D3 v4 (`758b542b00`) is running from retained D2, using authored roads and 0.2 m stance tolerance; no D3 pass yet. D1/D2 intact. Evidence: `D:/tetherbound/.artifacts/codex-service-carryovers/F19-D3/road-v4`. P2-092 paired Low captures are WEAK/full FAIL; exact `365b344a1` baseline retained. Fresh camera/trainer candidate `ea2832b366` stays OFF. P2-041 paired 18-view captures are WEAK/full FAIL; fresh chamfered paving/apron `9625177105` stays OFF. Proof: `ralph/reports/F41/p2-{092,041}-service/`. Giant-fit capture adapter parked after two failures, no candidate verdict. GPU calibration hash binding corrected; retry and P2-087 queued. Conditional D4/D5 packets are being refreshed.

**Open known issues:** offline-solo boss reward can be lost when every port is taken (full-bag captain reward fixed in `209748abd`); pre-existing `smoke_crossing_hall_circuit` reports “actual biome sign missing: meadows.” Mastery-flush series reverted from #681 after intermittent co-op failures (boss rewards journal, F48 feast feed, F28 masters, `harness_max_hp` on leave); Systems re-lands it after all four smokes pass 3/3 locally. F18 portal runtime remains ON (`multiplayer.json` `session.redesign_portal_runtime_enabled=true`); station-craft co-op and post-rejoin relic/Home Key stalls are fixed, while hung-relic reload loss remains in F18's queue. Criterion audit tables: `ralph/reports/INTEGRATION/criterion-audit/`; hourly board: `ralph/reports/COORDINATOR/dashboard/`.
**F25:** cartoon hit markers were rejected. Shared `hit_spark` stays OFF; moves carry their own contact. F25 remains open (`ralph/reports/VFX/f25/PROOF.md`).

**Active owner rulings (4–5 Oct):**
- Visual target: High/Medium judged to the full bar; Low/Compatibility checked for breakage until the Ally test passes. UI's second check is 1280×720. F36#0 may refine only the identity of installed NPCs.
- Grandpa's house gets one free creature bed using the camp component. Meadows ordinary-wild tuning waits for this and an F02#6 rerun (earned-run finding: eight potions for 10–12 practice fights, no slack).
- F22#1 sweeps ordinary trainers per band: reader win ≥0.9, reader median lead HP cost ≤55% of masher, and wilds keep their separate COMBAT §7 floor. All starters are balanced; no Terrapup tank exception.
- F26#5 stays owner-blocked until the built-game Ally test; Compatibility remains default and Codex builds no Ally package. Desktop performance is a release blocker (Medium 1080p target ≥60 fps average, 1% lows ≥40); latest GTX 1060 routes were Meadows 11, Tidewake 7, Stormwood 17 fps.
- One feature per lane before the next; re-proof folds into the lane. Build product, not test equipment: add tooling only where a criterion lacks verification. Co-op/save/economy changes need tests; visual/feel/content/balance need code-blind judgment or playtest. Update assertions with changed behavior. Long runs use real-state segments plus handoffs; one unbroken F49 run before release. Known-red probes run only in scheduled full/manual CI; multiplayer `net` skips presentation-only changes.
- When only blocked criteria remain, record BLOCKED-with-ask, take the next planned feature, and return when the blocker clears. F18 closes per criterion behind its flag; F22#2 closes with F24's tag-switch combo. Only a charge begun after its tell can be broken (0.1 s grace). Crossing Hall home arch returns to the last Meadows waystone.
- Co-op rejoin: host folds its own journaled payouts first; adopt the guest declaration at higher revision unless it is behind (missing any held receipt, personal flag or absorbed payout), in which case keep the held record. Implemented on `tb/f17` (66b2f539); audit/review: `ralph/reports/HUB/f17/`.
- Independent review remains mandatory for co-op, save, economy and world-visibility changes; pure tuning/data/visuals go to their check or code-blind judge. Rebaseline delivery pace while retaining scope and showing the former schedule as a ghost. The controller map is confirmed in COMBAT §1/UX §2.2: ultimate and Tether Commands are tap-then-tap, orb aim LT, flee RT, LB+face optional; commands unlock at practice catch and first two-creature fight.

**Settled owner decisions:** ROG Ally/home play pass occurs on the built four-chapter game (F49#1; F26#5/F49#2); nothing else waits on the owner. RD-26 caps attended Meshy work at 30 generations/night; Stormwood storm bear is named Stormursa (RD-28). Internet co-op completes the existing Steam invite path with free development AppID 480, two real accounts on separate home networks; no Epic/other relay, product AppID only at ship, Steam ship packaging stays OFF until then. Four accounts and partner access remain owner resources. Stormheart is the final relay; Tidewake's regional link remains one of four and its dock exchange closes the chapter. Demo scope is Meadows, village road, Hall and first homestead loop; price, launch and spending remain undecided. CODEX_START_HERE §8.1 defaults are owner-confirmed. Stormwood charged ground gives light, nonlethal trainer-only damage; gear reduces it and creatures are never hurt; Tidewake submersion remains drowning-only. Evidence/image policy: approved old report images move to a GitHub release archive with links; new images go to CI artifacts, text evidence stays and history is not rewritten. Stormwood audio assets landed in #540; spectral/loop checks and evidence: `ralph/reports/AUDIO/stormwood-nine/`.

**Open co-op items:** Stormwood hosted trainers lack durable actor vitals (F27 excludes them); guest catches stay local while `alpha_respawns` is OFF (F27); behind guests can lose an unfit payout (L2). M1's personal-flag case is resolved: a behind guest is re-offered.

**Owner-only:** human playtest F49#1 confirms F47#0's 15–25 h; ROG Ally Medium runs F26#5/F49#2. Board: [private board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site). Flags and fixtures never close acceptance.

ACCEPTANCE reconciles RD-01..RD-37 (PR #527); eleven legacy-path tests retire when portals turn on. Settled historical rulings remain in Git; §1 and owning specs govern.
## 1. Rulings in force

**Owner redesign (2026-09-29):** CODEX_START_HERE §1 (RD-01..RD-37) is the newest owner direction. Where a ruling below conflicts with it, the RD entry wins, including RD-36's minimum necessary testing and batch validation. Other proof/counting rules remain.

**Owner and coordinator, 2026-09-27.** Nothing may contradict these.
1. **Counting and proofs.** Criteria count at merge; post-batch full CI is a safety net. Disclosed fixtures/declared starts, teleports, flag/party writes, harness fights and skipped sub-parts are allowed (ACCEPTANCE §6.1, WORKFLOW §8), as are earned checkpoints. Held Fly is lawful; tap pulse optional.
2. **Solmane.** Like Meadows' Veridian, Cloudreach's legendary is freed after Veyra, with a once-only offer per participant; never wild/catchable. Summit wild tables use tempestwing. **Implemented:** F08#5 met, C3 rerun passed.
3. **Device profile.** A computer capture at 1920×1080 on Compatibility/`opengl3`, judged code-blind for 7-inch readability. No Ally hardware (#356 5857144944; ACCEPTANCE §6.1).
4. **Visual bar.** Bars A/B apply to every visual row. "Beauty matters." **Owner update (2026-09-29, RD-24):** Bars A/B are redefined as Palworld/Animo-class creatures and world plus Valheim-class light and atmosphere; every visual fix targets the full bar (ACCEPTANCE §4; F26, F38–F41).
5. **Build the game, not proof machinery.** Every round is player-visible. The two-strike harness rule applies, and each READY/FINAL post carries a `Balance: game N / tests-tools M` line (WORKFLOW §8).
6. **Return route.** The homeward return after Tidewake was exempt from A7 (T3/F15). After the redesign the Stormwood finale leads home by the Home Key, so no return walk exists (RD-22).
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
12. **Meadows top-fight bar (owner 2026-09-28, F04#7 option c; delegated to the Balance lane, coordinator agreed).** Per top fight and starter, 24 seeds: reader win ≥75%, masher loses its lead every run, reader party cost ≤55% of the masher's. Chapter reading (the lane's reading of the owner's intent): a masher loses ≥1 named trainer fight in ≥25% of playthroughs; measured 0.94–1.00, per-fight data in the F04#7 evidence. Owner option: raise the Band 3 pin for Vance for a per-fight 25%. The form applies to Tidewake F14#0 (Tidewake lane measures). COMBAT §7, BOSSES §9, ACCEPTANCE C2.

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
  - **Type matchups (12 Oct, owner delegated the call):** type advantage is meant to matter. Disadvantaged-lead rows are judged with the switching reader; advantaged-lead rows are exempt from masher-lead-faint only while reader party cost stays ≤55% of the masher's; a row that still fails, or fails on timeouts, is tuned in data. COMBAT §7, ACCEPTANCE C2. Applies to F04#7, F14#0, F22#1, F47#3, F22#4.

## 2. Product decisions

- **Owner redesign (2026-09-29), CODEX_START_HERE §1:** four chapters (Meadows → Tidewake → Cloudreach → Stormwood); 15–25-hour normal clear; creature growth is the spine and homestead its engine. Hybrid type-essence leveling, breakthroughs every 10 levels via Master 1v1s/Ascension Feasts, three move slots plus an ultimate. Tether Commands separately never deal damage. The Crossing Hall sits at one village road's end with portals, Shrine Room, Home Key and waystones; the Stormwood finale returns home for credits and the fifth arch. Saves reset; eight biomes remain planned. Visual target is Palworld/Animo creatures/world and Valheim light/atmosphere; Forward+ stays pending the Ally test.
- Keeping the same five through the ending is success; rewards deepen them and catches are optional. Water's critical path never requires an owned swimmer.
- Use existing code/tools/assets and held Meshy license. Scoped reference drafting/submission is authorized, plus the RD-26 bounded attended batch (≤30 generations/night) and RD-28 Stormursa. No other purchases, roster expansion, unreferenced text-to-3D or unattended batch.
- Required co-op is invitation-based, without router setup or typed address; LAN/direct-IP alone is insufficient. Product price/positioning authorize no spending, publication or commercial launch.
- **Legendary (RD-21):** every participant in the freeing fight receives their own once-only offer bound to their stable character; nonparticipants receive none. Keys and relics follow the per-participant rule.
## 3. What exists

| Domain | Current fact | Open against the plan |
|---|---|---|
| Combat | Wind, poise, burst and quick/charged geometry; per-body named-fight overrides; the hitstop attack buffer. | C2/C3 on named fights (F04#7, F10#2, F14#0/#1), large-body camera framing. |
| Creatures | 57 base species, individual IVs and bond, and limited evolution. Galecrest was rebuilt from a reference; its `companion_presence` head-tracking override did not land because main lacks that code. | Creature finish for Bars A/B, and attack-pose clipping (AUDIT §A). |
| Meadows | Opening, route, activities, Hall and finale. F02 and F05 are fully met; M4 is complete. | F01 walks, F03#0 lures, F04 presentation, Bars A/B. |
| Cloudreach | Six regions, Fly and remount, six activities (F07 met), Veyra, and Solmane's per-participant offer. C1 is complete. | Aerie art (F08#3, Codex), settlements and cliffs (F08#4, Codex). Owned-carrier Fly closed. |
| Stormwood | Six-region earned route, Arches, Dynamo, Stormheart/aftermath; F09/F11/S1/S3 MET. | F10#2 C3/F10#6 device OPEN. Stormwood owns unmeasured Deepwood3d5fb0e6 performance, overly bright aftermath, pools_west_loop crossing lit b_pools, b2 curb1.11m and d_giant step0.4–0.67m. Tidewake/F14 C3 owns Compatibility black world from Camera3D.v_offset (`STORMWOOD/f10_6/r3/ab_top_band/`). X03 owns NPC interaction during starting wild fight (`STORMWOOD/s1/phase1_rerun/`). X01 owns CHARGER "missed" with ally inside lane (`STORMWOOD/f10_2/c3_p1/`, W tell4). |
| Tidewake | Human swim route (F12 met), eight pockets, six local chains with map leads (F13#3), dock residents and current comets (F13#5), dock exchange, return, Grandpa and credits (F15 met, T3 complete). Veilfall rooms show their pumps, sluices and banners. | Named-fight C3 framing: Aquaryn and Tidecoil pass. Tess and Nerissa are blocked on contact-range occlusion, which needs a shared combat spacing rule. Bars A/B looks go to Phase 2. |
| Multiplayer | ENet authority, portable characters, ledgers and receipts, the exact-pose rejoin, and an optional default-off Steam lobby path. | Internet relay and four accounts (owner resources), host plus 3, device. |
| Save | Save version 27 with world format 2 and character format 6; atomic split saves; refusal of corrupt or absent halves without live mutation. | Legacy peer-ID receipt and slot-rename ambiguity (not recovered). |
| Redesign (F16–F49) | F16 and 15/179 redesign criteria accepted on main; active source drafts remain unproved. Baseline systems and retired physical-crossing history are recorded in Git. | Full ACCEPTANCE §6.2 and F49 remain the done bar. |
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
- **Forward camps (F34, lane A).** Tidewake now has the BuildPlacer (coordinator-approved hook), so forward camps place there. Sea and shallows refuse. World load is unchanged: 8.6 s with the hook against 8.8–9.5 s without. A co-op guest places a camp only in the host's loaded realm; elsewhere the host refuses with a reason. The second-camp pack-up offer applies when a kit is in hand. Ground within the allowed rise no longer blocks a camp's clearance; every other low collider still does. Evidence: `ralph/reports/HUB/f17/f34/`.
- **Opening gifts for a co-op guest (F01#6a, lane A).** Grandpa's gifts are held until the Home Key settles, then claimed from the host under the conversation that spoke them; a batch spoken while one is held waits behind it with its own name. UX follow-up (open): a guest's Basic Orbs arrive about 3.7 s after Grandpa hands them over, which is noticeable. Evidence: `ralph/reports/F01-FIXES/f01_6a/`.

## 5. Dependencies and still-open design questions

- **Owner resources:** the Steam AppID and partner access, and the four accounts (§0).
- **Meshy:** Meshy runs through Codex on the owner's machine. Claude sessions hold no key.
- **Design questions** (keep current behaviour conservatively until settled):
  - the wild defeat persistence policy;
  - which replacement subjects the reference/Meshy workflow takes: answered by RD-26, the priority list confirmed in F36 (ART_DIRECTION);
  - a Burrowback contrast treatment that keeps its identity;
  - a grass clump redesign beyond the approved settings.
- **Validate:** ACCEPTANCE §7 release performance on owner-provided Ally hardware; fair late-catch bond; shared encounter scaling. Failures require retuning, not relaxed bars.

## 6. Owner direction carried forward

Catalog defects scored above 12 must meet the full game bar and close with evidence (CODEX_START_HERE §1); live owner priorities and hard rules remain in §§1–2. New owner feedback supersedes older direction. Activation/criterion work moved to Astra on 2026-10-02; never consume a usage reset automatically.
