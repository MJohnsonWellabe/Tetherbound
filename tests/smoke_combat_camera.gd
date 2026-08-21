extends SceneTree

## RG8. The production orbit rig across exploration -> real encounter ->
## active-creature movement/switch -> throw aim/cancel -> combat exit, driven
## with physical joypad events for every camera/control assertion.
##
##   godot --headless --path . --script tests/smoke_combat_camera.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SETTLE_FRAMES := 300
const RIGHT_X := JOY_AXIS_RIGHT_X
const RIGHT_Y := JOY_AXIS_RIGHT_Y
const LEFT_Y := JOY_AXIS_LEFT_Y

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	# Raw B/LB events also reach the autoload menu. A manually-instanced world
	# is not current_scene unless the harness says so; without this, the menu's
	# production combat guard cannot find CombatManager and the test—not the
	# game—turns B into Pause instead of flee/cancel.
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	if not await _collect_and_stage():
		_report()
		return

	await _prove_exploration_baseline()
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_fail("the physical interact button never entered the production encounter")
		_report()
		return
	await _prove_combat_entry_follow_and_orbit()
	await _prove_creature_switch_keeps_the_camera()
	await _prove_aim_cancel_returns_combat_orbit()
	await _prove_combat_exit_restores_exploration()
	await _prove_a_second_entry_exit_cycle()
	_report()


func _collect_and_stage() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _game == null or _player == null or _rig == null or _camera == null \
			or _manager == null or _director == null:
		_fail("the real world is missing Game, Player, CameraRig/Camera3D, CombatManager, or EncounterDirector")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup", "Orbit")
	_wild = _director.call("wild_creature") as Node3D
	if _director.call("ally_instance") == null or _wild == null:
		_fail("the production encounter could not stage an ally and wild creature")
		return false

	# A real second party member makes the existing combat-switch input reachable.
	var second := CREATURE.from_species("ripplet", SPECIES.definition("ripplet"))
	(_game.get("party") as RefCounted).call("add", second)
	(_game.get("inventory") as RefCounted).call("add", "orb_basic", 3)

	# Move beside the authored wild spawn, but enter through the production
	# arbiter and physical X button. Walking there is smoke_combat.gd's concern.
	var offset := Vector3(3.0, 0.0, 0.0)
	var near := _wild.global_position + offset
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	return true


func _prove_exploration_baseline() -> void:
	if _rig.get("_target") != _player:
		_fail("exploration camera target is not the trainer before combat")
	if not _camera.current:
		_fail("CameraRig/Camera3D is not the active exploration camera")
	if not _rig.is_processing():
		_fail("the exploration orbit rig is not processing")
	await _assert_raw_orbit_changes("exploration baseline")


func _enter_real_encounter() -> void:
	# The wild keeps wandering while the baseline camera is exercised. Stage the
	# trainer beside its CURRENT authored body immediately before pressing X so
	# this remains a camera test rather than a race against wandering distance.
	# Stand close enough that a nearby harvest node cannot beat EncounterDirector
	# in the production interaction arbiter, and allow its idle-frame recompute
	# to publish that winner before the physical button arrives.
	var near := _wild.global_position + Vector3(1.5, 0.0, 0.0)
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 8:
		await physics_frame
	var candidate := _director.call("_engageable") as Node3D
	if candidate != null:
		_wild = candidate
	for i in 5:
		await process_frame
	await _press_button(JOY_BUTTON_X)
	for i in 120:
		if bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_ally = _director.call("ally_body") as Node3D


func _prove_combat_entry_follow_and_orbit() -> void:
	print("camera target on entry: %s" % _node_label(_rig.get("_target")))
	print("active camera: %s current=%s processing=%s" % [
		_camera.get_path(), _camera.current, _rig.is_processing()])
	if _ally == null or _rig.get("_target") != _ally:
		_fail("combat camera target is not the deployed active creature body")
	if not _camera.current:
		_fail("another camera became active when combat began")
	if not _rig.is_processing():
		_fail("the camera rig stopped processing when combat began")

	var ally_before := _ally.global_position
	var rig_before := _rig.global_position
	_send_axis(LEFT_Y, -0.85)
	for i in 50:
		await physics_frame
	_send_axis(LEFT_Y, 0.0)
	for i in 20:
		await physics_frame
	var ally_travel := _ally.global_position.distance_to(ally_before)
	var rig_travel := _rig.global_position.distance_to(rig_before)
	print("combat follow: ally moved %.2fm, rig moved %.2fm" % [ally_travel, rig_travel])
	if ally_travel < 0.5:
		_fail("physical left-stick input did not move the active creature")
	if rig_travel < 0.3:
		_fail("the rig did not follow the moving active creature")
	await _assert_raw_orbit_changes("combat")


func _prove_creature_switch_keeps_the_camera() -> void:
	await _press_button(JOY_BUTTON_DPAD_RIGHT)
	for i in 20:
		await physics_frame
	var active: RefCounted = _manager.call("active_creature")
	if active == null or str(active.get("species_id")) != "ripplet":
		_fail("physical D-pad switch did not make the second creature active")
	if _rig.get("_target") != _ally:
		_fail("switching left the camera on a stale/non-deployed target")
	if not _rig.is_processing():
		_fail("switching disabled the camera rig")
	await _assert_raw_orbit_changes("after creature switch")


func _prove_aim_cancel_returns_combat_orbit() -> void:
	# project.godot binds combat_throw to raw button 10 (the right shoulder in
	# Godot's enum), regardless of the UI's player-facing LB/RB labelling.
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 30:
		if bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		_fail("physical LB did not enter throw aim despite available orbs")
		return
	print("camera target in aim: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("throw aim did not temporarily target the trainer")
	# throw_aim deliberately guards the same shoulder press that opened the mode
	# for 0.15s. Wait beyond that production debounce before testing B/cancel.
	for i in 15:
		await physics_frame
	await _press_button(JOY_BUTTON_B)
	for i in 30:
		if not bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if bool(_manager.call("is_aiming")):
		_fail("physical B did not cancel throw aim")
	if _rig.get("_target") != _ally:
		_fail("cancelled aim did not return camera follow to the active creature")
	if bool(_player.call("locomotion_enabled")):
		_fail("cancelled aim left trainer locomotion active during creature combat")
	await _assert_raw_orbit_changes("after aim cancel")


func _prove_combat_exit_restores_exploration() -> void:
	await _press_button(JOY_BUTTON_B)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("physical B did not flee from combat")
		return
	print("camera target on exit: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("combat exit did not return camera target to the trainer")
	if not _rig.is_processing() or not _camera.current:
		_fail("combat exit left the exploration camera inactive")
	if absf(_camera.fov - 70.0) > 0.01 or absf(float(_rig.get("_shoulder"))) > 0.001 \
			or absf(float(_rig.get("_sensitivity_scale")) - 1.0) > 0.001:
		_fail("combat exit did not restore the exploration camera profile")
	if not bool(_player.call("locomotion_enabled")):
		_fail("combat exit did not restore trainer locomotion")
	var deployed: RefCounted = _director.call("ally_instance") as RefCounted
	var party_active: RefCounted = (_game.get("party") as RefCounted).call("active") as RefCounted
	if deployed == null or str(deployed.get("species_id")) != "ripplet" or party_active != deployed:
		_fail("combat exit did not preserve the creature selected by the player")
	if not _ally.visible or str(_ally.get("species_id")) != "ripplet":
		_fail("combat exit did not restore the selected creature as the visible follower")
	await _assert_raw_orbit_changes("exploration after combat")


func _prove_a_second_entry_exit_cycle() -> void:
	# Flee leaves the same wild encounter available. Re-enter through X and exit
	# through B once more to catch state that degrades only after the first cycle.
	var near := _wild.global_position + Vector3(3.0, 0.0, 0.0)
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_fail("the second production encounter would not start")
		return
	_ally = _director.call("ally_body") as Node3D
	if _rig.get("_target") != _ally or not _rig.is_processing():
		_fail("second combat cycle did not retarget a live, processing camera")
	# Let the same production input guard that separates the engage X press from
	# the first charged attack elapse before moving another physical control.
	for i in 20:
		await physics_frame
	await _assert_raw_orbit_changes("second combat cycle")
	await _press_button(JOY_BUTTON_B)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")) or _rig.get("_target") != _player:
		_fail("second combat exit did not restore trainer camera follow")


func _assert_raw_orbit_changes(context: String) -> void:
	# Keep away from either pitch clamp so both axes have room to move.
	_rig.set("yaw", 0.15)
	_rig.set("pitch", -0.15)
	_rig.rotation = Vector3(-0.15, 0.15, 0.0)
	var yaw_before := float(_rig.get("yaw"))
	var pitch_before := float(_rig.get("pitch"))
	_send_axis(RIGHT_X, 0.72)
	_send_axis(RIGHT_Y, -0.58)
	await physics_frame
	var live := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	print("%s look vector: %s (paused=%s, processing=%s, target=%s)" % [
		context, live, paused, _rig.is_processing(), _node_label(_rig.get("_target"))])
	for i in 18:
		await physics_frame
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	for i in 10:
		await physics_frame
	var yaw_after := float(_rig.get("yaw"))
	var pitch_after := float(_rig.get("pitch"))
	# Synthetic joy-motion state may be cleared by the engine after the camera's
	# physics read and before this coroutine resumes. The resulting yaw/pitch
	# deltas below are the durable proof that these raw events reached the rig.
	if absf(angle_difference(yaw_after, yaw_before)) < 0.08:
		_fail("%s: right-stick horizontal input did not orbit the camera" % context)
	if absf(pitch_after - pitch_before) < 0.05:
		_fail("%s: right-stick vertical input did not pitch the camera" % context)
	var held_yaw := yaw_after
	for i in 15:
		await physics_frame
	if absf(angle_difference(float(_rig.get("yaw")), held_yaw)) > 0.01:
		_fail("%s: camera yaw was continuously recentered after the stick returned to neutral" % context)


func _press_button(index: JoyButton) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	# Match the project's controller smokes: hold across two rendered frames so
	# both idle UI readers and physics-world readers see the physical press.
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await process_frame


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _node_label(value: Variant) -> String:
	var node := value as Node
	return str(node.get_path()) if node != null and is_instance_valid(node) else "<null/stale>"


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	_send_axis(LEFT_Y, 0.0)
	print("")
	if _failures.is_empty():
		print("PASS: combat camera follows the active creature, keeps free controller orbit, survives switch/aim, and restores exploration repeatedly")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)
