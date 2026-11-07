# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git, `archive/`.

## 0. Coordinator handoff and plan (7 Nov 2026)

Read first. Replaces the October §0 (Git history); CLAUDE.md overrides.

**State:**
- Batches #808 to the 7 Nov consolidation: about +66 CPU across 136 gains; about 40 rows crossed 6.0. Ledger and board: https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem, with source in `ralph/reports/COORDINATOR/dashboard/status.json`.
- CPU scores (llvmpipe, Low/Compat, `tools/visual_judge/`) are provisional and only compare within a batch.
- The board mixes stale GPU and newer CPU scores.
- Lane handoffs are the `## HANDOFF 7 Nov` sections in `ralph/reports/LANES/{VIS-MEADOWS,VIS-TIDEWAKE,VIS-CLOUDREACH,VIS-STORMWOOD,NEAR6-MS,NEAR6-TW,NEAR6-CR,CREATURES-RALPH,NET-F48}/READY.md`.

**Owner rules (7 Nov):**
- Every judged gain over live ships ON, including split or small gains. Only flat, worse, or a gain paid for by another row's loss stays OFF.
- New art is made in Blender, not Meshy (no credits): new meshes, reskins or recombinations of installed assets. Keep the drafted reference, 1.80 m scale check and provenance, and keep the flag OFF until judged. This overrides the 27 Sep "meshes stay with Codex" split.

**Plan:**
- Five lanes, each on one row. When the row is done, the lane pushes and is archived, and a new lane takes the next row.
- End of day 8 Nov: GPU re-judge (Medium and High) of every row whose last score is CPU-only or older than its latest landed change. The bar stays 7.5. A GPU score below the CPU score reopens the row.

**Lane brief:**
- Branch `tb/item-<row>` from main.
- The row, its score and source, and the judges' asks, from `ralph/reports/VISUAL/item-scores/` and the handoffs.
- One-item quick_judge rounds. A gain ships ON with `_why_on`, and any OFF-assert in a test flips to ON with the score.
- Hard rules: no camera reframing, never shrink creatures, red reserved for Team Tether, never weaken tests, one Godot process at a time.
- Done at 7.5, after two flat rounds, or when blocked; record the reason when parking.
- Write READY.md, push, stop.

**Coordinator loop (every 25–30 min):**
- Batch lane gains into one `tb/land-batch-N` PR built with `git merge-tree` and `commit-tree`.
- Before pushing, check that JSON parses, every OFF `creature_model_flags` entry is in HELD, no test asserts a newly ON flag OFF, and any big deletion is only reformatting.
- Open the PR with the template body and the `full-ci` label, and subscribe.
- Run only one full-CI PR at a time; stack the next batch on it.
- Merge by hand when green. Re-run a failed job once, after a comment.
- Republish the board.

**Blocked (owner, GPU or capture):**
- F38#30/F38#24 floating Burrow Warrens: owner terrain decision.
- F39#15 shoals: terrain re-bake plus route re-proof.
- F41#21/#16 Hollows results: GPU only.
- F41#3 Capacitor Alpha spacing (+0.05 arm OFF): combat-contract decision.
- F38#19/#26/#31/#33: capture-tool fixes (below).
- F41#14 candy: the +0.29 arm breaks the rule that rarer candy is bigger.

**Known CI:**
- `smoke_net_f48_cut_key` intermittent stale peer: NET-F48 watchdog fix landed. If it recurs, read its handoff.
- `smoke_water_combat_pause` (#843) and `smoke_water_dismount_state` (#837): one failure each, both passed on re-run.

**QUEUE: quick wins first (built but never judged, or one fix away):**
- Judge these arms: F38#12 orb reward and F38#5 grow-only scale (VIS-MEADOWS), F38#28 arena boundary arms (VIS-STORMWOOD), F39#25 map overlay (NEAR6-TW), F40#2 stone-ground candidate (VIS-CLOUDREACH).
- F40#12 Cloudreach speaker: unclaimed, base captured.
- One tooling lane:
  - Carry VIS-TIDEWAKE's quick_judge `find_frame` patch (`runbook/quick_judge_find_frame.patch.py`) into `tools/visual_judge/quick_judge.py`.
  - HUD stand settle frames 900 (F38#19).
  - Stand creatures keep physics (F38#26).
  - Stand alpha pose calls `set_alpha(true)` (F38#31).
  - Catch capture shoots `06-breakout` while the card holds (F38#33).

**QUEUE: Blender rows:**
- F41#1 Stormheart crown and core (3.94).
- F41#8 outfit variants (4.96).
- F38#17 Solene/Hald variant.
- F40#1 stone shelves (5.29).
- F41#9 harvest cues (5.40).
- F36#70 Sparkit legs (5.41).
- F38#6 pickup cloth (5.52).
- F39#31/#2 Veilfall (5.56/5.78).
- F41#14 candy in rarity order (5.70).
- F40#4 strata edges (6.27).
- F38#41 boulders.
- F38#20 keep on a hill.

**QUEUE: scene and shader rows:**
- Fulgocobra and Mirejaw eye emission (5.78/5.84).
- Shadelet, Paddlenewt, Glimmermoth and Tempestwing faint clipping and floating hit-react.
- F40#19 rain wetness (5.61).
- F40#17 rim turf (6.19).
- F41#6 telegraph cues (6.76).
- F41#7 baseline (6.58).
- F39#16 dash rhythm (6.75).
- F38#38 Missing chip (7.33).
- Not started: F39#17, #8, #10, #5, #27 and F38#36, #11, #27.

**Coordinator recommendations:**
1. Feed lanes actionable rows from this QUEUE, not the raw lowest. Most of the lowest rows are blocked or art.
2. Order by fresh scores. Run the GPU re-judge first if possible; otherwise run a CPU baseline sweep.
3. Make lane start-up cheap. The next coordinator's first job: in a fresh session with disk room, test and propose (`update_environment`) a Default-environment setup script. It should install Godot 4.7-stable (github.com godotengine releases) to `/usr/local/bin/godot` and portable Blender 4.2.3 LTS (download.blender.org `Blender4.2/blender-4.2.3-linux-x64.tar.xz`) under `/opt`. Both reachable 7 Nov. This saves 20–30 min per lane and avoids the permission prompt that blocked one Blender install. The disk needs about 10 GB for the full import plus Blender. Delete frames after each round.
4. Or keep five long-lived lanes that pull the next QUEUE row and reset their context between rows: the same Ralph effect, no cold start.
5. Cap each row at 3 judged rounds or about 3 h, or 5 rounds or about 6 h for art rows. Let one art lane carry related pieces.
6. Budget the weekly limit. Nine sessions used it in about 3 days (stopped 5 Nov 03:00 UTC until 7 Nov 03:00). Quick-judge rounds are the main cost; drop to three lanes if needed.
7. Keep landing batched; never open one PR per row. Full CI takes 35–60 min, and overlapping runs starve the runners.
8. Never put two lanes on rows that edit the same file (`hud.json`, `creature_coat_flags.json`, `tidewake_look.json`, `stormwood_ground_finish.json`). Group rows that share a cause.
9. Open owner decisions: F38#30 Warrens; F41#3 spacing; whether to land the 288 MB of F49 route saves; rotate the Meshy key.

**Earlier owner rulings still in force** (full text in Git history):
- 24 Oct: GPU judging closes visual rows (Medium and High, yardstick, mapped Bar A ≥ 7.5). CPU is for iteration, and the 6.7 CPU-provisional rule is retired. Rows are split per asset and subject, with the bars unchanged.
- 24 Oct: raise the floor worst-first: below 6 to 6, then all to 7, then 7.5. Unscored areas get a baseline first.
- 24 Oct, creature touches: current meshes stay; species gain light energy, elemental or war-worn touches. "Just shrink it": Terrapup ships at 3.20 m (the only exception to never-shrink).
- 17 Oct: F36#1 judges fly-grip only for Fly-capable species, and swim or ride only where used in play. CPU-only evidence never parks a visual item.
- 2 Nov, F49#0: "Park the opening join, just finish the training loop." The earned line from `relay` is accepted, and no Meadows-opening seam is required.

**Active owner rulings (4–5 Oct):**
- Visual target: High/Medium judged to the full bar; Low/Compatibility checked for breakage until the Ally test passes. UI's second check is 1280×720. F36#0 may refine only the identity of installed NPCs.
- Grandpa's house gets one free creature bed using the camp component. Meadows ordinary-wild tuning waits for this and an F02#6 rerun (earned-run finding: eight potions for 10–12 practice fights, no slack).
- F22#1 sweeps ordinary trainers per band: reader win ≥0.9, reader median lead HP cost ≤55% of masher, and wilds keep their separate COMBAT §7 floor. All starters are balanced; no Terrapup tank exception.
- F26#5 stays owner-blocked until the built-game Ally test; Compatibility remains default and Codex builds no Ally package. Desktop performance is a release blocker (Medium 1080p target ≥60 fps average, 1% lows ≥40); latest GTX 1060 routes were Meadows 11, Tidewake 7, Stormwood 17 fps.
- One feature per lane before the next; re-proof folds into the lane. Build product, not test equipment: add tooling only where a criterion lacks verification. Co-op/save/economy changes need tests; visual/feel/content/balance need code-blind judgment or playtest. Update assertions with changed behavior. Newer13Oct rule: bounded pieces/matched saves replace long runs, including F49. Known-red probes run only in scheduled full/manual CI; multiplayer `net` skips presentation-only changes.
- When only blocked criteria remain, record the blocker, take the next planned feature, and return when the blocker clears. F18 closes per criterion behind its flag; F22#2 closes with F24's tag-switch combo. Only a charge begun after its tell can be broken (0.1 s grace). Crossing Hall home arch returns to the last Meadows waystone.
- Co-op rejoin: host folds its own journaled payouts first; adopt the guest declaration at higher revision unless it is behind (missing any held receipt, personal flag or absorbed payout), in which case keep the held record. Implemented on `tb/f17` (66b2f539); audit/review: `ralph/reports/HUB/f17/`.
- Independent review remains mandatory for co-op, save, economy and world-visibility changes; pure tuning/data/visuals go to their check or code-blind judge. Rebaseline delivery pace while retaining scope and showing the former schedule as a ghost. The controller map is confirmed in COMBAT §1/UX §2.2: ultimate and Tether Commands are tap-then-tap, orb aim LT, flee RT, LB+face optional; commands unlock at practice catch and first two-creature fight.

**Settled owner decisions:** ROG Ally/home play pass occurs on the built four-chapter game (F49#1; F26#5/F49#2); nothing else waits on the owner. RD-26 caps attended Meshy work at 30 generations/night; Stormwood storm bear is named Stormursa (RD-28). Internet co-op completes the existing Steam invite path with free development AppID 480, two real accounts on separate home networks; no Epic/other relay, product AppID only at ship, Steam ship packaging stays OFF until then. Four accounts and partner access remain owner resources. Stormheart is the final relay; Tidewake's regional link remains one of four and its dock exchange closes the chapter. Demo scope is Meadows, village road, Hall and first homestead loop; price, launch and spending remain undecided. CODEX_START_HERE §8.1 defaults are owner-confirmed. Stormwood charged ground gives light, nonlethal trainer-only damage; gear reduces it and creatures are never hurt; Tidewake submersion remains drowning-only. Evidence/image policy: approved old report images move to a GitHub release archive with links; new images go to CI artifacts, text evidence stays and history is not rewritten. Stormwood audio assets landed in #540; spectral/loop checks and evidence: `ralph/reports/AUDIO/stormwood-nine/`.

**Open co-op items:** Stormwood hosted trainers lack durable actor vitals (F27 excludes them); guest catches stay local while `alpha_respawns` is OFF (F27); behind guests can lose an unfit payout (L2). M1's personal-flag case is resolved: a behind guest is re-offered.

**Owner-only:** human playtest F49#1 confirms F47#0's 15–25 h; ROG Ally Medium runs F26#5/F49#2. Board: [private board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site). Flags and fixtures never close acceptance.

ACCEPTANCE reconciles RD-01..RD-37 (PR #527); eleven legacy-path tests retire when portals turn on. Settled historical rulings remain in Git; §1 and owning specs govern.
## 1. Rulings in force

**Owner redesign (2026-09-29):** CODEX_START_HERE §1 (RD-01..RD-37), subject to newer13Oct owner takeover§0, governs. Where a ruling below conflicts with it, the RD entry wins, including RD-36's minimum necessary testing and batch validation. Other proof/counting rules remain.

**Retained owner/coordinator rulings:** newer owner direction supersedes conflicts.
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
   - Root Codex consolidates ready lanes under13Oct takeover; old per-lane self-landing is superseded.
   - **Wind-down:** push everything, including WIP; unjudged visuals land default-off/unwired. Coordinator consolidates, runs units once and CI once.
   - READY means a criterion fully closes, with an attached strict re-check, one criterion at a time. Codex-queue IDs are lane-prefixed and append-only.
10. **F04 retained evidence:** `ralph/reports/MEADOWS/f04_bosses/r1/`.
11. **Owner decisions, 23:55.**
   - **Meadows named trainers are made harder** until C2 passes: team-wipe rate at or above the 0.25 bar (F04#7). The bar is restated by ruling 12.
   - **Galewisp and ripplet are tuned to match terrapup in skill and strength**, so starter C2 difficulty is even (F10#2, CREATURES).
   - **The 326 m walk from the Hall exit after the finale is acceptable** (exempt from A7 and WORLD §3.1 spacing; M2).
   - **Codex does the Cloudreach aerie art** (F08#3). Active Astra Cloudreach look lane now owns it.
   - **Vess, the female officer,** gets the female officer body and portrait. Add a `defeated` clip to `officer_b`.
12. **F04#7 top-fight bar (owner28Sept optionc):** per fight/starter24seeds, reader win≥75%, masher loses lead every run, reader party cost≤55% of masher. Chapter interpretation: masher loses a named fight in≥25% of plays (measured0.94–1.00). Vance Band3 pin option remains. Also F14#0; COMBAT§7/BOSSES§9/ACCEPTANCE C2; later type-matchup ruling below qualifies disadvantaged/advantaged leads.

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

CODEX_START_HERE RD01–37 governs: four chapters Meadows→Tidewake→Cloudreach→Stormwood,15–25hours; creature growth/homestead; type-essence levels, ten-level Master/Feast breakthroughs, three moves+ultimate. Trainer support never damages; five companions, keeping all five is success. Water critical path requires no owned swimmer. Hall portals/Shrine/HomeKey/waystones; Stormwood homecoming/credits/fifth arch, eight biomes planned. Saves reset. Palworld/Animo creatures/world and Valheim atmosphere; Compatibility default pending Ally. Existing tools/assets/license only, RD26attended≤30generations/night, RD28Stormursa; no other roster expansion/unreferenced text-to-3D/purchases. Invite co-op without typed address/router setup required. Each freeing-fight participant gets a stable-character once-only legendary offer; nonparticipants none. Keys/relics per participant. Price/positioning grants no spending/commercial-launch authority.

## 3. What exists

| Domain | Built baseline / remaining proof |
|---|---|
| Combat/creatures | Wind/poise/burst/hitstop,57base species/IV/bond/evolution; C2/C3, large-body camera, BarsA/B and clipping remain. Galecrest head-tracking override did not land. |
| Meadows | F02/F05/M4 historically met; F01 walks/F03#0/F04/visual bars open. |
| Cloudreach | Six regions/Fly/activities(F07)/Veyra/Solmane; C1 and owned-carrier Fly closed. F08#3/#4 art in active look pass. |
| Stormwood | F09/F11/S1/S3 historicalMET; F10#2C3/#6device open. Deepwood3d5fb0e6 performance, bright aftermath, pools_west_loop/b_pools, b2curb1.11m/d_giant0.4–0.67m steps remain. Compatibility Camera3D.v_offset black world: `STORMWOOD/f10_6/r3/ab_top_band/`; NPC during wild: `STORMWOOD/s1/phase1_rerun/`; CHARGER missed with ally inside: `STORMWOOD/f10_2/c3_p1/` Wtell4. |
| Tidewake | F12/F13#3/F15/T3 baseline; Aquaryn/Tidecoil framing passed, Tess/Nerissa contact occlusion open. F13#5/current read and full look now active. |
| Multiplayer/save | ENet/portable ledgers/exact-pose rejoin/default-OFF Steam lobby; invite/host+3/device proof open. Historicalv27/world2/character6 evidence; redesign refusesv27-and-older without overwrite. Ambiguous legacy receipts/slot renames not recovered. |
| Redesign/visual/audio | F16 accepted; old15/179subtotal superseded by board§0. ACCEPTANCE§6.2/F49 are done bar; BarsA/B, music/mix open. `ralph/reports/VISUAL/AUDIT.md` retains evidence context. |

## 4. Risks and evidence boundaries

- GPU: F21#5/F25#4 Medium/Compatibility memory-stopped before combat, no timing proof (`ralph/reports/GPU/F21-F25/PROOF.md`). F26 High/Medium20/48/24/25frames Meadows/Tidewake/Cloudreach/Stormwood: WEAK/FAIL/WEAK/WEAK. Four-peer release proof separate.
- Full-port solo boss reward loss open (full-bag captain fixed209748abd). F18portalON; station-craft/rejoin relic/HomeKey fixes exist, hung-relic reload loss open. Old Hall-sign report predates#682fix; mastery-flush re-landed#682, required witnesses remain. Audit `ralph/reports/INTEGRATION/criterion-audit/`; dashboard `ralph/reports/COORDINATOR/dashboard/` owns current counts/active_lanes.

- **Wayfinding.** Owner's highest-impact complaint: corridor feel. Beacon/map reveals landed; judge geography/detours from whole paths, not beams.
- **Fixture debt.** Most met criteria use disclosed fixtures/teleports/harness fights, not fresh-play proof. Earned four-chapter chained proofs and human passes retire this debt.
- **Shared-fight geometry.** The proxy-body divergence behind a guest's non-landing blow is fixed at root (`tests/test_remote_proxy_snap.gd`; MEADOWS-PAYOFFS/proxy-ground-plane). Re-check guest-hit smokes after any follow or collision change.
- **Legacy receipts.** Ambiguous peer-ID receipts are not auto-recovered. Corrupt legacy saves must stay inspectable without mutating live runs.
- **Steam packaging.** Shipping Steam packaging remains OFF; development uses AppID480, required real-network proof remains open. Simultaneous two-client ENet disconnect may log a harmless native error.
- **Visual verdicts.** Software-GL proves composition/scale/colour, not fine lighting/performance. After two rounds without progress, change asset/approach, not tint (ART_DIRECTION §9).
- **Accepted art:** camp set, pickups, South Bridge gate and lost rigs retain ART_DIRECTION §7 dispositions unless gameplay evidence reopens them.
- **Owner reports.** Fresh owner repros reopen ledger-fixed items; first check the played build.
- **Forward camps F34:** Tidewake BuildPlacer places camps, refuses sea/shallows; world-load8.6s vs8.8–9.5s baseline. Guest placement limited to host-loaded realm; second-camp pack-up offered with kit. Allowed-rise ground does not block clearance, other low colliders do. `ralph/reports/HUB/f17/f34/`.
- **Opening gifts for a co-op guest (F01#6a, lane A).** Grandpa's gifts are held until the Home Key settles, then claimed from the host under the conversation that spoke them; a batch spoken while one is held waits behind it with its own name. UX follow-up (open): a guest's Basic Orbs arrive about 3.7 s after Grandpa hands them over, which is noticeable. Evidence: `ralph/reports/F01-FIXES/f01_6a/`.

## 5. Dependencies and still-open design questions

- **Owner resources:** partner access and four accounts (§0); developmentAppID480 is settled, productAppID at ship.
- **Meshy:** Meshy runs through Codex on the owner's machine. Claude sessions hold no key.
- **Design questions** (keep current behaviour conservatively until settled):
  - the wild defeat persistence policy;
  - which replacement subjects the reference/Meshy workflow takes: answered by RD-26, the priority list confirmed in F36 (ART_DIRECTION);
  - a Burrowback contrast treatment that keeps its identity;
  - a grass clump redesign beyond the approved settings.
- **Validate:** ACCEPTANCE §7 release performance on owner-provided Ally hardware; fair late-catch bond; shared encounter scaling. Failures require retuning, not relaxed bars.

## 6. Owner direction carried forward

Catalog defects scored above 12 must meet the full game bar and close with evidence (CODEX_START_HERE §1); live owner priorities and hard rules remain in §§1–2. New owner feedback supersedes older direction. Activation/criterion work moved to Astra on 2026-10-02; never consume a usage reset automatically.
