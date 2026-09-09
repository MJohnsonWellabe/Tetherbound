# PR95 first-head CI receipt — 548da7a3d

**Failed unit coverage, then superseded and cancelled. No landing approval.**
Reviewed 2026-09-09 UTC.

Head `548da7a3d33b5ccce6227a038762b6f6132ac3f7`, base
`4830bf402a94d7d945119027a454d07dfee1dccc`.
[CI 34343691520](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34343691520)
started 11:05:24 UTC, attempt 1. The corrected source push superseded it;
the final workflow result is **cancelled at 11:16:49 UTC**. That cancellation
does not erase the completed unit failure.

Direct REST `jobs?filter=all&per_page=100` returned all 29 jobs: **11 success,
1 failure, 15 cancelled, 2 intended skips**, every job attempt 1. All 25 jobs
that executed steps have complete raw logs retrieved and inspected (8,624,318
characters). The two cancelled dependency/export jobs and two manual-only skips
had zero steps and no executable-job log. Their absent logs are not test passes.

## Actual failure

[Unit shard 1, job 102440705331](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34343691520/job/102440705331)
finished with **761 tests, 301984 assertions, 1 failed**. Its two new distinct
script errors are:

- Invalid call. Nonexistent 'float' constructor, from
  `fresh_opening_segment.gd:311` and `:360`.
- Out of bounds index '-1' on Array[String], from
  `test_fresh_opening_target.gd:101`.

The existing ThrowVerdict fake lacked the newly read native `_guard` property.
The final-verdict test aborted before recording a refusal, then indexed the
empty failure list. It misleadingly printed “ok” after that script exception.
The transient-readiness test counted as failed. Five assertions were lost
versus the corresponding base shard (301989).

The other unit shards completed successfully: 851/138547, 645/26672 and
819/20406 tests/assertions. Aggregate completed unit output is therefore
**3076 tests, 487609 assertions, one counted failure**, with the additional
script-aborted assertions explicitly retained. This is not a full unit pass.

## Completed targeted evidence and coverage limits

The earned-aim step completed successfully at 11:09:48–11:09:59 UTC. Its complete
regions raw log proves all four cases actually ran: **19 windup checks,
8 HUD checks, 5 eight-tick/idempotent checks, 8 natural-guard readiness checks**,
each with empty failures. Those checks preceded the later cancellation of the
regions job. The sequential CI wrapper uses independent XDG profiles, native
timeouts, whole-log error scans and exact completion summaries with no retry.

Changes ran all seven Node release-helper tests, all passing. Both bake checks,
harvest, Gate B CORE and Gate A UI/build job completed successfully. These do
not imply the cancelled solo suites finished.

Network discovery found 37 tests and seven shards. Only shard 7 completed its
one split-realms smoke successfully. The other six shards were cancelled
partway through; no 37/37 network claim is made. Raw logs show only first-attempt
invocations, with no second attempt or retry rescue.

All 27 executed main4830 baseline raw logs were fetched directly for comparison.
The completed successful PR95 jobs retain their matching normalized baseline
native-error sets. The unit script errors above are new. Cancelled logs retain
known material-null, leak-count and smoke_relay_gate findings but cannot prove
full-run error-set equivalence. Normalization covers only dynamic peer/cache/
process IDs and resource/RID leak counts.

The e505 PR94 shard5 raw log was also fetched directly and contains the distinct
`ERR_UNAUTHORIZED` despawn rejection. PR95's cancelled network portion did not
complete Water-alpha coverage, so this run cannot establish whether that finding
would recur. No causal attribution or clearance is granted.

## Complete job inventory

| Job | Raw job ID | Final result |
| --- | ---: | --- |
| changes | 102440151567 | success |
| verify-gate-evidence-shard | 102440705059 | cancelled |
| verify-veg-corridor | 102440705060 | cancelled |
| verify-scatter-bake-freshness | 102440705150 | success |
| verify-unit-tests (2) | 102440705159 | success |
| discover-net-smokes | 102440705165 | success |
| verify-unit-tests (4) | 102440705167 | success |
| verify-terrain-bake-freshness | 102440705192 | success |
| verify-gate-b-core | 102440705195 | success |
| verify-combat-shard | 102440705199 | cancelled |
| verify-scatter-rules | 102440705200 | cancelled |
| verify-core-verb-shard | 102440705203 | cancelled |
| verify-regions-shard | 102440705273 | cancelled |
| verify-gate-a-ui-build-shard | 102440705282 | success |
| verify-owner-regressions-shard | 102440705283 | cancelled |
| verify-harvest | 102440705307 | success |
| verify-unit-tests (1) | 102440705331 | failure |
| verify-unit-tests (3) | 102440705348 | success |
| verify-gate-b-full-known-red | 102440706343 | skipped (no steps) |
| verify-continuous-core-known-red | 102440707076 | skipped (no steps) |
| verify-multiplayer-shard (2) | 102441262475 | cancelled |
| verify-multiplayer-shard (4) | 102441262490 | cancelled |
| verify-multiplayer-shard (7) | 102441262518 | success |
| verify-multiplayer-shard (1) | 102441262593 | cancelled |
| verify-multiplayer-shard (6) | 102441262607 | cancelled |
| verify-multiplayer-shard (5) | 102441262677 | cancelled |
| verify-multiplayer-shard (3) | 102441262704 | cancelled |
| verify-solo-regression | 102443297178 | cancelled (no steps) |
| export | 102443307337 | cancelled (no steps) |

## Correction tracking

Root corrected only the unit fake by adding its typed native-guard field and
retained a correction receipt. New head
`2a971cb3a2a232e0bdb4e89f4613f878b58fa24b` triggered separate CI
`34344633432`. That is a changed-source run requiring its own complete review,
not a retry rescue. This receipt does not pre-approve it.

Reviewer performed read-only remote review and wrote this receipt only: no
Godot, rerun, implementation, branch switch, push or merge. This is CI evidence,
not continuous campaign, full-world invalid-commit cancellation, visual,
performance, shipped-build or Beta Ready acceptance.

