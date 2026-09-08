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
- Full unit suite is running with engine log
  `%TEMP%/wave0-full-units-20260908.log` and stdout companion
  `%TEMP%/wave0-full-units-20260908-stdout.log`; no terminal verdict yet.
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
