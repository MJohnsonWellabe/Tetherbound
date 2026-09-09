# Main 8c0bfb31 CI and Release review

Reviewed 2026-09-09 UTC. Verdict: **exact-main regression CI and Release completed
successfully on first attempt**. Rolling release asset publication succeeded, but
the `latest` Git tag remained stale at the observed publication; that separate
release-identity defect is not resolved by these green workflows.

## Exact source and terminal runs

Source commit: `8c0bfb31a1e719b7e7e61f4c91d989da1a5b3896`, branch `main`.
Both workflows were push-triggered and began `2026-09-09T04:26:32Z`.

| Workflow | Run | Attempt | Terminal | Finished UTC | Duration |
|---|---:|---:|---|---|---|
| [CI](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34310983183) | 34310983183 | 1 | success | 2026-09-09T04:50:08Z | 23m36s |
| [Release](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34310983188) | 34310983188 | 1 | success | 2026-09-09T04:43:30Z | 16m58s |

REST `actions/runs/<run_id>/jobs?filter=all&per_page=100` verified all pages:
CI **29/29 jobs, 27 success / 2 skipped**, Release **2/2 success**. Every returned
job was attempt 1. All executed steps succeeded; cached Godot install steps
legitimately skipped. Complete decoded raw logs were fetched and inspected for
all **29 executed jobs across both runs**, with no missing log.

The main changes job compared against
`49da91d51953fb4b650f29b1399ae41218f68f86` and detected the new capture helper.
This was a real code validation run. No actual failed first attempt, retry rescue,
or `SCRIPT ERROR` was found. Unit total: **3,076 tests, 487,614 assertions,
zero failed**. Network total: **37/37 first-attempt smoke executions**.

## CI job matrix and raw-log identities

Each job ID identifies its decoded raw source at GitHub REST
`repos/MJohnsonWellabe/Tetherbound/actions/jobs/<job_id>/logs`, and its visible
job page under the CI run URL followed by `/job/<job_id>`.

| Job | Job ID | Result / evidence |
|---|---:|---|
| changes | 102337418109 | Success; all executed steps succeeded |
| verify-scatter-bake-freshness | 102337719689 | 1 tests / 1 assertions / 0 failed |
| verify-veg-corridor | 102337719733 | 9 tests / 1,537,510 assertions / 0 failed |
| verify-terrain-bake-freshness | 102337719742 | 1 tests / 1 assertions / 0 failed |
| verify-harvest | 102337719765 | 30 tests / 799,078 assertions / 0 failed |
| discover-net-smokes | 102337719774 | Success; all executed steps succeeded |
| verify-unit-tests (3) | 102337719775 | 645 tests / 26,672 assertions / 0 failed |
| verify-unit-tests (1) | 102337719777 | 761 tests / 301,989 assertions / 0 failed |
| verify-unit-tests (4) | 102337719781 | 819 tests / 20,406 assertions / 0 failed |
| verify-unit-tests (2) | 102337719790 | 851 tests / 138,547 assertions / 0 failed |
| verify-scatter-rules | 102337719834 | 38 tests / 1,019,854 assertions / 0 failed |
| verify-combat-shard | 102337719854 | Success; all executed steps succeeded |
| verify-regions-shard | 102337719857 | Success; all executed steps succeeded |
| verify-gate-evidence-shard | 102337719858 | Success; all executed steps succeeded |
| verify-gate-b-core | 102337719860 | Success; all executed steps succeeded |
| verify-gate-a-ui-build-shard | 102337719875 | Success; all executed steps succeeded |
| verify-owner-regressions-shard | 102337719886 | Success; all executed steps succeeded |
| verify-core-verb-shard | 102337719965 | Success; all executed steps succeeded |
| verify-continuous-core-known-red | 102337720711 | Manual-dispatch-only; not executed |
| verify-gate-b-full-known-red | 102337720935 | Manual-dispatch-only; not executed |
| verify-multiplayer-shard (1) | 102338054708 | 6 smokes, first attempt |
| verify-multiplayer-shard (4) | 102338054711 | 6 smokes, first attempt |
| verify-multiplayer-shard (6) | 102338054740 | 6 smokes, first attempt |
| verify-multiplayer-shard (7) | 102338054741 | 1 smokes, first attempt |
| verify-multiplayer-shard (3) | 102338054745 | 6 smokes, first attempt |
| verify-multiplayer-shard (2) | 102338054754 | 6 smokes, first attempt |
| verify-multiplayer-shard (5) | 102338054844 | 6 smokes, first attempt |
| export | 102340478016 | Windows debug export, PE check, Linux release ground check, artifact upload succeeded |
| verify-solo-regression | 102340478027 | Success; all executed steps succeeded |

The solo-regression job is a dependency fence, not another test execution.
Gate B CORE explicitly stops at tournament readiness; the two full-chain
known-red jobs were not run.

## Native-error comparison

Raw logs were compared with the previously inspected exact PR92 run
**34309659360** on `8ff6939fcee87c840c96717241b1ec94539096a3` and the
base-main run **34308309450** on
`49da91d51953fb4b650f29b1399ae41218f68f86`. The base raw job identities
and error contexts are retained in
[CI-PR92-8ff6939fc.md](CI-PR92-8ff6939fc.md). Normalization changes only
variable peer/process IDs, exit-leak counts, and long known-value lists.

- Unit shards and harvest retain the same native error classes: off-tree
  `get_node`, null `data.tree`, negative JSON/species/conversation fixtures,
  unscoped flags, and dummy-renderer/resource exit leaks. They all have zero
  failed assertions.
- Combat retains material-null, resource leaks, and the existing duplicate
  `adopt_starter` error reached through late-arrival story catch-up.
- UI/build, core verbs, and gate evidence retain material-null and/or exit leaks.
  Regions retains `unscoped flag: smoke_relay_gate` and exit leaks.
- Multiplayer shard 2's killed-process error and coordinator failure are the
  intentional `smoke_net_peer_death` negative control. Its explicit final PASS
  confirms the expected coordinator exit 2 after killing peer 1.
- Multiplayer shard 5 retains the base disconnect race's missing cached
  trainer/Sync node, invalid packet, cached-node lookup, and invalid synchronizer
  errors. On this main run its error set is a subset of the previous run,
  with no resource-leak line. Dynamic trainer/peer IDs differ.
- Release build, Release Pages, and CI export raw job logs contain no
  `ERROR:` or `SCRIPT ERROR` lines.

No new native-error class was identified. Existing nonfatal runtime errors are
retained findings, not erased by the successful workflow conclusion.

## Exports and publication

Release build job **102337418063** checked out the exact source SHA, imported,
exported Windows release, passed the PE32+ and size checks, staged GDExtension
libraries, packaged, and published successfully. The executable listed in its
raw log is **109,052,928 bytes**. The exported-build check reported:

```text
EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004
export: OK — extension loaded, data present, ground found.
```

CI export job **102340478016** separately checked out the same SHA, exported the
Windows **debug** build, passed its PE check, and produced the same successful
ground-check values before uploading its artifact.

**Runtime boundary:** despite the workflow step names, the exact source version
of `tools/verify_export.sh` exports and executes **Linux Test**
`build/linux/Tetherbound.x86_64` under xvfb/OpenGL. These runs verify Windows
binary production and Linux exported gameplay boot. They do not execute the
Windows binary or establish Ally stability/performance. The script redirects
the complete exported runtime log to `build/linux/run.log` and prints selected
checks; that file was not independently downloaded. No claim of inspecting
every line of that redirected runtime log is made.

Release Pages job **102339281085** also checked out the exact SHA, generated ten
patch-note entries, and deployed Pages with
`pages_build_version=8c0bfb31a1e719b7e7e61f4c91d989da1a5b3896`.
All its steps and its decoded raw log were reviewed.

The observed rolling Release record **364540334** had body
`Automatic build of main, commit 8c0bfb31a1e719b7e7e61f4c91d989da1a5b3896`.
Its newly published asset was:

- `Tetherbound-windows.zip`, asset **551987392**, **692,410,744 bytes**.
- Updated `2026-09-09T04:36:19Z`.
- API digest:
  `sha256:5655ec7b104ddfd646bdb25182efff4a59b5159725b149b81a46c0caef3c23aa`.
- [Rolling download](https://github.com/MJohnsonWellabe/Tetherbound/releases/download/latest/Tetherbound-windows.zip).

Publication raw logs, exact checkout, and release metadata support this source
association. The release zip was not downloaded or independently hashed.

At that observation, `refs/tags/latest` still pointed to
`a8423f00fc0245af166222383b9c24dc7beb603e`; `target_commitish` remained
`main`. The workflow at the reviewed SHA has no explicit tag move/read-back.
This review did not mutate the tag. The separate release repair is outside this
commit and must obtain its own validation.

## CI and Pages artifact metadata

All artifacts below are associated by the API with exact source
`8c0bfb31a1e719b7e7e61f4c91d989da1a5b3896`. Metadata and upload logs were
inspected; archives were not downloaded.

| CI artifact | ID | Bytes |
|---|---:|---:|
| Tetherbound-windows-debug | 10088861374 | 686774929 |
| net-smoke-runs-5 | 10088745234 | 11143643 |
| net-smoke-runs-2 | 10088690585 | 9378948 |
| net-smoke-runs-1 | 10088677346 | 9390149 |
| net-smoke-runs-3 | 10088667419 | 7615827 |
| net-smoke-runs-6 | 10088660700 | 11126275 |
| net-smoke-runs-4 | 10088651716 | 11120305 |
| net-smoke-runs-7 | 10088547888 | 1877696 |

Windows debug upload digest matches the artifact API:
`sha256:891c2a4a8f4a02209b1bd9ac26b74b12384e3bea4056d46e4248959d8def0f08`.

Release Pages artifact `github-pages`: **10088711310**, **2,135,080 bytes**,
digest
`sha256:d84b7075f6a410ca52be309e9b1158508a49fc719747f3bbba1f7c5be2cc62ea`.

## Acceptance limits

This establishes regression and export/publication evidence for the merged
checkpoint. It does not establish visual acceptance, road visibility closure,
full continuous chapter acceptance, multiplayer LAN/hardware acceptance, or Ally
frame time. It does not repair the stale rolling tag.

The reviewer launched no Godot process, reran no CI, changed no branch, pushed
nothing, and merged nothing. The orchestrator subsequently committed this receipt.
