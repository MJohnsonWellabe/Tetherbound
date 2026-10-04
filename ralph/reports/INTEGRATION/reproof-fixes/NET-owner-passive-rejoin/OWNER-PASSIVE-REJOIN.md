# Guest rejoin leaves the owner-passive stream un-admitted: reproduction and fix

**Verdict: fixed. `tools/net/run_net_smoke.sh owner_passive_rejoin` passes at `5a3d9a7e`** (exit 0, 24 PASS, 0 FAIL, 2026-10-04T22:15:50Z; `green-run1.txt`). The ten owner/guest passive unit test files also pass against the fix (93 tests, 1869 assertions, 0 failed).

Found by the F27 lane. In two-peer co-op, every passive-gated guest action stayed blocked after any reconnect, Altar spend included.

## Reproduction (unchanged code, `repro-unchanged-code.txt`)

The new smoke `tests/smoke_net_owner_passive_rejoin.gd` (with its peer script) runs two real ENet peers in production Meadows: join, then a plain `leave` + `join`, then the guest walks.

- First join: admitted. The guest's stream `19a4…` is held by the host with the same id.
- After the rejoin, the host still held the **departed** transport's stream (`19a4…`, old peer id, cursor 26). The guest's new stream (`018b…`) stayed `admission_pending: true`, `acked: 0`, and its sequence went 239 → 553 while it walked without a single ack.
- A real conflict was also silently pending, with no reason given.

## Cause

`diagnostic-admission-diff.txt` comes from a temporary, uncommitted print in `admitted()`.

1. `owner_passive_sync.admitted()` re-creates a stream only when the host's recovered authority **exactly** equals the guest's declaration, and otherwise returns silently. On an ordinary rejoin the two differ in passive care drift the owner kept ticking but the host never acknowledged: `nourishment`, `happiness`, `distance_m_together`. So every rejoin was refused.
2. Nothing removed the departed transport's stream (`peer_left` handled only portal checkpoints), and the guest's packets for its new stream id were dropped against it.

## Fix (isolated commits)

- `ca16cd2b` (`scripts/net/owner_passive_sync.gd`):
  - `peer_departed(peer)` drops the transport's streams. A portal-departed stream stays for `_recovery_admitted`, and a prepared checkpoint is cancelled as `reset()` does.
  - `admitted()` drops a stream bound to another transport.
  - **Re-admit against the recovered authority:** if the declaration differs only in `owner_passive_replay.PASSIVE_FIELDS` (`REPLAY._core` equal), which is the same list the F27 training fix uses, the stream opens on the host's state. The owner is sent `readmit`; it adopts the host's passive values, restarts its cursor on that baseline (inputs on the old base are dropped) and answers `readmitted`, and the host acks.
  - **A real conflict is refused loudly:** `admission_refused` carries the differing paths and is re-sent on `resume`/`inputs`. The owner records it, stops the stream, warns, and tells the player.
- `8dd16d2d` (`scripts/net/session.gd`, a hot file): `_on_peer_disconnected` calls `peer_departed`.
- `5a3d9a7e` (`owner_passive_sync.gd`): a readmitted owner restarts its travel/discovery clocks, as `arm_owner` does. `fix-run2-discovery-cadence.txt` shows the gap this closes: the re-admitted stream died on its first discovery input (`discovery_cadence`), because the old `_discovery_elapsed` did not match the new cursor. It is timing-dependent, which is why `fix-run1.txt` passed the rejoin legs.

## What the passing run proves (`green-run1.txt`)

- **Rejoin:** a new stream id, admitted (`admission_pending: false`), and the host holds the same id with no error. While the guest walks, acks climb 11 → 95 under the new id. This is the passive path every passive-gated action (`action_gate`/`gate`/`capture_gate`) checkpoints against.
- **Real conflict** (fixture: the guest's creature is +1 level on the guest only): not admitted. The guest receives `admission_refused: owner_passive_admission_conflict: /party[0]/max_hp, /attack, /defence, /hp, /level, …`, and both peers log warnings.

The smoke's ack check was corrected in `e7827cda`. A walking owner always has a few inputs in flight, so the check requires the host to ack inputs recorded *after* the rejoin, rather than `acked == sequence` at the sampling instant.

## Confirmation and regression

- `green-run2.txt`: a second rejoin run at `5a3d9a7e` is also green.
- `regression-cloudreach-activity-payoffs.txt`: `cloudreach_activity_payoffs` passes, exit 0, 96 PASS. It includes a real guest leave, rejoin and character reload. It ran on `ca16cd2b` + `8dd16d2d`, before the clock reset in `5a3d9a7e`.
