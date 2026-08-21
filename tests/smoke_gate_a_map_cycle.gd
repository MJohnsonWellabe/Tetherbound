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
	var bodies: Array = _menu.get("_bodies")
	var map_tab := bodies[int(_menu.get("_index"))] as Control
	if map_tab == null or float(map_tab.get("_zoom")) != 1.0:
		_fail("full map did not open at whole-world fit")
		return
	var controls := map_tab.get("_controls_label") as RichTextLabel
	if controls == null or not controls.text.contains("Zoom") or not controls.text.contains("Pan"):
		_fail("full-map controller zoom/pan controls are not discoverable on screen")
		return
	var canvas := map_tab.get("_canvas") as Control
	if canvas == null or not canvas.clip_contents:
		_fail("full-map canvas does not clip scaled map content inside its panel")
		return
	var fit_rect: Rect2 = map_tab.call("_map_rect_for_canvas", canvas.size)

	await _pulse_motion_action("map_zoom_in")
	if float(map_tab.get("_zoom")) <= 1.0:
		_fail("physical RT did not zoom the full map in")
		return
	var zoomed_rect: Rect2 = map_tab.call("_map_rect_for_canvas", canvas.size)
	if zoomed_rect.size.x < fit_rect.size.x * 3.5 or zoomed_rect.size.y < fit_rect.size.y * 3.5:
		_fail("zoom changed state without visibly scaling the map presentation")
		return
	# The relay's named region and major destination intentionally share a
	# centre. Their geometry is therefore the canonical regression case for
	# label-vs-marker collision avoidance at local zoom.
	var relay_centre := Vector2(348.0, 3756.0)
	var relay_point: Vector2 = map_tab.call("_world_to_canvas", relay_centre, zoomed_rect)
	var relay_marker_rect := Rect2(relay_point - Vector2(24.0, 24.0), Vector2(48.0, 48.0))
	var relay_occupied: Array[Rect2] = [relay_marker_rect]
	var relay_label_rect: Rect2 = map_tab.call(
		"_resolved_region_label_rect",
		canvas,
		zoomed_rect,
		{"display_name": "The Tether Relay", "centre": relay_centre},
		relay_occupied,
	)
	if relay_label_rect.size == Vector2.ZERO or relay_label_rect.intersects(relay_marker_rect):
		_fail("zoomed region label still overlaps its major destination marker")
		return
	var centre_before_pan := zoomed_rect.get_center()
	await _hold_axis(JOY_AXIS_RIGHT_X, 1.0, 35)
	if (map_tab.get("_pan_world") as Vector2).x <= 1.0:
		_fail("physical right stick did not pan the zoomed full map")
		return
	var panned_rect: Rect2 = map_tab.call("_map_rect_for_canvas", canvas.size)
	if panned_rect.get_center().distance_to(centre_before_pan) < 2.0:
		_fail("right-stick pan changed state without visibly relocating the map")
		return
	# Drive to the boundary, then keep driving. A stable world-space centre on
	# the second hold proves the clamp rather than merely proving movement.
	await _hold_axis(JOY_AXIS_RIGHT_X, 1.0, 300)
	var clamped := map_tab.get("_pan_world") as Vector2
	await _hold_axis(JOY_AXIS_RIGHT_X, 1.0, 60)
	if (map_tab.get("_pan_world") as Vector2).distance_to(clamped) > 1.0:
		_fail("right-stick pan did not clamp at the world boundary")
		return
	await _pulse_motion_action("map_zoom_out")
	if float(map_tab.get("_zoom")) != 1.0 or (map_tab.get("_pan_world") as Vector2).length() > 0.01:
		_fail("physical LT did not restore whole-world fit and clear pan")
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
	# Try two resolved directions: the opening house can legitimately block one
	# depending on the camera orbit used above, which is collision correctness,
	# not lost controller ownership.
	await _hold_axis(JOY_AXIS_LEFT_X, -1.0, 55)
	if _player.global_position.distance_to(before) < 0.5:
		await _hold_axis(JOY_AXIS_LEFT_Y, 1.0, 55)
	if _player.global_position.distance_to(before) < 0.5:
		_fail("world movement did not recover after closing the full map")
	else:
		print("  ok    physical Map/Back, RT/LT zoom, right-stick pan/clamp, and world recovery all work")


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


func _pulse_motion_action(action: String) -> void:
	if not InputMap.has_action(action):
		_fail("'%s' has no InputMap action" % action)
		return
	for event in InputMap.action_get_events(action):
		var binding := event as InputEventJoypadMotion
		if binding == null:
			continue
		var down := InputEventJoypadMotion.new()
		down.axis = binding.axis
		down.axis_value = binding.axis_value
		Input.parse_input_event(down)
		for i in 4:
			await process_frame
		var up := InputEventJoypadMotion.new()
		up.axis = binding.axis
		up.axis_value = 0.0
		Input.parse_input_event(up)
		for i in 5:
			await process_frame
		return
	_fail("'%s' has no physical joypad motion binding" % action)


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
		print("Gate A map/cycle: OK -- real pad cycling, movement-up minimap, full-map zoom/pan, recovery.")
		quit(0)
		return
	for line in _failures:
		print("Gate A map/cycle FAIL: %s" % line)
	quit(1)
