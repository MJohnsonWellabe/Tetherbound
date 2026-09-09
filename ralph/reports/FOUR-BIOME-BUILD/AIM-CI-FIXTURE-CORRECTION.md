# Earned aim CI fixture correction

PR95's first head `548da7a3d` failed unit shard 1 in CI `34343691520`.
The existing `ThrowVerdict` fake in `test_fresh_opening_target.gd` did not
declare the native `_guard` field now read by the earned readiness checks.
Converting that missing field to float caused a script error; a subsequent
assertion accessed an empty failure list. The shard reported 761 tests,
301,984 assertions and one counted failure, losing five baseline assertions
through the aborted callbacks. A printed per-test success did not establish
that those callbacks completed.

The correction adds `_guard = 0.0` to that fake, representing its intended
already-ready aim. The driver's strict native guard check is unchanged.
Actual positive-guard rejection is independently covered by the native guard
probe already selected in CI; this change does not weaken that behavior.

The corrected existing focused suite passed on its first local execution:
five tests, 21 assertions, zero failures and exit 0, with no ERROR or SCRIPT
ERROR in its complete log. Evidence is retained under
`.artifacts/aim-unit-fixture-20260909/`, using an isolated APPDATA/LOCALAPPDATA
profile and the installed Godot 4.7 executable. No world or campaign ran.

The failed head remains failed. The changed-source head requires a new full CI
run; superseded unfinished jobs are not credited as passed, and no workflow
retry is used to replace the original result.
