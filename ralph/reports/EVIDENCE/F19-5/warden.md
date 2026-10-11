# F19#5 Meadows piece `warden`: FAIL (meadows-route-b)

- **Input:** generated `hall` lineage. The `hall` piece passed again at `c3c39026` (1482 s); it is not re-run.
- **Command:** `earned_chain_runner.gd -- --segment=warden --generated-fixture --handoff-from=<hall root>/hall ...`, run from a pinned clean worktree at `c3c39026`.

| Attempt | Source | Result |
|---|---|---|
| 1 | `088adb0f` | Helper defect. `f49_warden_finale` restored `_supported_y` but not `_in_hall`, so a hurt party's preparation walked back toward a road camp and the supported-floor guard failed. Fixed in `b52ea554`. |
| 2 | `c3c39026`, 2:55–3:29 PM CT, 526 s | The Warden was beaten 5/5 (124 hits); `defeated_warden` set; items exact. The exact-XP check failed: 3 of 5 creatures were still below before+expected (capped), e.g. 10625 + 1114, capped at 11032, but only 11014 reached. |

The shortfall matches systems-b's finding that the duty queue delays round rewards by about 138 s of game time. Choice is with the coordinator: a bounded, disclosed wait before the exact check, or the queue fix.
