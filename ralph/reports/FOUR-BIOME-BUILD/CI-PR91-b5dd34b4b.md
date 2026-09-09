# PR 91 exact-head CI review

Date: 2026-09-08
Pull request: `91` (draft)
Head: `b5dd34b4b7cec5bafc76affdbf33af84192e84a5`
Base: `57660e4feb81fcbf8de5b0fe065e0ac107287676`
CI run: `34306689396` (`CI` run number 4594)
CI merge commit: `df4c9e5b7a4fd276a42c34bc799bc1f08ed7bb52`

## Terminal result

GitHub reports run `34306689396` terminal `completed/success`. The run has 29
jobs: 26 succeeded and 3 were skipped by workflow policy. Every executed step
is terminal success. The two explicitly known-red suites remained skipped, and
the PR export job was skipped. There was no failed or cancelled job and no job
retry.

| Job | Job ID | Result |
|---|---:|---|
| `changes` | 102324746738 | success |
| `verify-scatter-bake-freshness` | 102325100452 | success |
| `verify-terrain-bake-freshness` | 102325100488 | success |
| `verify-harvest` | 102325100505 | success |
| `verify-veg-corridor` | 102325100530 | success |
| `verify-scatter-rules` | 102325100533 | success |
| `verify-owner-regressions-shard` | 102325100593 | success |
| `verify-gate-a-ui-build-shard` | 102325100594 | success |
| `verify-unit-tests (1)` | 102325100603 | success |
| `verify-unit-tests (2)` | 102325100628 | success |
| `verify-unit-tests (3)` | 102325100667 | success |
| `verify-core-verb-shard` | 102325100672 | success |
| `verify-unit-tests (4)` | 102325100675 | success |
| `verify-gate-evidence-shard` | 102325100681 | success |
| `discover-net-smokes` | 102325100683 | success |
| `verify-gate-b-core` | 102325100760 | success |
| `verify-combat-shard` | 102325100794 | success |
| `verify-regions-shard` | 102325100839 | success |
| `verify-continuous-core-known-red` | 102325102042 | skipped by policy |
| `verify-gate-b-full-known-red` | 102325102089 | skipped by policy |
| `verify-multiplayer-shard (6)` | 102325449292 | success |
| `verify-multiplayer-shard (2)` | 102325449302 | success |
| `verify-multiplayer-shard (3)` | 102325449309 | success |
| `verify-multiplayer-shard (1)` | 102325449313 | success |
| `verify-multiplayer-shard (7)` | 102325449317 | success |
| `verify-multiplayer-shard (4)` | 102325449322 | success |
| `verify-multiplayer-shard (5)` | 102325449349 | success |
| `verify-solo-regression` | 102328137133 | success |
| `export` | 102328137990 | skipped for PR run |

The raw log for each of the 26 successful jobs was fetched and inspected, not
just its conclusion badge. Skipped jobs have no runnable log body. All 37
network artifact `NET_RUN.json` files, all 37 summaries, and all 74 peer logs
were also inspected from the seven retained shard artifacts. Every network
smoke ran as `attempt 1/1`; there was no retry. Thirty-six summaries ended
`ALL CHECKS PASSED`. `smoke_net_peer_death` deliberately kills peer 1 and
therefore retains an expected fatal `peer exited` NET_RUN; its surrounding
test asserted that negative control and its shard passed.

## Network discovery and Water assignment

`discover-net-smokes` raw log reports:

```text
found (37): ... tests/smoke_net_water_return.gd ...
```

The deterministic plan includes every discovered smoke exactly once.
`smoke_net_water_return.gd` had no prior completed CI measurement, so the
planner conservatively assigned the maximum 168-second cost and placed it in
multiplayer shard 3:

```text
warning: tests/smoke_net_water_return.gd has no completed measurement; reserving 168s
plan shard 3/7: measured=595s files=tests/smoke_net_water_return.gd ...
```

Shard 3 ran once and succeeded. Its raw group begins at
2026-09-09T03:27:10.9020373Z and the Water coordinator reached `ALL CHECKS
PASSED` at 03:28:04.7189963Z. Both full peers reported the exact CI merge SHA
`df4c9e5b7a4f`, used distinct isolated user-data directories, exited as
expected, and converged on durable-state hash `4169518313`.

## Strengthened Water completion proof

The CI checkout contains the final exact-budget code:

```gdscript
while waited_frames < REALM_STEP_BUDGET:
    # probe current/scene/world_ready/pending_entry
    var batch := mini(60, REALM_STEP_BUDGET - waited_frames)
    await step(1, "wait", {"frames": batch})
```

The realm probe supplies the read-only `world_ready` and `pending_entry`
fields. The smoke requires production Stormwood, completed world readiness and
an empty pending entry before it reads the player's position and grounded
state. CI executed that final predicate and printed:

```text
WATER RETURN NET COMPLETION: explicit_wait_frames=180 budget_frames=10000
PASS: ordinary gate interaction completes in the production Stormwood scene
PASS: completed client arrival is grounded at the authored Stormheart return anchor
PASS: host and other player remain in the production Water scene
PASS: host owns one ready Stormwood shell containing the departed client
PASS: client owns no simulation shells; shell authority remains on the host
PASS: peer 0 retains unchanged WORLD route facts with no personal copy
PASS: peer 1 retains unchanged WORLD route facts with no personal copy
ALL CHECKS PASSED
```

The Water artifact independently records the client heartbeat at
`(-100.0, 262.059295654297, 5501.0)`, the existing authored Stormheart return
point. The host log records its accepted landing claim at
`(-100.0, 262.0593, 5501.0)`. Both host shell and client full-world logs record
`STORMWOOD READY`, and neither Water-return peer log contains `ERROR`, `SCRIPT
ERROR`, or `FAIL`.

This proves the fixture-scoped connected-client movement/Interact route,
completed destination, grounded authored arrival, host Water residency,
registry and shell authority, and unchanged WORLD-versus-player route facts.
The prerequisites remain ledger-seeded fixture facts, so this is not earned
campaign evidence.

## Raw diagnostic review

No GitHub `##[error]`, failed assertion, unexpected nonzero exit, second
attempt, or new Water-return failure appears in the run. The raw logs do retain
diagnostics which a badge-only review would miss:

- Multiplayer shard 5 repeats the known shared transition packet teardown in
  `smoke_net_water_alpha.gd`: the departing
  `MeadowsPlayground/Spawned/Trainers/Trainer_*` node is absent while cache ID
  3 and RPC traffic arrive, followed by `Invalid packet received`; it also
  reports one invalid/non-authority synchronizer delta. The same node/cache/RPC
  family occurs in the existing Stormwood transition smokes, split-realms,
  reconnect, and realm-owner-disconnect fixtures. This remains an open shared
  transition issue. The successful Water-return sample does not establish it
  is fixed.
- Several unchanged full-scene smokes report `Parameter "material" is null`
  or a small number of resources still in use at exit. `join_by_address`
  records one busy-parent `remove_child()` diagnostic. These jobs still reached
  their explicit assertions and expected exits; this review does not convert
  those raw engine diagnostics into a claim of clean engine output.
- Unit shards deliberately exercise invalid JSON, unknown species, unscoped
  flags, fail-closed campaign prerequisites, and other negative paths, so their
  raw logs contain expected error/failure text while their test totals end with
  zero failed assertions. The harvest/unit fixtures also emit the established
  off-tree `get_node()`/null-tree diagnostics. No import parse/load failure was
  detected by the workflow's error gates.

The network artifact scan found 321 diagnostic lines across all 74 peer logs,
mostly repeated cache teardown and exit-resource messages. The Water-return
artifact contributes none of them. All seven network shard jobs and their
artifact uploads succeeded.

## Retained receipts

Ignored local receipts are under `.artifacts/ci-pr91-b5dd34b4/`:

- `net-smoke-runs-1.zip` through `net-smoke-runs-7.zip`
- expanded `net-smoke-runs-1/` through `net-smoke-runs-7/`

The Water evidence is in
`net-smoke-runs-3/net-water_return-20260909T032710Z/`. GitHub artifact 3 is ID
`10087214173`, size 7,620,890 bytes, digest
`sha256:aa37bbcf83b9c723c3f27a98f97d47e89ff1908d1683d8f751a4b7a98535d774`.

This review covers only PR 91 run `34306689396`. Main CI run `34305636072`
and release run `34305636213` were assigned to a separate reviewer and are not
duplicated here.
