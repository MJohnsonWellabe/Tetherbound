extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var test := preload("res://tests/test_f36_pose_candidates.gd").new()
	test._case_preview_library_preserves_installed_clips_and_revive_pivot()
	test._case_ordinary_body_keeps_candidates_off()
	await process_frame
	print("F36_POSE_RESULT=" + JSON.stringify({"assertions": test.assertion_count, "failures": test.failures}))
	quit(0 if test.failures.is_empty() and test.assertion_count == 16 else 1)
