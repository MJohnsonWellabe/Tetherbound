# CI control-listener reservation repair

PR85 head `856534a7`, CI `34236551038`, multiplayer shard5 job
`102097011145`: catch-race never reached gameplay assertions. At 14:17:28 UTC
the coordinator launched peer0 with TCP control port34021; listener creation for
peer1 on34022 then failed. The fatal summary was published after the normal
five-second cleanup. Other smokes in that shard continued on different bases.

The old default hashed each run ID into a fixed contiguous TCP range and bound
one listener immediately before launching each peer. A hash does not reserve a
port or establish that it is available. The selected range overlaps ordinary
Linux ephemeral TCP allocations. The original log does not include the OS bind
error or socket owner, so the exact occupying process/cause is not reconstructed.
In particular, peer0's control connection is not blamed: it connects only after
its world boot, and the failure occurred before that boot could complete.

`net_control_ports.gd` now calls TCPServer.listen(0, "127.0.0.1") to obtain and
retain real OS-assigned free listeners. The coordinator reserves every listener
before starting any child, passes each assigned port to its peer, and holds the
same sockets until teardown. There is no close/rebind gap or allocation retry.
An explicit TB_NET_CONTROL_BASE remains an exact request and fails closed if
unavailable. Partial reservations are released on failure; launch returns before
its process-creation loop. Teardown also releases listeners for unspawned peers.
ENet addressing, smoke retries, timing ceilings, and gameplay are unchanged.

Focused real-TCP validation (`test_net_control_ports.gd`): **3 tests,
52 assertions, 0 failed**, exit0. Two simultaneous groups reserve eight distinct
listening ports, a client connects to the assigned port, an occupied explicit
override fails without fallback, and all listeners stop on release.
Log: `.artifacts/net-control-port-unit.log` (unique engine log alongside it).

Loading the modified actual net harness through the catch observer regression:
**5 tests, 10 assertions, 0 failed**, exit0; log
`.artifacts/net-control-port-harness-parse.log`. Neither run emitted native or
script errors. No full-world smoke or rerun of the failed CI head was performed.

Root completed the full exact-head CI review: run34236551038 on
856534a7d564d97c4274c8ebe7993853ed41f2f1 finished at14:28:07UTC with
25 successful jobs, one failure (MP5 control bind), and three existing
conditional skips. All four unit shards passed:2921 tests/486218 assertions.
Every completed job's steps and log evidence were inspected. Passing jobs still
contain the previously disclosed engine cleanup/cache/material diagnostics;
the deliberate peer-death negative control is not a second failure. No new
push occurred before this terminal review. Full two-peer catch-race validation
of the changed allocator is queued behind the active campaign runtime.

Changed-allocator full two-peer validation completed once: exit 0, 47 assertions,
ALL CHECKS PASSED. The OS assigned reserved control ports 51862 and 51863;
both throws fired, exactly one was admitted, the host's admitted throw broke
out, and ownership stayed at zero. No ERROR or SCRIPT ERROR in coordinator,
engine or peer logs. Existing terrain mipmap/deprecation warnings, the client's
3246 m/s velocity clamp and refused too_far fly landings remain disclosed.
No Godot processes remained at terminal inspection. Evidence:
`.artifacts/catch-port-repair-20260908-coordinator.log`,
`.artifacts/catch-port-repair-20260908-engine.log`, and peer logs/NET_RUN.json
under `.artifacts/catch-port-repair-20260908/`. This validates changed code;
it is not a rerun of the unchanged failing CI head.

Exact-head CI for the changed allocator is now GREEN: commit
`8cd81b422e466a3918f471344750ee7edd15e883`, run `34242634338`, attempt 1,
completed 2026-09-08 15:30:29 UTC. All 26 required jobs passed; three existing
conditional jobs skipped. All seven multiplayer shards pass, including MP5's
actual catch race (47 assertions). The four unit shards total 2,963 tests and
486,540 assertions. Every job's steps and log evidence was inspected across
`.artifacts/wave1-ci-8cd81-initial.txt`, `-1514.txt`, `-1520.txt`, `-1526.txt`
and `-1532.txt`; raw ledger/logs are `.artifacts/ci-34242634338/`.
Existing cleanup/material/cache diagnostics and intentional peer-death failure
remain disclosed; green is not a claim of zero native diagnostic lines. No
rerun or cancellation was requested. This is PR CI, not a new main landing.

## 2026-09-08 16:00 UTC — subsequent exact-head verdict

Head `0a91f9b39aa552e554b849b4eb57d8011e2c7589` completed run
`34245691443`, attempt 1, at15:52:33 UTC:25 successful jobs, one failure,
three existing conditional skips. All four unit shards passed2977 tests and
486656 assertions. All seven multiplayer `Run net smokes` steps passed,
including catch race47 checks under the reserved-listener allocator.

The red job is multiplayer shard4, job102128348335, at upload-artifact
finalization, after all its smokes passed and9381576 bytes uploaded. The log
reports `Failed to FinalizeArtifact` and non-retryable intermediary HTTP403.
No artifact policy, retry, ignored error or acceptance change is proposed.
The run remains red, PR85 draft; no unchanged rerun was requested.

Every new terminal job/step/log was reviewed in
`.artifacts/wave1-ci-0a91-1554.txt`, complementing initial/1542/1547 reviews.
Raw logs are `.artifacts/ci-34245691443/`. Existing resource-at-exit/material
messages and multiplayer cached-node teardown messages remain present; MP3's
peer-death failure text is its deliberate negative control. Green individual
smoke steps are not a claim of a native-error-free full suite or green CI.

## Exact head 19d6ea8ec — complete CI pass

Run `34248963300` completed at16:23:38 UTC, attempt1, for exact head
`19d6ea8ecbc44ea479d5e49514359f6c116ba199`:26 successful jobs and three
existing conditional skips. All four unit shards passed2980 tests/486685
assertions; all seven multiplayer shards and their artifact uploads passed.
Every job/step/log evidence was reviewed in initial,1613,1617,1622 and1624
ledgers under `.artifacts/wave1-ci-19d6-*`; raw logs
`.artifacts/ci-34248963300/`. Existing native cleanup/material/cache messages
and deliberate negative-control errors remain disclosed. This is exact PR-head
CI proof, not a new main landing or a complete campaign run. No rerun requested.
