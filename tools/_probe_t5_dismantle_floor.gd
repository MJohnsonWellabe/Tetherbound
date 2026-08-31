extends SceneTree

## AUDIT-H control: does dismantle work on a generic BUILD_PIECE (which DOES
## create a StaticBody3D+CollisionShape3D, unlike creature_bed.gd), to confirm
## the dismantle ray/verb itself works and the creature_bed gap is specific to
## that piece's missing collision body?
##
##   godot --headless --path . --script tools/_probe_t5_dismantle_floor.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PATCH := Vector2(30.0, -40.0)

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
		print("DFLOOR> no BuildPlacer")
		quit(1)
		return

	_game.set("pending_build", "floor")
	for i in 30:
		await physics_frame
	await _pad(_pad_button_for("build_place"))
	for i in 25:
		await physics_frame

	var records: Array = _game.get("placed_buildings") as Array
	if records.is_empty():
		print("DFLOOR> nothing was placed")
		quit(1)
		return
	var last: Dictionary = records.back()
	var lp: Array = last.get("position", [])
	var piece_at := Vector3(float(lp[0]), float(lp[1]), float(lp[2]))
	print("DFLOOR> placed floor at %s, pending_build now = %s" % [str(piece_at), str(_game.get("pending_build"))])

	var back := Vector3(0.0, 0.0, 1.0) * 3.0
	_player.global_position = Vector3(piece_at.x, 0.0, piece_at.z) + back
	_player.global_position.y = float(_world.call("ground_height_at",
		_player.global_position.x, _player.global_position.z)) + 1.0
	_player.global_rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	for i in 45:
		await physics_frame

	var wood_pre := int(inventory.call("count", "wood"))
	var n_pre := (_game.get("placed_buildings") as Array).size()
	await _hold(_pad_button_for("build_dismantle"), 10)
	for i in 30:
		await physics_frame
	var n_post := (_game.get("placed_buildings") as Array).size()
	var refunded := int(inventory.call("count", "wood")) - wood_pre
	if n_post < n_pre:
		print("DFLOOR> PASS -- removed the floor (%d -> %d records), refunded %d wood." % [n_pre, n_post, refunded])
	else:
		print("DFLOOR> FAIL -- still %d record(s) standing, refund %d." % [n_post, refunded])
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
