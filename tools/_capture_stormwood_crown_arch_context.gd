extends "res://tools/catalogue_survey.gd"

## One retained production-world proof for the Crown Arch presentation.
## The catalogue pair stays canonical. Supplemental frames move the real
## trainer with ordinary input, then orbit the production camera with ordinary
## look input; no actor, arch, or camera transform is assigned for those views.

const BANNER_CLEAR_MAX_FRAMES := 300
const WALK_MAX_FRAMES := 300
const ORBIT_MAX_FRAMES := 180
const APPROACH_DISTANCE := 12.0
const PASSAGE_DISTANCE := 20.0


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Crown context capture requires a rendering display")
		quit(1)
		return
	if not _parse_args() or not _load_plan():
		quit(1)
		return
	if _biome_id != "stormwood" or _planned.size() != 2:
		push_error("Crown context capture requires --biome=stormwood --subset=crown_arch with day,night")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_manifest["supplemental_contract"] = "After the canonical pair, wait for RegionBanner to clear; walk the real trainer 12m west, capture the rear face, walk 24m east through the arch, orbit the production camera about 180 degrees, and capture the front face. No actor, arch, or camera transform assignment after canonical setup."
	_manifest["supplemental_planned_frame_ids"] = [
		"stormwood__hollow_crown__07__the_crown_arch__ordinary_west_approach_rear",
		"stormwood__hollow_crown__07__the_crown_arch__ordinary_east_orbit_front",
	]
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	for row: Dictionary in _planned:
		await _capture_row(row)
	if _records.size() != 2:
		_finish(false)
		return
	var banner_receipt := await _wait_for_region_banner_clear()
	_manifest["region_banner_clear"] = banner_receipt
	if not bool(banner_receipt.get("cleared", false)):
		_failures.append("RegionBanner did not clear before supplemental views")
		_finish(false)
		return
	var canonical := _player.global_position
	var west_walk := await _walk_action(&"move_back", APPROACH_DISTANCE)
	west_walk["from_canonical_m"] = _player.global_position.distance_to(canonical)
	_manifest["ordinary_west_walk"] = west_walk
	if float(west_walk.get("distance_m", 0.0)) < APPROACH_DISTANCE:
		_failures.append("ordinary west approach did not reach 12m")
	else:
		await _capture_context("stormwood__hollow_crown__07__the_crown_arch__ordinary_west_approach_rear", "rear mirrored detail", west_walk)
	var passage_walk := await _walk_action(&"move_forward", PASSAGE_DISTANCE)
	passage_walk["net_from_canonical_m"] = _player.global_position.distance_to(canonical)
	_manifest["ordinary_arch_passage"] = passage_walk
	if float(passage_walk.get("distance_m", 0.0)) < PASSAGE_DISTANCE:
		_failures.append("ordinary passage walk did not reach 24m")
	else:
		var orbit := await _orbit_camera_half_turn()
		_manifest["ordinary_camera_orbit"] = orbit
		if float(orbit.get("absolute_yaw_delta_deg", 0.0)) < 170.0:
			_failures.append("ordinary camera orbit did not reach 170 degrees")
		else:
			await _capture_context("stormwood__hollow_crown__07__the_crown_arch__ordinary_east_orbit_front", "front installed detail", {"walk": passage_walk, "orbit": orbit})
	_manifest["crown_runtime_identity"] = _crown_identity()
	var complete := _failures.is_empty() and _records.size() == 4
	_finish(complete)


func _wait_for_region_banner_clear() -> Dictionary:
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var waited := 0
	while banner != null and banner.visible and waited < BANNER_CLEAR_MAX_FRAMES:
		await physics_frame
		waited += 1
	return {
		"node_found": banner != null,
		"cleared": banner == null or not banner.visible,
		"physics_frames_waited": waited,
		"checked_utc": Time.get_datetime_string_from_system(true),
	}


func _walk_action(action: StringName, requested_distance: float) -> Dictionary:
	var start := _player.global_position
	var frames := 0
	Input.action_press(action, 1.0)
	while _player.global_position.distance_to(start) < requested_distance and frames < WALK_MAX_FRAMES:
		await physics_frame
		frames += 1
	Input.action_release(action)
	for _frame in 12:
		await physics_frame
	var finish := _player.global_position
	return {
		"action": str(action),
		"start": _vec3(start),
		"finish": _vec3(finish),
		"distance_m": finish.distance_to(start),
		"horizontal_distance_m": Vector2(finish.x - start.x, finish.z - start.z).length(),
		"vertical_delta_m": finish.y - start.y,
		"physics_frames_held": frames,
		"finite": start.is_finite() and finish.is_finite(),
	}


func _orbit_camera_half_turn() -> Dictionary:
	var start_yaw := float(_rig.get("yaw"))
	var frames := 0
	Input.action_press(&"look_right", 1.0)
	while absf(wrapf(float(_rig.get("yaw")) - start_yaw, -PI, PI)) < deg_to_rad(175.0) and frames < ORBIT_MAX_FRAMES:
		await physics_frame
		frames += 1
	Input.action_release(&"look_right")
	for _frame in 18:
		await physics_frame
	var finish_yaw := float(_rig.get("yaw"))
	return {
		"action": "look_right",
		"start_yaw_deg": rad_to_deg(start_yaw),
		"finish_yaw_deg": rad_to_deg(finish_yaw),
		"absolute_yaw_delta_deg": absf(rad_to_deg(wrapf(finish_yaw - start_yaw, -PI, PI))),
		"physics_frames_held": frames,
	}


func _capture_context(frame_id: String, viewed_face: String, motion_receipt: Dictionary) -> void:
	var observed_clock := await _pin_time("day")
	for _frame in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output_dir, frame_id]
	if image == null or image.is_empty() or image.save_png(path) != OK:
		_failures.append("%s: supplemental save failed" % frame_id)
	else:
		_records.append({
			"frame_id": frame_id,
			"file": path,
			"time": "day",
			"observed_clock": observed_clock,
			"viewed_face": viewed_face,
			"ordinary_input_motion": motion_receipt,
			"debug_travel": false,
			"player_position": _vec3(_player.global_position),
			"camera_position": _vec3(_camera.global_position),
			"camera_rig_transform": _transform(_rig.global_transform),
			"camera_transform": _transform(_camera.global_transform),
			"camera_player_distance_m": _camera.global_position.distance_to(_player.global_position),
			"bytes": FileAccess.get_file_as_bytes(path).size(),
		})
		print("CROWN CONTEXT CAPTURE %s -> %s" % [frame_id, path])
	_write_manifest()


func _crown_identity() -> Dictionary:
	var runtime: Node = root.get_tree().get_first_node_in_group("stormwood_arch_runtime")
	var crown := runtime.get_node_or_null(^"e_crown") as Node3D if runtime != null else null
	return {
		"runtime_found": runtime != null,
		"node_found": crown != null,
		"node_path": str(_world.get_path_to(crown)) if crown != null else "",
		"position": _vec3(crown.global_position) if crown != null else [],
		"yaw_deg": rad_to_deg(crown.rotation.y) if crown != null else 0.0,
		"presentation_found": crown != null and crown.get_node_or_null(^"ArchPresentation") != null,
	}
