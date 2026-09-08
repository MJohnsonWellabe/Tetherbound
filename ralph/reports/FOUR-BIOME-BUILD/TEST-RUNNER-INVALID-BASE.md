# Invalid test base — fail closed without an orphan

The first Stormwood interaction-race contract accidentally extended bare
`RefCounted`. Its initial unique log recorded an invalid `failures` access in
`tests/run_tests.gd:106`, and Godot processes32352/20512 stayed alive after the
script abort. The owning agent verified and terminated only that obsolete pair;
corrected test runs already exited cleanly. No gameplay process was terminated.

The runner now requires the real `tests/test_case.gd` base before accessing its
fixture hooks and assertion state. Invalid bases count as one failure and reach
the ordinary nonzero exit. Valid assertions and test bodies are unchanged.

Actual runner negative control:

`--headless --path . --log-file <unique path> --script tools/probe_test_runner_invalid_base.gd`

The probe overrides discovery only, supplying the deliberately malformed
`tests/fixtures/runner_invalid_base.gd` (not automatically discoverable). The
actual runner reports one test, zero assertions, one failure and exits **1** in
1.82 seconds. There is no SCRIPT ERROR/native ERROR and its test body never runs.
Log: `%TEMP%/root-runner-invalid-base-negative-20260908.log`.

Positive unchanged Dace/Brine/Water-args/Shellwatch tests run through the same
runner: seven tests, 40 assertions, zero failures; exit0, native log clean.
Log: `%TEMP%/root-runner-positive-regression-20260908.log`.

Scope: this prevents missing-base aborts only. It does not intercept arbitrary
GDScript runtime errors inside a valid test or prove the complete suite. The
separately observed missing selector in a multi-selector `--only` request remains
an existing runner limitation; root reran the correctly named test explicitly.
