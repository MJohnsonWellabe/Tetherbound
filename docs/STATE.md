# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git, `archive/`.

## 0. Current integration (coordinators: Claude and Codex)

**Status (12 Oct 2026, 9:05 PM CT):** board 229 of 271 met (`ralph/reports/COORDINATOR/dashboard/`, published at the coordinator's board link). All lane and Codex work is consolidated on `tb/ev-coordinator` in PR #681 to main (full CI, auto-merge on green; WORKFLOW §8). Every lane is archived; branch cleanup waits for the owner's go-ahead after the merge. Full CI on the consolidated head found 7 failures: 4 fixed (Crossing Hall reserved-arch sign, CI checkout of the npc-identity reference art, the Veridian crown through the Tether Machine and its cut-key warning), 3 timing smokes passed on rerun. Proof rules v2 are in WORKFLOW §8.1. **Owner delegation (11 Oct 4:12 PM CT):** the coordinator decides everything except the human playtest (F49#1) and the ROG Ally device runs (F26#5, F49#2); decisions are logged in `status.json` `decisions`.

**Landed this push (12 Oct), highlights:** the regional homecoming was unreachable in real play (dead world flag `stormheart_freed`), now fixed with a release-driven regression test; Stormheart keep-at-five fixed (lazy owner-passive getter) and proven live; camp-bed and training-fence soft-locks fixed with a fence watchdog; mastery/research per-frame cost (0 ms in combat; deferred durable flush at natural pauses); 77 s first-launch map bake fixed (byte-identical); portal NOT_READY race fix; COMBAT §7 type-matchup rule and trivial-fight floor; F04#7 guardian and F14#0 Brine Root tunes; F36 pose post-pass (r2 20/15/34 of 69, net improvement); flags ON after code-blind review: P2-037 bark, hall interiors (pools + reveal), HUD clarity pass, Veilfall kitbash, loss card. Parked: P2-022, P2-031, P2-060, P2-063, P2-111, F17 signage.

**Restart plan (owner, 12 Oct):** the board's **Delivery plan** tab (`plan.json`) schedules every open criterion except F38–F41 and the owner items, from 12 Oct 8:51 PM CT, in five lanes: Routes (F19#5 → F11#0/F09#0 → F49#0/#3), Fights (F22#4 → F10#2 → F33#2 → M2), Systems (F42#2 → F21#5 → T2 device profile → release reliability), Visuals (F36#1 r3 → F04#6 → F17#6 → F08#3/F13#5/M3 re-judge) and the Codex service (F36#0 remainder → F29#3 → GPU frame time F21#5/F25#4 and F26#3 matrices; also the F19#5 named-wild detour pieces, P2-092, P2-041). F38–F41 come last as their own features on the **Visual catalog** tab (`visual_catalog.json` tasks, `visual_plan.json`): each biome's top 20 plus every catalog row over impact 12 (39–43 tasks a biome, 106 unique rows, 15 done), Codex-led (scene, mesh, material, lighting, camera rows; four biome lanes), with Claude taking the cross-biome UI rows (F42) and creature-pose rows (F36#1) and running the code-blind judges. Known open bug: offline-solo boss rewards when every port is taken (full-bag captain reward loss fixed in 209748abd). Pre-existing, not CI-gated: `smoke_crossing_hall_circuit` fails "actual biome sign missing: meadows". **Owner ruling (12 Oct):** Codex's unevidenced Veridian 7.0 m / Abyssal Guardian 8.4 m scale trial (46892d0ea) is reverted to CREATURES.md (5.8 m / 7.2 m); a redo needs the spec change plus a taller Tether Machine and a wider Legendary Chamber (a 23.5 m machine crowds the 28 m room off the choice prompts).

**F18 portal runtime is ON** (`multiplayer.json session.redesign_portal_runtime_enabled=true`): station-craft co-op green (render 37401490374); post-rejoin relic/Home Key owner stalls fixed. Follow-up: hung-relic reload loss (F18 lane, next PR).

**Criterion audit (2026-10-04, against the consolidated code):** prior evidence counts only where its code is unchanged. 271 live criteria; 10 superseded rows dropped with citations. Tables: `ralph/reports/INTEGRATION/criterion-audit/`. Board (hourly): `ralph/reports/COORDINATOR/dashboard/`.

**Codex GPU/carry-over restart (13 Oct 02:07 CT):** PR #681 merged as `122682ad`; native checkout `C:/CodexTemp/tetherbound-native-service` stays on that source, isolated commit/push checkout is `D:/tetherbound/codex-service-main`. `tb/codex-creatures` is pushed at `5479e43`: NPC retries rejected, Solmane/Stormursa parked for changed approaches, Mirejaw fit candidate OFF with measured native 3.276395m OFF / 3.550000m ON against 1.80m trainer; stage-only blind full bar FAIL, no READY. `tb/codex-gpu` through `daeaa66af` retains Meadows 20/20 High and Medium with WEAK verdicts; original Tidewake Medium 46/48 and Cloudreach Medium 22/24 each refused one catalogue stand day/night. Tidewake authored-camp private coordinate preview passed 2/2 and complete Medium 48/48; High crashed once in nvoglv64.dll (0xc0000094) after 20 frames; one confirming run completed 48/48. Blind Medium/High full-bar FAIL/FAIL: sparse coasts, dark nights, weak/crowded creature presence. Cloudreach authored-arch Medium/High both finished 24/24; blind WEAK/WEAK (empty planes, repetitive cliffs, no creature focal presence). Stormwood first Medium failed 0/25 from an incompatible cover-OFF fixture expectation. Independently reviewed helper alignment preserves the legacy isolated OFF comparison and all live checks; corrected Medium and High each completed 25/25, exit 0. Supervisor `.artifacts/codex-service-gpu/run_stormwood_v2.ps1`, outputs C:/CodexTemp/codex-service-gpu/stormwood-v2-{Medium,High}; two fixture files were byte-backed up and restored, tracked native tree clean. Blind WEAK/WEAK, both bars NO: dark repetitive forests, weak trainer contrast and creature framing; full-resolution review confirms cropped/possible distant creatures rather than literal absence. Both production travel guards remain intact; default catalogue unchanged. Native tracked tree is clean after preserving four staged evidence files externally and verifying/refreshing 21 CRLF-only import-sidecar index entries. F21#5/F25#4 remains memory-blocked after prior four-peer allocation failure. F19 D1/D2 retained, D3-D5 pending execution; scoped current-main source audit admits a fresh D3 receipt from retained D2; exact P2-092 baseline from local `365b344a1` preserved in `.artifacts/codex-service-carryovers/P2-092/`; P2-041 private ON 1ddacb4e and P2-092 private ON 020be872 are local one-boolean children of 122682ad; external capture packets are being refreshed, production defaults remain OFF. D: is 19.64 GiB free, below the retained carry-over runner floor; asked approval to relocate eight completed GPU evidence folders (0.49 GiB) to C: with hashes/junctions, no action without reply. Stormwood supervisor session 77671 completed; no engine writer active, shared lease reserved by this service thread. Meadows F38 High/Medium preflight plans 528 frames per preset. No criterion closure, PR, CI or render workflow dispatch.

**F25:** owner 2026-10-04 rejected cartoon hit markers. The shared `hit_spark` is OFF and each move's impact carries contact. The library stays OFF and F25 is open (`ralph/reports/VFX/f25/PROOF.md`).

**Owner rulings 2026-10-04:**
- Visual cards judge High/Medium for the target look and confirm Low/Compatibility for no breakage until the Ally test passes.
- The second UI check is 1280×720.
- F36#0 may regenerate NPC faces only as identity-preserving refinements of the installed cast.
- Pre-camp creature healing (PROGRESSION §6, earned-run finding: 8 potions for 10–12 practice fights, zero slack): Grandpa's house gets one free creature bed using the existing camp `creature_bed` component, so home heals creatures. Meadows ordinary-wild tuning toward COMBAT §7's 15–30% lead cost waits on that bed and an F02#6 re-run.
- F22#1 reading (coordinator, from COMBAT §7): the band sweep runs each band's ordinary trainer fights; pass needs reader win ≥0.9, masher lead-faint rate ≥0.25 above the reader's, and reader median lead HP cost ≤0.55× the masher's. Wilds keep their own §7 floor.
- Owner 2026-10-04: ROG Ally test deferred to the owner's own playtest once the game is built; Codex builds no Ally package for now. F26#5 stays owner-blocked; Compatibility stays default.
- Owner 2026-10-04: one feature per lane to done before the next; re-proof folds into each lane.
- Owner 2026-10-04: CI known-red probes run only on the scheduled full tier and manual dispatch; the multiplayer group skips presentation-only changes (ci.yml `net` output). Delivery plan: 13 eight-hour sprints across five lanes, tracked on the board's Delivery plan tab (ralph/reports/COORDINATOR/dashboard/plan.json). Times are reported in Chicago time.
- Owner 2026-10-04 (7:50 PM CT): frame rate is a release blocker. Codex's GTX 1060 Medium 1080p routes average Meadows 11, Tidewake 7, Stormwood 17 fps. A performance lane (tb/perf) fixes it without clipping the world; the desktop proxy target is ≥60 fps avg with 1% lows ≥40 at Medium.
- Owner 2026-10-04 (8:15–8:25 PM CT): build the game, not test equipment. Equipment is built only where a criterion has no existing way to verify it; co-op, save and economy changes still ship with a new or extended test; visuals, feel, content and balance use a code-blind judge or a playtest. A product change that legitimately changes an asserted behaviour updates that test in the same commit; a CI test blocking a landing goes to the coordinator. Long CI playthroughs are proven as segments plus handoff checks (each segment starts from the previous one's real end-state save); one unbroken playthrough stays on the scheduled 8-hourly tier (non-blocking), and one unbroken F49 run happens before release.

**Owner rulings 2026-10-05 (coordinator interview on the behind-plan bars):**
- **Blocked criteria:** when only blocked criteria remain, the lane records them BLOCKED-with-ask, starts its next feature in plan order, and returns when the blocker clears.
- **F18 lands per criterion:** portals turn on behind their flag for the proven parts (Home Key gift, one-tap use) now. #4 (guest regional ack) closes after. Each criterion counts as it lands.
- **F22#2** (switching value) is proven when F24's tag-switch combo lands. F22 closes without it.
- **Per-starter balance (F22#1):** every starter is balanced; Terrapup gets no tank exception (owner). F22#1 is measured by the COMBAT §7 floor-trainer form: reader lead cost ≤55% of the masher's, reader win ≥0.9 (coordinator). The sky_rend trial is dropped.
- **Forced break (COMBAT §4):** only a charge started after its tell can be broken, with a 0.1 s grace window.
- **Home arch (F18, former open decision #11):** the Crossing Hall home arch returns to the last Meadows waystone the player touched.
- **Co-op rejoin authority (owner ruling 2026-10-05, supersedes "held record wins"): guest wins unless behind.** On a rejoin whose record differs:
  1. The host first folds its own journaled payouts.
  2. The guest's declared record is adopted (first-join rules, at a higher revision) when it is not behind the held record. "Not behind" means every receipt, personal flag and absorbed payout the host recorded is present.
  3. Only a declaration that is behind (a rollback or restored backup) adopts the held record.
  
  Implemented on tb/f17 (66b2f539); audit and review: `ralph/reports/HUB/f17/`.
- **Review gate:** independent code review stays mandatory for co-op, save, economy and world-visibility (culling, streaming) changes. Pure tuning, data and visual changes go straight to their tests or code-blind judge without a separate code review.
- **Schedule:** rebaseline the delivery plan to the measured pace; scope kept, old baseline shown as a ghost.
- **Combat controller map (former open decision #10; COMBAT §1, UX §2.2):** confirmed as written. The ultimate and Tether Commands are tap-then-tap sequences, orb aim is on LT, flee is on RT, the LB+face layout is an optional preset, and the commands unlock at the practice catch and the first two-creature fight.

ACCEPTANCE was reconciled with RD-01..RD-37 (PR #527). Eleven legacy-path tests retire when portals turn on.

**Open co-op items:** Stormwood hosted trainers have no durable actor vitals (F27 excludes them); guest catches stay local while alpha_respawns is off (F27); owner to rule if a missing personal flag is behind (yes now; M1); a payout that can't fit while behind can be lost (L2).

**Owner-only:** the human playtest (F49#1, which also confirms F47#0's 15–25 h) and the ROG Ally Medium handheld runs (F26#5, F49#2). Nothing else waits on the owner.

**Board:** [private board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site); flags/fixtures do not close acceptance.

### Owner decisions (all answered 2026-10-05; Codex restarted by the owner)

1. **ROG Ally test (F26#5):** stays parked until the owner playtests the built game. Compatibility stays the default; Forward+ becomes the default only after that test passes.
2. **Meshy:** keep the cap of 30 generations per night (RD-26).
3. **Storm bear:** the name *Stormursa* is locked (RD-28).
4. **Internet co-op:** finish and prove the existing Steam invite path (MULTIPLAYER §1) with Valve's development AppID 480, at no cost. The US$100 product AppID is decided only at ship time, and `ship_steam_runtime` packaging stays off until then. No Epic or other relay work. The two-network proof needs two real accounts on separate home networks.
5. **Stormwood audio:** the nine missing `assets/audio/stormwood/*.wav` are authored from installed sources (AUDIO §10), landed in #540; spectral and loop checks, no owner listen. Evidence `ralph/reports/AUDIO/stormwood-nine/`.
6. **Owner play pass (F47/F49):** one pass, at F49, on the complete four-chapter build.
7. **Final relay:** Stormwood's Stormheart is the final relay. Tidewake's regional link is one of four, and the dock exchange stays Tidewake's chapter close (WORLD follows).
8. **PRODUCT:** the "Build the best five" sub-line, the demo scope (Meadows, village road, Hall, first homestead loop) and the §6 cut order are confirmed. Price stays open; this authorizes no launch or spending.
9. **Design defaults:** every CODEX_START_HERE §8.1 default is owner-confirmed.
10. **Controller map** and 11. **home arch:** settled; see §0 owner rulings 2026-10-05.
12. **Repo size:** approved. Existing `ralph/reports` images move to a GitHub release archive with links preserved, and new evidence images go to CI artifacts. Text evidence stays, and history is not rewritten.
13. **Hazard terrain (F33#3, RD-14):** Stormwood's charged ground deals light contact damage to the trainer only. It never hurts creatures and is never lethal. Rootiron and Stormglass trainer gear reduce it. Tidewake submersion stays drowning-only (coordinator).

**Settled and kept (history in Git):** the Capacitor Alpha no-stagger ruling and storm strikes sparing trainers in fights (owner, 2026-09-27 23:55); harder Meadows trainers, starter parity and the female officer Vess (batch 68); the C2 masher rule (ruling 12, option c).

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

- **Owner redesign (2026-09-29), CODEX_START_HERE §1:**
  - Four chapters in the order Meadows → Tidewake → Cloudreach → Stormwood.
  - A 15–25-hour normal clear with a loop that is fun to grind but optional to repeat. Creature power is the spine; the homestead is its engine.
  - Hybrid leveling with type essence, and breakthroughs every 10 levels through Master 1v1s and Ascension Feasts.
  - Three move slots plus an ultimate. Tether Commands, which never deal damage.
  - The Crossing Hall at the end of a single village road, with portals, a Shrine Room, Grandpa's Home Key and waystones.
  - Ending: the Stormwood finale → Home Key homecoming → credits → the fifth arch stirs.
  - Visual bar: Palworld/Animo plus Valheim. A Forward+ path, pending the owner's Ally test.
  - Saves reset. Eight biomes remain the plan.
- Keeping the same five through the ending is success. Rewards deepen them (essence, breakthroughs, gear, traits), and catches stay optional. Water's critical path must not require an owned swimmer.
- No new investment: code and existing tools/assets, including the held Meshy licence. Agents may draft references and submit scoped Meshy work, plus the bounded overnight batch (RD-26) and one new creature, the storm bear (RD-28).
- Co-op is required through invitation, with no router setup or typed address. LAN or direct-IP alone is insufficient for release.
- Owner: "personal / friends — I just want it good". PRODUCT price and positioning do not authorize publishing or spending; a commercial launch needs a separate owner decision.
- **Legendary rule:** each participant in the freeing fight receives their own once-only offer, bound to their stable character; non-participants get none. Keys and relics follow the same per-participant rule (RD-21).

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
- **Usage/stop direction:** prior P2-008 usage/stop requests are historical. The2026-10-02 owner stops this coordinator and delegates activation/criterion work to a new Astra lane. Never consume a usage reset automatically.
- **Owner redesign interview, 2026-09-29:** 35 decisions, recorded as RD-01..RD-35 in CODEX_START_HERE §1. The owner asked that every catalog defect scored above 12 be fixed to the full game bar, "not just passing the defect", so the game looks like something people would play (Valheim, Palworld, Animo, ARK as quality references). Done means the whole plan is done: push consistently, rebuild the dashboard hourly, then burn the criteria down over time.
- Record owner feedback here; it overrides other documents on its subject.

R2/R3 source consolidated; production wiring, runtime proof and main pending.

