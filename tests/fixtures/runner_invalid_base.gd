extends RefCounted

## Intentionally malformed negative-control fixture, not a discoverable test.
func test_should_never_run() -> void:
	push_error("Malformed test body must never execute")
