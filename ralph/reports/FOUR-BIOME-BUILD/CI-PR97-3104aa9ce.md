# PR97 head 3104aa9ce CI audit — complete

Run [34369962476](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34369962476), exact head `3104aa9cee10e2e5baab15023874dcfd72d889db`, attempt 1: **completed success, all executed raw jobs reviewed**. Final inventory: 29 jobs, 26 successful and three skipped (the two existing known-red jobs and PR export). Solo regression executed successfully. No new blocker found for this exact reviewed scope.

All **26 full executed job logs / 9,377,222 bytes** are retained. No executed first-invocation failure or attempt 2+ group was found. Comparisons against both previous PR97 5fae and main 77745 are retained separately. The initial and intermediate notes below preserve chronology; their pending statuses were superseded by the final review at the end.

Artifact root: `.artifacts/pr97-3104aa9c-ci/`. Eight completed full job logs retained at the initial checkpoint: changes, discovery, two bake freshness checks and four unit shards. Metadata is saved in `run.json` and `final-jobs.json`; the latter is a current snapshot until the workflow completes. No CI rerun, remote mutation or local engine run is involved.

Four unit shards: **3,129 tests / 487,903 assertions / zero failed**. Aggregate normalized engine diagnostics compared with prior PR97 head 5fae: 218 versus 217; added exact-count messages are existing shutdown-resource class variants (15 and 4 resources). No new non-shutdown engine class in the reviewed unit logs. Different shard membership means per-shard totals are not directly comparable. Full diagnostics remain retained, not waived as clean raw output.

The same aggregate also matches main 77745's 218 normalized diagnostic lines exactly (`comparison-main.json`). Both baseline comparisons are retained separately.

No executed failed-attempt or retry group appears in these eight logs. Most world/native smoke jobs are still running at this checkpoint; no first-invocation claim or native acceptance is made for them. Earlier PR97 5fae's failed opening followed by automatic retry remains separately recorded and is not erased by this new run.

## Nineteen-job checkpoint

Nineteen completed executed jobs now have full retained logs, including multiplayer shards 2, 3, 4, 6 and 7, combat, owner regressions, gate-A UI/build, gate-B core, harvest and vegetation. No executed failed-attempt line or retry group in reviewed logs. New differences against 5fae remain existing resource-shutdown count variations; multiplayer shard 2's normalized process-child error matches baseline. Six jobs remain active at this checkpoint, so overall acceptance remains pending.

## Final exact-head results

Regions job `102529663810` includes all lifecycle cases, with complete per-role raw logs echoed and the native artifact uploaded as `realm-transition-34369962476-1`, artifact ID `10111792785`:

| Case | Assertions | Elapsed | Raw result |
|---|---:|---:|---|
| Actual Game control flow | 108 | 1.571 s | Exit 0; exactly four declared negative errors |
| Native baseline | 81 | 3.071 s | All three roles exit 0; zero ERROR/SCRIPT ERROR/WARNING |
| Native cancellation | 77 | 3.171 s | All three roles exit 0; zero ERROR/SCRIPT ERROR/WARNING |
| Native late join | 82 | 4.278 s | All three roles exit 0; zero ERROR/SCRIPT ERROR/WARNING |

Terminal synchronizer counts exactly match baseline 12/4/8, cancellation 12/12/12 and late join 14/4/10. Game's declared errors are two readiness-timeout messages, one guarded-recovery message and one failed-autosave message. Those four are the only new non-shutdown diagnostics versus main and belong to explicit negative cases; they already match prior protocol-head evidence.

Gate evidence `102529664066` runs opening **attempt 1/1**. Its readiness line names **Engage Bramblebun at 4.81 m**, followed by the actual tutorial Bramblebun combat checkpoint. The corrected enemy-body assertion is in this exact head. This invocation passes without retry; 5fae's earlier failed opening is still retained as failed history.

All seven multiplayer shards pass first invocation. Normalized engine diagnostics match prior 5fae's existing multiplayer classes, including the known process-child and cached-node/non-authority diagnostics in the broader smoke suite. Do not describe the entire multiplayer suite as raw-error-free; that clean statement applies to the three new native lifecycle cases above. Outside them, changes against the two baselines are existing shutdown-resource count variations. No new native diagnostic class or hidden retry was found.

Hosted Stormwood and Water settlement tests execute in the unit shards on the final source. Their component coverage is not a new real-transport hosted encounter travel proof. Existing host-world rebuild limitations remain outside Phase1. This receipt supports landing the reviewed exact head within that scope; it does not accept unrelated held PR94 or visual changes, and it does not erase older failures.
