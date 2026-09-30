# State — live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Resume here

**Resume (owner redesign, 2026-09-29):** the owner's design interview replaced the Phase 1 and Phase 2 plans. Every lane now works from **`CODEX_START_HERE.md`**: owner decisions RD-01..RD-35, Waves 0–3, features F16–F49, lanes with owned files, work orders, and landing, hourly push and board rules. Start with **Wave 0 (`tb/foundations`, F16)**. `tb/combat`, `tb/vfx` and `tb/lookdev` may prototype in parallel. The detailed Phase 1/2 lane history that stood here (serial closer, Meadows/Stormwood/Tidewake/Cloudreach/Cards/Combat-spacing handoffs, Phase 2c/2d wind-downs) is in Git at `1c3f0b0d` (`git show 1c3f0b0d:docs/STATE.md`).

**Board:** `ralph/reports/COORDINATOR/dashboard/` (`criteria.json`, `status.json`, `build_dashboard.py`; README for the scoring rule and republishing). **Criteria met: 95 of 280.** That is 95 of the original 101 (F01–F15) plus 0 of 179 redesign criteria (F16–F49, ACCEPTANCE §6.2). No chapter is accepted. Current /goal execution starts from e2de59571; F16#0 is in progress, and no new criteria are counted. Main was green at `8f5dd6ed2` (full CI run 36626653020), and the rolling download was rebuilt there.

**Still-open original criteria and where they go (CODEX_START_HERE §7.5):**
- F04#1, #2, #6, #7 (Meadows named fights) and F14#1 (Nerissa C3) fold into **F22#4**. Their last evidence and BAR files are under `ralph/reports/CLOSER/` (`f04_6/`, `f04_2_7/`, `f14_1_nerissa/`), `ralph/reports/MEADOWS/f04/` and `ralph/reports/TIDEWAKE/phase1/`. Recurring residue: contact-range overlap, the ally covering the foe's head, and HUD cover. **Every C2 number and judge capture taken before #448/#450 (the combat timing change) is stale** and must be re-taken on main.
- F10#6 (Stormwood handheld HUD) folds into **F42#2**. The r7 judges contradicted each other (`ralph/reports/STORMWOOD/f10_6/r7/`); small HUD text fails at 7 inches.
- Cards M2 (blocked at Keeper Hald: no heal-and-retry in `tests/helpers/meadows_earned_hall_segment.gd`), M3, S2 and T2 re-run under **F49** in the new order. Complete: M1, M4, C1, C2, C3, S1, S3, T1, T3 (history; F18–F20 replace their physical-crossing and Tidewake-credits clauses).

**Known defects carried into the redesign (each has an owning feature):**
- Tidewake current direction does not read at 7 inches. Flat water marks, rock wakes and foam darts all failed; the untried idea is standing-wave ridges (`ralph/reports/TIDEWAKE/phase1/t2_current_direction/`). Owner: F39.
- No Stormwood audio assets (`assets/audio/stormwood/` is empty), so the Surge phases are silent. Owner decision still open (below). Owner: F41 and AUDIO.
- `smoke_party_strip_reflow` and `smoke_progression_feedback` fail on baseline and are not in CI. Owner: F42.
- The travelling-lane "locked" visual reads the global `face_lock_fraction` instead of the per-body value (`wild_creature.gd`). Owner: F22.
- Visual catalog `ralph/reports/VISUAL/phase2/catalog.csv`: 116 rows, 106 with impact >12. Fixed and enabled: P2-032, P2-042, P2-095/096. Open with evidence: P2-008 (Tidewake shore, `fixes/P2-008/phase2d-shore-profile-review.md`), P2-037 (Stormheart tree), P2-021/022 (Cloudreach skyline and crown). `top20.csv` statuses are stale; use `catalog.csv`. Owners: F38–F41 after F26.
- Flag-off, unjudged: Stormwood `scorched_scars`, Cloudreach towers and occupied terrace, Tidewake Pump Hall kitbash. Enable only on a passing code-blind judge.
- Fresh containers: the reference boards are skip-worktree. Restore them with `git ls-files -v docs/reference | grep '^S' | cut -c3- | xargs git update-index --no-skip-worktree && git checkout -- docs/reference`.

**Recent landed owner requests (2026-09-29):** combat pace faster on both sides and power-attack re-aim (#448/#450/#454/#457, `combat.json` `strike_reaim`, `player_pace`); sprint lean and cadence (#449; owner to feel it on a pad); village option B, one straight main street (#455, `tests/test_village_main_street.gd`), which F17 now rebuilds into the road-plus-Crossing-Hall layout. The mouse-capture fix needs the owner to confirm it on a real PC.

**To resume work:** read CODEX_START_HERE §0 and your lane's work order. Work on `tb/<lane>` from current main. Push at least hourly. Land each closed criterion through the lane's own PR (strict re-check, unit suite once, board and STATE line, auto-merge). The board-duty holder rebuilds the board hourly (§7.3). Add one line per landing to the lane table below. Keep this file under 25 KB. Current /goal explicitly resumes the full redesign and supersedes the older wind-down stop below.

| Lane | Features | State |
|---|---|---|
| `tb/foundations` | F16 | F16#0 implementing v28 refusal on current main e2de59571; proof/re-check open |
| `tb/hub` | F17, F18 | waits on F16 |
| `tb/reorder` | F19, F20 | waits on F16, F18 |
| `tb/combat` | F21–F24 | read-only impact/authority prototype active; edits and landings after F16 |
| `tb/vfx` | F25, F35 | read-only archetype/arrival prototype active; edits and landings after F16 |
| `tb/lookdev` | F26 | read-only preset/runtime prototype active; edits and landings after F16 |
| `tb/training` | F27–F30, F37 | Wave 2 |
| `tb/homestead` | F31–F34 | Wave 2 |
| `tb/creature-art` | F36 | Wave 2 (after the F26 look bar) |
| `tb/visual-meadows`, `-tidewake`, `-cloudreach`, `-stormwood` | F38–F41 | Wave 2 (after F26) |
| `tb/hud` | F42 | Wave 2 |
| `tb/loop`, `tb/balance`, `tb/coop`, `tb/release` | F43–F49 | Wave 3 |

**Active ownership:** `tb/foundations` owns the F16 save/title refusal, central-order consumers and legacy-crossing gate call sites through Wave 0; hub/reorder take those paths only after F16. Exact extra paths are in board `status.json` WIP. `tb/redesign-board` holds board/STATE writes during this slice. Godot writers serialize; no prototype runs Godot. Reference boards restored in the clean board checkout.

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

**Settled and kept (history in Git):** the Capacitor Alpha no-stagger ruling and storm strikes sparing trainers in fights (owner, 2026-09-27 23:55); harder Meadows trainers, starter parity and the female officer Vess (batch 68); the C2 masher rule (ruling 12, option c).

## 1. Rulings in force

**Owner redesign (2026-09-29):** CODEX_START_HERE §1 (RD-01..RD-35) is the newest owner direction. Where a ruling below conflicts with it, the RD entry wins. The rulings below still govern proof, counting and process.

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
| Stormwood | Earned six-region route, Arches, Dynamo, Stormheart and aftermath. F09, F11 and cards S1/S3 are met. | F10#2 C3, F10#6 device profile. Open risk (owner: Stormwood lane): no perf measurement of the dense Deepwood bake (3d5fb0e6). Phase 2: aftermath under the canopy brighter than the owner's ruling. Findings (owner: Stormwood lane, after S2): pools_west_loop crosses the lit b_pools arch; a 1.11 m curb on b2's landing side; a 0.4–0.67 m step behind d_giant. Defect (owner: Tidewake, F14 C3): the top band's `Camera3D.v_offset` lens lift renders Stormwood's lit fight world black on Compatibility (`STORMWOOD/f10_6/r3/ab_top_band/`). Defect (owner: X03): `interaction_arbiter.gd` does not gate on a starting wild fight, so `interact` can open a nearby NPC mid-fight (`STORMWOOD/s1/phase1_rerun/`). Residual (owner: X01 combat): a named CHARGER strike reads "it missed you" while the ally stands inside the drawn lane (`STORMWOOD/f10_2/c3_p1/` W tell4). |
| Tidewake | Human swim route (F12 met), eight pockets, six local chains with map leads (F13#3), dock residents and current comets (F13#5), dock exchange, return, Grandpa and credits (F15 met, T3 complete). Veilfall rooms show their pumps, sluices and banners. | Named-fight C3 framing: Aquaryn and Tidecoil pass. Tess and Nerissa are blocked on contact-range occlusion, which needs a shared combat spacing rule. Bars A/B looks go to Phase 2. |
| Multiplayer | ENet authority, portable characters, ledgers and receipts, the exact-pose rejoin, and an optional default-off Steam lobby path. | Internet relay and four accounts (owner resources), host plus 3, device. |
| Save | Save version 27 with world format 2 and character format 6; atomic split saves; refusal of corrupt or absent halves without live mutation. | Legacy peer-ID receipt and slot-rename ambiguity (not recovered). |
| Redesign (F16–F49) | **Nothing built yet.** Partial foundations: bond milestones, the Mudsnout evolution, `good/great/rare_candy`, 5 trainer armor slots, the craft panel, buildables (workbench, storage, creature beds), berry farm plots, TMs (18) and 52 moves with `vfx {kind, colour}` shapes, the realm gates, and the `realm_key_*` flags. | Every F16–F49 criterion (ACCEPTANCE §6.2). |
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
- **Usage/stop direction:** the owner overrode the 10% usage stop rule for P2-008 on 2026-09-29, then explicitly requested landing the work on `main` and stopping for now. The current stop request governs; resume P2-008 only at the owner's direction. Never consume a usage reset automatically.
- **Owner redesign interview, 2026-09-29:** 35 decisions, recorded as RD-01..RD-35 in CODEX_START_HERE §1. The owner asked that every catalog defect scored above 12 be fixed to the full game bar, "not just passing the defect", so the game looks like something people would play (Valheim, Palworld, Animo, ARK as quality references). Done means the whole plan is done: push consistently, rebuild the dashboard hourly, then burn the criteria down over time.
- Record owner feedback here; it overrides other documents on its subject.
