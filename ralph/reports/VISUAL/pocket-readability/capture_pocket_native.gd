extends "res://tools/capture_stormwood_pocket_walks.gd"

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	await super._run()
func _capture(frame_id: String, description: String, extra: Dictionary = {}) -> void:
	if _hud_off:
		for layer: Node in _world.find_children("*", "CanvasLayer", true, false) + root.find_children("*", "CanvasLayer", true, false):
			(layer as CanvasLayer).visible = false
	for _frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("%s: empty viewport image" % frame_id)
		return
	if image.get_width() != 1920 or image.get_height() != 1080:
		_failures.append("native viewport mismatch"); return
	var path := "%s/%s.png" % [_output_dir, frame_id]
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_failures.append("%s: save_jpg failed" % frame_id)
		return
	var combat := _world.get_node_or_null(^"CombatManager")
	var record := {
		"id": frame_id, "file": path.get_file(), "label": _label, "description": description,
		"camera": "player camera (production CameraRig/Camera3D)",
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"camera_player_m": _camera.global_position.distance_to(_player.global_position),
		"prompt": str(_arbiter.call("prompt")) if _arbiter != null else "",
		"hud": "off" if _hud_off else "on",
		"surge_phase": str(_surge.get("phase")) if _surge != null else "",
		"surge_elapsed": _surge_elapsed(),
		"time_of_day": str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "",
		"in_fight": combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")),
		"staged": {"flags": _staged_flags.duplicate(), "clock": "day pinned; surge elapsed re-pinned to %d s (Calm) before the frame" % int(CALM_PIN_SECONDS),
			"placement": "debug_teleport_to + Player transform at stand point"},
	}
	var current := _world.get_node_or_null(^"StormwoodRoadCurrent")
	if current != null:
		var near := 0
		for chunk: Node in current.get_children():
			if chunk is MeshInstance3D and (chunk as MeshInstance3D).global_position.distance_to(_camera.global_position) \
					< (chunk as MeshInstance3D).visibility_range_end + 30.0:
				near += 1
		record["road_current"] = {"chunks": current.get_child_count() - 1, "chunks_in_draw_range": near,
			"frame_draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)}
	record.merge(extra, true)
	_frames.append(record)
	_log("captured %s prompt='%s' phase=%s cam=%.1fm" % [frame_id, record.prompt, record.surge_phase,
		record.camera_player_m])



