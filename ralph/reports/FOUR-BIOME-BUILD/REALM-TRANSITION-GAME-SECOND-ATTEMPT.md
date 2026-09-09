# Game orchestration fixture — corrected pass, explicit negative cases

2026-09-09. `.artifacts/realm-transition-game-fixture-v2/` retains stdout, stderr, receipt and source hashes. Exit 0 after 3.927971 seconds, 73 assertions passed. Terminal CIM check found zero Godot processes. The first failed fixture attempt remains retained; corrected setup awaits `SceneTree.scene_changed` and verifies the actual source scene identity before entering each case.

This uses the actual `Game.enter_realm` wrapper, loading overlay, scene changes, readiness, state compensation and recovery UI, with two authored empty realm scenes and a recording coordinator seam. A separate final case awaits the real coordinator's host interlock across reset. It does not run ENet, procedural worlds or a real disconnection. Those limits are separate from the earlier 81-check native component proof.

Cases and observed behavior:

- Client: duplicate entry refused; ready event before admission; actual destination scene; deliberately failing world saver called zero times. Client drain cannot reach the host-only autosave-refusal branch.
- Epoch invalidation during grant, overlay and destination readiness: false result, no stale admission or rollback, only the operation's own overlay removed. An unrelated overlay survives every case.
- Unexpected replacement of the ready scene during admission: old coroutine returns false, leaves the replacement scene untouched and performs no compensating rollback.
- Injected target readiness failure: source scene actually rebuilt, source readiness before source admission, target never admitted.
- Injected rollback admission failure: bounded recovery overlay exposes an enabled focused Exit game button. Its actual global rectangle is wholly inside the viewport. The action quits without calling normal leave/save behavior; this fixture does not invoke it because that would end the test process early.
- Host save refusal: exactly one save attempt; old realm and source scene preserved; reverse announcement and host-permit release observed.
- Host and solo happy paths: legacy announcement/readiness retained; host finite permit released; solo uses no network permit.
- Real coordinator host-permit wait across reset: old await returns false, no host permit remains, new-session local state is empty.

Raw log accounting is deliberate: **four expected ERROR lines**, not an error-free claim. Two `realm 'water' did not become ready within 120.0 seconds` messages come from injected false readiness; the test does not wait 120 seconds. One `realm transition rollback entered guarded recovery` follows injected rollback admission refusal. One `realm 'water' transition autosave failed; crossing cancelled` follows the host's failing saver. Zero additional ERROR lines, SCRIPT ERRORs or WARNINGs were present. All negative cases then satisfied their recovery assertions.

The earlier pure integration run passed 18 tests/91 assertions. This fixture validates the later ready-scene identity guard and recovery-button layout in live control flow. Remaining gates include a root-leased real default Water multiplayer route, native late-join/rollback/disconnection coverage, unchanged host regression evidence, full exact-head CI and independent integration review. The client-only fix remains uncommitted and unshipped.
