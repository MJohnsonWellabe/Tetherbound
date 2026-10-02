# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Astra takeover — activate, prove, land, close

**Owner direction, 2026-10-02:** Stop/archive this coordinator and its lanes without losing work. The goal and heartbeat are PAUSED; do not resume the old coordinator or three-lane plan. The owner will start a new Astra lane to turn the features on, code missing behavior, prove each criterion and continually keep main green. No new session is started by this handoff. This direction supersedes source-only/default-off delivery assumptions.

**Done means:** The intended features work in ordinary title/new-game/continue/controller play with production defaults, genuine save/reload and solo/co-op behavior. Required CI passes on landed source; each closed criterion has full acceptance evidence and independent review recorded on the board. Code presence, detached fixtures, test overrides and CI alone do not close criteria. Scope:34 feature rows F16–F49/179 redesign criteria plus101 original criteria,280 total.

**Resume:** Use `D:/tetherbound/foundations-batch-check`, `tb/integration`; parent `D:/tetherbound` is not Git. Preserved code baseline `d74d88fef5f3955d2d4d6ee9f3e6cb1059723ab5`; takeover commit adds documentation/evidence. Main is `30fcc38fc591d5df3a7cfb122b9da58445467021`, still red. Draft [PR519](https://github.com/MJohnsonWellabe/Tetherbound/pull/519) remotehead `6a591e548e3d9a1aa3b46411862245792013d09e` is behind LOCAL source. Do not reset to it. R1/R2/R3 initial code is consolidated; that did not activate every feature. MET110/280 unchanged, zero new closures. Last fullCI6175/36944890249 failed; mainCI6174 failed.

**Activation gap:** At least17 rows have important behavior disabled: F18,F19,F20,F22,F24,F27,F28,F30,F31,F32,F33,F34,F42,F43,F44,F45,F46. This does not mean17 wholly disabled features or87 blocked criteria. Portal/ending/curve, patterns/Commands, Altar/essence/feasts/traits, stations/materials/gear/camps and menus/bounties/repeatables/research/lessons have false production gates. Additional art/loadout/evolution gates need audit. F19 curve is unmounted; flipping its flag alone is insufficient. The F48 six-file overlay enables selected mechanics ONLY in tests and restores defaults. It never activates the game for players.

**Astra execution plan:**
1. Take sole ownership of this integration checkout/STATE. Read CODEX_START_HERE, ACCEPTANCE §6.1–6.2 and relevant design contracts. Inspect preserved source, main/PR/jobs and the branch manifest below. Recover useful unmerged work by review, not resets or blind WIP merges.
2. Enable the intended F16–F49 gameplay/UI/content in the candidate's ORDINARY production configuration now; code the missing callers/mounts that make it work. Trace config → real UI/input/action → authority → durable save → reload. Include actual level/encounter tables, combat/loadout/Commands, progression, stations/materials, portals/ending and repeatables. Keep disabled, unreachable or test-only features INCOMPLETE. Do not blindly enable unrelated debug/retired alternatives/reserved biomes or invent human/device/platform approval.
3. Build real player loops: title/opening → resources → build/use Altar/stations → teach/equip/attack → essence/cap → Master/feast → portal/waystone → relic/next biome → homecoming/credits. Extend the working path across all four chapters and co-op. Repair gameplay, persistence, admission and arrival causes as they fail. Proof machinery must not replace the missing game behavior.
4. For EACH criterion record full acceptance text, enabled defaults/callers and exact required proof. Run meaningful native/controller/save-reload/co-op/visual/device checks under the shared engine lease; retain raw results and source/config/package hashes. Prove every conjunction: catalogues do not prove paid player actions; local ACKs do not prove guest delivery; fixtures do not prove earned economy/duration. Reuse relevant actual proof only when changed source/activation preserves its scope. Reassess all280 including historical110; explicit human/device blockers stay OPEN.
5. Land coherent enabled working batches continuously through validated PRs, reusing PR519/the long-lived branch where suitable. Run appropriate local checks and required CI on exact source, fix returned causes, merge validated work and verify actual MAIN CI/package identity. Do not wait for every feature to close before landing a sound batch. Never cure red by turning the feature off, skipping required tests, weakening acceptance or direct main pushes. Use one consolidated full CI per meaningful integration batch, not per tiny edit.
6. Close exact criterion IDs only after clause-complete proof passes independent review and the required enabled behavior is on validated main. Update board/evidence/STATE immediately. Report working enabled features, landed validated SHA, newly closed IDs and concrete remaining blockers. Mapped, source-written, candidate and partial-proof counts are not closures.
7. Continue the next OPEN criterion. After two failed attempts/report-only turns, change approach; deliver player-visible progress and commit regularly. Additional lanes are the new owner's choice; do not restart archived sessions or the paused heartbeat.

**Known blockers/evidence:** Named native fixes cover the original17 unit failures; CORE845f PASS528.688s proves opening/tournament readiness, not the full new game. Raw source-bound returns: `ralph/reports/INTEGRATION/branch-closeout/returned-evidence/`. Full F48 inputs/all24 cuts remain OPEN: V7/V8 paidAltar failures retained; reviewed owner/epoch repairs remain fullflow-unverified. V9failed initialhostload_save BEFORE Altar with freshHB, incomplete120physics settling; fix actual boot/callback/readiness, not bounds. Latest diagnostic was OWNER-INTERRUPTED with no verdict, configrestored/sourceexact/0handles; its extra snapshots cannot prove uninstrumented speed. Changing production defaults needs truthful new source/config pins and genuine inputs, not edited old profile478 receipts. Existing F48 shell already dispatches its runner. Veridian/scaling/hosted crossing runtime proofs remain open; CI6175 scatter and intentional peer-death control passed. Evidence170-row draft:5candidates/109partial/56missing, final audit unfinished,110not rechecked,0newMET. Full visual/audio/device proof remains required; original §0 below-baseline history and sealed packets locate every prior return.

**Recover work:** Exact checkout/branch/HEADs and archive history: `ralph/reports/INTEGRATION/branch-closeout/session-takeover.json` → `owner_stop_and_astra_takeover`. No source/import/worktree/ignored runtime data deleted; commits LOCAL, no stop-wrap push/CI. Integration includes reviewed repairs/input gate/timing/diagnostic. Unmerged UNVERIFIED work: `tb/astra-ci-closeout`420eabf9e0 harnessfix; `tb/astra-player-closeout`33fedcee4d realTM/Altar/hit proof; `tb/r3-f48`1e696c7db1 genuine save/load/lifetime observations; `tb/criterion-evidence-closeout`5a83a6b8ae draftreviews/inventory/TMhelper. Review these before picking; native or compilation proof is missing. Foundation93afca390a/inputbed1b235fc retain already-integrated source.

**Board:** [private board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site), source/scoring/republishing: `ralph/reports/COORDINATOR/dashboard/`. Binding decisions remain below/CODEX_START_HERE. Older §0 details: `git show d74d88fef5:docs/STATE.md`.

### Open owner decisions

Recommended defaults: keep Compatibility until the Ally gate; retain the 30/night cap and Stormursa name; keep Steam packaging off without an AppID; keep the tap-then-tap controller map and §8.1 defaults. Recommend scoped installed-source Stormwood audio with owner listen, Stormheart as final relay, and existing PRODUCT defaults; these decisions remain open. Human play/device proof uses the passing integrated build.

1. **ROG Ally test (F26#5):** run one Forward+ test build on the Ally (Medium preset, handheld, the scripted route) when `tb/lookdev` posts the checklist here. Forward+ becomes the default only after this passes.
2. **Meshy credits:** the overnight cap is 30 generations per night (RD-26) unless the owner sets another number.
3. **Storm bear name:** the working name is *Stormursa* (RD-28).
4. **Internet co-op proof:** real Steam AppID and partner access, four accounts, at least 2 on separate home networks. `steam_api64.dll` redistribution is approved; packaging (`ship_steam_runtime`) stays off until an AppID exists.
5. **Stormwood audio:** whether to author the nine missing `assets/audio/stormwood/*.wav` from installed sources under AUDIO §10. Agents cannot listen, so acceptance would rest on spectral and loop checks plus an owner listen.
6. **Owner play pass (F47/F49):** a human play pass at the end of Wave 3.

7. **Story framing of the final relay:** Tidewake was written as the supply network's final relay. With Stormwood last, the recommended reading is: Stormwood's Stormheart is the final relay; Tidewake's regional link is one of four; the dock exchange stays Tidewake's chapter close. WORLD keeps the current wording conservative until the owner confirms.
8. **PRODUCT proposals to confirm:** the cut order within owner-decided systems, the "Build the best five" sub-line, a demo that includes the village, the Hall and the first homestead loop, and keeping US$19.99 at 15–25 h.

9. **Design defaults taken in the doc pass** (conservative, the owner may override): listed in CODEX_START_HERE §8.1.

10. **Controller map for the new combat (COMBAT §1, UX §2.2): please confirm.**
    - The ultimate and commands are tap-then-tap sequences (tap RB, then a face button), not chords, to respect the no-held rule.
    - Orb aim moves to LT and flee to RT.
    - Ordinary consumable use stays free, and the Tether Command item throw only buys an instant throw (default).
    - The LB+face command layout is an optional preset only.
    - Command unlock: item throw and Snare at the practice catch; Rally and Tag-switch at the first two-creature fight.

11. **Meadows waystones (F18):** recommend home arch returns to last Meadows waystone; keep home-only until owner confirms.

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
