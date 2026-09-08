# Main recovery — 2026-09-08

Owner interrupted the Wave 1 landing wait to prioritize a verified green main.
No campaign completion is claimed. Wave 1 has not started.

## Reproductions from CI, before repairs

Main `f6b79a6b32983d3b60f7333d8b44706736701474`, run `34180178882`:

- Multiplayer shard 3, job `101918182509`: shared-wild-fight diagnostic rejected
  4.61 m against its obsolete fixed 4.0 m bound. The existing Wave 0 change uses
  the Terrapup body radius and production `floor_reach_for_bodies`; it is retained.
- Multiplayer shard 7, job `101918182611`: `smoke_net_stormwood_hosted_trainers`
  failed final Tamsin completion after round 1, both peers' defeat flags, and
  completed-trainer replay refusal. This is a separate failure, not the reach
  assertion and not a shard timeout.

PR #80 preservation head `b16d117c639c2ab503a39b7e0a5e0e0eebe238fb`,
run `34221457038`, attempt 1, 11:35:02–11:54:33 UTC: 23 successful jobs,
three failed jobs, three intentional skips. Every job's steps inspected.

- Unit shard 1, job `102046210961`: 790 tests / 117250 assertions / one failure.
  Varga's anchor is 56.457642; unchanged terrain-grounding contract expects
  56.607642 ± 0.01. His relocation omitted the catalogue's 0.15 m clearance.
- Multiplayer shard 4, job `102046743296`: Tamsin final completion failure again.
  Sender action increment and pre-input geometry are insufficient to establish
  that the authoritative impact connected. Full peer artifacts retrieved for
  diagnosis under `%TEMP%/wave0-net4-34221457038/`.
- Multiplayer shard 5, job `102046743309`: catch race reports neither throw
  admitted. The log actually records the client resolving its granted throw
  and the host receiving `already_resolving`; the observer read the client's
  stale synchronous `pending` verdict.

Failed-smoke coordinator extracts:
`%TEMP%/wave0-tamsin-ci34221457038.log` and
`%TEMP%/wave0-catch-ci34221457038.log`. Raw payloads remain local.

## Repair and verification in progress

- Corrected Varga's data Y to terrain height plus the existing 0.15 m clearance;
  no assertion, tolerance, route position or acceptance condition changed.
  `tests/run_tests.gd -- --only=test_stormwood_trainers_data.gd` passes
  3 tests / 506 assertions / zero failures, exit 0; unique engine log
  `%TEMP%/wave0-varga-grounding-20260908.log`.
- Catch observation now reads the completed host-granted resolution when the
  synchronous submit verdict is pending. A breakout proves admission but does
  not count as a capture; conservation uses the actual completed decision.
  Added exactly one winner resolution and zero contradictory winner refusals.
  Regression before fix: 3 tests / 6 assertions / one failure. Observer plus
  arbitration suites after fix: 18 tests / 58 assertions / zero failures.
  Exact captured transcripts are `.artifacts/catch-ci-repair-negative.txt` and
  `.artifacts/catch-ci-repair-positive.txt`. First repaired two-peer runtime
  passes 47 assertions / zero failures / exit 0, host-first breakout. The
  client-first case is proved by the deterministic regression, not this run.
  Logs: `.artifacts/catch-ci-repair-20260908-coordinator.log`, corresponding
  `-engine.log`, and `catch-ci-repair-20260908/peer-{0,1}.log`. No native/script
  errors. Observed fixture/runtime warnings are not hidden: client velocity
  clamp at 3246 m/s, six host `fly too_far` refusals, missing terrain mipmaps,
  and deprecated interpolation. Both child processes exited; SUMMARY's stale
  `exited=false` snapshot is not relied upon for teardown proof.
- Diagnostic Tamsin run `%TEMP%/tamsin-impact-diag-console.log` completed, and
  the retained round-1 authoritative impact reports hit, killed, HP zero. This
  unchanged-path diagnostic success is NOT a repair verdict for CI's failure.
  The fixture placed centres 1.25 m apart despite combined body radii 2.60 m.
  Finishing staging now derives spacing from live radii and production enemy
  preferred range. Host impact diagnostics and a killing-hit assertion precede
  the unchanged completion, shared flags and replay checks. Focused staging
  checks pass 2 tests / 8 assertions and hosted lifecycle checks pass
  5 tests / 14 assertions. Revised two-peer runtime passes all 59 checks,
  exit 0. Round 0 action 704 and round 1 action 1 each report an authoritative
  hit, kill and zero HP at approximately 7.28/7.15 m, within the unchanged
  9 m range and 26-degree cone. Completion, both flags and replay checks pass.
  This establishes the repaired fixture's runtime behavior; original CI impact
  geometry was not captured, so its exact missed angle is not reconstructed.
  Its first new-source invocation failed at compile time before launching
  peers because the new `killed` local needed explicit `bool` typing. The
  source was corrected before the runtime invocation; this is a compile
  failure and repair, not an intermittent smoke failure re-run to get green.
  Unique logs: `%TEMP%/tamsin-sized-stage-typed-console.log`, corresponding
  `-engine.log`, and `tamsin-sized-stage-typed-20260908/peer-{0,1}.log`.
  No script errors in the executed repaired run. Native networking error set
  matches the diagnostic baseline: missing Meadows trainer node/cache ID 3,
  requested node absent in packet, non-authority delta/invalid synchronizer.
  Both peer processes were independently confirmed terminated.
  No retry, ceiling increase, shard skip or acceptance weakening was introduced.
- Full unit suite completed exit 1: 2993 tests / 3842642 assertions /
  three failed tests, identified below. It began before the follow-up Varga
  expectation correction and is not a final-head all-green verdict. Engine log
  `%TEMP%/wave0-full-units-20260908.log` and stdout companion
  `%TEMP%/wave0-full-units-20260908-stdout.log`.
- Required `tests/smoke_playground.gd` passes, exit 0 / `smoke: OK`.
  `%TEMP%/wave0-playground-20260908.log` and its stdout companion record the
  known `ERROR: Parameter "material" is null.` as the sole native error kind;
  no script errors. This matches the documented baseline, not clean output.

PR #80 remains draft. Its old green runs do not validate the current head.
Main's post-merge SHA and its own CI run remain unverified and will be recorded
before the four-biome goal resumes.

Independent astra review of the bounded repair diff found no actionable issues.
It inspected code and regression evidence only; it does not substitute for
the outstanding runtime and exact-head CI checks.

## Follow-up from exact-head CI

Submitted `d387d0bdd9fac44ec81087e31b0e18d963f27bf9` once; run `34225403192`
completed at 12:37:29 UTC (18m21s), attempt 1: 25 successful jobs, one failure,
three intentional skips. Every completed job log and every job's steps were
reviewed; all seven multiplayer shards and all runtime shards pass on their
first attempts. Unit shard 1 passes the repaired catalogue, but unit shard
4 fails `test_stormwood_varga_route` (575 tests / 279741 assertions / one failure).
That route test, introduced with relocation `efa2a92b`, expects raw terrain
height and contradicts the pre-existing catalogue's terrain + 0.15 m contract.
Root missed this second test in the initial focused verification.

The follow-up corrects its expected height to include the existing clearance.
Its stricter 0.001 m tolerance is unchanged; so are exact X/Z, route proximity,
prompt separation and 120 m travel checks. Both suites together pass 5 tests /
517 assertions / zero failures, exit 0, with clean native output in
`%TEMP%/wave0-varga-contracts-20260908.log`. Independent astra review confirmed
this resolves contradictory expectations without weakening acceptance.

The completed run's logs and job metadata are retained locally under
`.artifacts/ci-34225403192/`. Only unit shard 4 failed; no rerun or cancellation
was requested. The test expectation correction and this evidence form the
next coherent push, after that terminal review.

Local full-suite terminal failures are the
same Varga contradictory test (now corrected) plus two Gate F issues: S04/S05
recorder row thresholds versus retained report telemetry, and unavailable
Windows `bash` for the lane-declaration subprocess followed by a missing-file
parse error. These are recorded in `docs/SECOND_PASS_BACKLOG.md`, with no
assertion, telemetry or threshold changes. Existing CI sparse-report behavior
does not prove the full-checkout recorder check. The local suite is NOT green.

## Follow-up head d0f9a263e

Head `d0f9a263e283612df4d1a1bf2378f506c871d5a1`, CI `34227293723`, passes
all four unit shards (2918 tests / 486209 assertions) but multiplayer shard 5
job `102065696857` fails `smoke_net_shared_boss` on attempt 1/1. The friendly
strike is refused with `friendly_target`, and boss HP stays unchanged, but
peer 0 HP falls from 124.403 to 109.718. The quiet-window diagnostic reports
one `pick_struck` choice of peer 1 both before and after. Actual boss activity
and that observation boundary are under investigation; no intermittent-pass
rerun is accepted as proof. Raw job log: `.artifacts/ci-34227293723/102065696857.log`;
full peer artifact: `%TEMP%/wave0-net5-34227293723/`.

The run terminated at 12:57:37 UTC: 25 successful jobs, one failure, three
intentional skips. Every job log and step was reviewed. All other multiplayer
shards, all runtime shards and the solo aggregate pass. No rerun or cancellation
was requested. PR #80 remains draft and main remains red; the four-biome goal
has not resumed.

The shared-boss smoke sampled HP using separate encounter probes outside its
pre/post boss-hit-counter probes. This strictly wider HP interval can include
a legitimate boss hit that the counter interval excludes. The exact CI hit
frame cannot be reconstructed from retained logs; that timing explanation is
an inference, while the torn observation is directly present in the code.
The repair captures HP and a deep copy of the encounter record synchronously
in the real boss probe. It preserves exact HP acceptance, refusal checks,
existing attempt limits and gameplay. Three deterministic regressions / nine
assertions pass, including both former sampling gaps and unexplained HP loss
still failing the unchanged criterion (`.artifacts/boss-snapshot-unit.log`).
The single repaired shared-boss runtime invocation passes 85 checks / zero
failures, exit 0. The first friendly-fire window has host HP 125.050 -> 125.050,
boss HP 194.879 -> 194.879 and hit tally 1 -> 1, with `friendly_target` refusal.
Both child processes exited. Coordinator and engine logs use local prefix
`.artifacts/boss-atomic-repair-20260908`; peer logs are in its matching directory.
No script errors; both peers retain the pre-existing `player already has a
creature; adopt_starter is not a swap` error also present in the original CI
artifact, so native output is not clean. Independent astra review found no
actionable issues and confirmed unchanged HP/refusal/attempt criteria. This
is not yet exact-head green evidence; the next coherent push requires fresh CI.
