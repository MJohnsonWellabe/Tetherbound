# PR92 exact-head CI review

Reviewed 2026-09-09 UTC. Verdict: acceptable for landing the bounded evidence and
capture-helper checkpoint. This is not a visual or continuous chapter acceptance.

## Run identity and completeness

- Repository: `MJohnsonWellabe/Tetherbound`; PR: **92**.
- Head: `8ff6939fcee87c840c96717241b1ec94539096a3` on
  `codex/four-biome-audit-evidence-0909`.
- Base: `49da91d51953fb4b650f29b1399ae41218f68f86`.
- [CI run 34309659360](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34309659360),
  run number 4596, `pull_request`, attempt **1**, terminal **success**.
- Started `2026-09-09T04:06:14Z`; finished `2026-09-09T04:24:21Z`: **18m07s**.
- REST `actions/runs/34309659360/jobs?filter=all&per_page=100` returned all
  **29/29 jobs**, all attempt 1: **26 success, 3 skipped**. No pagination gap.
- Every executed step succeeded. Cached Godot installation steps legitimately
  skipped. All 26 successful jobs' complete decoded raw logs were fetched through
  `github_fetch_workflow_job_logs` and inspected, including setup/import, test
  execution, native errors, retry groups, and completion. No missing raw log.
- No actual failed first attempt, retry rescue, or `SCRIPT ERROR` found.
- The changes job detected `tools/capture_road_heading_probe.gd` against the named
  base, so this was a real code run, not documentation-only gating.

Each job ID below identifies its raw-log source at GitHub REST
`repos/MJohnsonWellabe/Tetherbound/actions/jobs/<job_id>/logs`, and its visible
job page under the run URL followed by `/job/<job_id>`.

## Job matrix

| Job | Job ID | Result and evidence |
|---|---:|---|
| changes | 102333503687 | Success; capture-helper code detected against the named base |
| verify-harvest | 102333955054 | 30 tests / 799,078 assertions / 0 failed |
| verify-scatter-bake-freshness | 102333955098 | 1 test / 1 assertion / 0 failed |
| verify-scatter-rules | 102333955145 | 38 tests / 1,019,854 assertions / 0 failed |
| verify-regions-shard | 102333955151 | Every region, interaction, road observation, Stormwood, Water, and art step succeeded |
| verify-core-verb-shard | 102333955169 | All eight smokes first attempt, including traversal, catching, and audio |
| verify-terrain-bake-freshness | 102333955172 | 1 test / 1 assertion / 0 failed |
| verify-veg-corridor | 102333955203 | 9 tests / 1,537,510 assertions / 0 failed |
| verify-gate-a-ui-build-shard | 102333955204 | All ten smokes first attempt |
| verify-unit-tests (1) | 102333955230 | 761 tests / 301,989 assertions / 0 failed |
| verify-unit-tests (2) | 102333955252 | 851 tests / 138,547 assertions / 0 failed |
| verify-unit-tests (4) | 102333955264 | 819 tests / 20,406 assertions / 0 failed |
| verify-combat-shard | 102333955265 | All steps succeeded; retry-enabled smokes first attempt |
| verify-gate-evidence-shard | 102333955278 | All ten smokes first attempt, including two beds and finale |
| verify-unit-tests (3) | 102333955281 | 645 tests / 26,672 assertions / 0 failed |
| verify-owner-regressions-shard | 102333955291 | All eight smokes first attempt |
| discover-net-smokes | 102333955296 | Discovered 37 two-peer smokes |
| verify-gate-b-core | 102333955325 | First attempt; explicit CORE stopping boundary |
| verify-multiplayer-shard (2) | 102334313595 | Six first attempts; deliberate peer-death negative control passed |
| verify-multiplayer-shard (3) | 102334313625 | Six first attempts |
| verify-multiplayer-shard (1) | 102334313635 | Six first attempts |
| verify-multiplayer-shard (7) | 102334313658 | Split-realms first attempt |
| verify-multiplayer-shard (4) | 102334313661 | Six first attempts |
| verify-multiplayer-shard (5) | 102334313683 | Six first attempts |
| verify-multiplayer-shard (6) | 102334313690 | Six first attempts |
| verify-solo-regression | 102336980327 | Success; dependency fence, not another test execution |
| verify-gate-b-full-known-red | 102333956439 | Skipped: manual-dispatch-only |
| verify-continuous-core-known-red | 102333956530 | Skipped: manual-dispatch-only |
| export | 102336981615 | Skipped on PR |

Unit total: **3,076 tests, 487,614 assertions, zero failed**. Network total:
**37/37 first-attempt executions**. The smoke jobs' configured retry budgets did
not result in any second attempt.

## Native errors and base comparison

The comparison source is actual base-main
[CI run 34308309450](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34308309450)
on `49da91d51953fb4b650f29b1399ae41218f68f86`, not a prior agent summary.
Complete decoded baseline raw logs were fetched for these jobs:

| Base job | Job ID |
|---|---:|
| verify-harvest | 102329819585 |
| verify-unit-tests (1) | 102329819641 |
| verify-unit-tests (2) | 102329819667 |
| verify-unit-tests (3) | 102329819726 |
| verify-unit-tests (4) | 102329819715 |
| verify-combat-shard | 102329819684 |
| verify-gate-a-ui-build-shard | 102329819728 |
| verify-regions-shard | 102329819670 |
| verify-core-verb-shard | 102329819752 |
| verify-gate-evidence-shard | 102329819740 |
| verify-multiplayer-shard (5) | 102330172666 |

Harvest, unit shards, combat, UI/build, region, core-verb, and gate-evidence
distinct error sets matched those baseline sets or a subset after normalizing
variable exit-leak counts. Findings retained rather than hidden behind green:

- `Parameter "material" is null` and exit resource/RID leaks remain present in
  some successful jobs. Material-null is pre-existing despite older status prose
  describing a particular earlier instance as fixed.
- Off-tree `get_node`, null `data.tree`, invalid JSON, unknown fixture species or
  conversation, unscoped flags, and dummy-renderer allocation errors in the unit
  and regression jobs match base error sets. Negative-input test context was
  inspected; these are not new PR92 errors.
- Combat reports `the player already has a creature; adopt_starter is not a swap`
  through `SequenceDirector._hand_a_late_arrival_a_companion`; the identical
  existing base error is not evidence of a clean runtime log.
- Regions reports `unscoped flag: smoke_relay_gate`, also present on base.
- Multiplayer shard 5 reports missing cached trainer/Sync nodes, invalid packets,
  and non-authority/invalid synchronizer deltas around disconnect. Its normalized
  distinct error set exactly matches base job **102330172666**, substituting
  dynamic peer IDs and exit resource counts only.
- Multiplayer shard 2 deliberately kills peer 1 in `smoke_net_peer_death`.
  The resulting process-not-found errors, coordinator `FAIL`, and exit 2 are the
  negative control's expected result. Its explicit final `PASS: negative control`
  confirms that a killed peer correctly fails the coordinator; this is not a
  failed smoke hidden by a retry.

No newly introduced native-error class was identified in the reviewed run.

## Artifact inventory and limits

Seven nonexpired network artifacts were present at terminal review:

| Artifact | ID | Bytes |
|---|---:|---:|
| net-smoke-runs-1 | 10088243796 | 9,390,503 |
| net-smoke-runs-2 | 10088169899 | 9,373,773 |
| net-smoke-runs-3 | 10088199013 | 7,620,531 |
| net-smoke-runs-4 | 10088220447 | 11,120,036 |
| net-smoke-runs-5 | 10088280249 | 11,143,652 |
| net-smoke-runs-6 | 10088274659 | 11,126,190 |
| net-smoke-runs-7 | 10088079862 | 1,877,790 |

Artifact metadata was inventoried; archives were not downloaded or inspected.
CI raw job logs were inspected directly and remain the source for this verdict.

This run supports checkpoint integration. It does not establish visual acceptance,
road-population completion, full continuous chapter acceptance, Ally performance,
or a newly published Windows build. The two known-red full-chain jobs and export
did not execute. Green regression checks do not erase retained native-error
findings or replace the separate blind visual and continuous-player-path gates.

The CI reviewer did not launch Godot, rerun CI, mutate branches, push, or merge.
This receipt was written after the exact-head review and is not part of the
reviewed PR92 commit.
