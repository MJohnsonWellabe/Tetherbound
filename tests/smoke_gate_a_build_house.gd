extends SceneTree

## Focused Gate A production-path proof for the construction integration seam.
## Placement/dismantle presses begin as physical joypad events read from the
## live InputMap; the harness stages ordinary paid inventory, never Free Build.

const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

var _game: Node
var _world: Node3D
var _player: Node3D
var _placer: Node
var _camera: Camera3D
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_finish()
		return
	_game.set("pending_build", "")
	_game.set("free_build", false)
	_game.set("placed_buildings", [])
	_stock_paid_materials()

	_world = FlatWorld.new()
	root.add_child(_world)
	_player = Node3D.new()
	_player.name = "Player"
	_world.add_child(_player)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.current = true
	_world.add_child(_camera)
	_placer = BUILD_PLACER.new()
	_placer.name = "BuildPlacer"
	_placer.set("player_path", NodePath("../Player"))
	_world.add_child(_placer)
	await physics_frame

	await _build_paid_modular_sample()
	await _dismantle_exact_middle_piece()
	await _cancel_returns_control()
	_finish()


func _stock_paid_materials() -> void:
	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 200)


func _arm(id: String) -> void:
	_game.set("pending_build", id)
	for i in 3:
		await process_frame


func _aim_candidate(position: Vector3) -> void:
	# The production placer projects exactly 3m down the player's -Z axis.
	_player.global_position = position + Vector3(0.0, 0.0, 3.0)
	_player.global_rotation = Vector3.ZERO
	await process_frame
	await process_frame


func _place_at(id: String, candidate: Vector3) -> void:
	if str(_game.get("pending_build")) != id:
		await _arm(id)
	await _aim_candidate(candidate)
	await _tap_action("build_place")
	await physics_frame


func _build_paid_modular_sample() -> void:
	var start := int((_game.get("placed_buildings") as Array).size())
	for position in [Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(2, 0, 2)]:
		await _place_at("floor", position)
	if int((_game.get("placed_buildings") as Array).size()) != start + 4:
		_fail("four fresh controller Place edges did not create a persistent 2x2 floor selection")
	if str(_game.get("pending_build")) != "floor":
		_fail("repeat placement lost the selected floor after the 2x2 footprint")

	# One outer support per tile; reserve the first tile's north edge for Door.
	await _place_at("door", Vector3(0, 0, -1))
	await _place_at("wall", Vector3(2, 0, -1))
	await _place_at("wall", Vector3(0, 0, 3))
	await _place_at("wall", Vector3(2, 0, 3))
	for position in [Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(2, 0, 2)]:
		await _place_at("roof", position)

	var records: Array = _game.get("placed_buildings") as Array
	var roof_count := 0
	var door_ok := false
	for raw: Variant in records:
		var record := raw as Dictionary
		var p: Array = record.get("position", [])
		if str(record.get("id", "")) == "roof":
			roof_count += 1
			if p.size() == 3 and absf(float(p[1]) - 3.05) > 0.001:
				_fail("production roof placement ignored the wall-top anchor: %s" % [p])
		if str(record.get("id", "")) == "door" and p.size() == 3:
			door_ok = absf(float(p[2]) + 1.0) < 0.001
	if roof_count != 4:
		_fail("expected four supported roof pieces, got %d" % roof_count)
	if not door_ok:
		_fail("door did not occupy the shared wall edge at z=-1")
	else:
		print("paid controller build: 2x2 floor + shared door/walls + four wall-top roofs")


func _dismantle_exact_middle_piece() -> void:
	# Isolate three surviving-neighbour records. Using production spawn/registry
	# keeps the same metadata/index contract save/load uses.
	_game.set("pending_build", "")
	_game.set("placed_buildings", [])
	_placer.call("restore_from_game", _game)
	await physics_frame
	for position in [Vector3(-2, 0, 0), Vector3(0, 0, 0), Vector3(2, 0, 0)]:
		var index := int((_game.get("placed_buildings") as Array).size())
		var node: Node3D = _placer.call("_spawn_building", _game, "floor", 0.0, index)
		node.global_position = position
		_game.call("register_building", "floor", position, 0.0, true)
	await physics_frame

	_camera.global_position = Vector3(0.0, 3.0, 5.0)
	_camera.look_at(Vector3.ZERO)
	await _arm("floor")
	var stone_before := int(_game.get("inventory").call("count", "stone"))
	await _tap_action("build_dismantle")
	await physics_frame
	var records: Array = _game.get("placed_buildings") as Array
	if records.size() != 2:
		_fail("controller dismantle did not remove exactly one registry entry (got %d)" % records.size())
	else:
		var xs := [float((records[0] as Dictionary).position[0]), float((records[1] as Dictionary).position[0])]
		if xs != [-2.0, 2.0]:
			_fail("dismantle removed a neighbour instead of the aimed middle floor: %s" % [xs])
	if int(_game.get("inventory").call("count", "stone")) != stone_before + 4:
		_fail("paid floor dismantle did not refund its full four stone exactly once")
	else:
		print("controller dismantle: exact middle piece removed; neighbours survive; full refund")


func _cancel_returns_control() -> void:
	await _arm("wall")
	await _tap_action("build_cancel")
	await physics_frame
	if not str(_game.get("pending_build")).is_empty():
		_fail("build Cancel left a selected ghost armed")
	if paused:
		_fail("build Cancel paused/froze the world instead of returning control")
	else:
		print("build Cancel: ghost cleared and unpaused world control returned")


func _tap_action(action: String) -> void:
	var binding: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			binding = event
			break
	if binding == null:
		_fail("%s has no physical joypad binding" % action)
		return
	if binding is InputEventJoypadButton:
		var down := InputEventJoypadButton.new()
		down.button_index = (binding as InputEventJoypadButton).button_index
		down.pressed = true
		Input.parse_input_event(down)
		Input.flush_buffered_events()
		await create_timer(0.15).timeout
		if action == "build_dismantle":
			# SceneTree script harnesses do not schedule sibling Node physics while
			# their timer coroutine owns the loop consistently on Windows headless.
			# Tick the production poller once while the real InputMap-backed Y event
			# is physically held; no transaction helper is called or bypassed.
			if not Input.is_action_pressed(action):
				_fail("physical joypad Y did not reach build_dismantle through InputMap")
			# A prior unscheduled headless tick can observe the press without the
			# aimed physics world; reset only the poller's edge latch, then tick the
			# exact production input/target/transaction path with Y still held.
			_placer.set("_dismantle_pressed_last", false)
			_placer.call("_physics_process", 0.0)
		var up := down.duplicate() as InputEventJoypadButton
		up.pressed = false
		Input.parse_input_event(up)
		Input.flush_buffered_events()
	else:
		var down := InputEventJoypadMotion.new()
		down.axis = (binding as InputEventJoypadMotion).axis
		down.axis_value = (binding as InputEventJoypadMotion).axis_value
		Input.parse_input_event(down)
		Input.flush_buffered_events()
		await create_timer(0.15).timeout
		var up := down.duplicate() as InputEventJoypadMotion
		up.axis_value = 0.0
		Input.parse_input_event(up)
		Input.flush_buffered_events()
	await create_timer(0.05).timeout


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	_game.set("pending_build", "")
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _failures.is_empty():
		print("GATE A BUILD HOUSE SMOKE: PASS")
		quit(0)
	else:
		print("GATE A BUILD HOUSE SMOKE: FAIL (%d)" % _failures.size())
		for failure in _failures:
			print("  - %s" % failure)
		quit(1)
