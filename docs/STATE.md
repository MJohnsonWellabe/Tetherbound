# State — live status against the release plan

Read this first. Update in place; keep under25KB. No dated status, goal, directive or handoff documents. Evidence is in `ralph/reports/<LANE>/`; history remains in Git and the existing archive.

**Audited baseline:** main b8eda885 (consolidation PR131). **Current effort:** design-only rewrite on `ralph/plan-rewrite`, PR132. No gameplay/config/asset changes, engine runs or new playthrough certification are part of this effort. The baseline was fetched/reset and confirmed before recovery. FINDINGS records the read coverage and report.

## 1. Product decision

A finite12–16-hour creature expedition action RPG: four authored chapters, solo/1–4co-op, at most five owned companions, directly piloted real-time fights, camps supporting journeys, regional victory and homecoming in Tidewake. GAME_BIBLE states the central decision; PRODUCT states audience, launch scope, economics and cuts. No hard-rule change is requested.

The existing code is substantial. What remains unproven is whether mastery, attachment and worthwhile detours replace the collection/factory/survival loops deliberately removed from the reference games. The old four co-equal lanes are superseded by ROADMAP's expedition-first dependency order. This is a design recommendation made under the owner's explicit request to own and challenge the plan; it is not a claim the previous owner enjoyed no part of the game.

## 2. What exists and what remains open

| Domain | Current implementation fact | Against the new plan |
|---|---|---|
| Combat | Wind/poise/burst, quick/charged move geometry, targeting/camera code and tests are on main. Historical commits dfb28289,9c77c1e6,b92d2e5f,e570daaf are foundations. | **Partial:** third skill, reactive behavior, normalized poise, complete camera/body-size matrix, reader-versus-masher proof and meaningful roster roles open. |
| Creatures |57base species/12Water adapter IDs,53base model paths; unordered bond tasks, IVs, Best perks, limited evolution, catching/care. | **Partial:** revised bond credit/skill/trait targets, traversal promises, attachment and art appeal unproven. Five is ownership, not species count. |
| Camps/economy | Build/craft/harvest/inventory, beds/healing, food, trade, riding and save foundations. | **Partial:** bounded injury target not built, source-to-route solvency/three-bed tournament integration/four-player resources need proof. |
| Meadows | Five bands,31trainer rows,365wild rows, seven local objectives; Hall/ceremony/aftermath code. Old source ledger43/43 and location ledger23/23 are bounded historical claims. | **Partial:** no current clean earned A1–A11 acceptance; source repairs and location passes do not certify chapter experience or commercial visual bar. |
| Cloudreach | Six regions,7trainer rows/82wild rows, flight/training/aviary/finale/relic/gate paths. No captive legendary adoption in this chapter. | **Partial:** old visual ledger0PASS/9POLISH/3FAIL; below-floor survey-camera evidence must be corrected before judging those views. Full path/remount/hardware acceptance open. |
| Stormwood | Six regions,26trainer rows plus leader handling/401wild rows; Dynamo, Stormheart, Spark/aftermath consumers mounted. | **Partial, not unbuilt:** current earned end-to-end path, named fight depth, visuals/audio/device proof open. |
| Tidewake | Twelve islands/sixgroups,24trainers/303wild rows, five named spawn integrations and Water runtime on main (fe13cc3e6 in history). | **Partial, not held branch-only:** full earned route, co-op interior/mount/catch proof and final regional ending/homecoming open. |
| Multiplayer | ENet authority, world/character split, ledgers, shared encounters, realm shells and personal presentation exist. | **Partial:** not all product scope accepted. Outside host+3joiners, owner LAN, Ally host, shared Cloudreach and full campaign/reconnect proof remain. New design states also need authority/migration. |
| Visuals/audio | Compatibility with ordinary directional shadows; generated audio/config/managers; extensive installed stand-in assets and authored places. | **Partial:** Bars A/B aspirational, no blanket mesh authorization. Final score/mix/per-chapter evidence and asset rights/quality decisions remain. |
| Save/time/storage | Save version24, persisted clock and synchronized placed-storage contents. | **Built foundations:** old six-doc claims of no clock/storage persistence were false. New design fields require migration; no new schema committed here. |

Census is source rows, not authored hours. Trainer rows31/7/26/24; wild365/82/401/303; conversations146/47/63/112; lines370/107/186/170; main objective rows28/17/27/12. First-clear duration per chapter remains unmeasured by this review. See FINDINGS for counting boundaries and source citations.

## 3. Next authorized implementation sequence

This design effort ends at the plan PR; it does **not** begin game implementation. When implementation is commissioned:

1. **P1 expedition proof:**45–60minutes of combat/team/camp/detour play. Settle shared schema/authority first; integrate L4skill, normalized poise/AI/spacing, bounded strain and late-catch bond. Test every starter and a remote peer. ACCEPTANCE C1–C5/A2/A4/A6 are the gate.
2. **P2 complete Meadows:** earned opening→Hall→Cloudreach; six useful optional activities minimum, source-backed XP/material/recovery ledger, distinct named fights, art/audio benchmark, actual Ally budget.
3. **P3–P5:** integrate Cloudreach, Stormwood, Tidewake/ending in order using existing code. ART/AUDIO/reference/provenance work can proceed independently where contracts are fixed.
4. **P6 release proof:** campaign, co-op, migrations, accessibility, device/frame pacing, final assets, distribution and honest store claims.

Do not restart a broad campaign walker merely because it exists. Use focused player-path evidence first, full continuous runs at milestones. ROADMAP estimates780–1,180owner/integration hours and36–52calendar weeks at25h/week, conditional on external art/audio. Reforecast after P1/P2 rather than treating these as promises.

## 4. Defects, risks and evidence boundaries to retain

| Item | Current disposition |
|---|---|
| Wayfinding / straight corridor impression | Owner's highest-impact complaint. Beacon/map reveals landed, but geographic understanding and voluntary detours need fresh whole-path evidence. No assumption a beam fixes the map. |
| Combat placement/input lock; owner could not run/reposition | Preserve as regression scenarios from9/11 and later playtests; do not label still reproducible without current replay. |
| Creature aspect colour masks, Burrowback low contrast, slope contact, guardian distant silhouette | Open visual risks from bounded verdicts. Rejudge current gameplay motion before any new asset/scale change. Never shrink to fit. |
| River/canal read, broadleaf trunk ratio, dark trainer legs, mipmap claim | Historical known findings requiring source/frame verification; the review did not rerender or establish all as live defects. Geometry/source texture issues cannot be closed by an exposure slider. |
| Peblik rejection / Cloudreach remount | Owner reproduction has priority over earlier static passes; include exact source/build in next focused witness. |
| Cloudreach survey camera | Correct below-floor/inaccurate camera stands before spending art effort on their conclusions. |
| Old GateF failures | Aim/input-provider/bed/guardian/quarry/reward/realm lifecycle were real failure classes. Some were harness bugs already fixed. Use current originating failure, not stale symptom, and no copied-save claim of fresh play. |
| Art asset limitations | ART_DIRECTION contains known accepted defects/closed exceptions. Do not reopen a ship-as-is gate/tent or lost rig without new gameplay evidence; do not call it equal to final visual acceptance. |
| Source implementation diverges from new plan | Expected: no code changed. Each target stays open until implementation+integration+proof. Most prominent: skill, strain, bond, scaling/admission, tap revive/climb, ending. |

The historical43-row audit at44056970 and visual23/23 remain evidence of those rows/stands; neither closes this new acceptance set. Old unmerged lane verdicts, including combat work at868f312d3, do not become main evidence because their report is readable. Check reachability and actual package before reuse.

## 5. Decisions and dependencies

**Settled by this proposed plan:**6–10activities per chapter; current1.25/.80types; L4geometryskill; five unordered bond tasks with revised late-catch credit; bounded strain rather than C4penalty stack; explicit HP-based co-op scaling/admission proposal; tap revival; Ripplet return capability only after Stormwood completion/Water entry; Tidewake regional ending. These are deliberate lower-level changes recorded in the owning specs and FINDINGS, not silent archival loss.

**Still open:** wild defeat persistence policy (never return versus long meaningful cooldown); whether cosmetic wild-body drift between peers meets owner quality expectations; specific replacement-subject reference art/production approval for missing silhouettes; any reinterpretation of the owner's visual bar; Burrowback contrast treatment that preserves its identity; grass clump/blade redesign beyond approved settings. Preserve current code conservatively until those decisions are made; do not add periodic farm spawns or new mesh generation by inference.

**Target to validate, not an open blank:** Ally1080p15W30fps percentile target in ACCEPTANCE; fair late-catch bond; optional-activity qualification; shared encounter scaling/catch neutrality. Failure triggers retuning/reforecast, not an invisible relaxed bar. No owner hardware test has been performed for this rewrite.

**Dependencies:** target-audience testers, owner device sessions, owner reference art for newly needed subjects, lawful final asset/audio supply, platform/distribution access and actual pricing terms. They do not authorize spending, publishing or contacting third parties in this task.

## 6. Owner direction carried forward

Latest instruction: recover all archive decisions/owner directives/biome/spec contracts, inspect actual code, report findings/central decision before writing, and deliver this exact design set in one PR. No implementation. Phase1/2 were reported in session before Phase3 drafting. Senior design judgment and lower-tier bounded reading/drafting were explicitly requested.

Standing feedback remains: content off the trail and visuals matter, and combat depth continues; Meadows should be the first complete chapter; no held inputs; grow smaller creatures rather than shrink larger; five total/no storage; human never fights; no starvation; no additional street villagers beyond the five-street-resident arrangement; Pond is a local lush reference; actual-game captures over bad survey shots; no hour-long CI fan-out; outside co-op/device proof is required. Later source repairs do not erase owner priorities.

FINDINGS preserves all125full-slug decision records,33owner bundle files plus earlier owner/handoff material, all biome contracts, all spec bundles and CURRENT_STATE coverage. The archive is no longer falsely described as wholly reproduced in one Bible. Consult the recovered source when a scoped task needs its detailed constraint; do not resurrect obsolete work lists.
