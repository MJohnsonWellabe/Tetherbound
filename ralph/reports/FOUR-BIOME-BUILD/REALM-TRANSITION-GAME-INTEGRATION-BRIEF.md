# Bounded Game integration sequence

2026-09-09. Follows the corrected 81-check native component proof and amended client-only design. Owned edits: `autoload/game_state.gd`, existing `scripts/net/realm_transition.gd` lifecycle seams, focused tests and this lane's reports. No visual files, broad replication redesign or host authority handoff.

1. `enter_realm` claims a local serial/context to refuse overlapping fire-and-forget entry calls. Capture Session identity, active state, coordinator identity/epoch. Its wrapper releases only its own serial after the delegated coroutine returns. New-game reset invalidates the serial.
2. Existing validation remains. A live client awaits `begin_client`; a live host awaits the finite `begin_host` interlock. Solo bypasses both. Check context and source scene/current realm after the await. Snapshot/sync save-facing state only after that reservation succeeds.
3. Keep existing realm/map/pending-entry/announcement and host-only autosave behavior. Present loading overlay, check context, swap scene, then await authored destination readiness with cancellation checks on every frame. No detached client falls back to uncoordinated announcement.
4. Client awaits `finish_client` only after authored receiver readiness. Then complete deferred entry and dismiss the overlay, checking context after both admission and dismissal. Host/solo use their legacy scene-ready completion.
5. A connected failure restores the snapshot and retargets the same client token to its source. Rebuild source only when the scene was replaced; await rollback readiness, then client admission before overlay dismissal. Compensating save/readiness failures retain recovery UI and the scoped permit. Never reopen admission at rollback initiation.
6. A stale Session/epoch or new-game serial returns false and only frees that operation's own overlay. It must not compensate state, save, rebuild a scene or clear a newer operation. Host permit release is also epoch/identity guarded.

Necessary coordinator lifecycle repairs stay narrow: reset must clear stale local transaction state; rollback preparation validates token/source and clears the old attempt's error before source admission; host permit wait must not grant after session invalidation. Existing tombstone/origin matching still gates successful readiness.

Validation: focused context cancellation/new-session reuse, rollback preparation/stale-token, existing entry/readiness/save-compensation tests, and a tiny actual Game orchestration fixture if needed. Root lease is required before the default real Water route. The old host scene-rebuild defect, native late-join and full CI remain explicit open limits.

## Implementation checkpoint

Game integration is now written. First focused run passed 18 tests/91 assertions with no raw errors (`.artifacts/realm-transition-game-integration-v1/unit.log`). This predates the subsequent explicit ready-scene identity guard and remains a partial checkpoint, not final verification.

The wrapper guards epoch, Session/coordinator identity, active state, local owner and expected realm; after readiness it also holds the exact ready scene by weak reference across admission/dismissal. Recovery preparation refuses stale or already-admitted tokens, so a target that might be receiving traffic is not blindly destroyed as rollback. Session reset clears local refusal state while old awaiters fail their captured epoch. A failed recovery exposes a controller-focusable Exit game button without invoking normal Session.leave(), which would save potentially inconsistent state. The normal leave path is unchanged.

Prepared `tools/probe_realm_transition_game.gd`: actual Game entry with two tiny authored empty scenes and a recording coordinator seam. Cases cover success, duplicate refusal, cancellation at grant/overlay/readiness, scene replacement during admission, rollback, terminal recovery controls, host/solo compatibility, and the real coordinator host interlock canceled across reset. It intentionally injects two destination-readiness failures and one guarded-recovery error; these exact negative outputs must be counted, with any other error treated as failure. No ENet or world-generation acceptance is inferred from this control-flow test. Execution awaits the character import lease release.
