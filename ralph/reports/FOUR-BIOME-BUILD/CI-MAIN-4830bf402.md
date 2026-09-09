# Main 4830bf402 CI review

Reviewed 2026-09-09 UTC. Verdict: **exact-main regression CI passed on first attempt**.
This receipt covers CI only. The orchestrator owns the separate Release run
34313176648 and rolling-tag identity receipt; this document grants no release-tag closure.

Source: `4830bf402a94d7d945119027a454d07dfee1dccc`, branch `main`.
[CI run 34313176597](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34313176597)
completed successfully, attempt **1**, from **05:00:46Z to 05:27:16Z**
(**26m30s**). The run API verified the exact SHA and terminal result.
The jobs API with `filter=all&per_page=100` returned **29 of 29** jobs,
all attempt 1: **27 success, 2 intentional skips**.
Every executed step succeeded; cached Godot install steps skipped legitimately.
Complete decoded raw logs were retrieved for all 27 executed jobs and inspected
for test outcomes, executed attempts, native errors, and export evidence.
No log was missing. No actual second attempt or retry rescue occurred.

The changes job compared against `8c0bfb31a1e719b7e7e61f4c91d989da1a5b3896`,
detected release workflow/helper/test changes, and ran all **7 Node helper tests**
with 7 pass, 0 fail, 0 cancelled. This was full code CI.
Unit total: **3,076 tests, 487,614 assertions, zero failed**.
Network total: **37/37 smokes, first attempt**, across all seven shards.

## Jobs and raw-log identities

Each ID identifies the complete decoded source at
`repos/MJohnsonWellabe/Tetherbound/actions/jobs/<job_id>/logs`.
All job steps were reviewed, including imports and artifact uploads.

| Job | Job ID | Evidence |
|---|---:|---|
| changes | 102343857525 | 7 Node helper tests passed; code changes detected |
| verify-harvest | 102344184221 | 30 tests, 799078 assertions, 0 failed |
| verify-veg-corridor | 102344184246 | 9 tests, 1537510 assertions, 0 failed |
| verify-scatter-rules | 102344184247 | 38 tests, 1019854 assertions, 0 failed |
| verify-terrain-bake-freshness | 102344184253 | 1 tests, 1 assertions, 0 failed |
| verify-scatter-bake-freshness | 102344184258 | 1 tests, 1 assertions, 0 failed |
| verify-unit-tests (4) | 102344184286 | 819 tests, 20406 assertions, 0 failed |
| verify-unit-tests (3) | 102344184290 | 645 tests, 26672 assertions, 0 failed |
| verify-gate-b-core | 102344184296 | Success; all executed steps succeeded |
| verify-unit-tests (2) | 102344184298 | 851 tests, 138547 assertions, 0 failed |
| verify-gate-a-ui-build-shard | 102344184303 | Success; all executed steps succeeded |
| verify-unit-tests (1) | 102344184309 | 761 tests, 301989 assertions, 0 failed |
| verify-regions-shard | 102344184315 | Success; all executed steps succeeded |
| discover-net-smokes | 102344184341 | Success; all executed steps succeeded |
| verify-core-verb-shard | 102344184358 | Success; all executed steps succeeded |
| verify-gate-evidence-shard | 102344184365 | Success; all executed steps succeeded |
| verify-owner-regressions-shard | 102344184402 | Success; all executed steps succeeded |
| verify-combat-shard | 102344184441 | Success; all executed steps succeeded |
| verify-gate-b-full-known-red | 102344185000 | Manual-only known-red; not executed |
| verify-continuous-core-known-red | 102344185199 | Manual-only known-red; not executed |
| verify-multiplayer-shard (1) | 102344544113 | 6 network smokes, first attempt |
| verify-multiplayer-shard (3) | 102344544120 | 6 network smokes, first attempt |
| verify-multiplayer-shard (4) | 102344544148 | 6 network smokes, first attempt |
| verify-multiplayer-shard (5) | 102344544158 | 6 network smokes, first attempt |
| verify-multiplayer-shard (6) | 102344544171 | 6 network smokes, first attempt |
| verify-multiplayer-shard (7) | 102344544173 | 1 network smokes, first attempt |
| verify-multiplayer-shard (2) | 102344544261 | 6 network smokes, first attempt |
| export | 102347592990 | Windows debug PE check, Linux runtime ground check, upload passed |
| verify-solo-regression | 102347593052 | Success; all executed steps succeeded |

The solo-regression job is a dependency fence, not an additional test.
Gate B CORE ends at tournament readiness. The two full-chain known-red jobs
were not executed and receive no acceptance credit.

## Native-error comparison

All 27 matching baseline raw logs from main CI **34310983183** were fetched
again for a job-by-job comparison, alongside
[CI-MAIN-8c0bfb31a.md](CI-MAIN-8c0bfb31a.md).
The distinct `ERROR:` sets match the baseline in every executed job after
normalizing dynamic peer/process/cache IDs, resource/RID leak counts, and
known-species/conversation lists. No new native-error class and no actual
`SCRIPT ERROR:` occurred. Shell commands mentioning error patterns were
excluded from engine-output classifications.

Retained findings include off-tree `get_node` and null `data.tree`; intentional
invalid JSON/species/conversation and unscoped-flag unit fixtures; the unit
party-seam fallback error; off-tree transform access; dummy renderer/resource
exit leaks; world material-null errors; and the combat duplicate
`adopt_starter` error. Regions retains `smoke_relay_gate`.

Multiplayer shard 2's killed-process error, coordinator failure and FATAL
line belong to the intentional `smoke_net_peer_death` negative control.
Its explicit final PASS verifies expected coordinator exit 2 after killing
peer 1; it is not a rescued failed smoke. Shard 5 retains the known disconnect
race's missing trainer/Sync node, cached-node lookup, invalid packet, and
invalid synchronizer errors. These have the same normalized set as baseline.
Green CI does not erase these existing runtime findings.

## Export and artifact scope

Export job **102347592990** checked out the exact main SHA, imported the project,
exported Windows **debug**, verified PE32+ executable (GUI), x86-64, and passed
the size check. It then reported:

```text
EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004
export: OK — extension loaded, data present, ground found.
```

The exact-source `tools/verify_export.sh` exports and executes **Linux Test**
`build/linux/Tetherbound.x86_64`. Thus this proves Windows binary production
and Linux exported runtime boot/ground, not execution of the Windows binary,
Ally stability, or frame time. The runtime script redirects its complete log
to `build/linux/run.log`; that redirected file was not downloaded independently.
The complete CI export job raw log contains no actual native or script errors.

The upload log and artifact API agree:
**Tetherbound-windows-debug**, artifact **10089703929**, **686,774,970 bytes**,
created **05:27:10Z**, source SHA identical to the reviewed main commit.
Digest: `sha256:61b9e827d7410cfc8a928157922cf5333567a5446d586ea22ac8ce62cc13d512`.
Seven network artifact uploads also succeeded (shards 1–7), and the artifact
API returned all eight CI artifacts associated with the same exact SHA.
Archives were not downloaded or independently hashed.

## Limits and review conduct

This is regression and CI export evidence only. It does not establish the
continuous four-biome player path, road visibility, visual acceptance,
LAN/hardware multiplayer, Windows shipped runtime, or Ally performance.
Release publication and live `latest` tag identity remain the separate
orchestrator review.

This reviewer reran no workflow, launched no Godot process, changed no branch,
pushed nothing, and merged nothing. Only this receipt was written, uncommitted.

