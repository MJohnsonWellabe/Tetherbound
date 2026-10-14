# Systems guardian b6 failed witness

Source: `b6f19b4da9d6f2a9761708aa95ffb12c0244d41c`; result **FAILED**, process exit 1.
Command: Godot 4.7 `--headless --path C:/CodexTemp/tetherbound-native-service --script tests/smoke_warrens.gd -- --guardian-reward --no-scatter-visuals`.
Run: 13 October 2026, 9:35–9:41 PM US Central; bounded at 600 seconds.
Disclosed fixture: generated retained five with valid L16/cap20 headroom; production guardian/input/rewards/save/reload retained, decorative scatter upload omitted.

The sole printed assertion failure is exact authored XP delivery.
All five started at 6,730 XP; active ended at 7,124 (+394), four others at 6,997 (+267 each), below the 11,032 cap.
Positive XP delivery is observed but the exact-XP assertion remains failed. No unchanged rerun or acceptance closure follows.
Combat and save/load/rebuild progressed without another reported assertion failure.
Two nonempty scatter placement/collision censuses were verified; this is not shipping visual or earned-route evidence.

Stderr contains exactly one known `instance_reset_physics_interpolation()` deprecation warning block and no `ERROR` or `SCRIPT ERROR`.
The warning is preserved, not silently discarded or broadly waived.
The supervisor also recorded `GetFullPath` on an empty path during process polling.
Its vulnerable field is `Win32_Process.ExecutablePath`; a teardown race is consistent with the evidence, but no CIM snapshot proves the timing.
That wrapper diagnostic masks the native assertion in the receipt's stop reason; the raw log retains the actual failed assertion.

`raw-evidence.json` contains byte-exact receipt, stdout, stderr and independent review with original paths, byte counts and SHA-256.
All four files passed serialization roundtrip comparison with their original bytes. Original artifacts remain unchanged.
The separate focused 28-test pass does not convert this guardian witness to PASS.
