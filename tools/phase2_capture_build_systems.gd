extends "res://tools/phase2_capture_locations.gd"

## Production-scene visual fixture for placed camp, bed, building and craft
## station presentation. Uses BuildPlacer._spawn_building, the production
## player and camera, and the production CraftPanel. No build costs, placement
## validation, sleep, recipe execution, save or progression are demonstrated.

const OPEN_STANDS := {
	"meadows": Vector2(9.0, 1300.0),
	"water": Vector2(35.707, 98.104),
	"cloudreach": Vector2(-15.5, -202.0),
	"stormwood": Vector2(-320.0, 240.0),
}

func _load_plan() -> bool:
	_planned = [{"frame_id": "%s__system__build_suite" % _biome_id}]
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixture_disclosure"] = "Visual-only production-scene fixture: player debug-travels to an open authored spot; BuildPlacer creates real tent, campfire, bedroll, floor, wall and workbench nodes near the player; CraftPanel opened directly. No placement cost, interaction, sleep, recipe result or saved state proof."


func _finish(_complete: bool) -> void:
	super._finish(_failures.is_empty() and _records.size() == 4)


func _capture_row(_row: Dictionary) -> void:
	var game := root.get_node_or_null(^"Game")
	var placer := _world.find_child("BuildPlacer", true, false)
	if game == null or placer == null or not placer.has_method("_spawn_building"):
		_failures.append("production BuildPlacer unavailable")
		return
	var stand: Vector2 = OPEN_STANDS[_biome_id]
	if not bool(game.call("debug_teleport_to", stand.x, stand.y, _biome_id, "")):
		_failures.append("debug travel to open build stand failed")
		return
	for _frame in ARRIVE_FRAMES:
		await physics_frame
	var stand_y := float(_world.call("ground_height_at", stand.x, stand.y))
	if is_nan(stand_y):
		_failures.append("open build stand has no terrain")
		return
	_player.global_position = Vector3(stand.x, stand_y + TRAINER_CLEARANCE, stand.y)
	_player.velocity = Vector3.ZERO
	var heading := Vector2(0.0, 1.0)
	var yaw := capture_yaw(heading)
	_player.rotation.y = atan2(heading.x, heading.y)
	_rig.call("set_target", _player)
	_rig.set("pitch", deg_to_rad(-12.0))
	_rig.set("yaw", yaw)
	_rig.rotation = Vector3(deg_to_rad(-12.0), yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in POPULATE_FRAMES:
		await physics_frame
	var observed := await _pin_time("day")
	if observed.is_empty():
		return
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length() < 0.5:
		forward = Vector3.FORWARD
	var side := Vector3(-forward.z, 0.0, forward.x)
	var anchor := _player.global_position + forward * 5.0
	var ground := float(_world.call("ground_height_at", anchor.x, anchor.z))
	if is_nan(ground):
		ground = _player.global_position.y - 0.3
	anchor.y = ground
	var active: Array[Node3D] = []
	var tent := _place(placer, game, "tent", anchor, active)
	_place(placer, game, "campfire", anchor + side * 3.0, active)
	if tent == null:
		_failures.append("tent could not be created")
		return
	await _settle()
	await _shoot("camp", "camp", "placed camp tent and campfire visual fixture")
	_place(placer, game, "bedroll", anchor, active)
	await _settle()
	await _shoot("bed", "bed", "placed bedroll in production tent visual fixture")
	_clear(active)
	await _settle()
	_place(placer, game, "floor", anchor, active)
	_place(placer, game, "wall", anchor + side * 2.0, active)
	await _settle()
	await _shoot("building", "building", "placed floor and wall visual fixture")
	_clear(active)
	await _settle()
	_place(placer, game, "workbench", anchor, active)
	await _settle()
	placer.call("_open_craft_panel")
	await _settle()
	await _shoot("crafting", "crafting", "workbench and production CraftPanel directly opened")
	_write_manifest()


func _place(placer: Node, game: Node, id: String, at: Vector3, active: Array[Node3D]) -> Node3D:
	var piece := placer.call("_spawn_building", game, id) as Node3D
	if piece == null:
		_failures.append("failed to create %s" % id)
		return null
	piece.global_position = at
	active.append(piece)
	return piece


func _clear(active: Array[Node3D]) -> void:
	for piece: Node3D in active:
		if is_instance_valid(piece):
			piece.queue_free()
	active.clear()


func _settle() -> void:
	for _frame in 16:
		await physics_frame
	for _frame in 3:
		await process_frame


func _shoot(state: String, system: String, note: String) -> void:
	_hide_hud()
	if state == "crafting":
		var panel := root.get_node_or_null(^"CraftPanel") as CanvasLayer
		if panel != null:
			panel.visible = true
	await RenderingServer.frame_post_draw
	var frame_id := "%s__system__%s" % [_biome_id, state]
	var path := "%s/%s.jpg" % [_output_dir, frame_id]
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: viewport save failed" % frame_id)
		return
	_records.append({
		"frame_id": frame_id, "identity": "%s__system__build_suite" % _biome_id,
		"destination_display_name": system, "system": system, "view": "ui" if state == "crafting" else "normal",
		"time": "day", "file": path, "note": note,
		"player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position),
	})
	_write_manifest()
