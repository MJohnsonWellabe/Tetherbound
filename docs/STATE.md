# State — live status against the release plan

Read this first. Update in place; keep under25KB. No dated status, goal, directive or handoff documents. Evidence is in `ralph/reports/<LANE>/`; history remains in Git and the existing archive.

**Audited baseline:** main b8eda885 (consolidation PR131). **Current effort:** design-only rewrite on `ralph/plan-rewrite`, PR132. No gameplay/config/asset changes, engine runs or new playthrough certification are part of this effort. The baseline was fetched/reset and confirmed before recovery. FINDINGS records the read coverage and report.

## 1. Product decision

**Follow-up:** the six owner-requested Matt Pocock skill packages are committed in `.claude/skills/` and mirrored in Codex's `.agents/skills/` at fb354d0ec, with upstream metadata/license and project overrides in AGENTS/CLAUDE. The owner answered the first `grill-me` round:

- Keep mechanics testing minimal. Use a short existing-loop check before adding proposed systems; do not build the whole new-mechanics bundle just to test it.
- Keeping the same beloved five through the ending is success. Later rewards deepen the existing team; new catches are optional. Consequently the Water critical path must not require an owned swimmer/new catch; WORLD/SYSTEMS mark the human-route/gate work explicitly unaccepted.
- No new investment: coding and existing tools/assets, including the already-held Meshy license. Withdraw the assumed commissioning budget and owner-hour valuation. Reference-backed subject authorization remains required.
- Co-op is required. The remaining choice is joining convenience, not whether to cut multiplayer.
- Eight good hours can ship. No mandatory 12–16-hour campaign or equal-length chapter floor.
- The longer-term plan remains eight biomes; this pass completes the current four and their regional ending.

Tetherbound remains a four-chapter creature expedition action RPG in this pass, solo/required1–4co-op, at most five owned companions, directly piloted real-time fights, camps supporting journeys, regional victory and homecoming in Tidewake. GAME_BIBLE states identity; PRODUCT scope/resources; ROADMAP sequencing. No hard-rule change has been approved. This follow-up updates design only; it does not start game implementation.

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

This design effort ends at the plan PR; it does **not** begin game implementation. When implementation is authorized:

1. **P1 brief existing-loop check, then build:** one15–30minute owner play check of fight/team/detour/preparation. Repair observed blockers/readability, then select only the next justified mechanic. L4skill, normalized poise, strain and revised bond remain candidates, not prerequisites. Keep targeted correctness/save/co-op checks for changes; do not create a new harness, recruitment or repeated tuning programme.
2. **P2 complete Meadows:** earned opening→Hall→Cloudreach; six useful optional activities minimum, source-backed XP/material/recovery ledger, distinct named fights, art/audio benchmark, actual Ally budget.
3. **P3–P5:** integrate Cloudreach, Stormwood, Tidewake/ending in order using existing code. ART/AUDIO/reference/provenance work can proceed independently where contracts are fixed.
4. **P6 release proof:** campaign, co-op, migrations, accessibility, device/frame pacing, final assets, distribution and honest store claims.

Do not restart a broad campaign walker merely because it exists. Use brief targeted checks while building; full integrated evidence belongs at milestones. The earlier780–1,180hour/36–52week and$15k–35k external-production scenario is withdrawn following owner correction. No fixed weekly owner allocation or commissioning pipeline is assumed. Estimate bounded implementation tasks from source, record actual work and reforecast after a completed Meadows slice; no replacement finish date is established.

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

**Current plan:**6–10activities per chapter; current1.25/.80types; tap revival; Ripplet return only after Stormwood completion/Water entry; Tidewake regional ending. **Specified candidates, not automatic first tasks:** L4geometryskill, normalized poise, revised unordered bond credit, bounded strain and HP-based co-op scaling/admission. Their specs remain concrete, but minimal observation selects the next needed change; explicitly retain/revise/drop any rejected candidate in its owner document. Earlier recovery dispositions remain traceable in FINDINGS.

**Next grilling decisions:** whether launch co-op joining must avoid typed addresses/router setup, and whether new creature references must still originate from the owner or may be drafted by agents for explicit owner approval. No alternative is approved by asking; preserve the current transport and owner-supplied reference rule.

**Still open:** wild defeat persistence policy (never return versus long meaningful cooldown); whether cosmetic wild-body drift between peers meets owner quality expectations; specific replacement-subject reference art/production approval for missing silhouettes; any reinterpretation of the owner's visual bar; Burrowback contrast treatment that preserves its identity; grass clump/blade redesign beyond approved settings. Preserve current code conservatively until those decisions are made; do not add periodic farm spawns or new mesh generation by inference.

**Target to validate, not an open blank:** Ally1080p15W30fps percentile target in ACCEPTANCE; fair late-catch bond; optional-activity qualification; shared encounter scaling/catch neutrality. Failure triggers retuning/reforecast, not an invisible relaxed bar. No owner hardware test has been performed for this rewrite.

**Dependencies:** brief owner mechanics checks, target-audience/device evidence at integrated milestones, owner references and subject permission for new meshes, existing asset/audio provenance, platform/distribution access and actual pricing terms. No external asset vendor or new spending is assumed. They do not authorize spending, publishing or contacting third parties in this task.

## 6. Owner direction carried forward

Latest owner decisions are the six bullets in §1; they supersede the initial rewrite's duration, investment and P1 assumptions. The original task remains recovery/source grounding and an exact design set in one PR, followed by the requested skill installation and grilling. No gameplay implementation has been authorized in these turns. Phase1/2 were reported in session before Phase3 drafting. Senior design judgment and lower-tier bounded reading/drafting were explicitly requested.

Standing feedback remains: content off the trail and visuals matter, and combat depth continues; Meadows should be the first complete chapter; no held inputs; grow smaller creatures rather than shrink larger; five total/no storage; human never fights; no starvation; no additional street villagers beyond the five-street-resident arrangement; Pond is a local lush reference; actual-game captures over bad survey shots; no hour-long CI fan-out; outside co-op/device proof is required. Later source repairs do not erase owner priorities.

FINDINGS preserves all125full-slug decision records,33owner bundle files plus earlier owner/handoff material, all biome contracts, all spec bundles and CURRENT_STATE coverage. The archive is no longer falsely described as wholly reproduced in one Bible. Consult the recovered source when a scoped task needs its detailed constraint; do not resurrect obsolete work lists.
