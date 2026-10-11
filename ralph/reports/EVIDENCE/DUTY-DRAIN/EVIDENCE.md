# Foundation duty drain (coordinator-ruled narrow fix), 92ed032a
- Problem, measured: the retry scan ran every 1 s and committed one duty per character, and each row settles on the next frame (deferred owner apply). After a long fight ~100 combat_mastery duties held every later reward: a rematch win landed 8308 frames (~138 s game time) after the fight; rematch-wiring saw 5054–9597 frames. Owner input was never blocked (0 frames).
- Fix: when a scan has just committed a still-settling duty, FoundationComposition rescans after `session.foundation_backlog_scan_interval_s` = 0.1 s. Each duty stays its own row and receipt, settled one at a time; order, exactly-once and the guest owner-passive path are unchanged.
- Proof:
  - new `tests/test_foundation_mastery_drain.gd`: 100 real duties drain one row per backlog scan, each receipt exactly once in retry order across a mid-drain reload (119 assertions, 0 failed);
  - retry order/admission, retained settlement, F19 boss delivery, owner-passive and mastery suites: 92 tests, 0 failed; authority suites: 32 tests, 0 failed; no assertion changed (`unit_suites.txt`);
  - played: the Meadows rematch payout now lands 1111 frames (~18.5 s) after the win, was 8308.
- Also 0d677b6a: honest "released" log for held duties; the host seeds its own authority record before its load-time ack (removes the "training stalled… revision -1" warning after a title Load).
