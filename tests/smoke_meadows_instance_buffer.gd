extends SceneTree

## Renderer-required companion to the headless buffer-reference test. Root
## runs this under its native lease with Compatibility and Forward+; it does
## not load the production world or constitute visual acceptance.
const LOOK_TESTS := preload("res://tests/test_realm_look_overlay.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Meadows instance-transform proof requires a real renderer; headless cannot satisfy this check")
		quit(1)
		return
	var test := LOOK_TESTS.new()
	test.check_runtime_instance_transform_with_renderer()
	for failure: String in test.failures:
		print("FAIL: %s" % failure)
	print("MEADOWS INSTANCE BUFFER: renderer=%s assertions=%d failures=%d" % [
		RenderingServer.get_current_rendering_method(), test.assertion_count, test.failures.size(),
	])
	quit(0 if test.failures.is_empty() and test.assertion_count == 4 else 1)
