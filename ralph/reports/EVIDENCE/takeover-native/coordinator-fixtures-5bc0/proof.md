# Coordinator fixture native proof: FAILED

Exact source `5bc0ac3ea71ad524d956751423f650432ac9de1b`. Receipt interval `2026-10-14T04:43:18.6691484Z` to `2026-10-14T04:43:56.5233556Z`. The batch stopped at the third file; the fourth vegetation-harvest-streaming file was not launched. **The requested 61-method batch did not pass.**

| Selected file | Reported methods | Reported assertions | Seconds |
|---|---:|---:|---:|
| water-guardian-participants | 36 | 360 | 12.441 |
| water-guardian-confirm | 14 | 141 | 11.247 |
| warrens-walk-observer | 7 | 283 | None |

Guardian participants and Guardian confirm passed: 50 methods, 501 assertions, zero failures, empty stderr and natural exit zero. Warrens exited zero and printed 7 methods/283 assertions/0 failed, but stderr reported `SCRIPT ERROR: Left operand of 'is' is a previously freed instance.` at `tests/helpers/warrens_walk_observer.gd:169`, in `same_original`, from the original weak-identity/lifetime test at line149. Its printed successful rows and summary cannot establish a pass when execution raised this error. The strict wrapper correctly refused the batch. No diagnostic was suppressed or assertion relaxed.

Independent review verified all 1,054 canonical source SHA-256/Git blob bindings, exact clean staged source, pinned engine, admitted job/supervisor/request hashes, all three observed argv and natural exits, serial chronology, 180-second process caps, log hashes and recorded disk/memory floors. The failed step lacks a wall_seconds receipt field; its creation-to-terminal interval is retained in the independent review. Recorded engine PIDs are absent and the root lease is idle. Review launched no engine and left stage unchanged for Terrain.

[raw-bundle.json](raw-bundle.json) embeds 14 byte-exact base64 entries: original receipt/logs, admitted packet and independent review. Every entry round-trips to its declared length and SHA-256. Canonical LF container SHA-256: `63c6f01864bfe74a972ccce5ef2c1895079b333af11f18eae3d5cf9509337374`. This is failure evidence and two scoped fixture passes, not full-suite, live multiplayer or visual acceptance.
