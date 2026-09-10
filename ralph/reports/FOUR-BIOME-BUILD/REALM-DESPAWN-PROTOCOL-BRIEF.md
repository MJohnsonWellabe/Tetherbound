# Next bounded proof: realm replication departure and admission

2026-09-09. Design only; no production edits. The simple native negative/control in [REALM-DESPAWN-NATIVE-PROOF.md](REALM-DESPAWN-NATIVE-PROOF.md) proves the received-node map failure, but has no synchronizer and does not yet prove a complete transition protocol.

## Transport facts at the installed engine revision

Read `modules/multiplayer/scene_replication_interface.cpp` at installed revision `5b4e0cb0f`. `_send_raw` always selects channel 0. Spawn/despawn and on-change deltas are **reliable**; continuous sync uses **unreliable**. `on_sync_receive` skips an unknown synchronizer without an error; a found synchronizer with missing root/wrong authority reports an error. `on_delta_receive` and `on_despawn_receive` have the stricter errors observed in CI.

A reliable Session ledger-channel acknowledgment does not establish ordering of channel-0 traffic. A same-sender reliable channel-0 fence can follow that sender's already-enqueued reliable deltas, but says nothing about another sender or unreliable sync delivery. No design below assumes otherwise.

## Owned proof files and limits

Proposed ownership: new `tools/probe_realm_despawn_protocol.gd`, `tools/probe_realm_despawn_protocol_peer.gd`, and `ralph/reports/FOUR-BIOME-BUILD/REALM-DESPAWN-PROTOCOL-PROOF.md`. Preserve the simple negative/control unchanged. Raw artifacts and isolated role profiles under a fresh ignored `.artifacts` directory. No production files, engine patch, error filtering, branch change, commit, or CI rerun.

Use three tiny native ENet processes: host H, departing client D, continuing client S. Each holds persistent RPC/scene paths and a minimal old-realm spawner/parent. Host authors three bodies; each body's authority belongs to its represented peer, with an actual MultiplayerSynchronizer carrying one continuous and one on-change property. At least H and S continually change their own values while D departs. This is needed to prove sender-specific barriers and that S continues receiving updates instead of globally freezing the old realm.

No full worlds/assets. Internal deadline <=20 seconds, wrapper <=30 seconds per case, one execution per materially distinct case. A timeout is failure/retained evidence, never permission to shorten the asserted lifecycle. Keep the expected raw native-error set empty in the candidate protocol and retain the simple negative's exact known set as the independent reproduction.

## Protocol the next proof must exercise

1. D connects its spawner spawned/despawned observers before departure and inventories actual received old-realm bodies. Stable transition tokens and body identities tie all messages to this request. Host validates sender identity and the starting realm; a client cannot withdraw another peer.
2. Host marks D as *pending departure*, while committed realm identity and the receiving scene remain unchanged. This prevents new old-realm admission to D and destination admission before ready. Pin old host spawners until drain completes.
3. Every authority currently sending reliable old-realm deltas to D stops sending to D through an explicit outbound-recipient gate. Other viewers remain enabled. D stops its own retiring body's outbound replication to every affected observer. Merely stopping `_physics_process` is insufficient: the synchronizer may still have a changed property to publish.
4. Each affected authority sends its own reliable channel-0 fence after applying that outbound gate. Each intended receiver acknowledges receipt to host with token/sender identity. Host waits for the necessary per-sender acknowledgments; a single host ledger acknowledgment cannot replace these fences. The exact visibility API behavior must be observed: non-host owner gates must not independently destroy other viewers' bodies, and the host's own gate must not create a premature untracked removal.
5. Host withdraws D's visibility from every old-realm body it can see, while preserving visibility to S. Host also retires D's authoritative old-realm body for its former viewers. These must be **actual engine visibility/despawn operations**, not local receiver frees. Host sends a same-channel-0 fence after those operations have enqueued their despawns; the proof must establish that enqueue boundary from behavior, not guess one frame is sufficient.
6. D's completion condition combines actual spawner `despawned` observations, an empty received-body inventory, and the host fence. An empty snapshot before a possible late spawn is insufficient. Only then may D remove its old realm subtree. Its surviving peers continue receiving changing H/S properties throughout the crossing.
7. D builds a minimal destination receiving parent and spawner while admission remains blocked. Only an authenticated destination-ready token enables host destination visibility/replication. Prove zero destination bodies before ready and a real received spawn afterward. Reject stale ready, duplicate departure, and wrong-peer tokens.

The candidate must inspect stdout/stderr from every process, not just assertions. Late continuous unreliable sync is not claimed to be ordered by reliable fences; the engine's missing-synchronizer handling must remain safe, and the proof must expose any found-but-invalid root interval. No arbitrary sleep may serve as successful drain or readiness evidence.

## Failure and rollback obligations

For the tiny proof, one focused disconnect/cancellation scenario may establish bounded cleanup after the main protocol succeeds. A disconnected peer is removed from the required acknowledgments by actual transport state, never by timeout alone. If the host disconnects, fail/abort the network transition and retain the preexisting solo/session-end behavior; do not claim host migration.

Before old subtree destruction, cancellation restores the old realm's admission and outbound gates with a fresh token. After destruction, rollback must rebuild the old receiver first and then perform the same ready/admission phase. Never simply clear the gate while the receiver path is absent. Real save/scene rollback remains a production integration requirement, outside the tiny proof.

## Production integration shape after the proof passes

Proposed eventual owned paths, requiring a separate implementation approval: `autoload/game_state.gd` (await departure before scene replacement and publish readiness after `_await_realm_scene_ready`; route existing abort/recovery through the same lifecycle); `scripts/net/session.gd` (authenticated transition state and RPC transport); a new `scripts/net/realm_transition.gd` helper if it keeps Session focused; `scripts/net/trainer_spawn.gd` (actual received inventory/despawn events, host spawn/visibility gate); `scripts/net/remote_trainer.gd` only if the proven sender-quiescence API needs it; `scripts/net/realm_shells.gd` (pin old shell until drain and respect destination readiness). Corresponding focused tests follow a later brief.

Solo/no-session bypass remains immediate. Host movement needs extra care: replacing a host current scene or an already occupied destination shell removes authoritative spawners seen by other clients. The host path must drain those affected observers too, or retain the authoritative scene with its exact paths. Existing `realm_shells.gd` has no live-scene adoption API, so silent adoption is not a minimal assumption. A client-only fix must not be advertised as resolving host transition lifecycle.

The authored scenes also contain CreatureSpawner and ItemSpawner. Current trainer-only activity does not justify ignoring a nonempty receiving container: inventory all active spawners in the replacement subtree and either enroll their replicated bodies in the protocol or reject unsupported active state explicitly before destruction. Do not silently claim all-realm safety from a trainer-only fixture.

This brief authorizes no production change and records no protocol pass. The next useful evidence is the three-peer native protocol result with exact sender/receiver ordering and unbroken continuing-viewer updates.
