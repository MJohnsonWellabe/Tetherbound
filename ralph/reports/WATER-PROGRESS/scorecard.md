# Water progress scorecard

Fixed denominator: **100 original-goal points**. Baseline 2026-09-06 21:55:38 UTC, main `5547d415ffe58438f5bed9fc9b6b710b37a5bdad`. First window ends 23:55:38 UTC. Partial credit requires a specific completed player-facing subpath with passing runtime evidence on the delivery branch; prose/data/code existence alone earns nothing. Full row credit requires all named exit evidence, including blind judgment where applicable. Never renormalize around deferred work. The owner's newer branch-only instruction changes the delivery target, not the goal or quality bar; shipped-to-main evidence stays separate below.

| System / directive completion bar | Weight | Baseline | Full-credit evidence |
|---|---:|---:|---|
| Stormwood entry and continuous main path | 16 | 0 | earned key, ordinary transition, complete docks/objectives/camps to finale with real body |
| Human swimming, drowning, fair safe landings | 12 | 0 | low-skill first crossings, exhaustion/health feedback, no idle exploit, safe exit |
| Mounted swimming, currents, expanded second half | 12 | 0 | five different viable mounts, stamina/exhaustion, readable route choice, hardest crossing |
| Aquaryn Alpha, Swim Stone, crafted saddle | 12 | 0 | distinctive land/water fight, catch and defeat branches, alternate mount path |
| Veilfall approach/reveal/stronghold/finale | 14 | 0 | continuous shore→hike→falls→sluices→captain→legendary/ceremony; blind board verdict |
| Global Skills and Skill Candy | 7 | 0 | Meadows accumulation, Biome2 reveal, controller menu, real benefits, owned cap-safe consumption |
| Water combat and remount | 6 | 0 | interception, direct pilot/switch/catch, drain pause, no healing exploit, legal resumption |
| Multiplayer authority and split islands | 8 | 0 | real peers, swimming/drowning/mount sync, shared docks/Alpha/finale, separate islands |
| Persistence, migration, reconnect | 5 | 0 | old saves, character and world split, midwater reconnect, once-only ownership |
| Island content, exploration and density | 4 | 0 | 12 islands, runtime census actuals, rewarding optional routes, measured dead-travel bounds |
| Tidal Guard, relic and world response | 2 | 0 | earn/place/single-active damage reduction and visible persisted aftermath |
| Broad visuals, controller and target performance | 2 | 0 | ten blind judged route frames, 720p/controller path, shipping performance evidence |
| **Total** | **100** | **0** | |

## Baseline evidence

Stable main source inventory finds no Water scene, swimming system, global Skills or Skill Candy. The Water directive is present. No completed Stormwood handoff report exists; Stormwood is a concurrent owner-authorized Stage A run. Existing multiplayer and Cloudreach are dependencies, not earned Water completion points. Owner boards inspected from fetched reference branch; its PR is being integrated by Stormwood. No Water runtime or visual test has run, so baseline is 0/100.

## Window history

| UTC checkpoint | Main SHA | Score | Window gain | Evidence / response |
|---|---|---:|---:|---|
| 2026-09-06 21:55:38 | 5547d415f | 0 | — | Source baseline only; no Water player path exists |
| 2026-09-06 23:55:38 | e78f2ab45 | 0 | 0 | First low-gain window. PR69 remains deliberately unmerged under the newer owner branch-only instruction. Human lesson and Skills menu have local runtime evidence, but neither a continuous chapter path nor current-wave full CI has passed. Shift immediately from foundational systems/data to the First Shore→dock→Alpha player path. |

Owner branch-only update supersedes automatic merging. Keep main evidence and branch evidence distinct; do not claim an unmerged result exists on main. The original fixed denominator, clock and thresholds remain unchanged. `runtime-wave-1.md` lists local evidence without crediting plans or data. The next checkpoint is 2026-09-07 01:55:38 UTC.

### Delivery-target correction recorded 2026-09-07 01:35 UTC

The earlier main-only interpretation would force zero delivery progress solely because the owner explicitly prohibited merging. That is an agent-authored restriction, not evidence that working branch subpaths made no progress. Apply the original rate rule to verified work on the authorized Water branch; continue to show main as unshipped. Preserve the original main-history rows above unchanged. No completed chapter, passing CI or accepted frame is inferred by this correction.

For comparison at the unchanged second checkpoint, the **reconstructed branch baseline at 23:55:38 is 5/100**: human swimming 3/12 (dated 16-check production 60.143m lesson/resource path), Skills 2/7 (dated 44-check menu and focused use/ownership regressions), all other rows zero. This reconstruction is recorded now, not represented as a score published then. It credits no first-window terrain/data counts. At 01:55:38, cite actual new evidence per row, current branch/main SHAs, CI limitations and remaining gaps before awarding any further points. Under five in two successive delivery windows still stops the run. Do not spend or reset an extra two-hour window because of this correction.

At each 2-hour checkpoint: >=10 points strong, continue; 5–<10 acceptable, name next change; <5 change strategy immediately; two consecutive <5 windows stop, integrate verified work, and write the fresh-session tail. No third near-identical attempt. Record actual elapsed time and any external blockers; do not give score credit for waiting or documentation.

## Second checkpoint — 2026-09-07 01:55:38 UTC

Delivery branch `ralph/water-foundation-0906` at `05a272f8961ca122a23063adc763202d2a853906`, with runtime-wave implementation ancestor `33b3c9ef9`. Main ancestor `84125fcd008d93c0fefdfff51a2752b94b4faada` contains no Water implementation: shipped-main score remains **0/100**. Authorized branch score is **18/100**, gain **13** against the transparently reconstructed first-window branch score of 5. This is a strong delivery window under the unchanged thresholds. Continue; it is not chapter completion or phase closure.

| System | Weight | Branch score | Dated inspected evidence and remaining limit |
|---|---:|---:|---|
| Entry / main path | 16 | 2 | `water-dock-actions-smoke.log` 01:06:32checks and `water-camps-smoke.log` 01:20:129checks: actual barrier/current repair, costs, craft/rest/save. Prerequisites and travel use fixtures; no continuous key-to-finale path. |
| Human swimming | 12 | 5 | `water-swim-material-fix.log` 00:28:19assertions,60.143m production lesson, exhaustion/health/pause/landing; fresh-world 21checks below. Full first-half crossing budget and feedback still unproven. |
| Mounted traversal | 12 | 4 | `water-mounted-axis-fix.log` 01:25:91checks across all5species, swim/resource loss/HP damage/dismount/remount/no-refill/dry exit. Stone/saddle and exit resource reset are fixtures; hardest crossing and actual route choice unproven. |
| Aquaryn / Stone / saddle | 12 | 0 | No earned fight-to-craft path. New tuning is implementation data, no credit. |
| Veilfall finale | 14 | 0 | Interior and complete finale absent. |
| Skills / Candy | 7 | 2 | First-window44check menu/use/ownership evidence retained; rebase-focused48tests448assertions includes Skills. Ordinary Meadows→Biome2 reveal and complete Candy placement path unproven. |
| Water combat | 6 | 0 | Paused resources alone do not prove interception/direct pilot/switch/catch/remount sequence. |
| Multiplayer | 8 | 2 | `water-net-swimming-coordinator-b.log` 00:02 actual isolated2process human swim/drowning and bodies>1.5km apart; satchel host6/client8 at00:59 handles lost reply. Mounted transport, Alpha and finale missing. |
| Persistence | 5 | 2 | `water-reconnect-save-smoke.log` 00:55:21checks, actual character disk + destroyed/rebuilt world retains exhaustion/health/anchor. Durable escrow regression62tests322assertions and actual2peer bag replay. Mounted reconstruction newly changed but not yet runtime-proven; earns0. |
| Content / density | 4 | 1 | `water-encounters4.log` 00:30:28checks actual wild/trainer setup; independent census and camp129checks. Counts never substitute for continuous travel; optional named encounters/sidechains missing. |
| Relic / world response | 2 | 0 | Not implemented. |
| Visuals / controller / performance | 2 | 0 | Six frames failed blind acceptance; no accepted shipping performance evidence. |
| **Total** | **100** | **18** | **+13 in this fixed window.** |

These paths ran before the rebase; the rebased map/flight/Skills/save seams were subsequently checked, but a complete current-head suite has not passed. CI34073362639 had two failing unit shards; their three concrete portrait/roster/save-key failures pass root's63tests359assertions and were pushed in05a272f89. That new commit awaits its own full CI. The local import failed with memory-allocation errors; the changed two-worker strategy is currently live without logged errors. The partial local shard run before import completion is not a clean regression pass. No points are awarded for imports, PRs, reports, analytic placement, untested mounted load changes or promised Alpha architecture.

Next window ends **2026-09-07 03:55:38 UTC**. Prioritize the host-owned Aquaryn encounter, durable eligible-character Stone awards and ordinary saddle crafting, then second-half/Veilfall playability. Finish the already-prepared mounted transport and save checks while import completes; do not turn them into a narrow polishing tail. Preserve branch-only delivery and the two-consecutive-low-window stop rule.
