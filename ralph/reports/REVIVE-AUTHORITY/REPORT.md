# Co-op revive authority

Work starts from PR142/58f3aaaec on `ralph/revive-first-tap`; the final branch
also includes its Water placement correctionea48d6aab. This report
distinguishes the unresolved CI input failure from the confirmed direct-peer
completion defect. No release, internet or four-player acceptance is implied.

## First-tap investigation

CI35493402142's `smoke_net_revive.gd` first tap showed zero progress; the next
tap apparently completed revival. Subsequent missing-target errors occurred
after that and do not establish a disappearing body as the cause.

One instrumented stock-Godot4.7 run on58f3aaaec passed all45checks, exit0:
`revive-diag-20260920T065246Z` in OS temp, with isolated peer homes and actual
two-process ENet. Temporary diagnostic changes to the existing peer runner and
smoke were restored byte-for-byte after the run; no new harness is retained.

Before the first tap, the body gap was1.800016m. The revive prompt's direct
offer was actionable, priority10, distance1.899834m. The cached arbiter winner
was empty, but its synchronous recompute on the press selected and activated
the real `RevivePrompt`. Progress was0.30577s immediately after injection and
1.10s after the existing45-frame wait. Thus an empty pre-tap UI cache does not
by itself explain the CI failure. Root inspected the coordinator results.

The CI failure did not reproduce; its cause remains unresolved. No range,
movement, damage, body, realm or session guard was weakened to make it pass.
If investigated again, capture the first continuation refusal and reviver
displacement; repeated blind reruns are not evidence. The peer log also records
an entombment recovery and another local-down entry after successful revival;
the smoke's observed up/walking checks do not close that separate geometry
finding or prove an extended post-revive journey.

## Authority boundary

Baseline `downed_state.gd::_tick_revive` advanced the reviver's local timer and
sent `_rpc_revive` directly to the target. The target's `any_peer` receiver
checked only local downed state. A remote completion packet could therefore
bypass elapsed time, position and the initiating peer's continuation guards.

The intended correction puts the three-second authorization clock, range,
realm, body identity, attempt ordering and one-completion decision on the host.
It retains the existing target-local45s expiry/death/satchel pipeline: this
slice does not claim host-authoritative finalized death or disconnected death
settlement. Human damage is currently local; reliable client cancellation
remains necessary and is not independent host validation of player health.

No new save fields, inventory mechanics, revive item, self-revive, sixth
creature, held-input mechanic or new global singleton belongs to this change.

## Implemented boundary and validation

`downed_state.gd` now delegates to the pure `net/revive_authority.gd` service.
Host authorization requires registered peers, finite host-observed positions,
matching registry/body realms, unchanged body identities, a current target
window and ordered attempt. It permits one channel per reviver and target,
checks2.5m range and0.3m horizontal movement, and consumes the authorization
before emitting one grant after3s. Clients display attempt/window-bound host
notices at up to10Hz. The host-local damage/movement guard runs before the
completion tick. Late old notices cannot move a new attempt's presentation;
a new attempt does not inherit the preceding attempt's progress throttle.
Only sender1 may grant the exact current target window. `_rpc_revive` is inert.

Steam's lobby/member admission marker is now `tetherbound-invite-v3` because
the RPC shapes changed. ENet has no equivalent version gate; its current
requirement remains matching builds. This is not exact content-fingerprint
admission or proof of mixed-version safety for all Session RPCs.

Stock Godot4.7 validation from the source tree:

- `--headless --path . --script tests/run_tests.gd --
  --only=test_downed_revive.gd,test_revive_authority.gd,test_steam_lobby.gd`:
  **27tests /135assertions /0failed**. No script/plain errors.
- The protocol mismatch case first failed with the old v2 marker
  (1test/4assertions/1failure), then the Steam file passed11tests/46assertions
  with v3. Pure-service review also caught one reviver starting two targets
  and a reviver becoming downed mid-channel; their regression cases failed
  before correction and are included in the final focused batch.
- `--headless --path . --script tests/smoke_net_revive.gd`:
  **53checks, exit0, ALL CHECKS PASSED**. Run
  `revive-host-authority-20260920T071230Z`, isolated OS-temp peer homes.
  Original first tap progressed1.06s, release continued, re-press and motion
  cancelled. Host-to-client and client-to-host completion each granted once,
  restored movement and created no death satchel. The client then walked3.21m.
  Coordinator and both peer logs contain no SCRIPT ERROR, plain ERROR or FAIL;
  both peers exited as expected. Root inspected the source and result logs.

Parent PR141's completed CI35494808558 has26successful jobs and3skipped,
with no failures. Its revive step ran once and passed. This additional pass
does not establish the cause of the earlier CI35493402142 first-tap failure.
Neither that failure nor broad co-op acceptance is closed by this checkpoint.

No save format or singleton changes. Target-local expiry/finalized death,
client-reported human damage, same-realm interior/encounter exit semantics,
disconnected death settlement, four-peer/internet/device validation and full
downed-player progress presentation remain outside this correction.
