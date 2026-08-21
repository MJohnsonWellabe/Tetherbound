extends SceneTree

## Targeted Gate A reproduction for the controller catch seam.
##
## The fixture skips only the already-covered opening/travel ceremony: it gives
## the world the starter and orbs Grandpa would have supplied and starts beside
## the authored practice cluster. From there every combat action is a parsed
## physical controller event. The test never assigns combatant HP, camera yaw or
## camera pitch, and never calls catch resolution. It must naturally weaken the
## wild creature, make an intentional physical miss, then track the moving target
## with the right stick and complete a physical hit/catch outcome.
##
##   godot --headless --path . --script tests/smoke_controller_catching.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null
var _misses := 0
var _resolutions: Array[bool] = []
const NATURAL_OPENING_ENGAGE_DISTANCE := 5.72


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for _i in 300:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _game == null or _player == null or _rig == null or _manager == null or _director == null:
		_fail("production world is missing a catch dependency")
		_finish()
		return

	await _fixture_opening_rewards_and_short_travel()
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_fail("authored practice cluster produced no wild creature")
		_finish()
		return
	_manager.connect("catch_refused", _on_catch_refused)
	_manager.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _resolutions.append(success))

	if not await _walk_to_and_engage():
		_finish()
		return
	_ally = _director.call("ally_body") as Node3D
	if not await _naturally_weaken_target():
		_finish()
		return

	if not await _intentional_physical_miss():
		_finish()
		return
	var resolved_before := _resolutions.size()
	var caught := false
	for attempt in 8:
		if not bool(_manager.call("is_fighting")):
			break
		if not await _open_aim():
			continue
		if not await _track_target_with_right_stick(360):
			_fail("full right-stick deflection could not catch a naturally circling target")
			break
		var outcomes_before := _misses + _resolutions.size()
		await _tap_button(JOY_BUTTON_RIGHT_SHOULDER)
		for _i in 900:
			if _misses + _resolutions.size() > outcomes_before or not bool(_manager.call("is_fighting")):
				break
			await physics_frame
		if _resolutions.size() > resolved_before and _resolutions[-1]:
			caught = true
			print("controller catch: moving-target throw caught on attempt %d" % (attempt + 1))
			break
	if not caught:
		_fail("physical right-stick throws did not complete a catch within eight attempts")
	elif _misses + _resolutions.size() < 2:
		_fail("fewer than two physical throw outcomes completed")
	_finish()


func _fixture_opening_rewards_and_short_travel() -> void:
	# Fixture only: the title/opening smokes own the ceremony. This leaves all
	# combat, damage, aiming, projectile and resolution behavior untouched.
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	var inventory: RefCounted = _game.get("inventory")
	var short := 15 - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO


func _walk_to_and_engage() -> bool:
	var range_value := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for _i in 1500:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		# Mirror the continuous opening's measured interaction geometry. The
		# smaller historical fixture stopped at 3.6m, while the real opening
		# engaged at 5.72m; that extra flight time is exactly the condition this
		# regression is meant to preserve.
		if to.length() <= minf(range_value * 0.98, NATURAL_OPENING_ENGAGE_DISTANCE):
			_stop_left_stick()
			break
		_drive_stick_toward(_player, _wild.global_position)
		await physics_frame
	_stop_left_stick()
	print("controller catch: mirrored opening engage distance %.2fm" % _player.global_position.distance_to(_wild.global_position))
	await _tap_action(&"interact")
	for _i in 120:
		if bool(_manager.call("is_fighting")):
			return true
		await physics_frame
	_fail("physical Interact did not start combat")
	return false


func _naturally_weaken_target() -> bool:
	var foe: RefCounted = _manager.call("enemy")
	var own: RefCounted = _manager.call("active_creature")
	for i in 1800:
		if not bool(_manager.call("is_fighting")) or own.fainted:
			break
		if float(foe.hp) <= float(foe.max_hp) * 0.28:
			print("controller catch: naturally weakened to %.0f/%d HP" % [foe.hp, foe.max_hp])
			_stop_left_stick()
			return true
		_drive_stick_toward(_ally, _wild.global_position)
		if _ally.global_position.distance_to(_wild.global_position) < 4.0 and i % 35 == 0:
			await _tap_action(&"combat_quick")
		else:
			await physics_frame
	_stop_left_stick()
	_fail("parsed controller attacks did not naturally weaken the target")
	return false


func _intentional_physical_miss() -> bool:
	if not await _open_aim():
		_fail("physical shoulder input did not open catch aim")
		return false
	# A full second turns well away from the creature through the same raw right
	# stick path a player uses, without assigning the camera's angles.
	_send_axis(JOY_AXIS_RIGHT_X, 1.0)
	for _i in 70:
		await physics_frame
	_stop_right_stick()
	var outcomes_before := _misses + _resolutions.size()
	await _tap_button(JOY_BUTTON_RIGHT_SHOULDER)
	for _i in 360:
		if _misses + _resolutions.size() > outcomes_before:
			print("controller catch: intentional physical miss resolved")
			return true
		await physics_frame
	_fail("intentional physical throw never resolved")
	return false


func _open_aim() -> bool:
	for _attempt in 18:
		await _tap_button(JOY_BUTTON_RIGHT_SHOULDER)
		for _i in 6:
			if bool(_manager.call("is_aiming")):
				return true
			await physics_frame
	return false


func _track_target_with_right_stick(budget: int) -> bool:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return false
	for _i in budget:
		var velocity := Vector3.ZERO
		if _wild is CharacterBody3D:
			velocity = (_wild as CharacterBody3D).velocity
		var predicted := (_wild.call("centre") as Vector3) + velocity * 0.30
		var to := predicted - camera.global_position
		var desired_yaw := atan2(-to.x, -to.z)
		var desired_pitch := atan2(to.y, maxf(Vector2(to.x, to.z).length(), 0.01))
		var yaw_error := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_error := desired_pitch - float(_rig.get("pitch"))
		if absf(yaw_error) < deg_to_rad(3.0) and absf(pitch_error) < deg_to_rad(3.0):
			_stop_right_stick()
			return true
		_send_axis(JOY_AXIS_RIGHT_X, -signf(yaw_error))
		_send_axis(JOY_AXIS_RIGHT_Y, -signf(pitch_error))
		await physics_frame
	_stop_right_stick()
	return false


func _drive_stick_toward(body: Node3D, point: Vector3) -> void:
	var direction := point - body.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		_stop_left_stick()
		return
	var local := (_rig.call("planar_basis") as Basis).inverse() * direction.normalized()
	_send_axis(JOY_AXIS_LEFT_X, local.x)
	_send_axis(JOY_AXIS_LEFT_Y, local.z)


func _tap_button(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	Input.parse_input_event(event)
	for _i in 3:
		await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for _i in 5:
		await physics_frame


func _tap_action(action: StringName) -> void:
	for configured in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			await _tap_button((configured as InputEventJoypadButton).button_index)
			return
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.device = 0
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value
			Input.parse_input_event(motion)
			for _i in 3:
				await physics_frame
			motion.axis_value = 0.0
			Input.parse_input_event(motion)
			for _i in 5:
				await physics_frame
			return
	_fail("action '%s' has no physical controller binding" % action)


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_left_stick() -> void:
	_send_axis(JOY_AXIS_LEFT_X, 0.0)
	_send_axis(JOY_AXIS_LEFT_Y, 0.0)


func _stop_right_stick() -> void:
	_send_axis(JOY_AXIS_RIGHT_X, 0.0)
	_send_axis(JOY_AXIS_RIGHT_Y, 0.0)


func _on_catch_refused(reason: String) -> void:
	if reason == "the orb went wide":
		_misses += 1


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	_stop_left_stick()
	_stop_right_stick()
	if _failures.is_empty():
		print("controller catching: OK — natural damage and two physical throw outcomes completed")
	else:
		for message in _failures:
			print("controller catching FAIL: %s" % message)
	quit(0 if _failures.is_empty() else 1)
