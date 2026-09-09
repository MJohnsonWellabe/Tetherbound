# PR94 exact-head CI review — f823de9a5

Reviewed 2026-09-09 UTC. **Do not land this head: CI failed on its first telemetry execution.** The production death lifecycle regressions passed, but the telemetry artifact output contract is broken in CI.

## Identity and terminal result

PR94 head `f823de9a53f4b032b1c5d541fff748cacb5a304d`, base `4830bf402a94d7d945119027a454d07dfee1dccc`.
[CI run 34313300491](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34313300491) is terminal **failure**.
Checkout logs identify synthetic merge `4e66fa2f563631e3448b60fe4fa5edf78b3f7693`, merging that exact head into that base.
PR remained open/draft at review. Superseded run 34313111893 at 5403 was cancelled and is not a passing result.

The jobs response contains 29 jobs: **24 success, 1 failure, 4 skipped**.
All 25 executed jobs' complete decoded raw logs were fetched (9,107,840 characters) and inspected for outcomes, first-attempt groups, error classes, and relevant assertion evidence. Raw log activity spans 05:03:24–05:30:49 UTC. Direct REST `jobs?filter=all&per_page=100` independently confirmed total_count=29, returned=29, and every job run_attempt=1. No second smoke attempt occurs in the raw logs. No rerun was requested by this reviewer.

## Blocking failure

Region job **102344677192**, step **Verify Stormwood combat telemetry**, failed at 05:23:37 UTC:

- Fourteen behavioral checks passed, including authored Stormraven level 39, accepted miss/hit, real >=900 ms wall cadence, immutable impact records, active terminal sample, independent poses, no authority mutation, creature identity, and freed/missing body handling.
- The fifteenth check, **artifact output opened**, failed. Final line: `STORMWOOD TELEMETRY: 15 checks; 1 failures; elapsed_ms=915`.
- The script reads `TETHERBOUND_TELEMETRY_OUTPUT` then calls `FileAccess.open(output, FileAccess.WRITE)`. This exact CI step supplies no environment value. The inspected workflow and script establish the missing output contract; the earlier local run's output environment does not carry into GitHub Actions.
- This is a real failed assertion and exit 1, not an acceptable negative control. Supply a writable explicit output path and validate the changed head. Do not rerun the unchanged failed head to obtain green.

The region job continued its remaining independently guarded steps; those succeeded. The solo regression dependency fence skipped because regions failed. Export and the two manual-only full-chain known-red jobs did not execute.

## Execution evidence

The four unit shards passed **3,076 tests / 487,614 assertions / zero failed**:
761/301,989; 851/138,547; 645/26,672; 819/20,406.
The changes job actually executed **seven Node release-reference tests**, seven pass, zero fail.
Separate scatter/terrain/harvest/corridor suites also passed.

The native finalized-death smoke passed **37 checks**. Its exercised paths include active and between-round death, synchronous retirement before camp movement, deployed-control release, existing camp/vitals/satchel behavior, stale snapshots, idempotence, renewed explicit challenge, authenticated self-withdrawal with another participant retained, contribution preservation, delayed admission, and transient downed acceptance.

Discovery found **38** two-peer smokes; all **38 executed once and passed** across seven shards (6/6/6/6/6/7/1). The new `smoke_net_stormwood_finalized_death.gd` ran in job **102346294510** at 05:18:51–05:20:54 UTC with two native processes, real ENet identities, and **28 passing checks**. Its disclosed fixture grants realm access and a level-99 Terrapup then emits lethal damage. The normal revival window remained live from 05:20:03.620 to 05:20:48.893; final death cleared client combat and host membership, later snapshots did not restart it, no defeat flag/reward appeared, and authority remained in Meadows. This proves that bounded lifecycle path, not earned chapter progress.

The deliberate peer-death negative control moved to multiplayer shard 3. Its expected killed-peer coordinator exit 2 was followed by explicit `PASS: negative control`; it is not a retry rescue.

## Job inventory

| Job | Raw job ID | Conclusion |
|---|---:|---|
| changes | 102344234125 | success |
| verify-gate-a-ui-build-shard | 102344677063 | success |
| verify-veg-corridor | 102344677083 | success |
| verify-harvest | 102344677084 | success |
| verify-core-verb-shard | 102344677090 | success |
| verify-scatter-bake-freshness | 102344677097 | success |
| discover-net-smokes | 102344677105 | success |
| verify-owner-regressions-shard | 102344677108 | success |
| verify-terrain-bake-freshness | 102344677116 | success |
| verify-unit-tests (1) | 102344677139 | success |
| verify-gate-b-core | 102344677151 | success |
| verify-gate-evidence-shard | 102344677160 | success |
| verify-unit-tests (2) | 102344677162 | success |
| verify-combat-shard | 102344677171 | success |
| verify-regions-shard | 102344677192 | failure |
| verify-unit-tests (4) | 102344677246 | success |
| verify-scatter-rules | 102344677306 | success |
| verify-unit-tests (3) | 102344677496 | success |
| verify-continuous-core-known-red | 102344677992 | skipped |
| verify-gate-b-full-known-red | 102344678039 | skipped |
| verify-multiplayer-shard (6) | 102346294445 | success |
| verify-multiplayer-shard (4) | 102346294459 | success |
| verify-multiplayer-shard (3) | 102346294463 | success |
| verify-multiplayer-shard (5) | 102346294473 | success |
| verify-multiplayer-shard (7) | 102346294484 | success |
| verify-multiplayer-shard (2) | 102346294510 | success |
| verify-multiplayer-shard (1) | 102346294523 | success |
| verify-solo-regression | 102349560312 | skipped |
| export | 102349560749 | skipped |

## Native-error comparison and limits

The full raw logs for eleven relevant base-main 8c0bfb31 jobs were fetched anew, rather than trusting a prior report: UI/build 102337719875; harvest 102337719765; core verbs 102337719965; unit shards 1/2/3/4 102337719777/102337719790/102337719775/102337719781; combat 102337719854; regions 102337719857; gate evidence 102337719858; multiplayer shard 5 102338054844. The exact-base report is [CI-MAIN-8c0bfb31a.md](CI-MAIN-8c0bfb31a.md).

Their distinct native `ERROR:` / `SCRIPT ERROR:` sets are identical or subsets after normalizing only resource/RID leak counts and dynamic peer/cache IDs. No new native error class was identified. Existing material-null, off-tree node/data.tree, invalid fixture JSON/species/conversation/flags, dummy-renderer/resource leaks, duplicate adopt_starter, and network teardown cached-node/invalid-packet/synchronizer errors remain. Terrain mipmap/interpolation and sparse scatter warnings also remain. Green checks are not a clean-runtime-log claim. The new telemetry failure is a separate explicit assertion failure, fully retained above.

Network artifacts were uploaded by all seven shards; archive contents were not downloaded or audited. This receipt uses complete raw job logs and job/step metadata. No visual, performance, continuous full-player-path, Varga victory, shipped Windows build, or Beta Ready gate is established.

Reviewer changed only this uncommitted receipt. No Godot, implementation, branch change, commit, push, GitHub mutation, merge, or rerun.
