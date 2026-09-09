# Water to Stormwood return connection

## Outcome

The ordinary Water realm now mounts a real `RealmGate` on First Shore and routes
it to Stormwood's existing `stormwood_departure_to_water` entry anchor. The gate
has no key flag of its own. It is locked until the shared world fact
`realm_gate_water_unlocked` exists, then enters Stormwood without consuming,
restoring, or minting a second key. Stormwood now resolves that elevated anchor
at its authored height on the physical Stormheart core deck instead of replacing
its Y coordinate with terrain height.

This implements the return connection required by
`BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md` sections 1 and 21(1). It does not
change Stormwood's forward Waterward gate: that existing specialization still
atomically consumes `realm_key_water` and persists
`realm_gate_water_unlocked` once. The existing forward-gate regression remains
green.

## Implementation

`data/config/water_world.json` already authored a separate
`entry_anchors.return_to_stormwood` position at `(12, 1.881, 162)`. It now names
its existing peer anchor explicitly as `stormwood_departure_to_water`. That ID
already resolves through `stormwood_world.gd::entry_anchor()` to the authored
Stormwood transition point `(-100, 262.21, 5501)`.

Stormwood previously re-grounded every incoming anchor with
`ground_height_at(x, z) + 0.3`. That terrain-only derivation discards the
authored Water departure height even though the point lies on Stormheart's
generated `DynamoCore` collision ring. The shared
`resolve_entry_position()` derivation now recognizes the explicit
`arrival_height_policy: "authored"` data policy on that existing anchor. All
unmarked anchors keep the prior terrain-plus-0.3 placement, including the
Cloudreach entry. No destination coordinate, fallback maximum, BuiltFloor
query, or anchor-ID special case was added.

`water_world.gd::_ready()` mounts `StormwoodReturnRealmGate` after terrain and
surface setup. Its production configuration is:

| Field | Value |
|---|---|
| Component | existing `scripts/world/realm_gate.gd` |
| Origin realm | `water` |
| Destination realm | `stormwood` |
| Destination entry | `stormwood_departure_to_water` |
| Key flag | empty |
| Unlock flag | `realm_gate_water_unlocked` |

The empty key flag is how the generic gate expresses this existing contract.
Before the durable unlock, `state_for()` returns locked and `try_unlock()` has
no key path to execute. After the unlock, `try_enter()` calls the normal
two-argument `Game.enter_realm("stormwood", "stormwood_departure_to_water")`.
It does not use the Waterward gate's pre-authorized bypass and does not add a
router. The normal Game route retains realm entitlement, loading, save, realm
announcement, remote-trainer despawn, and destination-shell behavior.

RealmGate reads unlock state through `StoryLedger.world_flag`, which selects
`Game.world.flags` before the merged/personal progression view. A player-local
flag with the same ID therefore cannot open the gate, while a peer joining the
same world sees the already-open return.

No adapter was needed. No Game/autoload, forward gate, story, quest, asset,
terrain-scale, inventory, HP, or progression producer changed.

## Focused runtime evidence

The focused unit fixture invokes Water's production `_build_return_gate()` and
gets the mounted `StormwoodReturnRealmGate` child. This executes the real gate
constructor and configuration without launching the full Water world.

Command:

```powershell
$env:APPDATA='C:\Projects\Tetherbound\.artifacts\water-return-unit-profile-03'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_water_return_connection.gd
```

Result: **6 tests, 40 assertions, 0 failed**.

The passing assertions prove:

- Water mounts the generic production RealmGate at the authored First Shore
  return position;
- the destination is the existing Stormwood departure anchor;
- a personal lookalike unlock cannot substitute for world authority;
- even a present `realm_key_water` cannot unlock the return gate;
- the durable world unlock permits travel and produces no key or flag mutation;
- two peer views sharing one world see the same unlocked state, while travel is
  issued only through the activating peer's local Game route;
- the existing Stormwood destination resolves to the exact authored
  `(-100, 262.21, 5501)` position through its explicit height policy;
- the production Stormheart builder creates a concave `DynamoCore` collision
  triangle under that authored X/Z point, at its real heightfield-derived world
  base, and the authored arrival remains above that collision;
- the existing unmarked Cloudreach entry still resolves from the real
  Stormwood heightfield with its original terrain-plus-0.3 rule.

The established forward transaction was rerun separately:

```powershell
$env:APPDATA='C:\Projects\Tetherbound\.artifacts\water-return-forward-regression-profile-02'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_water_gate.gd
```

Result: **5 tests, 41 assertions, 0 failed**. This preserves the host-only,
proximity-checked, journaled one-time Water key consumption and the reusable
world unlock.

## Evidence boundary

The return connection and bounded Stormwood anchor-placement repair are
implemented. The mounted production component, authority states, destination,
non-mutation, peer-visible world state, resolved Stormheart arrival, actual
supporting collision, and preserved Cloudreach ground-entry behavior are
runtime proven in the focused native fixture. Source inspection verifies that
the unchanged Game router carries the normal realm announcement and shell
transition path.

No full Water or Stormwood scene was launched, no physical interaction prompt
was walked to, and no real two-process network crossing or earned campaign was
run under this lane. The real full-scene arrival and network crossing remain for
the later leased full-world evidence pass; this report does not treat fixture
flags as earned campaign progression.
