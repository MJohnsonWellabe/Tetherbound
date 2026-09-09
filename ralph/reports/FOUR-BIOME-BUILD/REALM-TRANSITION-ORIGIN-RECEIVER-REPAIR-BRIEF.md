# Minimal scoped-origin receiver admission proposal

2026-09-09. Read-only design following root direction. No production edits or Godot run. The latejoin proof brief identifies the concrete gap: an origin row currently permits every receiver absent its deny map, including a newly connected peer whose target world is absent.

## Intrinsic default denial

Add explicit receiver membership to each **scoped origin row**. `allowed` returns true for the host and immutable body owner; for another receiver it requires recorded membership plus no active deny. An unknown transport peer therefore fails the predicate from its very first automatic visibility evaluation, before hello or any RPC. Untagged bodies and nonexistent origin rows preserve existing baseline behavior. Existing peers present at origin creation keep their current realm-based admission; currently denied peers remain denied. Do not replace this with a peer_connected callback that races native spawn evaluation.

Use the existing immutable origin identity plus a unique host-created receiver generation (the existing join permit) for newly registered receivers. Registering a new receiver records membership and a deny; registration alone never grants admission. Disconnect removes membership as well as denial, restoring unknown-default-denied for any reused transport ID. Reset clears all scoped rows. A stale readiness permit cannot admit a later identity or replace its generation.

## Actual readiness without a snapshot deadlock

Keep the existing policy-applied ACK order: apply scoped policy, ACK, then host releases the ordinary world snapshot and peer_joined. Waiting for a finished world before releasing its required world snapshot could deadlock, so the first ACK must remain a policy application receipt.

Retain the same scoped join permit in a receiver-readiness phase. On the joiner, only after ordinary snapshot_ready is true and its actual realm passes the existing authored-spawner/readiness inventory check may it send a receiver-ready receipt. The host validates exact live peer/permit, realm and captured origin generations before clearing only matching denies for that realm. Other-realm origin bodies remain denied. Broadcast the updated origin policy and refresh affected actual recipients through existing mechanisms. This is only for a join with live scoped policy, not a new global initial-join handshake.

New scoped bodies created while a receiver is still awaiting this ready phase must inherit that receiver's pending deny even if its registry realm already matches. The receiver-ready handler may admit the current pending-generation cohort only after that actual realm is ready; older captured permits cannot clear a replacement generation. Keep pending state bounded by actual joining peers and clear it on disconnect/reset. Existing completed transition history continues its current lifecycle.

## Proposed exact files

- `scripts/net/realm_spawn_origins.gd`: membership/default denial, register pending generation, matching readiness and disconnect cleanup.
- `scripts/net/realm_transition.gd`: reuse scoped join permit through receiver-ready phase; local snapshot/actual-world readiness observation; pending-generation propagation when stamping new scoped cohorts; actual policy refresh. Existing Session hello/snapshot code should need no behavior edit.
- `tests/test_realm_spawn_origins.gd` and `tests/test_realm_transition.gd`: intrinsic unknown denial, existing host/owner/baseline preservation, pending same-realm denial, matching readiness, other-realm retention, new cohort during wait, stale receipt/disconnect/reuse/reset.
- Existing adapter peer fixture and runner plus evidence report, as in the latejoin brief: three peers, actual third-peer Session.join/policy/snapshot, absent Water receiver, real state/presentation exchange.

This proposal deliberately calls out the extra scoped receiver-ready phase for root review rather than hiding it in a predicate patch. An allow-list alone prevents unsafe spawning but would strand legitimate future same-realm receivers; a hello-based allow would reopen the original race. No native execution until the lifecycle is approved and an explicit lease is granted.
