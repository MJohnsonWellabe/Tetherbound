# Network departure synchronizer diagnostic — NET-DEPARTURE-SYNC-DIAGNOSTIC01

## Evidence

The split-realm smoke `cloud-live-cover-net-second` ran from **09:11:29 to
09:15:07 UTC**. Its checks passed. The preserved host log is:

`.artifacts/broad-visual-0910/runs/cloud-live-cover-net-second/profile/Godot/app_userdata/Tetherbound/net-runs/net-run-local-1658739/peer-0.log`

The peer-1 log was clean. Peer 0 contains **304** matching engine errors,
consisting of repeated pairs of:

```text
Node not found: "MeadowsPlayground/Spawned/Trainers/Trainer_573344690/Sync" (relative to "/root").
Failed to get cached node from peer 573344690 with cache ID 8.
```

The first occurrence is at log line 364, during
`CloudreachCliffs` `live_crossing` (line 323 begins that phase). The old
Meadows trainer is later rebuilt successfully after Meadows is loaded again
(the new build is logged at line 1172). This is a transient departure error,
not evidence that the destination trainer failed to spawn.

## Source path and ordering hypothesis

Relevant source paths:

- `scripts/net/session.gd:400` — `_apply_realm_change()` updates the registry,
  emits `peer_realm_changed`, broadcasts the registry, then reconciles shells.
- `scripts/net/trainer_spawn.gd:205` — each realm's
  `_on_peer_realm_changed()` immediately calls `_reconcile()`.
- `scripts/net/trainer_spawn.gd:258` — `_despawn_for()` erases the host body
  and calls `queue_free()`; the MultiplayerSpawner then replicates the
  despawn.
- `scripts/net/realm_transition.gd:396-428` — the existing transition enters
  `draining`, waits for the mover's old-realm scope inventory to drain, then
  applies the registry change.
- `scripts/net/realm_replication_scope.gd:109-123` — actual spawner
  `spawned`/`despawned` receipts maintain the inventory used by that drain.

Observed local ordering shows that the Meadows body is freed on the
`peer_realm_changed` callback while the crossing is still in the Cloudreach
build. The likely cause is that host-side trainer reconciliation is ahead of
the final old-body synchronizer/cache settlement, leaving late traffic
referencing cache ID 8 after the `Sync` node has been freed. **Network packet
causality is not proven by this log alone**: the log proves the missing path,
the free/reconcile code path, and the later successful respawn, but does not
provide packet-level ordering.

## Safe follow-up

Do not suppress these errors, disable replication, or add an arbitrary frame
delay. A focused follow-up should make trainer reconciliation honor the
existing transition drain/commit boundary (or add an explicit host departure
hook at that boundary), then free the old body and create the destination body
through the existing MultiplayerSpawner lifecycle. The split-realm smoke
should gain a zero-stale-cached-node assertion. Implementation is deferred
pending focused protocol evidence; no production source was changed for this
diagnostic.
