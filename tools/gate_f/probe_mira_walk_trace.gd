extends SceneTree

## T2-BUILDPLACE round 2: single-boot diagnostic that walks several candidate
## routes into Mira's shop with the SAME `stick_navigator.gd` the real harness
## uses, printing a position trace every few frames so a wall-slide gone wrong
## is visible directly instead of inferred from a FAIL message's own summary.
##
##   godot --headless --path . --script tools/gate_f/probe_mira_walk_trace.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 240

var _stick_left := Vector2.ZERO
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _world: Node = null
var _mira: Node3D = null
var _interactable: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	# Exactly gate_f_probe.gd::camera_rig() -- a DIRECT child of world, not a
	# deep search, which is what the earlier version of this probe got wrong
	# (found some other node and fed the navigator a garbage planar_basis).
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_mira = _find_by_name(root, "Mira") as Node3D
	_interactable = _find_interactable(_mira)
	if _player == null or _rig == null or _mira == null:
		print("PROBE FAIL: player=%s rig=%s mira=%s" % [_player, _rig, _mira])
		quit(1)
		return
	var door := _find_by_script(root, "village_door.gd")
	print("Mira: %s   door: %s (is_open before=%s)" % [
		str(_mira.global_position), str((door as Node3D).global_position) if door else "?",
		str(door.call("is_open")) if door else "?"])
	if door != null and not bool(door.call("is_open")):
		door.call("force_open", true)
		for i in 30:
			await physics_frame
	print("door is_open now: %s" % (str(door.call("is_open")) if door else "?"))

	# Candidate final interior points, local cottage coords converted to world
	# with the same rotation formula village_npcs.json's own comment gives
	# (building at 18,-2, yaw -135), each picked to stand on the CUSTOMER side
	# of shop_interior.gd's counter (local z > -0.1) rather than aim at Mira's
	# own tile (local z=-1.4, behind the counter -- the straight line from the
	# door to HER tile crosses the counter's footprint at local x~0.24-0.55).
	var candidates := {
		"Mira herself (within 2.5, mimics move_to_entity)": _mira.global_position,
	}

	for label: String in candidates:
		var target: Vector3 = candidates[label]
		print("")
		print("--- candidate %s -> world (%.2f, %.2f) ---" % [label, target.x, target.z])
		# Start each attempt from just outside the door, on the door's own
		# approach lane, so this isolates the LAST short leg (door -> Mira)
		# from the long outdoor walk (already proven clean).
		_teleport(_local_to_world(1.0, 5.0))
		for i in 15:
			await physics_frame
		await _traced_walk(target, 900, 2.5)
		var d := _player.global_position.distance_to(_mira.global_position)
		var los: bool = bool(_interactable.call("_has_line_of_sight", _player.global_position + Vector3.UP * 0.0)) if _interactable != null else false
		var offer: Dictionary = _interactable.call("interaction_offer", _player.global_position) if _interactable != null else {}
		print("  final: %s  dist_to_mira=%.2f  los=%s  offer=%s" % [
			str(_player.global_position), d, los, str(offer.get("label", "(none)"))])

	quit(0)


func _local_to_world(lx: float, lz: float) -> Vector3:
	var bx := 18.0
	var bz := -2.0
	var yaw := deg_to_rad(-135.0)
	var wx := bx + lx * cos(yaw) + lz * sin(yaw)
	var wz := bz - lx * sin(yaw) + lz * cos(yaw)
	var y := float(_world.call("ground_height_at", wx, wz)) if _world.has_method("ground_height_at") else 0.9
	return Vector3(wx, y, wz)


func _teleport(pos: Vector3) -> void:
	_player.global_position = pos + Vector3.UP * 0.2
	_player.velocity = Vector3.ZERO


func _traced_walk(target: Vector3, budget: int, close_enough: float = 1.0) -> void:
	var nav: RefCounted = NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick_left = Vector2(x, y); _drive())
	nav.call("reset")
	var walked := 0
	while walked < budget:
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			print("  ARRIVED after %d frames" % walked)
			_stick_left = Vector2.ZERO
			_drive()
			return
		if not bool(nav.call("can_walk")):
			await physics_frame
			continue
		walked += 1
		await nav.call("step", target)
		if walked % 60 == 0:
			print("  t=%d pos=%s gap=%.2f" % [walked, str(_player.global_position), to.length()])
	print("  BUDGET EXHAUSTED at pos=%s (%.2f m short)" % [
		str(_player.global_position), (target - _player.global_position).length()])
	_stick_left = Vector2.ZERO
	_drive()


## Exactly `operator_harness.gd::_drive_sticks()`/`_press_axis()` -- both the
## polled action strength (`player_controller.gd` reads `Input.get_vector()`)
## and the physical joypad event, which is why the real harness sends both.
func _drive() -> void:
	_press_axis(&"move_right", clampf(_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick_left.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick_left.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	var binding := _physical_binding(action)
	var motion := binding as InputEventJoypadMotion
	if motion == null:
		return
	var m := InputEventJoypadMotion.new()
	m.axis = motion.axis
	m.axis_value = signf(motion.axis_value) * strength
	Input.parse_input_event(m)


func _physical_binding(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null


func _find_by_name(node: Node, name: String) -> Node:
	if str(node.name) == name:
		return node
	for child in node.get_children():
		var found := _find_by_name(child, name)
		if found != null:
			return found
	return null


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null


func _find_interactable(node: Node) -> Node:
	if node == null:
		return null
	for child in node.get_children():
		if str(child.name) == "Interactable":
			return child
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("interactable.gd"):
			return child
	return null
