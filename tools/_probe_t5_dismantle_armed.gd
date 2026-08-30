extends SceneTree

## AUDIT-H probe: does dismantle work if the player stays ARMED (a piece
## still selected in the build catalogue) while aiming at an already-placed
## piece and pressing Y? `build_placer.gd::_physics_process` only reaches its
## DISMANTLE_ACTION handling when `pending_build != ""` (see build_placer.gd
## line 220's early return) -- this checks whether that is a usable, if
## unintuitive, path, or whether dismantle is unreachable altogether.
##
##   godot --headless --path . --script tools/_probe_t5_dismantle_armed.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PATCH := Vector2(30.0, -40.0)
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

var _game: Node
var _world: Node3D
var _player: CharacterBody3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	await _stand(PATCH)

	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 200)
	var placer := _find_placer()
	if placer == null:
		print("DISMANTLE-ARMED> no BuildPlacer")
		quit(1)
		return

	# Place a piece, same as _play_t5_deaths.gd, but this time DO NOT clear
	# pending_build afterward -- stay armed with the same piece type.
	_game.set("pending_build", "creature_bed")
	for i in 30:
		await physics_frame
	await _pad(_pad_button_for("build_place"))
	for i in 25:
		await physics_frame

	var records: Array = _game.get("placed_buildings") as Array
	if records.is_empty():
		print("DISMANTLE-ARMED> nothing was placed")
		quit(1)
		return
	var last: Dictionary = records.back()
	var lp: Array = last.get("position", [])
	var piece_at := Vector3(float(lp[0]), float(lp[1]), float(lp[2]))
	print("DISMANTLE-ARMED> placed at %s, pending_build now = %s" % [str(piece_at), str(_game.get("pending_build"))])

	var back := Vector3(0.0, 0.0, 1.0) * 1.2
	_player.global_position = Vector3(piece_at.x, 0.0, piece_at.z) + back
	_player.global_position.y = float(_world.call("ground_height_at",
		_player.global_position.x, _player.global_position.z)) + 1.0
	_player.global_rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	var rig := _world.get_node_or_null(^"CameraRig")
	if rig != null:
		print("DISMANTLE-ARMED> camera rig yaw before = %s" % str(rig.get("yaw")))
		rig.set("yaw", 0.0)
	for i in 45:
		await physics_frame
	if rig != null:
		print("DISMANTLE-ARMED> camera rig yaw after settle = %s, global_pos = %s" % [
			str(rig.get("yaw")), str(rig.global_position)])

	var wood_pre := int(inventory.call("count", "wood"))
	var n_pre := (_game.get("placed_buildings") as Array).size()
	var target: Variant = placer.get("_dismantle_target")
	print("DISMANTLE-ARMED> still armed with pending_build=%s; dismantle target = %s" % [
		str(_game.get("pending_build")), "<none>" if target == null else str((target as Node).name)])
	var cam := root.get_camera_3d()
	print("DISMANTLE-ARMED> active camera = %s" % [str(cam.name) if cam != null else "<none>"])
	var input_owner_current: Variant = INPUT_OWNER.current(self)
	print("DISMANTLE-ARMED> INPUT_OWNER.current() = %s" % [
		str((input_owner_current as Node).name) if input_owner_current != null else "<none>"])
	if cam != null:
		var centre := root.get_visible_rect().size * 0.5
		var from := cam.project_ray_origin(centre)
		var to := from + cam.project_ray_normal(centre) * 8.0
		print("DISMANTLE-ARMED> ray from %s to %s (piece at %s)" % [str(from), str(to), str(piece_at)])
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		var hit: Dictionary = _world.get_world_3d().direct_space_state.intersect_ray(query)
		print("DISMANTLE-ARMED> raw ray hit (no exclusions) = %s" % str(hit))
		var query2 := PhysicsRayQueryParameters3D.create(from, to)
		query2.collide_with_areas = false
		var excl: Array[RID] = []
		if _player is CollisionObject3D:
			excl.append((_player as CollisionObject3D).get_rid())
		query2.exclude = excl
		var hit2: Dictionary = _world.get_world_3d().direct_space_state.intersect_ray(query2)
		print("DISMANTLE-ARMED> ray hit (player excluded) = %s" % str(hit2))
		if hit2.has("collider"):
			var c: Node = hit2["collider"] as Node
			var walk: Node = c
			var groups: Array[String] = []
			while walk != null:
				groups.append("%s in placed_group=%s" % [walk.name, str(walk.is_in_group("placed_building"))])
				walk = walk.get_parent()
			print("DISMANTLE-ARMED> collider chain: %s" % str(groups))
	placer.call("_update_dismantle_target")
	print("DISMANTLE-ARMED> after manual _update_dismantle_target(): target = %s" % [
		"<none>" if placer.get("_dismantle_target") == null else str((placer.get("_dismantle_target") as Node).name)])

	await _hold(_pad_button_for("build_dismantle"), 10)
	for i in 30:
		await physics_frame
	var n_post := (_game.get("placed_buildings") as Array).size()
	var refunded := int(inventory.call("count", "wood")) - wood_pre
	if n_post < n_pre:
		print("DISMANTLE-ARMED> PASS -- removed a piece (%d -> %d records), refunded %d wood." % [n_pre, n_post, refunded])
	else:
		print("DISMANTLE-ARMED> FAIL -- still %d record(s) standing, refund %d." % [n_post, refunded])
	print("DISMANTLE-ARMED> tree_paused=%s" % str(self.paused))
	quit(0)


func _stand(xz: Vector2) -> void:
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	_player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	_player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame


func _find_placer() -> Node:
	for node in _world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("build_placer.gd"):
			return node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _pad(button_index: int) -> void:
	await _hold(button_index, 2)


func _hold(button_index: int, frames: int) -> void:
	if button_index < 0:
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in frames:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 6:
		await physics_frame
