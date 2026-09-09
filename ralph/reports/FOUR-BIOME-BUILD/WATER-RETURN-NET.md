# Water return two-peer runtime evidence

Date: 2026-09-08
Branch: `codex/four-biome-audit-resume-0908`
Production connection commit: `d769a93c5`

## Evidence boundary

This is a focused two-peer fixture for the ordinary Water-to-Stormwood return
connection. It is not earned campaign evidence, does not close the Water
campaign or four-biome audit, and does not establish clean shared-transition
packet teardown.

No earned save carrying the durable Water unlock was available. Both peers
start in production Water with all three inspected route facts absent from
WORLD and player scopes. The host then submits exactly two fixture
prerequisites through the existing production ledger:

- WORLD `realm_key_stormwood = true`
- WORLD `realm_gate_water_unlocked = true`

The fixture never submits `realm_key_water` or a player-scope copy. It does not
write HP, items, party state, chapter completion, or any other progress. Each
full client uses a separate retained user-data directory inside its run
artifact directory.

## Fixture contract

`tests/smoke_net_water_return.gd` extends the existing network harness and
launches two equivalent full clients in the production Water scene. It forms a
real host/client Session, proves both prerequisite flags replicated from WORLD
authority, walks the connected client to the mounted return gate with the
ordinary `move_to` control, and sends the ordinary `interact` action. It never
calls the realm router or the gate's `try_enter` method directly.

Destination completion is asynchronous. The final test polls the existing
read-only realm probe inside the unchanged 10,000-frame Stormwood transition
budget until all four facts hold:

- `current_realm == "stormwood"`
- current scene name is `Stormwood`
- the production world reports `shell_build_complete()`
- `pending_realm_entry` is empty

The final polling loop caps every wait batch at the exact remaining budget, so
it cannot request the former nominal 20-frame overrun caused by rounding
10,000/60 upward. This arithmetic correction was made after run 02; it was not
rerun because run 02 completed far inside the budget and the correction does
not change the observed completion predicate.

After completion the test reads the destination from
`stormwood_world.json::transition_points.water_departure`, requires the
existing ID `stormwood_departure_to_water`, and asserts the connected client's
position against that authored point plus `on_floor == true`. It then verifies
that the host remains in production Water, both peers retain an active
two-member Session and the same Water/Stormwood registry, the host owns the one
ready Stormwood simulation shell, the client owns no shells, and all inspected
WORLD/player route values remain byte-equivalent to their pre-travel values.

The only shared harness expansion is two read-only fields in the existing
`tools/net/peer_runner.gd` realm probe: `world_ready` and `pending_entry`. No
production runtime code changed for this proof.

## Run 01: scoped route evidence, incomplete completion assertion

Artifacts are retained at `.artifacts/water-return-net-run-01/`. The wrapper
logs span 2026-09-09 03:00:30.618Z through 03:01:52.226Z
(2026-09-08 22:00:30.618-05:00 through 22:01:52.226-05:00). The embedded
`water-return-net-20260909T0304Z` string is a run identity only, not the
wall-clock timestamp.

The coordinator exited 0 with 33 checks and `ALL CHECKS PASSED`, but this
revision waited a fixed 240 frames and asserted only the published realm and
scene names. Those names can change before the destination's sliced `_ready`
work finishes. Its last client heartbeat was correspondingly stale at
`physics_frame=540`, position `(0, 60, 0)`. Run 01 therefore proves the physical
movement/Interact request, registry and shell routing, continuing Session, and
unchanged authority facts. It does not prove cleared pending entry, completed
Stormwood readiness, or the authored deck arrival.

The host log supplies supporting, non-asserted evidence after the shell became
ready:

```text
STORMWOOD READY realm=stormwood shell=true terrain_regions=108
[fly] peer 1134173533 claimed a landing at (-100.0, 262.0593, 5501.0) -- granted (ok)
```

Run 01 also contains this exact engine error set in `peer-0.log` lines 52-60:

```text
ERROR: Node not found: "WaterArchipelago/Spawned/Trainers/Trainer_1134173533/Sync" (relative to "/root").
ERROR: Failed to get cached node from peer 1134173533 with cache ID 2.
ERROR: Node not found: "WaterArchipelago/Spawned/Trainers/Trainer_1134173533" (relative to "/root").
ERROR: Failed to get cached node from peer 1134173533 with cache ID 3.
ERROR: Invalid packet received. Requested node was not found.
```

The engine source references in that log are
`scene/main/node.cpp:1975`,
`modules/multiplayer/scene_cache_interface.cpp:293`, and
`modules/multiplayer/scene_rpc_interface.cpp:211`.

The named mechanism is shared realm-transition packet teardown.
`autoload/game_state.gd::enter_realm` announces the new realm before the local
scene swap. `scripts/net/session.gd::_apply_realm_change` updates the registry
and emits `peer_realm_changed`; `scripts/net/trainer_spawn.gd` reconciles that
event and queues the departing Water trainer proxy for deletion while cached
RPC/synchronizer traffic from the old proxy can still be in flight. Root found
the same Trainer node/cache-ID/invalid-packet class during the existing
Meadows-to-Water transition in prior CI run `34296093682`, shard 2, lines 3965
and following, and current CI run `34303950964`, shard 2, lines 3977 and
following. This is a pre-existing systemic issue newly exposed by the local
fixture, not a Water-return regression. It remains open.

Run 01 resource guard: 35 samples, three owned Godot processes at peak,
2,757,259,264 peak aggregate private bytes, 1,674,579,968 peak aggregate
working-set bytes, 61.07% peak system commit, and 259 peak total processes.
Neither stop threshold was reached.

## Run 02: completed arrival and authority evidence

Run 02 used the corrected completion predicate and the authored position/floor
assertion. Artifacts are retained at
`.artifacts/water-return-net-run-02/`. The wrapper logs span 2026-09-09
03:07:53.335Z through 03:09:11.493Z
(2026-09-08 22:07:53.335-05:00 through 22:09:11.493-05:00). The embedded
`water-return-net-20260909T0318Z` string is again only a run identity.

The coordinator exited 0 with 33 checks and `ALL CHECKS PASSED`. In particular:

```text
PASS: connected client reaches the real Water return gate through ordinary movement (arrived within 0.90 m of (9.8, 162.7))
PASS: connected client sends ordinary Interact at the physical gate (pressed 'interact' x1)
PASS: ordinary gate interaction completes in the production Stormwood scene
PASS: completed client arrival is grounded at the authored Stormheart return anchor
PASS: host and other player remain in the production Water scene
PASS: host owns one ready Stormwood shell containing the departed client
PASS: client owns no simulation shells; shell authority remains on the host
```

The host log records the ready shell and the actual landing at the authored
point:

```text
STORMWOOD READY realm=stormwood shell=true terrain_regions=108
[fly] peer 1965987940 claimed a landing at (-100.0, 262.0593, 5501.0) -- granted (ok)
```

The client log separately records
`STORMWOOD READY realm=stormwood shell=false terrain_regions=108`. The executed
probe assertions then read ready state, empty pending entry, the player's
authored position, and grounded state directly. The final client heartbeat
still predates completion because heartbeats publish only every 60 physics
frames; its last observed value was physics frame 420 at position `(0, 60, 0)`,
and it is not used as arrival evidence. The crossing-only wait count was not
printed by the executed revision, so no exact crossing duration is claimed.

Both peers reported expected exits and matching final durable-state hashes
`4169518313`. Route checks proved both named WORLD prerequisites unchanged,
`realm_key_water` still absent, and all three personal copies absent on both
peers. Distinct scans of coordinator stdout/stderr and both peer logs found no
`ERROR`, `SCRIPT ERROR`, or failed assertion in this sample. The absence of the
run-01 packet errors in this one sample does not establish that the systemic
packet teardown issue is fixed.

Run 02 resource guard: 34 samples, three owned Godot processes at peak,
2,583,470,080 peak aggregate private bytes, 1,861,226,496 peak aggregate
working-set bytes, 61.14% peak system commit, and 260 peak total processes.
Neither stop threshold was reached.

The asynchronous peers reported different Git identities because documentation
commits landed while the two full clients were booting: host `1183e0c9e0d5`,
client `9e9f56ecfd1e`. A direct diff contains only
`docs/CURRENT_STATE.md` and `docs/DEVELOPMENT_ROADMAP.md` (8 insertions, 6
deletions), so their production/code trees for this fixture were equivalent.
The later merge commit `6c46c23c9cc6c019ecd2565470f5e596c74e8bf5` has zero
tree diff from the client identity.

No viewport capture was requested under headless networking.

## Verdict

| Claim | Result | Boundary |
|---|---|---|
| Connected client used ordinary movement and Interact at the mounted Water gate | Proven | Runs 01 and 02 |
| Asynchronous destination finished with ready world and empty pending entry | Proven | Executed run-02 realm probe |
| Client reached the existing authored Stormheart point and was grounded | Proven | Executed run-02 position and `on_floor` probes |
| Host and other player remained in Water while registry and shell authority tracked both realms | Proven | Run 02 |
| WORLD route facts stayed unchanged and no player copy or second Water key appeared | Proven | Run 02 fixture boundary |
| Shared realm-transition packet teardown is clean | Not proven | Known pre-existing packet issue remains open |
| Earned Water or four-biome campaign completion | Not proven | Prerequisites were explicitly ledger-seeded |
