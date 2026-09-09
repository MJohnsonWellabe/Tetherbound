# Scoped latejoin — read-only source audit and proposed proof

2026-09-09. No source implementation or Godot run. Existing evidence: normal Water initial join passed before the cancellation correction; component81 is pre-snapshotted; actual-Game cancellation77 proves its branch only. None proves a new peer connecting while controlled-transition-created bodies/history already exist.

## Existing path and concrete concern

Session.join closes snapshot_ready, creates real ENet, restores the isolated character and queues hello. Session._rpc_hello registers the sender and calls coordinator.prepare_joined_sender. With live transaction/history/origins, the coordinator sends a policy snapshot on reliable channel 0, waits for its actual applied ACK, and only then invokes Session._finish_peer_hello. That method sends the ordinary snapshot on its own channel, broadcasts registry and emits peer_joined. This explicitly protects policy application before newly created owner producers; send order across channels alone would not.

However, existing origins.create only denies receivers already present at cohort creation. origins.allowed returns true for a new receiver absent its deny map, and _send_joined_policy copies the unchanged rows. After a completed Meadows-to-Water departure, a fresh Meadows peer can be permitted to receive the still-live Water mover body even though its Water path is absent. Native automatic visibility starts at transport connection, earlier than hello/snapshot settlement. The policy-applied ACK does not itself protect this receiving side. This is a source-derived likely failure, not a native reproduction or permission to broaden initial-join policy. Root has been notified before implementation.

## Bounded fixture proposal

Extend the existing adapter fixture and runner with a dedicated latejoin mode, owning only `tools/probe_realm_transition_adapter_peer.gd`, `tools/run_realm_transition_adapter.ps1`, and this/new evidence report. Keep initial host+mover setup explicitly pre-snapshotted, perform a real controlled departure to create live Water origin bodies and receiver history, then connect a third process through **actual Session.join and the real hello/policy/snapshot handlers**. Existing initial-count assumptions need mode-specific counts; the original three-peer component/cancellation modes must remain unchanged.

The latejoin process starts a tiny authored Meadows receiver and no Water/dummy destination path. It must be a fresh isolated profile, with no prior owner bodies, state sends or scene RPC producers. Host Session processing must remain enabled for the real handshake. Observe actual policy application before snapshot_applied and actual host peer_joined; do not replace either with synthetic acknowledgements. The existing peer_joined hook may spawn the fixture's actual trainer/creature bodies only after the real host event, and the fixture's state producer must record whether snapshot_ready was true before its first send.

Record and assert:

1. A real completed departure exists before the third peer connects; live origin metadata and source history are nonempty, and the Water mover's actual state continues reaching the host.
2. Before the new peer's policy application, it has no owner producers. Its scoped policy contents are applied before ordinary snapshot application and before its first actual state/presentation/scene request. Host peer_joined follows policy ACK.
3. Native pre-existing Water bodies never produce a spawn/path lookup at the joiner's absent Water path; actual Meadows trainer/creature bodies arrive normally, including the new owner body. Raw errors take precedence over fixture assertions.
4. The new peer actually exchanges continuous state and reliable presentation with host, while the existing Water mover continues exchanging state with host. No unrelated receiver is globally stopped.
5. Joining-policy pending state clears after actual ACK, and unrelated baseline bodies retain their prior visibility. This scenario does not fabricate a populated registry or force snapshot_ready true on the new peer.

One candidate, three tiny peers, internal deadline at most 60 seconds and external at most 90 seconds; isolated profiles, exact engine descendants/run marker, system commit below 90%, global process count below 400, first unexpected raw ERROR/SCRIPT ERROR stops owned children, all logs/peaks retained. Root must review the identified receiving-side gap and choose observation versus a narrow approved repair before this candidate. No full world, CI rerun or production policy expansion is included.

Limits: a passed fixture would prove real scoped latejoin into this tiny realm arrangement. It would not establish a full-world reconnect, arbitrary old host occupied-world rebuild, campaign progression or broad multiplayer acceptance. A dedicated reconnect may follow only if evidence makes it necessary; it is not silently bundled into this candidate.
