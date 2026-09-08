extends "res://tests/run_tests.gd"

## Negative control for the actual runner: expected process exit is ONE.
## Overrides discovery only; production validation/accounting/quit stay intact.
func _find_tests(_dir_path: String) -> Array[String]:
	return ["res://tests/fixtures/runner_invalid_base.gd"]
