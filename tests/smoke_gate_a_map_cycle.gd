extends SceneTree

## Gate A checkpoints 7 and 12 through the real Meadows input paths.
##
## This intentionally sends physical joypad events. `Input.action_press()` can
## make a poll-driven test pass when the controller binding printed to the
## player is absent or conflicts with another owner.
##
##   godot --headless --path . --script tests/smoke_gate_a_map_cycle.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _party: RefCounted = null
var _director: Node = null
var _player: CharacterBody3D = null
var _minimap: Control = null
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	var hud := _world.get_node_or_null(^"PlaygroundHUD")
	_minimap = hud.get("_minimap") as Control if hud != null else null
	_menu = _game.call("menu") as CanvasLayer if _game != null else null
	_party = _game.get("party") as RefCounted if _game != null else null
	if _game == null or _director == null or _player == null or _minimap == null \
			or _menu == null or _party == null:
		_fail("real Meadows boot is missing Game/director/player/HUD minimap/menu/party")
		_report()
		return

	await _check_real_pad_party_cycle()
	await _check_actual_travel_drives_minimap()
	await _check_full_map_controller_ownership_and_recovery()
	_report()


func _check_real_pad_party_cycle() -> void:
	_party.call("clear")
	for id in ["terrapup", "ripplet", "galewisp", "tuskroot", "meadowhart"]:
		var creature: RefCounted = SPECIES.spawn(id)
		if creature == null or not bool(_party.call("add", creature)):
			_fail("could not seed the five owned creatures needed for live cycling")
			return
	var sixth: RefCounted = SPECIES.spawn("bramblebun")
	if bool(_party.call("add", sixth)) or int(_party.call("size")) != 5:
		_fail("controller-cycle setup bypassed the five-creature ownership cap")
		return

	# An unavailable second slot must be skipped by the real Next Pal binding.
	_party.call("set_resting", 1, true, 91)
	await _press_action("combat_switch_right")
	if int(_party.call("active_index")) != 2:
		_fail("physical Next Pal did not skip the resting slot (active=%d)" % int(_party.call("active_index")))
		return
	_party.call("set_resting", 1, false)

	# Continue through every owned slot and wrap, then prove Previous wraps back.
	for expected in [3, 4, 0, 1, 2]:
		await _press_action("combat_switch_right")
		if int(_party.call("active_index")) != expected:
			_fail("physical Next Pal expected slot %d, got %d" % [expected, int(_party.call("active_index"))])
			return
	await _press_action("combat_switch_left")
	if int(_party.call("active_index")) != 1:
		_fail("physical Previous Pal did not cycle backward (active=%d)" % int(_party.call("active_index")))
		return
	print("  ok    real pad Previous/Next cycles five owned creatures, wraps, and skips resting")


func _check_actual_travel_drives_minimap() -> void:
	# Let the HUD establish its initial stationary sample, then move through the
	# real left-stick binding. The expected heading comes from resolved world
	# displacement, never from camera yaw or the requested stick vector.
	for i in 8:
		await physics_frame
	var before := _player.global_position
	await _hold_axis(JOY_AXIS_LEFT_X, 1.0, 70)
	var after := _player.global_position
	var displacement := Vector2(after.x - before.x, after.z - before.z)
	if displacement.length() < 0.5:
		_fail("physical left stick did not move the trainer; minimap travel cannot be proven")
		return
	var expected := atan2(displacement.x, displacement.y)
	var movement_yaw := float(_minimap.get("_movement_yaw"))
	if absf(angle_difference(expected, movement_yaw)) > 0.12:
		_fail("minimap heading %.3f does not match resolved travel %.3f" % [movement_yaw, expected])
		return

	# Orbit with the real right stick while standing still. World orientation
	# must retain travel-up; the independently drawn look marker must change.
	var retained := movement_yaw
	var look_before := float(_minimap.get("_look_yaw"))
	await _hold_axis(JOY_AXIS_RIGHT_X, 1.0, 35)
	var look_after := float(_minimap.get("_look_yaw"))
	if absf(angle_difference(retained, float(_minimap.get("_movement_yaw")))) > 0.02:
		_fail("stationary camera orbit rotated the movement-up map")
	elif absf(angle_difference(look_before, look_after)) < 0.15:
		_fail("physical right stick did not update the minimap's independent look heading")
	else:
		print("  ok    resolved travel stays map-up while stationary right-stick look remains independent")


func _check_full_map_controller_ownership_and_recovery() -> void:
	await _press_action("map")
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "map":
		_fail("physical Map button did not open the full map tab")
		return
	if not paused:
		_fail("full map opened without owning/pause-protecting world input")
		return

	var active_before := int(_party.call("active_index"))
	await _press_action("combat_switch_right")
	if int(_party.call("active_index")) != active_before:
		_fail("party cycling leaked through while the full map owned input")

	await _press_action("menu_cancel")
	if bool(_menu.call("is_open")) or paused:
		_fail("physical Back did not close the full map and release pause ownership")
		return
	var before := _player.global_position
	await _hold_axis(JOY_AXIS_LEFT_Y, -1.0, 55)
	if _player.global_position.distance_to(before) < 0.5:
		_fail("world movement did not recover after closing the full map")
	else:
		print("  ok    physical Map/Back opens and closes the north-up full map; world control recovers cleanly")


func _press_action(action: String) -> void:
	var index := _button_for(action)
	if index < 0:
		_fail("'%s' has no physical joypad button binding" % action)
		return
	var down := InputEventJoypadButton.new()
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


func _button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _hold_axis(axis: JoyAxis, value: float, frames: int) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	Input.parse_input_event(motion)
	for i in frames:
		await physics_frame
	var release := InputEventJoypadMotion.new()
	release.axis = axis
	release.axis_value = 0.0
	Input.parse_input_event(release)
	for i in 8:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("Gate A map/cycle: OK -- real pad cycling, movement-up minimap, full-map ownership, recovery.")
		quit(0)
		return
	for line in _failures:
		print("Gate A map/cycle FAIL: %s" % line)
	quit(1)
