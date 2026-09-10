extends "res://tools/_capture_stormwood_stormheart_context.gd"

## Production-camera evidence for the actual southern Stormheart road and deck.
## Setup uses one disclosed debug travel to the authored approach foot; every
## evidence pose after that is reached with ordinary left-stick movement and
## framed with ordinary right-stick look input.
##
## godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##   --script tools/capture_stormheart_gameplay_approach.gd -- \
##   --biome=stormwood --subset=glass_field --times=day \
##   --output=res://shots/catalogue/stormwood/<fresh> --launch-head=<sha>

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const APPROACH_FOOT := Vector2(-100.0, 5350.0)
const APPROACH_POSES := [
	{"id": "stormheart_approach_80m", "xz": Vector2(-100.0, 5390.0), "focus_y": 45.0,
		"label": "80m road approach silhouette"},
	{"id": "stormheart_approach_deck_edge", "xz": Vector2(-100.0, 5425.5), "focus_y": 22.0,
		"label": "outer-deck entry and trunk mouth"},
	{"id": "stormheart_approach_40m", "xz": Vector2(-100.0, 5430.0), "focus_y": 20.0,
		"label": "40m deck approach"},
]

var _navigator: RefCounted


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Stormheart gameplay approach requires a rendering display")
		quit(1)
		return
	if not _parse_args() or not _load_plan():
		quit(1)
		return
	if _biome_id != "stormwood" or _planned.size() != 1 or str((_planned[0] as Dictionary).time) != "day":
		push_error("Stormheart gameplay approach requires --biome=stormwood --subset=glass_field --times=day")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	# This subclass captures three physical approach poses instead of its one
	# inherited catalogue-plan row. Keep the top-level accounting truthful.
	_manifest["planned_frame_count"] = APPROACH_POSES.size()
	_manifest["planned_frame_ids"] = APPROACH_POSES.map(
		func(row: Dictionary) -> String: return str(row.id))
	_manifest["supplemental_contract"] = "Production Stormwood, real trainer and production CameraRig. One Settings debug travel to the authored road foot (-100,5350), then ordinary left-stick travel to 80m, the outer-deck edge and 40m from tree centre; ordinary right-stick look frames each view. Day clock pin is audit-only. No actor/camera transform, progression, creature, collision or art mutation."
	_manifest["supplemental_planned_frame_ids"] = APPROACH_POSES.map(
		func(row: Dictionary) -> String: return str(row.id))
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	var tree := _world.get_node_or_null(^"StormheartTree") as Node3D
	if tree == null:
		_failures.append("Production StormheartTree is absent")
		_finish(false)
		return
	_manifest["stormheart_runtime"] = _tree_contract(tree)
	if not await _travel_to_approach_foot():
		_finish(false)
		return
	var banner := await _wait_for_region_banner_clear()
	_manifest["region_banner_clear"] = banner
	if not bool(banner.get("cleared", false)):
		_failures.append("RegionBanner did not clear before approach traverse")
		_finish(false)
		return
	_navigator = NAVIGATOR.new(self, _player, _rig, _drive_stick)
	for raw: Dictionary in APPROACH_POSES:
		var walk := await _walk_to(raw.xz as Vector2)
		if not bool(walk.get("arrived", false)):
			_failures.append("ordinary approach blocked before " + str(raw.id))
			break
		var aim := await _aim_at(tree.global_position + Vector3.UP * float(raw.focus_y))
		if not bool(aim.get("reached", false)):
			_failures.append("ordinary camera look did not frame " + str(raw.id))
			await _capture_context(str(raw.id) + "_aim_failure", str(raw.label) +
				" (diagnostic failed aim retained)", {"walk": walk, "look": aim})
			break
		var centre_distance := Vector2(_player.global_position.x - tree.global_position.x,
			_player.global_position.z - tree.global_position.z).length()
		await _capture_context(str(raw.id), str(raw.label), {
			"walk": walk, "look": aim, "tree_centre_distance_m": centre_distance})
	_manifest["approach_finish"] = _vec3(_player.global_position)
	_finish(_failures.is_empty() and _records.size() == APPROACH_POSES.size())


func _finish(complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["complete"] = complete
	_manifest["captured_frame_count"] = _records.size()
	_manifest["planned_frame_count"] = APPROACH_POSES.size()
	_write_manifest()
	if not complete:
		for failure: String in _failures:
			push_error("Stormheart approach: %s" % failure)
	print("STORMHEART APPROACH %s: %d/%d frames in %s" % [
		"OK" if complete else "FAILED", _records.size(), APPROACH_POSES.size(), _output_dir])
	quit(0 if complete else 1)


func _travel_to_approach_foot() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null or not bool(game.call("debug_teleport_to", APPROACH_FOOT.x,
			APPROACH_FOOT.y, "stormwood", "")):
		_failures.append("Settings debug travel refused the authored Stormheart approach foot")
		return false
	for _frame in 45:
		await physics_frame
	return Vector2(_player.global_position.x, _player.global_position.z).distance_to(APPROACH_FOOT) < 2.0


func _walk_to(xz: Vector2) -> Dictionary:
	var start := _player.global_position
	var target := Vector3(xz.x, start.y, xz.y)
	var budget := maxi(900, ceili(Vector2(start.x, start.z).distance_to(xz) * 70.0))
	var arrived := bool(await _navigator.call("walk_to", target, budget, 1.0))
	_drive_stick(0.0, 0.0)
	for _frame in 12:
		await physics_frame
	return {"arrived": arrived, "start": _vec3(start), "finish": _vec3(_player.global_position),
		"target_xz": [xz.x, xz.y], "physics_frame_budget": budget,
		"on_floor": _player.is_on_floor()}


func _aim_at(target: Vector3) -> Dictionary:
	var start_yaw := float(_rig.get("yaw"))
	var start_pitch := float(_rig.get("pitch"))
	var frames := 0
	while frames < 240:
		var delta := target - _camera.global_position
		var wanted_yaw := atan2(-delta.x, -delta.z)
		var wanted_pitch := atan2(delta.y, maxf(Vector2(delta.x, delta.z).length(), 0.001))
		var yaw_error := wrapf(wanted_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_error := wanted_pitch - float(_rig.get("pitch"))
		_release_look()
		if absf(yaw_error) < deg_to_rad(2.0) and absf(pitch_error) < deg_to_rad(2.0):
			break
		if absf(yaw_error) >= deg_to_rad(2.0):
			# Input.get_vector first removes the action-map 0.20 deadzone and
			# renormalizes the remainder; CameraRig then rejects the resulting
			# vector below 0.18. Raw strength must therefore exceed
			# .20 + .18*(1-.20) = .344. At .36 the production 190 deg/s rate
			# advances about .63 degrees per 60 Hz frame, safely inside this
			# controller's unchanged 2-degree acceptance band.
			var yaw_strength := clampf(absf(rad_to_deg(yaw_error)) / 12.0, 0.36, 0.55)
			Input.action_press(&"look_left" if yaw_error > 0.0 else &"look_right", yaw_strength)
		if absf(pitch_error) >= deg_to_rad(2.0):
			var pitch_strength := clampf(absf(rad_to_deg(pitch_error)) / 12.0, 0.36, 0.55)
			Input.action_press(&"look_up" if pitch_error > 0.0 else &"look_down", pitch_strength)
		await physics_frame
		frames += 1
	_release_look()
	for _frame in 12:
		await physics_frame
	var final_delta := target - _camera.global_position
	var final_yaw := atan2(-final_delta.x, -final_delta.z)
	var final_pitch := atan2(final_delta.y,
		maxf(Vector2(final_delta.x, final_delta.z).length(), 0.001))
	var yaw_error := wrapf(final_yaw - float(_rig.get("yaw")), -PI, PI)
	var pitch_error := final_pitch - float(_rig.get("pitch"))
	return {"reached": absf(yaw_error) < deg_to_rad(2.0) and absf(pitch_error) < deg_to_rad(2.0),
		"target": _vec3(target), "start_yaw_deg": rad_to_deg(start_yaw),
		"start_pitch_deg": rad_to_deg(start_pitch), "end_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"end_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"desired_yaw_deg": rad_to_deg(final_yaw), "desired_pitch_deg": rad_to_deg(final_pitch),
		"yaw_error_deg": rad_to_deg(yaw_error), "pitch_error_deg": rad_to_deg(pitch_error),
		"production_pitch_limits_deg": [-60.0, 32.0], "physics_frames": frames}


func _tree_contract(tree: Node3D) -> Dictionary:
	var static_bodies := tree.find_children("*", "StaticBody3D", true, false)
	var colliders := tree.find_children("*", "CollisionShape3D", true, false)
	return {"path": str(tree.get_path()), "position": _vec3(tree.global_position),
		"static_body_count": static_bodies.size(), "collision_shape_count": colliders.size(),
		"outer_deck_radius_m": 44.0,
		"outer_deck_radius_source": "stormheart_tree.gd::OUTER_WORKS_OUTER_RADIUS"}


func _drive_stick(x: float, y: float) -> void:
	for action: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		Input.action_release(action)
	if y < -0.2:
		Input.action_press(&"move_forward", -y)
	elif y > 0.2:
		Input.action_press(&"move_back", y)
	if x < -0.2:
		Input.action_press(&"move_left", -x)
	elif x > 0.2:
		Input.action_press(&"move_right", x)


func _release_look() -> void:
	for action: StringName in [&"look_left", &"look_right", &"look_up", &"look_down"]:
		Input.action_release(action)
