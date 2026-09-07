# Stormwood weighted progress scorecard

Frozen original goal: 100 points (exit criteria 80; entrypoint checklist 20). Established before implementation on 2026-09-06 22:04 UTC. Run began 21:54:38 UTC; checkpoints due 23:54:38, 01:54:38, then every two hours. Full goal and thresholds are the owner's 2026-09-06 Stormwood execution request.

Baseline main: `5547d415ffe58438f5bed9fc9b6b710b37a5bdad`. Reference PR #68 pending. Preserved previous local work: `a92faa8bd`, scratch/pre-water-20260906-0015. Water work is isolated in its own worktree; root checkout belongs to Stormwood.

Evidence: tracked-file search finds no Stormwood runtime/config/scene; realm_hearts.json registers only Meadows and Cloudreach; cloudreach_chapter.json still grants realm_key_water and waterward_route_revealed. Existing runtime smoke initially failed before execution because the sandbox could not open user logs; an elevated retry is pending. No Stormwood runtime, visual, or multiplayer acceptance evidence exists. Score is zero, not a judgment that existing reusable Meadows/Cloudreach systems are broken.

Credit rules: evidence on merged main only. Each row may earn 0, 25%, 50%, 75%, or 100% of its frozen weight for explicitly listed proven sub-capabilities; tests, smokes, and judged frames must support relevant claims. Data/code alone earns no credit. Full credit requires the original criterion including fails-if clauses. The 20-point checklist deliberately weights broad delivery separately from full acceptance; no weights change later. Multiplayer is required in each relevant row, including server-authoritative hazard, simultaneous arches, deduplicated pickups, shared progression and late join.

| §32 | Exit criterion | Weight | Baseline | Evidence |
|---|---|---:|---:|---|
| 1 | Entry and return | 6 | 0 | Not implemented/proven |
| 2 | First minute | 3 | 0 | Not implemented/proven |
| 3 | Surge changes play | 8 | 0 | Not implemented/proven |
| 4 | Arches and Hollow Crown | 8 | 0 | Not implemented/proven |
| 5 | Required building | 4 | 0 | Not implemented/proven |
| 6 | Main story through Dynamo and aftermath | 12 | 0 | Not implemented/proven |
| 7 | Density census | 5 | 0 | Not implemented/proven |
| 8 | Level curve | 3 | 0 | Not implemented/proven |
| 9 | Named encounters and Dynamo identity | 5 | 0 | Not implemented/proven |
| 10 | Fair lightning hazard | 3 | 0 | Not implemented/proven |
| 11 | Camping pressure | 2 | 0 | Not implemented/proven |
| 12 | Realm relic powers | 4 | 0 | Not implemented/proven |
| 13 | Persistence and multiplayer reconstruction | 5 | 0 | Not implemented/proven |
| 14 | Eight blind visual reviews | 4 | 0 | Not implemented/proven |
| 15 | Performance | 2 | 0 | Not implemented/proven |
| 16 | Continuous and CI evidence | 3 | 0 | Not implemented/proven |
| 17 | Placeholder replacement ledger | 1 | 0 | Not implemented/proven |
| 18 | Waterward view | 2 | 0 | Not implemented/proven |

| §7 | Broad-build checklist | Weight | Baseline |
|---|---|---:|---:|
| 1 | Cloudreach transition | 1 | 0 |
| 2 | All six regions | 1 | 0 |
| 3 | Whole-biome traversable route | 2 | 0 |
| 4 | Recognizable forest | 1 | 0 |
| 5 | Surge gameplay | 2 | 0 |
| 6 | Arches traversal | 1 | 0 |
| 7 | Crown through arch | 1 | 0 |
| 8 | Four rod stations | 1 | 0 |
| 9 | Distributed chapter content | 1 | 0 |
| 10 | Rewarded exploration | 1 | 0 |
| 11 | Task chain reaches Dynamo | 1 | 0 |
| 12 | Dynamo finale | 2 | 0 |
| 13 | Legendary release choice | 1 | 0 |
| 14 | Spark and aftermath | 1 | 0 |
| 15 | Water direction | 1 | 0 |
| 16 | Save/load chapter state | 1 | 0 |
| 17 | Target visual direction | 1 | 0 |

Baseline total: **0 / 100**.

## Checkpoint history

| UTC | Main SHA | Score | Window delta | Strategy |
|---|---|---:|---:|---|
| 2026-09-06 22:04 | 5547d415f | 0 | baseline | Land owner boards with code CI, then multiplayer realm seam and Terrain3D foundation. |

Every checkpoint appends newly playable capabilities, reachable regions/story, live mechanics, content added, merged SHA, evidence, blockers and next highest-value task. >=10 points: strong; >=5 and <10: acceptable and name approach change; <5: change strategy immediately; two consecutive <5 windows: stop building, integrate completed work and write §34 final report plus §9 fresh-session tail. No third near-identical attempt on a narrow issue.

## Two-hour checkpoint — 2026-09-06 23:54:38 UTC

Merged main: `e78f2ab45f5d22bbf2ffcbb0394bd5b17b99f779` (reference PR #68). Original weighted score: **0 / 100**, delta **0**, first consecutive window under five points. Every exit/checklist row remains zero: PR #70 is not merged, and authored data is not playable evidence. The next checkpoint is 2026-09-07 01:54:38 UTC; another delta under five invokes the owner's stop-building, integrate-finished-work, and fresh-session-tail rule.

Player-visible work on the integration branch: Cloudreach's actual gate enters the 108-region Terrain3D Stormwood and returns to Cloudreach in a completed runtime smoke. A real two-peer run places the client in Stormwood while the host remains in Meadows with the Stormwood simulation shell, then returns the client with the session intact. The client terrain load now yields between asset stages instead of starving network heartbeats. These are branch evidence, not merged-main score credit.

Regions/content: all six regions have terrain and baked scatter (15,066 placements); the full walking route, Crown access, living encounters, NPC interactions and chapter finale do not yet work. Encounter, trainer, pickup and dialogue catalogues and the root-authored 28-beat story are unintegrated drafts. No Surge, Stormglass Arches or Dynamo gameplay has shipped. The eight-frame foundation visual review failed both bars; framing was corrected but not yet recaptured or rejudged.

Evidence: `stormwood-route-smoke-fixed.log` ended STORMWOOD TRANSITION OK, exit 0. Net run `net-run-local-2020643` has no failures/fatal and both children exited; root read the separate child user directories and host's 108-region READY line. Positive fog growth was weakly asserted and is being strengthened in a fresh-location smoke. CI run 34067435099 passed all four unit and five multiplayer shards, terrain/scatter freshness and most gameplay jobs, but failed trainer_battle and trainer_no_usable_ally. The full local unit run is still executing its expensive vegetation tail; three earlier failures have targeted passing corrections, not a clean full-suite claim.

Strategy change, effective now: stop treating foundation acceptance details as the only useful lane. Keep one bounded agent on the two trainer CI failures, another on the strengthened crossing smoke, and move root implementation focus to the continuous chapter route and working kitbashed Stormheart Dynamo. Integrate the foundation as soon as its actual code jobs pass; dependent runtime lanes must branch from that merged main. Content agents correct bounded catalogues while root retains story, world composition, architecture and acceptance. Do not attempt a third near-identical fix or count another catalogue as playable progress.

| UTC | Main SHA | Score | Window delta | Strategy |
|---|---|---:|---:|---|
| 2026-09-06 23:54:38 | e78f2ab45 | 0 | 0 | Narrow foundation blockers delegated; root shifts to continuous chapter route and working Dynamo. |

## Two-hour checkpoint — due 2026-09-07 01:54:38 UTC, recorded 02:00 UTC

Merged main at the checkpoint: `84125fcd008d93c0fefdfff51a2752b94b4faada` (PR #70). Score **5.25 / 100**, window delta **5.25**: acceptable, not strong. The preceding observation call was interrupted; this entry records the due checkpoint against the main that existed then, not a later landing. The consecutive-under-five count resets to zero. Next checkpoint: 03:54:38 UTC.

Explicit row credits: §32.1 Entry and return earns 75% of 6 = **4.5**: the production mounted gate refuses no-key unlock/travel, accepts the durable host-ledger key, enters the real Terrain3D realm and returns; a two-peer crossing retains the host in Meadows with an active Stormwood simulation shell. The completed-Cloudreach save/load fixture remains unmerged and earns no credit, so this is not full entry acceptance. §7.1 Cloudreach transition earns 75% of 1 = **0.75**, for that same broad-build transition capability with the same missing completed-save proof. All other original rows remain zero. The frozen scorecard deliberately includes broad delivery separately; no extra CI, density, visual, or draft-code credit is added.

Evidence inspected: merged `tests/smoke_stormwood_transition.gd` exercises the actual scene/router/gates; strict two-peer run `net-run-local-1977417` and subsequent foundation run `net-run-local-2021033` have separate peer directories, host 108-region shell READY, client fog growth without host fog contamination, and normal completion. PR #70 code jobs passed before its ancestry-confirmed merge. PR #74 was not merged at the checkpoint and is excluded even though its retry has since become green.

Player-visible branch work, not score credit: 19 NPCs, 26 trainers and 660 ordinary wild instances load in six regions; a physical Stormheart ascent reaches the upper platform; ordinary pickups use existing host claims. The opening interaction exposed overlapping NPC/trainer/pickup offers, now under a bounded placement correction. Surge clock and save v23 transport exist locally, but strikes, arch travel/construction, Crown progression, four rod stations, Dynamo phases, legendary choice and Waterward ending remain unfinished. Every blind visual review still fails. No whole-chapter playability claim is justified.

Approach change for the next window: pause tree silhouette and density polishing; keep CI diagnosis bounded; prioritize working Surge, arches and chapter gates across the route. Require real opening interactions and multiplayer/save evidence as each slice is integrated, and ship dependent work from the newly merged foundation. Avoid another visual tuning loop or CI retry without changed evidence. Full local unit wave 2 was started, but its last log is incomplete; its result is not credited.

| UTC | Main SHA | Score | Window delta | Strategy |
|---|---|---:|---:|---|
| 2026-09-07 01:54:38 | 84125fcd0 | 5.25 | 5.25 | Visual polishing paused; prioritize live Surge, arches and chapter gates, with bounded proof lanes. |
