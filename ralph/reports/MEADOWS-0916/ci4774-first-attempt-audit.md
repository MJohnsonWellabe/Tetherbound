# CI 4774 first-attempt audit

Audited 2026-09-16 through the GitHub connector. [Run 35068510862](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862) reports head SHA `b246278841ebcc306e3d70ba1c8f267840633fa2`, completed success, **run_attempt=1**, previous_attempt_url=null.

## Result and limits

The 15 requested terminal job logs below contain no observed smoke attempt 2 or higher and no actual `SCRIPT ERROR:` diagnostic. Retry capacities such as combat `1/2` and traversal `1/3` are not retries that occurred: only their first launch marker appears. Direct named tests were also inspected separately from wrapper markers. Four unit shards report **3,730 tests, 506,975 assertions, zero failed**. All 39 multiplayer wrapped smoke launches show attempt 1/1.

This supports first-attempt completion for the audited jobs, not error-free output or acceptance of Meadows gates. Other enabled verification jobs were present/successful in job metadata but their raw logs were outside this bounded audit. Known-red continuous/full Gate B jobs and export were skipped; they are not passes. No Godot, reruns, code changes, or commits were performed.

| Job | Job ID / terminal log | Attempt / terminal evidence |
|---|---|---|
| verify-unit-tests (3) | [104704732823](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732823) | 951 tests, 30486 assertions, 0 failed |
| verify-unit-tests (1) | [104704732866](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732866) | 835 tests, 35328 assertions, 0 failed |
| verify-gate-evidence-shard | [104704732877](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732877) | 10 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-combat-shard | [104704732891](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732891) | 6 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-unit-tests (4) | [104704732962](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732962) | 947 tests, 88610 assertions, 0 failed |
| verify-regions-shard | [104704732967](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732967) | 9 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-unit-tests (2) | [104704732995](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704732995) | 997 tests, 352551 assertions, 0 failed |
| verify-core-verb-shard | [104704733011](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104704733011) | 8 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (7) | [104705481264](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481264) | 1 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (6) | [104705481273](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481273) | 7 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (3) | [104705481334](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481334) | 6 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (1) | [104705481369](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481369) | 7 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (4) | [104705481382](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481382) | 6 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (2) | [104705481389](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481389) | 6 wrapped smoke launches, all attempt 1; direct named checks also inspected |
| verify-multiplayer-shard (5) | [104705481401](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35068510862/job/104705481401) | 6 wrapped smoke launches, all attempt 1; direct named checks also inspected |

## New production staging regression

Combat job 104704732891 has one direct invocation of `smoke_combat_trainer_staging_clearance.gd`, followed at 07:36:28 UTC by all six PASS lines: intended open-side placement; blocked transit choosing opposite side; both sides blocked retaining origin; unsupported claimed floor retaining origin; supported gentle slope; small arena containment. The subsequent trainer-battle smoke launches once at attempt 1/2. No retry or failed staging assertion occurs.

## FAIL and error classification

- **Expected negative control:** multiplayer shard 2, job 104705481389, 07:42:02 UTC: `FAIL: ERROR: peer exited (peer 1, pid 3155)`, coordinator exit 2, immediately followed by `PASS: negative control -- killing peer 1 made the coordinator record exit 2`. The process-not-a-child errors and fatal peer receipt belong to this deliberate peer-death test, not an unreported failed smoke.
- **Expected refusal/watchdog controls:** unit logs emit unknown species/conversation, malformed JSON, missing retained services, earned-run watchdog/refusal FAIL text, and deliberately undeclared flags. Their surrounding named tests and final zero-failure summaries distinguish tested refusal output from assertion failures. Regions job 104704732967 explicitly tests realm readiness timeout, guarded rollback, and failed transition autosave; lifecycle terminal reports checks=108 failed=false, with adapter terminals also failed=false.
- **Nonfatal production diagnostic, not a negative control or shutdown leak:** combat job 104704732891 emits `the player already has a creature; adopt_starter is not a swap` at 07:35:51 (boss) and 07:37:52 (trainer). Backtrace: encounter_director.adopt_starter:1258 → sequence_director._hand_a_late_arrival_a_companion:865 → _catch_up_a_behind_character:845 → _process:535. Both smoke fixtures explicitly adopt a starter. This records an actual catch-up/fixture inconsistency during successful smokes; no failed assertion or rerun occurred. The logs alone do not establish a new gameplay regression.
- **Nonfatal fixture diagnostics:** units 2/3 call item-cache/felled-resource visual helpers off-tree, producing get_node/get_tree errors; unit 1 cloudreach environment test reads an off-tree global transform. These are runtime diagnostics inside passing fixtures, not parser errors. Unit 4 `test_realm_world_records.gd:80` sets synthetic `upper_open` without declaring its scope and emits `unscoped flag: upper_open`; the following assertion still passes. This should be cleaned up as a fixture issue rather than described as clean stderr.
- **Headless renderer diagnostics:** core/gate-evidence/combat print null-material errors from `servers/rendering/dummy/storage/material_storage.cpp:264`. Gate A build-house emits some during execution, so these must not all be relabeled shutdown-only.
- **Shutdown resource diagnostics:** ObjectDB/resource/RID leak messages occur in several scene smokes and unit shard 4. These are reported separately from assertions; no associated retry marker was observed. Their presence prevents any blanket “no errors” claim.

## Retrieval and reproducibility

Fetched the run metadata, latest job list, and complete decoded terminal logs using GitHub connector read-only calls. Job links above identify the raw source. Logs were retained in this agent's tool store during analysis (`log<job-id>`); no standalone raw-log files were created. Scanned actual timestamped output separately from echoed shell `grep SCRIPT ERROR` commands and test names containing “retry.” This receipt is the persisted compact audit.
