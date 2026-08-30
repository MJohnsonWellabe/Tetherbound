extends SceneTree

## T2-GATEF-RUN4: S03-60 ("walk past Oskar on the way back") still fails
## after the S03-59a door-staging fix, stopping ~4.3m short at (19.0,-3.0) --
## the SAME stop point BUILDPLACE round 3 recorded walking from Mira's own
## interior position, even though S03-59a starts this leg from OUTSIDE the
## door instead. Since the stop point is identical regardless of start
## position, this traces the walk from a position matching what the real
## S03-59a step actually reaches (15.93, -2.97, per this run's own
## telemetry) straight toward Oskar (22,-6), printing position every few
## frames, to find what fixed geometry sits at/near (19,-3).
##
##   godot --headless --path . --script tools/gate_f/probe_oskar_walk_trace.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 240

var _stick_left := Vector2.ZERO
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: player=%s rig=%s" % [_player, _rig])
		quit(1)
		return

	print("--- from S03-59a's real landing spot (15.93, -2.97) straight to Oskar (22,-6) ---")
	_teleport(Vector3(15.93, 0.9, -2.97))
	for i in 15:
		await physics_frame
	await _traced_walk(Vector3(22.0, 0.9, -6.0), 3000, 3.5)

	print("")
	print("--- candidate fix 2: shop_interior.gd's own counter (local x:[-1.6,0.9], z:[-0.6,-0.1]) sits directly on the straight line from Mira (local 0,-1.4) to the door staging point (local 1,4/5) -- the navigator slides WEST around it into the shelf-vs-wall pocket at local x=-1.37 (world ~18.4to18.8,-3.2to-3.6), which is exactly where every prior attempt got stuck. Route through the door LANE first (local x=1.3, clear of the counter's x<=0.9 edge by 0.4m) at Mira's own z, THEN to the staging point, THEN out. From 2m off Mira (not overlapping her collision -- direct teleport onto her exact tile triggers the unrelated 'entombed' safety net and is not representative).")
	_teleport(Vector3(17.5, 0.9, -1.6))
	for i in 15:
		await physics_frame
	await _traced_walk(Vector3(17.788, 0.9, -0.374), 600, 1.5)
	await _traced_walk(Vector3(13.757, 0.9, -4.828), 800, 2.0)
	await _traced_walk(Vector3(22.0, 0.9, -6.0), 3000, 3.5)

	quit(0)


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
		if walked % 30 == 0:
			print("  t=%d pos=%s gap=%.2f" % [walked, str(_player.global_position), to.length()])
	print("  BUDGET EXHAUSTED at pos=%s (%.2f m short)" % [
		str(_player.global_position), (target - _player.global_position).length()])
	_stick_left = Vector2.ZERO
	_drive()


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
