extends SceneTree
const CHECK := preload("res://tests/test_meadows_earned_material_segment.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var check := CHECK.new()
	check.check_live_supply(self)
	for failure: String in check.failures:
		push_error(failure)
	print("LIVE MATERIAL SELECTION: %d assertions, %d failures" % [check.assertion_count, check.failures.size()])
	quit(0 if check.failures.is_empty() else 1)
