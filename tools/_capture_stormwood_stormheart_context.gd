extends "res://tools/_capture_stormwood_crown_arch_context.gd"

## Source-prepared supplemental landmark probe. The inherited helpers use the
## production camera and ordinary input. Canonical catalogue setup remains
## disclosed debug travel; none of this is progression or traversal acceptance.
## --biome=stormwood --subset=glass_field --times=day --output=<fresh directory>


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Stormheart context requires a rendering display")
		quit(1)
		return
	if not _parse_args() or not _load_plan():
		quit(1)
		return
	if _biome_id != "stormwood" or _planned.size() != 1:
		push_error("Stormheart context requires one Stormwood Glass Field day row")
		quit(1)
		return
	var row: Dictionary = _planned[0]
	var at: Array = row.position_xz
	if str(row.time) != "day" or Vector2(float(at[0]), float(at[1])).distance_to(Vector2(-310.0, 5050.0)) > 0.01:
		push_error("Stormheart context requires the unchanged Glass Field coordinate and day")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_manifest["supplemental_contract"] = "Retain the canonical Glass Field day frame. Wait for the region banner; aim the real camera at Stormheart with ordinary look input, capture, walk backward 12m using ordinary input, re-aim, and capture. No actor or camera transform assignments after canonical setup. Debug catalogue setup and day clock freeze remain audit-only."
	_manifest["supplemental_planned_frame_ids"] = ["stormwood__stormheart__glass_field_look", "stormwood__stormheart__glass_field_backstep_look"]
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	await _capture_row(row)
	if _records.size() != 1:
		_finish(false)
		return
	var tree := _world.get_node_or_null("StormheartTree") as Node3D
	if tree == null:
		_failures.append("Production StormheartTree is absent")
		_finish(false)
		return
	_manifest["stormheart_runtime"] = {"path": str(tree.get_path()), "position": _vec3(tree.global_position), "world_scene": _world.scene_file_path}
	var banner := await _wait_for_region_banner_clear()
	_manifest["region_banner_clear"] = banner
	if not bool(banner.get("cleared", false)):
		_failures.append("Region banner did not clear")
		_finish(false)
		return
	var aim := await _aim_at_tree(tree)
	if not bool(aim.get("reached", false)):
		_failures.append("Ordinary camera look did not reach Stormheart framing")
		_finish(false)
		return
	await _capture_context("stormwood__stormheart__glass_field_look", "split trunk and living crown from Glass Field", aim)
	var walk := await _walk_action(&"move_back", 12.0)
	_manifest["ordinary_backstep"] = walk
	if not bool(walk.get("finite", false)) or float(walk.get("horizontal_distance_m", 0.0)) < 11.5:
		_failures.append("Ordinary backstep did not reach the approach offset")
		_finish(false)
		return
	var second_aim := await _aim_at_tree(tree)
	if bool(second_aim.get("reached", false)):
		await _capture_context("stormwood__stormheart__glass_field_backstep_look", "approach parallax after ordinary backstep", {"walk": walk, "look": second_aim})
	else:
		_failures.append("Ordinary look after backstep did not reach Stormheart framing")
	_finish(_failures.is_empty() and _records.size() == 3)


func _aim_at_tree(tree: Node3D) -> Dictionary:
	var start_yaw := float(_rig.get("yaw"))
	var start_pitch := float(_rig.get("pitch"))
	var target := tree.global_position + Vector3.UP * 135.0
	var delta := target - _camera.global_position
	var desired_yaw := atan2(-delta.x, -delta.z)
	var desired_pitch := atan2(delta.y, Vector2(delta.x, delta.z).length())
	var frames := 0
	while frames < 180:
		var yaw_error := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_error := desired_pitch - float(_rig.get("pitch"))
		if absf(yaw_error) < deg_to_rad(2.0) and absf(pitch_error) < deg_to_rad(2.0):
			break
		# CameraRig subtracts rightward stick from yaw and adds upward stick
		# to pitch. Small ordinary input avoids overshooting the target frame.
		var yaw_action: StringName = &"look_left" if yaw_error > 0.0 else &"look_right"
		var pitch_action: StringName = &"look_up" if pitch_error > 0.0 else &"look_down"
		if absf(yaw_error) >= deg_to_rad(2.0):
			Input.action_press(yaw_action, 0.5)
		if absf(pitch_error) >= deg_to_rad(2.0):
			Input.action_press(pitch_action, 0.5)
		await physics_frame
		Input.action_release(yaw_action)
		Input.action_release(pitch_action)
		frames += 1
	for _frame in 18:
		await physics_frame
	var yaw_delta := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
	var pitch_delta := desired_pitch - float(_rig.get("pitch"))
	return {"reached": absf(yaw_delta) < deg_to_rad(2.0) and absf(pitch_delta) < deg_to_rad(2.0),
		"target": _vec3(target), "start_yaw_deg": rad_to_deg(start_yaw), "start_pitch_deg": rad_to_deg(start_pitch),
		"end_yaw_deg": rad_to_deg(float(_rig.get("yaw"))), "end_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"yaw_error_deg": rad_to_deg(yaw_delta), "pitch_error_deg": rad_to_deg(pitch_delta), "physics_frames": frames}
