# Systems focused b6 proof

Source: `b6f19b4da9d6f2a9761708aa95ffb12c0244d41c`.
Command: Godot 4.7 `--headless --path C:/CodexTemp/tetherbound-native-service --script tests/run_tests.gd -- --only=test_meadows_earned_warrens_segment.gd,test_four_biome_checkpoints.gd`.
Scope: 15 guardian XP-oracle methods and 13 checkpoint methods, one bounded 180-second group.

The original long-path run exited 0 and printed 28 tests / 1,411 assertions / 0 failed, but remains **FAILED**.
It emitted six directory-enumeration errors during checkpoint cleanup at existing paths 255–266 characters long.
The supervisor correctly rejected those diagnostics; neither tests nor error gates were weakened.

The same source and selectors passed using isolated home `D:/tetherbound/.artifacts/s/run-b6f28-r2/h`.
Result: **28 tests / 1,411 assertions / 0 failed**, natural exit 0, empty stderr, matching raw log hashes.
The old and new stdout bytes have the same SHA-256; only the corrected short-path run establishes clean execution.
The longest corresponding problematic path shortened to 164 characters.

`raw-evidence.json` preserves both receipts, stdout/stderr and independent reviews as byte-exact UTF-8 text with byte counts and SHA-256.
All eight embedded files were decoded and checked against their original bytes after serialization.
The prior verified 42 focused tests plus six Home Key/research tests are reused separately, not rerun or included in this 28-test total.
This proves the selected logic regression checks only. Guardian combat/reward/reload acceptance requires its separate native witness.
