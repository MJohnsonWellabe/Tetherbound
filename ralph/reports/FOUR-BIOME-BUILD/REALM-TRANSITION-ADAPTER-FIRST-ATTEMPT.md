# Production adapter first native attempt — held before protocol checks

2026-09-09, Godot 4.7 `5b4e0cb0f`, current uncommitted Phase1 source. `Game.enter_realm` is still unconnected. This candidate is a failure; it establishes no transition acceptance.

`tools/run_realm_transition_adapter.ps1` launched isolated host/departing/staying profiles with a 20-second fixture deadline and 30-second external bound. It stopped all three owned processes on the first unexpected raw error after **6.977 seconds**. No retry was run. The runner was notified of root's additional resource-headroom requirement only after launch; that guard must be added before any later authorized candidate.

| Role | PID | Exit | Raw ERROR | SCRIPT ERROR | Protocol checks |
|---|---:|---:|---:|---:|---:|
| Host | 15852 | -1, stopped | 0 | 0 | 0 |
| Departing | 11016 | -1, stopped | 1 | 0 | 0 |
| Staying | 13160 | -1, stopped | 1 | 0 | 0 |

Both client errors are identical:

```text
ERROR: Condition "!peers.has(p_id)" is true. Returning: nullptr
   at: get_peer (modules/enet/enet_multiplayer_peer.cpp:461)
   GDScript backtrace (most recent call first):
       [0] _configure_transport_timeout (res://scripts/net/session.gd:692)
       [1] _on_peer_connected (res://scripts/net/session.gd:652)
```

Each client's ordinary Session callback receives the *other client's* logical `peer_connected` event. `_configure_transport_timeout` then asks its ENet transport for that ID as a physical connection. In client/server topology the client's physical remote endpoint is the server, peer 1. The guard checks null only after `get_peer()` has already emitted the native error. `git show HEAD:scripts/net/session.gd` confirms the same unguarded call predates this Phase1 diff. This source finding is distinct from the receive-map failure under repair.

Proposed bounded correction for root review: clients configure only their physical server connection; the host continues configuring every directly connected client. Do not suppress the native error or remove actual Session from the fixture.

All six complete raw files and process receipt remain under `.artifacts/realm-transition-adapter-20260909-v1/` (`host`, `departing`, `staying` `.stdout.log`/`.stderr.log`, `receipt.json`). The host had only its boot marker and two connection notices. Both clients had their boot marker, server and other-client connection notices, then the error above. No role reached the first production protocol assertion.

Preflight on this candidate: fixture parse passed; origin lifecycle tests passed **4 tests/19 assertions**, persistent reward tests **2/6**, and updated coordinator gate tests **5/22**. Those logs had no native or script errors. They do not replace the failed native candidate. Initial join/late scoped join ACK, reconnect, Game rollback, default Water, existing host travel and full CI remain outstanding.
