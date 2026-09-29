extends "res://tests/test_case.gd"

const MATRIX := preload("res://tools/art_pipeline/capture_tidewake_matrix.gd")


func _saved_pair() -> Dictionary:
	return {"frame_id": "dock-day", "frame": "dock-day", "status": "captured",
		"file": "res://.artifacts/phase2/probe/dock-day.png", "start_captured": true,
		"player": [1, 2, 3], "camera": {"position": [4, 5, 6]}, "surface_state": {"on_floor": true},
		"observed_clock": {"hour": 8.0}, "render": {"adapter": "fixture"},
		"target": [10, 2, 3], "distance_m": 9.0, "horizontal_distance_m": 9.0,
		"hold_seconds_requested": 2.0, "hold_seconds_simulated": 2.01,
		"hold_start_process_frame": 100, "hold_start_physics_frame": 90,
		"hold_end_process_frame": 222, "hold_end_physics_frame": 211,
		"hold_end_captured": true, "hold_end_file": "res://.artifacts/phase2/probe/dock-day-hold-end.png",
		"hold_end_player": [2, 2, 3], "hold_end_camera": {"position": [5, 5, 6]},
		"hold_end_surface_state": {"on_floor": true, "stamina_fraction": 0.9},
		"hold_end_observed_clock": {"hour": 8.01}, "hold_end_render": {"adapter": "endpoint fixture"},
		"hold_end_distance_m": 8.0, "hold_end_horizontal_distance_m": 8.0}


func test_export_preserves_start_and_assigns_actual_endpoint_metadata() -> void:
	var source := _saved_pair()
	var original := source.duplicate(true)
	var result := MATRIX.export_image_records([source], ["dock-day"], 2.0)
	assert_eq(result.frames.size(), 2)
	assert_eq(result.expected_frame_ids, ["dock-day", "dock-day-hold-end"])
	assert_eq(result.missing_or_failed_frame_ids, [])
	assert_eq(result.failed_views, [])
	var start: Dictionary = result.frames[0]
	var endpoint: Dictionary = result.frames[1]
	assert_eq(start.file, source.file)
	assert_eq(endpoint.file, source.hold_end_file)
	assert_eq(start.player, source.player)
	assert_eq(start.observed_clock, source.observed_clock)
	assert_eq(start.distance_m, 9.0)
	for key: String in ["player", "camera", "surface_state", "observed_clock", "render", "distance_m", "horizontal_distance_m"]:
		assert_eq(endpoint[key], source["hold_end_" + key], "endpoint replaces start metadata: " + key)
	assert_eq(endpoint.target, source.target)
	assert_eq(endpoint.paired_frame_id, start.frame_id)
	assert_eq(start.paired_frame_id, endpoint.frame_id)
	assert_eq(start.capture_elapsed_hold_seconds, 0.0)
	assert_eq(endpoint.capture_elapsed_hold_seconds, 2.01)
	assert_eq(endpoint.capture_process_frame, 222)
	assert_eq(endpoint.capture_physics_frame, 211)
	endpoint.camera.position[0] = 999
	assert_eq(source, original, "exported nested records never mutate source evidence")


func test_failed_hold_keeps_saved_start_but_reports_missing_endpoint() -> void:
	var record := _saved_pair()
	record.status = "failed"
	record.hold_end_captured = false
	var result := MATRIX.export_image_records([record], ["dock-day"], 2.0)
	assert_eq(result.frames.size(), 1)
	assert_eq(result.frames[0].status, "captured")
	assert_eq(result.frames[0].view_status, "failed")
	assert_eq(result.frames[0].player, record.player)
	assert_eq(result.failed_views.size(), 1)
	assert_eq(result.missing_or_failed_frame_ids, ["dock-day-hold-end"])


func test_preflight_failures_have_no_phantom_image_rows() -> void:
	var result := MATRIX.export_image_records([
		{"frame_id": "dock-day", "status": "failed", "stand_failure": "no floor"}], ["dock-day"], 2.0)
	assert_eq(result.frames, [])
	assert_eq(result.failed_views[0].stand_failure, "no floor")
	assert_eq(result.missing_or_failed_frame_ids, ["dock-day", "dock-day-hold-end"])


func test_no_hold_exports_one_settled_image_and_no_extra_expectation() -> void:
	var record := _saved_pair()
	record.hold_end_captured = false
	var result := MATRIX.export_image_records([record], ["dock-day"], 0.0)
	assert_eq(result.frames.size(), 1)
	assert_eq(result.frames[0].capture_phase, "settled")
	assert_false(result.frames[0].has("paired_frame_id"))
	assert_eq(result.expected_frame_ids, ["dock-day"])
	assert_eq(result.missing_or_failed_frame_ids, [])
