extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script := load("res://tests/test_shop_floor_support.gd") as GDScript
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var test: RefCounted = script.new()
	test.call("_case_actual_enabled_floor_top_tracks_transform_and_refuses_absent_support")
	test.call("_case_npc_support_uses_its_current_village_floor_without_lowering_terrain")
	await test.call("_case_real_flat_idle_controller_recovers_resumes_and_loses_support")
	var failures: Array = test.get("failures")
	var assertions: int = test.get("assertion_count")
	print("SHOP_FLOOR_SUPPORT_RESULT=" + JSON.stringify({"failures":failures,"assertions":assertions,"completed":assertions == 23}))
	quit(0 if failures.is_empty() and assertions == 23 else 1)
