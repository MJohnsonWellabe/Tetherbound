extends SceneTree

const CASES := preload("res://tests/test_water_gull_rest_signal_site.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases := CASES.new()
	cases._case_supports_touch_terrain_reach_one_platform_and_match_collision()
	var result := {
		"assertions": cases.assertion_count,
		"failures": cases.failures,
	}
	print("GULL_REST_SIGNAL_SITE_RESULT=" + JSON.stringify(result))
	quit(0 if cases.failures.is_empty() and cases.assertion_count == 60 else 1)
