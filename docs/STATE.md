# State â€” live status against the release plan

Read first; update in place, under 25KB. No dated status/goal/directive/handoff documents. Evidence: `ralph/reports/<LANE>/`; history: Git and `archive/`.

## 0. Handoff â€” Claude CI pass on PR519, returned to Codex (2026-10-02)

**Active integration:** The owner assigned Codex to bring the existing PR519 baseline to green main before taking the new feature sessions' work. Baseline is f48a0ba1ea; integration uses `D:/tetherbound/foundations-batch-check`, `tb/integration`. F17–F20 continue separately and return bounded deltas; only an independently verified dependency required to fix the selected gates belongs in this first cut. CI6200/37068576138 is the baseline run. No merge or acceptance closure yet. Initial admission-cost repair reuses the existing authored species catalogue without caching character state; affected checks and measurements are in `ralph/reports/INTEGRATION/main-green/PROOF.md`.

**Current blocker:** F48 real paid-Altar run37075508544 proves JSON numeric save loss in the complete owner carrier, world journal and building height. The integration candidate introduces a shared lossless save envelope while retaining schema28/old-save refusal and exact transaction equality. Actual writer/reload/recovery and scoped compatibility checks pass; full CI and native producer/interruption proofs remain open. Targeted F18/F19 baseline dependencies and the Nysa outer-watchdog correction are integrated; broader F17–F20 completion stays separate. Exact evidence and limitations remain in the existing integration proof report.

**Authority:** The owner asked Claude to move `tb/integration` ([PR519](https://github.com/MJohnsonWellabe/Tetherbound/pull/519)) to main, fixing CI as it ran; then, with a short window and no owner-run steps available, to stop at a state Codex can continue. PR519 stays **draft and unmerged**; main is 30fcc38fc. The game is unfinished; MET110/280 is unchanged. The owner deleted every other `tb/*` branch; each was verified fully contained in `tb/integration` first (including the four formerly "unmerged" closeout branches, already gone).

**F18 candidate:** All six criteria remain UNPROVEN. Earned R6 actual opening/catch/protected Drop/slot5 key/combat/Mira dialogue/Settings Replay cutscene/vendor absence/tool bindings and all4strict actualshop-owner handoffs pass; Workbench still fails because fixture confuses shared thumbnails with piece IDs and physically selects Stormwood forge. Original failed guard/null-material error retained; canonical actualbutton/catalogue ID correction8a3 independentlysourceAPPROVED and earnedR7 dispatched without production UI edits/grants/longer waits. Production388 syntheticR8 passes67/67 including native ridge/tinybevel/foreignRID negatives; resident28 and Meadows74 pass. Genuine Cloudcanonicalentry R3 nativecontact query saturates32 duplicates at50triangle mesh hub; all floor rays/actualPlayer60onfloorframes pass but initialcandidate rightly refuses. Coordinator authorizes bounded flattransition topology980: same perimeter/height/skirt and sharedrender/collision triangulation, saturation rejection untouched, independent Sol sourceAPPROVE; actualnativeR4 dispatched. Summit isolatedprobe now inherits unchanged shipping skin helper980, outcome pending. All originals/hashes/scope in native-followups/receipt.json and cloud-transition-topology-v1.json; oldpatch09/v2 preserved. Root owns shared lifecycle/network fixes. Local engine/GPU remain held; all work GPT-6.1 Sol and safe GitHub winddown at10% remaining usage.

**CI baseline:** CI6181/36998880911 on e19d231f9 failed in units, catching, Tidewake, world aim, Stormwood, combat, traversal, gate-b-core, gate-a UI (cancelled) and multiplayer (hello timeouts, F48 provisioning, 30-min cancels). Known-red probes are `continue-on-error`.

**Fixed in this pass (each verified locally on Godot 4.7 headless; commits on `tb/integration`):**
- Units (F23 map, RD-10 Cloudreach ledger from Tidewake L33 to L44), `keyboard_q.png`, Cradle seam world-once, aim-cancel hotbar latch, foundation-poll perf (node groups, cached config), per-frame portal context gated, combat smokes (RD-17, RT flee, owned loadout), host saves after Foundation events (`foundation_event.errors` empty world_id), gate-a/catching (story-modal refusal hint, `set_level` forgets unlocks above level, `old key` match, `menu_cancel`), Nysa blocking-wild drive.
- CI6184 on 69e0c2c8d: all single-process gates green except gate-b-core (also red on main).
- Wilds wait during a trainer challenge dialogue (Nysa); an idle-slope controller change was reverted (broke the tree-prompt probe). Traversal: the smoke teleported mid-fight; it now flees first. The camera snap 6f1a93db3 is unrelated and can be reverted.
- **F31 paid stations** (merged 8042f8fc9): v2 Altar-journal rows, exact price/refund, attachments; free_build and `smoke_f31_station_paid_path` pass. Guests cannot build stations yet; legacy records not refundable. Next: two-peer F31 smoke, tier-2+ recipes, judge frames.
- Host saves after Foundation events were refused (`foundation_event.errors` vs the snapshot's absent `world_id`); fixed efbdef654 with a regression test.
- Combat smokes aligned with settled changes (boss RD-17, trainer_battle RT flee, encounter_scaling seating); no production change.

**Still open, with diagnosis (next steps in order):**
1. **CI on this head** first. Net hello (CI6182) and traversal (CI6188) are fixed.
3b. **Multiplayer shards:** fixed in 1ff4b3763/e507d5828/2c6b39e80, each verified locally unless noted. (A) move commit: `_step_strike` presses the real button for ordinary swings and sends move_start â†’ wind-up â†’ strike for harness-aimed ones; shared_wild_fight's authority probe uses the quick slot with a same-frame rapid start (`recovering`), stages out of reach (an enemy blow cancels a wind-up) and waits for projectile impacts. (C) guest world writes: `peer_runner --joiner` relinquishes world-save ownership after `Game._ready`. foundations: waits for the owner-mutation guard, baselines the host after its bounty board, asserts disk content. **Perf (real bug):** every input-owner check re-validated all retained `creature_training` rows (~100 ms each), stalling two-peer trainer fights to seconds per frame (Warden/Bryn "no verdict"); now memoized by content (`training_row_valid`, `Session._owner_training_row`), and F32's 10 s mount retry no longer walks the ~180k-node world. Local Warden run still times out on this 4-core box (3 of 5 creatures met); confirm on CI. **Pad X interact (real bug):** outside Meadows, quick attack beside a trainer opened her dialogue mid-fight (stormwood_hosted_trainers); the arbiter now stands down while fighting (unverified, CI). catch_race: guest grant polled in short steps (CI peers ~10 fps outlived 55 s waits). Remaining spikes: `bounty_host_adapter`, `ledger_rpc`, `foundation_rematches`, `foundation_composition` (0.5â€“4 s each). CI6196 single-process timeouts (regions world/stormwood, veridian capacity) were green the run before; one confirming rerun.
4. **F48 inputs** (owner chose "finish properly"; owner will not run anything): `tests/fixtures/f48-inputs/` was never produced, so shards with f48 smokes fail provisioning by design. Real sources can come from `tools/net/run_net_smoke.sh shared_boss` (genuine 2-peer opening + Warden; ROOT's origin, `ralph/reports/R3-F48/mechanics-fixture/source.json`), blocked locally by the hello hang. Then: verify each character is one Terrapup L9/cap10, no receipts, empty site (if L8, that is a spec decision, not synthesis); `f48_profile_fixture.py` (2 and 4 sources) â†’ `f48_prepare_profile.py` â†’ native `f48_prepare.gd` â†’ write the missing producers (4-peer boss_four, behind Tidewake routes, release route pack from the actual capture) with tests on synthetic data confined to tests/ â†’ commit a packager (ROOT's `package_f48_actual_producer.py` never landed) that runs `f48_profile_ready.py --require-complete` (include boss_four; its DEFAULT_REQUIRED omits it) â†’ verify with `f48_relocate_profile.py`/`f48_ci_ready.py` â†’ run the four f48 smokes. Never synthesize inputs or relax the tools.
5. **gate-b-core** (owner chose a controller fix, not a looser tolerance): CI6196 failed on (i) "deep actual overlap": the player ended a frame ~1.9 mm inside `trainer_camp/tree-log_Collision` on the Mira route (1 mm skin); `player_controller._settle_skin_overlap()` now applies the physics server's own zero-motion recovery when it exceeds the skin (bounded 2 cm, not an unstick); (ii) the door-standoff block behind the same logs (expected to follow (i)); (iii) Satchel assignment pressed a fixed count, but the HUD autofills an empty bar, so the segment now presses until the tool lands (one cycle max). Traversal smoke passes locally; gate-b-core itself is unverified (CI). Also open: right-stick reticle line-up in the opening. F48 stays with Codex (owner).
6. Then Codex's earlier queue (`e19d231f9:docs/STATE.md` Â§0): F31 paid stations producer, versioned relic recipe grant, Cloudreach paid progression/cap-aware producers, guest passive sync, F23 proof and families, chapter handoffs, all24 cuts, visual/audio/device/human proof.

**Rules for the merge:** merge only on green required CI (ci-gate) for the exact head; never skip/quarantine tests or relax assertions; keep `full-ci`. Marking PR519 ready enables `auto-merge.yml`, which merges as soon as required checks pass.

**Repo size:** owner proposal pending (archive `ralph/reports` images to a release; evidence images to CI artifacts).

**Board:** [private board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site); flags/fixtures do not close acceptance.

### Open owner decisions

Recommended defaults: keep Compatibility until the Ally gate; retain the 30/night cap and Stormursa name; keep Steam packaging off without an AppID; keep the tap-then-tap controller map and Â§8.1 defaults. Recommend scoped installed-source Stormwood audio with owner listen, Stormheart as final relay, and existing PRODUCT defaults; these decisions remain open. Human play/device proof uses the passing integrated build.

1. **ROG Ally test (F26#5):** run one Forward+ test build on the Ally (Medium preset, handheld, the scripted route) when `tb/lookdev` posts the checklist here. Forward+ becomes the default only after this passes.
2. **Meshy credits:** the overnight cap is 30 generations per night (RD-26) unless the owner sets another number.
3. **Storm bear name:** the working name is *Stormursa* (RD-28).
4. **Internet co-op proof:** real Steam AppID and partner access, four accounts, at least 2 on separate home networks. `steam_api64.dll` redistribution is approved; packaging (`ship_steam_runtime`) stays off until an AppID exists.
5. **Stormwood audio:** whether to author the nine missing `assets/audio/stormwood/*.wav` from installed sources under AUDIO Â§10. Agents cannot listen, so acceptance would rest on spectral and loop checks plus an owner listen.
6. **Owner play pass (F47/F49):** a human play pass at the end of Wave 3.

7. **Story framing of the final relay:** Tidewake was written as the supply network's final relay. With Stormwood last, the recommended reading is: Stormwood's Stormheart is the final relay; Tidewake's regional link is one of four; the dock exchange stays Tidewake's chapter close. WORLD keeps the current wording conservative until the owner confirms.
8. **PRODUCT proposals to confirm:** the cut order within owner-decided systems, the "Build the best five" sub-line, a demo that includes the village, the Hall and the first homestead loop, and keeping US$19.99 at 15â€“25 h.

9. **Design defaults taken in the doc pass** (conservative, the owner may override): listed in CODEX_START_HERE Â§8.1.

10. **Controller map for the new combat (COMBAT Â§1, UX Â§2.2): please confirm.**
    - The ultimate and commands are tap-then-tap sequences (tap RB, then a face button), not chords, to respect the no-held rule.
    - Orb aim moves to LT and flee to RT.
    - Ordinary consumable use stays free, and the Tether Command item throw only buys an instant throw (default).
    - The LB+face command layout is an optional preset only.
    - Command unlock: item throw and Snare at the practice catch; Rally and Tag-switch at the first two-creature fight.

11. **Meadows waystones (F18):** current CODEX_START_HERE F18#3/#5 settles personal last-waystone return through the home arch (entry if none); candidate live proof remains open.

**Settled and kept (history in Git):** the Capacitor Alpha no-stagger ruling and storm strikes sparing trainers in fights (owner, 2026-09-27 23:55); harder Meadows trainers, starter parity and the female officer Vess (batch 68); the C2 masher rule (ruling 12, option c).

## 1. Rulings in force

**Owner redesign (2026-09-29):** CODEX_START_HERE Â§1 (RD-01..RD-37) is the newest owner direction. Where a ruling below conflicts with it, the RD entry wins, including RD-36's minimum necessary testing and batch validation. Other proof/counting rules remain.

**Owner and coordinator, 2026-09-27.** Nothing may contradict these.
1. **Counting and proofs.** Criteria count at merge; post-batch full CI is a safety net. Disclosed fixtures/declared starts, teleports, flag/party writes, harness fights and skipped sub-parts are allowed (ACCEPTANCE Â§6.1, WORKFLOW Â§8), as are earned checkpoints. Held Fly is lawful; tap pulse optional.
2. **Solmane.** Like Meadows' Veridian, Cloudreach's legendary is freed after Veyra, with a once-only offer per participant; never wild/catchable. Summit wild tables use tempestwing. **Implemented:** F08#5 met, C3 rerun passed.
3. **Device profile.** A computer capture at 1920Ã—1080 on Compatibility/`opengl3`, judged code-blind for 7-inch readability. No Ally hardware (#356 5857144944; ACCEPTANCE Â§6.1).
4. **Visual bar.** Bars A/B apply to every visual row. "Beauty matters." **Owner update (2026-09-29, RD-24):** Bars A/B are redefined as Palworld/Animo-class creatures and world plus Valheim-class light and atmosphere; every visual fix targets the full bar (ACCEPTANCE Â§4; F26, F38â€“F41).
5. **Build the game, not proof machinery.** Every round is player-visible. The two-strike harness rule applies, and each READY/FINAL post carries a `Balance: game N / tests-tools M` line (WORKFLOW Â§8).
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
   - **The 326 m walk from the Hall exit after the finale is acceptable** (exempt from A7 and WORLD Â§3.1 spacing; M2).
   - **Codex does the Cloudreach aerie art** (F08#3). The Codex lane is shut down; the owner assigns this when the next round of work starts.
   - **Vess, the female officer,** gets the female officer body and portrait. Add a `defeated` clip to `officer_b`.
12. **Meadows top-fight bar (owner 2026-09-28, F04#7 option c; delegated to the Balance lane, coordinator agreed).** Per top fight and starter, 24 seeds: reader win â‰¥75%, masher loses its lead every run, reader party cost â‰¤55% of the masher's. Chapter reading (the lane's reading of the owner's intent, not the owner's words): a masher loses â‰¥1 named trainer fight in â‰¥25% of playthroughs; measured 1.00/0.97/0.94, observed 24/24, 24/24, 22/24. Per-fight masher loss: Oreth 100/96/83%, Halder 8/25/29%, Warden 0/4/33%, Hald 0/0/25%, Vance and Vess 0% (L12 pin; DIVER ending). Fixed harness party ends on Trailpup (conservative bias). Owner option: raise the Band 3 pin for Vance for a per-fight 25%. The form applies to Tidewake F14#0 (Tidewake lane measures). COMBAT Â§7, BOSSES Â§9, ACCEPTANCE C2.

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
  - The Cliff Circuit keeps a one-time Tavi rematch (ace tier, 90 coins plus great_candy). This differs from WORLD Â§11's deferred rematch tier.
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

- **Owner redesign (2026-09-29), CODEX_START_HERE Â§1:**
  - Four chapters in the order Meadows â†’ Tidewake â†’ Cloudreach â†’ Stormwood.
  - A 15â€“25-hour normal clear with a loop that is fun to grind but optional to repeat. Creature power is the spine; the homestead is its engine.
  - Hybrid leveling with type essence, and breakthroughs every 10 levels through Master 1v1s and Ascension Feasts.
  - Three move slots plus an ultimate. Tether Commands, which never deal damage.
  - The Crossing Hall at the end of a single village road, with portals, a Shrine Room, Grandpa's Home Key and waystones.
  - Ending: the Stormwood finale â†’ Home Key homecoming â†’ credits â†’ the fifth arch stirs.
  - Visual bar: Palworld/Animo plus Valheim. A Forward+ path, pending the owner's Ally test.
  - Saves reset. Eight biomes remain the plan.
- Keeping the same five through the ending is success. Rewards deepen them (essence, breakthroughs, gear, traits), and catches stay optional. Water's critical path must not require an owned swimmer.
- No new investment: code and existing tools/assets, including the held Meshy licence. Agents may draft references and submit scoped Meshy work, plus the bounded overnight batch (RD-26) and one new creature, the storm bear (RD-28).
- Co-op is required through invitation, with no router setup or typed address. LAN or direct-IP alone is insufficient for release.
- Owner: "personal / friends â€” I just want it good". PRODUCT price and positioning do not authorize publishing or spending; a commercial launch needs a separate owner decision.
- **Legendary rule:** each participant in the freeing fight receives their own once-only offer, bound to their stable character; non-participants get none. Keys and relics follow the same per-participant rule (RD-21).

## 3. What exists

| Domain | Current fact | Open against the plan |
|---|---|---|
| Combat | Wind, poise, burst and quick/charged geometry; per-body named-fight overrides; the hitstop attack buffer. | C2/C3 on named fights (F04#7, F10#2, F14#0/#1), large-body camera framing. |
| Creatures | 57 base species, individual IVs and bond, and limited evolution. Galecrest was rebuilt from a reference; its `companion_presence` head-tracking override did not land because main lacks that code. | Creature finish for Bars A/B, and attack-pose clipping (AUDIT Â§A). |
| Meadows | Opening, route, activities, Hall and finale. F02 and F05 are fully met; M4 is complete. | F01 walks, F03#0 lures, F04 presentation, Bars A/B. |
| Cloudreach | Six regions, Fly and remount, six activities (F07 met), Veyra, and Solmane's per-participant offer. C1 is complete. | Aerie art (F08#3, Codex), settlements and cliffs (F08#4, Codex). Owned-carrier Fly closed. |
| Stormwood | Six-region earned route, Arches, Dynamo, Stormheart/aftermath; F09/F11/S1/S3 MET. | F10#2 C3/F10#6 device OPEN. Stormwood owns unmeasured Deepwood3d5fb0e6 performance, overly bright aftermath, pools_west_loop crossing lit b_pools, b2 curb1.11m and d_giant step0.4â€“0.67m. Tidewake/F14 C3 owns Compatibility black world from Camera3D.v_offset (`STORMWOOD/f10_6/r3/ab_top_band/`). X03 owns NPC interaction during starting wild fight (`STORMWOOD/s1/phase1_rerun/`). X01 owns CHARGER "missed" with ally inside lane (`STORMWOOD/f10_2/c3_p1/`, W tell4). |
| Tidewake | Human swim route (F12 met), eight pockets, six local chains with map leads (F13#3), dock residents and current comets (F13#5), dock exchange, return, Grandpa and credits (F15 met, T3 complete). Veilfall rooms show their pumps, sluices and banners. | Named-fight C3 framing: Aquaryn and Tidecoil pass. Tess and Nerissa are blocked on contact-range occlusion, which needs a shared combat spacing rule. Bars A/B looks go to Phase 2. |
| Multiplayer | ENet authority, portable characters, ledgers and receipts, the exact-pose rejoin, and an optional default-off Steam lobby path. | Internet relay and four accounts (owner resources), host plus 3, device. |
| Save | Save version 27 with world format 2 and character format 6; atomic split saves; refusal of corrupt or absent halves without live mutation. | Legacy peer-ID receipt and slot-rename ambiguity (not recovered). |
| Redesign (F16â€“F49) | F16 and 15/179 redesign criteria accepted on main; active source drafts remain unproved. Baseline systems and retired physical-crossing history are recorded in Git. | Full ACCEPTANCE Â§6.2 and F49 remain the done bar. |
| Visual/audio | Compatibility renderer with directional shadows; installed asset families; generated audio managers. | Bars A/B on every visual row; final music and mix. The Codex queue is `ralph/reports/VISUAL/AUDIT.md`. |

## 4. Risks and evidence boundaries

- **Wayfinding.** Owner's highest-impact complaint: corridor feel. Beacon/map reveals landed; judge geography/detours from whole paths, not beams.
- **Fixture debt.** Most met criteria use disclosed fixtures/teleports/harness fights, not fresh-play proof. Final earned four-chapter run and human passes retire this debt.
- **Shared-fight geometry.** The proxy-body divergence behind a guest's non-landing blow is fixed at root (`tests/test_remote_proxy_snap.gd`; MEADOWS-PAYOFFS/proxy-ground-plane). Re-check guest-hit smokes after any follow or collision change.
- **Legacy receipts.** Ambiguous peer-ID receipts are not auto-recovered. Corrupt legacy saves must stay inspectable without mutating live runs.
- **Steam packaging.** Windows rolling download lacks GodotSteam until an AppID exists; invitation co-op cannot yet work. Simultaneous two-client ENet disconnect may log a harmless native error.
- **Visual verdicts.** Software-GL proves composition/scale/colour, not fine lighting/performance. After two rounds without progress, change asset/approach, not tint (ART_DIRECTION Â§9).
- **Accepted art:** camp set, pickups, South Bridge gate and lost rigs retain ART_DIRECTION Â§7 dispositions unless gameplay evidence reopens them.
- **Owner reports.** Fresh owner repros reopen ledger-fixed items; first check the played build.

## 5. Dependencies and still-open design questions

- **Owner resources:** the Steam AppID and partner access, and the four accounts (Â§0).
- **Meshy:** Meshy runs through Codex on the owner's machine. Claude sessions hold no key.
- **Design questions** (keep current behaviour conservatively until settled):
  - the wild defeat persistence policy;
  - which replacement subjects the reference/Meshy workflow takes: answered by RD-26, the priority list confirmed in F36 (ART_DIRECTION);
  - a Burrowback contrast treatment that keeps its identity;
  - a grass clump redesign beyond the approved settings.
- **Validate:** ACCEPTANCE Â§7 release performance on owner-provided Ally hardware; fair late-catch bond; shared encounter scaling. Failures require retuning, not relaxed bars.

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
- **Owner redesign interview, 2026-09-29:** 35 decisions, recorded as RD-01..RD-35 in CODEX_START_HERE Â§1. The owner asked that every catalog defect scored above 12 be fixed to the full game bar, "not just passing the defect", so the game looks like something people would play (Valheim, Palworld, Animo, ARK as quality references). Done means the whole plan is done: push consistently, rebuild the dashboard hourly, then burn the criteria down over time.
- Record owner feedback here; it overrides other documents on its subject.

R2/R3 source consolidated; production wiring, runtime proof and main pending.
