extends SceneTree

## AUDIT-H probe: does the dismantle step in `tools/_play_t5_deaths.gd` leave
## state behind that breaks the fall right after it? `tools/_probe_t5_falldrop.gd`
## showed a clean 120m drop falls correctly on its own; this repeats the same
## drop AFTER the same build/dismantle sequence `_play_t5_deaths.gd` runs first,
## to isolate whether the dismantle step is the cause.
##
##   godot --headless --path . --script tools/_probe_t5_falldrop2.gd

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
	await _dismantle()

	print("T5FALL2> post-dismantle pos %s on_floor=%s carried=%s locomotion_enabled=%s tree_paused=%s" % [
		str(_player.global_position), str(_player.is_on_floor()),
		str(_player.get("_carried")), str(_player.get("_locomotion_enabled")), str(self.paused)])
	var owner_node := INPUT_OWNER.current(self)
	print("T5FALL2> input owner: %s" % [str(owner_node.name) if owner_node != null else "<none>"])

	await _stand(PATCH)
	print("T5FALL2> post-_stand(PATCH) pos %s on_floor=%s" % [str(_player.global_position), str(_player.is_on_floor())])

	var from := _player.global_position
	_player.global_position = from + Vector3.UP * 120.0
	_player.velocity = Vector3.ZERO
	print("T5FALL2> teleported to %s" % str(_player.global_position))
	for f in 20:
		await physics_frame
		print("T5FALL2> frame %2d pos (%.2f, %.2f, %.2f) vel %s on_floor=%s" % [
			f, _player.global_position.x, _player.global_position.y, _player.global_position.z,
			str(_player.velocity), str(_player.is_on_floor())])
	quit(0)


func _stand(xz: Vector2) -> void:
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	_player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	_player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame


func _dismantle() -> void:
	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 200)
	var placer := _find_placer()
	if placer == null:
		print("T5FALL2> no BuildPlacer")
		return
	_game.set("pending_build", "creature_bed")
	for i in 30:
		await physics_frame
	var ghost: Node3D = placer.get("_ghost") as Node3D
	if ghost == null:
		print("T5FALL2> arming produced no ghost")
		return
	await _pad(_pad_button_for("build_place"))
	for i in 25:
		await physics_frame
	_game.set("pending_build", "")
	for i in 15:
		await physics_frame

	var records: Array = _game.get("placed_buildings") as Array
	if records.is_empty():
		print("T5FALL2> nothing was placed")
		return
	var last: Dictionary = records.back()
	var lp: Array = last.get("position", [])
	var piece_at := Vector3(float(lp[0]), float(lp[1]), float(lp[2]))

	var back := Vector3(0.0, 0.0, 1.0) * 3.0
	_player.global_position = Vector3(piece_at.x, 0.0, piece_at.z) + back
	_player.global_position.y = float(_world.call("ground_height_at",
		_player.global_position.x, _player.global_position.z)) + 1.0
	_player.global_rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	for i in 45:
		await physics_frame
	await _hold(_pad_button_for("build_dismantle"), 60)
	for i in 30:
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
