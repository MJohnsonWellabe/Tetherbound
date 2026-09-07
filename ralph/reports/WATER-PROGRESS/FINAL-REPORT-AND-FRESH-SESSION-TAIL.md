# Water build stop report and fresh-session tail — 2026-09-07

**Water is incomplete.** The broad run stopped under the owner's two-consecutive-low-progress-window rule. Final branch evidence is35/100; the original100-point goal is unchanged. The clock crossed an approximately eight-hour gap without evidence of continued execution. This report does not claim14 hours of productive unattended building. See [scorecard.md](scorecard.md) for the dated history and missed checkpoints.

## Delivery and recovery

Work is isolated in `D:\Tetherbound-Water`, branch `ralph/water-foundation-0906`, draft [PR69](https://github.com/MJohnsonWellabe/Tetherbound/pull/69). The newer owner instruction reserves merging for later. Nothing from Water was pushed or merged to main. The last integrated main ancestor is `c5e4d14d101275de2f96b3918ae6ddcd19dafd35`; fetched main at stop is `4562268dee581d2f2ce167a4670bbf752f139310` (Stormwood PR76). That newer Stormwood merge is not yet rebased into Water. Preserve it at the next integration wave and review shared-world/net conflicts rather than resetting this branch.

Final implementation is `a636877d1`; its release-journal regression is `4f4de063a2bb9032eec09b35294fbc4ba6bcd65e`. The previously pushed milestone was `494209824215967771fb89d171b368e99826f035`; its ancestor `5375dde9ed5028772b10f20f20a06db44ac62ed8` had successful CI34079878893 with all enabled code jobs green. Known-red and export jobs were explicitly skipped. Raw unit logs contain fixture errors, so successful jobs are not a claim of clean logs. The workflow lookup returned no runs for494209824; no later-head CI success is inferred.

Local `override.cfg` isolates saves into `Tetherbound-Water-0906-Tests` and limits worker threads to2; it is intentionally untracked. Import-generated `.gd.uid` files are also untracked. Do not add them indiscriminately. Original source work was preserved on `scratch/pre-water-20260906-0015`; this Water run does not own other Stormwood branches. Never reset the shared source checkout to resume this tail.

## Per-system acceptance

| System | Classification and exact practical limit |
|---|---|
| Stormwood handoff / entry | Implemented but unproven as an ordinary earned-key journey. Existing transition seam consumes the key; the full Stormwood victory→reveal→key spend→Water path has not been played on this branch. Rebase the newer Stormwood handoff first. |
| World / islands / docks | Proven subpaths: actual Terrain3D world, lesson, dock repair/barrier/current actions and eight camps. Continuous twelve-island travel and all dock prerequisites remain unproven. |
| Human swimming / drowning | Proven production60.143m lesson and exhaustion/health/landing subpaths, including two-peer split-island state. All first-half crossing budgets and controller feedback remain unproven. |
| Mounted swimming | Proven five compatible species, separate persistent stamina, exhaustion/dismount/remount/dry exit, two-peer30-check state and43-check disk reconstruction. Hardest crossing, route selection and live ENet reconnect remain unproven. |
| Aquaryn / Stone / saddle | Proven33-check ordinary attacks→victory→Stone→Iona dialogue→material-consuming craft→same Mosshell mounted. Aquaryn's `surface_route` is empty and spawn is dry. Actual catch roll/animation/reconnect and complete alternate-mount journey remain unproven. |
| Skills / Candy | Proven focused global skill state/menu/ownership/cap paths. Ordinary Meadows XP→Biome2 reveal, all skill benefits and twelve pickups through actual travel remain unproven. |
| Water combat | Implemented resource pause and species buoyancy. Interception→dismount→direct pilot→switch/catch→remount with no resource exploit remains unproven. |
| Story / objectives | Twelve ordered main objectives exist. The BUILD28–32 main objectives and six local chains are incomplete. No continuous three-act chapter evidence. |
| NPCs / trainers / encounters |18 NPCs,24 trainer definitions with three shared bodies and live streamed wild encounters. Actual Lysa and Nerissa combat subpaths pass. Five optional named encounters are not instantiated; full trainer ladder and speech delivery remain unproven. |
| Resources / gear / pickups / camps | Five resources, ten recipes,200 pickups,182 authored harvest nodes and eight functioning camps. Camp smoke129checks passes. Analytic placement and counts do not prove every pickup/harvest footing or complete reward cadence. |
| Veilfall approach / reveal | Mountain and waterfall exist; shore→preparation→hike→resistance→concealed entrance is not continuously played or visually accepted. |
| Veilfall interior / captain | Proven31-check physical entry/pump/sluice/bridge/exit with actual colliders. Proven16-check four-opponent Nerissa fight using normal attacks and post-victory release control; upstream/proximity/party fixtures explicitly supplied. |
| Guardian / ceremony | Proven35-check actual offer→five-holder release choice→exact personal creature/receipt disk save→world settlement→physical shrine. Freed state and proximity are fixtures. No continuous captain-through-ceremony run, decline/reconnect/four-player finale proof. |
| Tidal Guard / Compass | Proven physical named relic placement and activation; focused actual health mutation tests verify90% incoming creature strike damage and replacement of other active powers. Hazard damage coverage and visible persisted aftermath remain incomplete. |
| World response | World flags and current-strength query integration exist; Guardian/crystal visibility changes pass the ceremony smoke. Occupation removal, pump shutdown presentation and visibly calmer currents remain unproven/incomplete. |
| Multiplayer / persistence | Proven separated islands, mounted packets, host Alpha pose/HP/hit and disconnect cleanup24checks; capture handover64checks with a seeded caught journal. Four-player finale, actual network catch/reconnect and adversarial recipient acknowledgment remain unproven. |
| Art / performance / controller | No blind accepted frame. Six prior frames failed for bare shore, weak mountain silhouette and angular water. No target performance acceptance. Meshy intentionally deferred:0 generations/0 landed meshes. |

## Evidence and reproduction

Use `D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path D:\Tetherbound-Water --script res://tests/<script>.gd --log-file D:\<log>.log` for these nonrendering smokes. Never combine headless mode with a rendering driver. Actual visual work must use `tools/survey.sh` and a blind judge.

- `smoke_water_veilfall_runtime.gd`:31-check physical route; earlier log `%TEMP%\water-veilfall-runtime-route2.log`.
- `smoke_water_veilfall_captain.gd`:16checks0fail in `%TEMP%\water-captain-runtime2.log`; four trainer-owned level55 opponents. The final source adds an explicit await to the ordinary summon call after that run.
- `smoke_water_guardian_ceremony.gd`:35checks0fail, `D:\water-guardian-ceremony-final.log`. Root read the test and final log. The process handle expired across continuation, but OS inspection found no remaining process and the log reached its explicit completion. No exit code is fabricated. One unsupported-footing warning remains for `water_salt_crown_wild_012`.
- `smoke_water_capture_recovery.gd`:64checks0fail in `%TEMP%\water-capture-recovery-runtime.log`. Seeded capture result, actual destroyed/rebuilt service, exact creature fields, real five-holder UI and character/world disk receipts. Not a real catch roll or ENet session.
- Actual Alpha/saddle33-check log `D:\Tetherbound-Water-alpha-saddle.log`; two-peer lifecycle24-check log `D:\water-alpha-lifecycle-net.log`, run `net-run-local-2143408` with inspected peer logs.
- Final focused suite `D:\water-finale-unit-wave.log`:21tests196assertions0fail, including actual Tidal Guard health mutation, relic replacement, capture rollback, Guardian journal and dialogue delivery. Final full-suite result is recorded in the integration addendum below.
- Earlier detailed tests, fixtures, census and failed visual verdicts are preserved in `runtime-wave-1.md`, `runtime-wave-2.md`, `runtime-wave-3.md`, `density-census-wave2.md` and the scorecard. Do not turn fixture assertions into continuous chapter acceptance.

## Density actuals versus BUILD targets

These source counts were previously independently recomputed; this finale wave changes no encounter/pickup/island placement counts. Runtime limits remain explicit.

| Category | Actual / required | Remaining limitation |
|---|---|---|
| Islands |12 /12:8 main,4 optional | Complete routes unplayed |
| Landmarks |18 /18 | Most names/positions lack accepted distinct physical presentation |
| Land spines |12 authored;11,026.528m planned /8km continuous walked |0m credited toward complete continuous target |
| Water links |11 edges;22 polylines | Complete inter-island chain unplayed |
| Anchors / currents |24 /22 anchors;22 current channels /at least10 | Readability unaccepted |
| Wild sites / encounter tables |240 /240;16 /16 | Streamed16 per nearby peer; not all footing tested |
| Named encounters |1 live scripted Alpha +5 unspawned optional /6 | Optional encounters incomplete |
| Trainers / NPCs |24 /24;18 /18 |39 unique intended bodies after3 reuses; full ladder unplayed |
| Pickups / harvest |200 /200;182 /160 | Most analytic placements not individually exercised |
| Skill Candy |12 /12:7I,4II,1III | Ordinary collection distribution unplayed |
| Dialogue |111 conversations,168 line entries /150 delivered nodes | Not168 delivered/accepted nodes |
| Main objectives / local chains |12 /28–32;0 /6 | Major content gap |
| Resources / recipes / camps |5 /5;10 /10;8 /8 | Camp interaction proven; full preparation economy unplayed |
| Settlements |0 accepted /3 | Individual NPCs/camps do not constitute3 finished settlements |

## Placeholder replacement register

All12 species still use installed placeholder bodies. Runtime registration is `scripts/creatures/water_species_catalog.gd`; authoritative per-species replacements and bindings are `data/config/water_roster.json` → `species.<id>.placeholder`. Their exact future model paths follow `res://assets/creatures/tetherbound/<destination>/models/creature_<destination>_lod0.glb`:

| Water species | Installed source | Destination |
|---|---|---|
| Cannonback |mosshell|cannonback|
| Riptusk |tuskroot|riptusk|
| Aquaryn |paddlenewt|aquaryn|
| Tidecoil |paddlenewt|tidecoil|
| Mirejaw |paddlenewt|mirejaw|
| Torrentoad |ripplet|torrentoad|
| Cragclaw |burrowback|cragclaw|
| Riverdrake |paddlenewt|riverdrake|
| Sirenseal |brooktail|sirenseal|
| Mangrove Monitor |paddlenewt|mangrove_monitor|
| Mosshell |mosshell|water_mosshell|
| Abyssal Guardian |paddlenewt|abyssal_guardian|

Existing source portraits also remain placeholders; replace the Water species portrait mapping in the same catalogue and NPC portraits in `data/config/water_characters.json`/`data/dialogue/water.json`. Humanoids intentionally reuse installed rigs and rank/material variants; no new humanoid generation is authorized by this report. The kitbashed waterfall-gate and crystal replacement points are `water_veilfall.gd::_build_waterfall` and `_build_heart_chamber`, preserving controls, collision and Guardian state. Cave walls, pump housings, banners, channels and shrine remain primitive kitbash presentation, not board acceptance. Island silhouettes/scatter/current markers remain first-pass art. No Meshy assets landed; after broad playability the mandated order remains Aquaryn→Abyssal Guardian→Mosshell→others, plus the single authorized Veilfall hero object.

## Blockers, attempted hypotheses and next bounded tasks

1. **P0 main path: complete the actual chapter route.** Rebase current main safely, then play earned Stormwood key→First Shore lesson→all dock gates→Alpha→saddle→second half→hardest crossing→Veilfall. Existing separate smokes use travel/prerequisite fixtures and cannot expose route dead ends. Strongest next hypothesis: real crossing budgets, sparse objectives and missing optional named encounters dominate player-path gaps. Implement the missing six side chains and full objective spine as bounded data lanes while root walks/fixes progression. Do not spend another window on the receipt tail first.
2. **P0 biome mechanic: Aquaryn needs its shore/water arena and water combat.** Reproduce at `data/config/water_alpha.json`: dry spawn `[601.574,1389.434]`, empty `surface_route`. Author a reachable low shore/channel layout in the shared heightfield/config, rebake Terrain3D and surface height, then prove ordinary attacks/catch, drain pause, switching and remount. The passing dry fight is not a tested amphibious fight. No terrain/channel rework has been attempted yet.
3. **P0 multiplayer/persistence: run two then four real peers through finale and catch/reconnect.** Current claims authenticate stable recipient but trust that recipient's save acknowledgment. A modified recipient can acknowledge early and advance world ceremony flags; no host proof of the remote disk write exists. Keep character ownership boundaries explicit and decide the acknowledgment protocol consistently with existing main. Also test two simultaneous offers, decline, host save failure, reconnect on different islands and a host outside Water. Pure journal tests and solo35/64-check paths are the strongest current evidence, not network proof.
4. **Quality/main-path presentation: finish aftermath and readable islands.** Current restoration changes the flow query; no actual post-release current comparison/visual proof or cleared occupation exists. Salt Crown streaming emits `water_salt_crown_wild_012` unsupported-footing warning during shrine approach; inspect baked footprint before moving the site. Prior blind frames failed bare First Shore, pale cone Veilfall and angular cyan water. Fix composition/material/scatter mechanisms, capture via survey and judge blind. No third near-identical micro-tuning attempt.
5. **Evidence/release: complete full regressions, census and target-device route.** Inspect the final integration results below, rerun only changed/failing seams, then full code CI and current-main ancestry check before owner merge. Verify720p controller readability and frame performance. Only after broad chapter playability generate the authorized reference-based meshes; only after Water's real exit bar is satisfied advance to Stage C's four-biome audit.

## Final integration addendum

Final source is preserved in `a636877d1`, with release rollback tests in `4f4de063a`. Main ancestor `c5e4d14d1` remains verified by `git merge-base --is-ancestor`; fetched newer main4562268de remains a required rebase. Focused evidence logs are copied into `evidence-final/` beside this report.

The first full local regression was stopped after C: reached0 bytes free. A subsequent Guardian journal test exposed a truncated save read in that environment. No passing full-suite result is claimed from that run (`D:\water-final-full-suite.log`). Setting the child process environment `APPDATA=D:\WaterTestAppData` provides actual isolated test storage on D: without moving/deleting user files. The exact same journal tests then passed4tests44assertions0fail (`D:\water-release-journal-final-D.log`), including the new captain requirement and atomic release-save rollback. The full suite was restarted once with this changed environment in `D:\water-final-full-suite-D.log`; its terminal result is recorded below when available.
