extends SceneTree

## OP23-02 (owner playtest 2026-08-23): "Combat camera control is lost at
## Meadows Hall battles... battle start takes the camera, can't see."
## `smoke_trainer_battle_camera.gd` already proves the camera survives a
## trainer battle in the open meadow (Mira); it is a coverage hole for the
## Stronghold gauntlet specifically, where a room's walls sit close enough
## for the flat combat camera profile's `shoulder_offset` (a raw, uncollided
## sideways shift — see `combat_manager.gd::_combat_camera_profile()`'s own
## header) to push the rig through them.
##
## Fights `stronghold_elite` (`tether_approach`, the tightest gauntlet room —
## 16x18m, the room OP21-25's own comment names as the closest wall margin)
## through its physical challenge prompt, the real production path
## (`trainer_npc.gd`), not a direct director call — same reasoning
## `smoke_trainer_battle.gd`'s own header gives for driving real input.
##
##   godot --headless --path . --script tests/smoke_stronghold_battle_camera.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const TRAINER_ID := "stronghold_elite"
const SETTLE_FRAMES := 300
const RIGHT_X := JOY_AXIS_RIGHT_X
const RIGHT_Y := JOY_AXIS_RIGHT_Y

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _trainer: Node3D = null
var _spec: Dictionary = {}
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_spec = TRAINERS.trainer(TRAINER_ID)
	if _spec.is_empty():
		_fail("trainers.json has no trainer '%s'; nothing here can run" % TRAINER_ID)
		_report()
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	_stand_in_front_of_the_trainer()
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		_fail("the challenge never started a fight against the gauntlet trainer; "
			+ "nothing below this point was tested")
		_report()
		return
	_ally = _director.call("ally_body") as Node3D

	print((
		"stronghold gauntlet battle active; camera target=%s current=%s processing=%s "
		+ "distance=%.2f shoulder=%.2f spring_length=%.2f"
	) % [
		_node_label(_rig.get("_target")), _camera.current, _rig.is_processing(),
		float(_rig.get("_distance")), float(_rig.get("_shoulder")), _rig.spring_length])

	if _ally == null or _rig.get("_target") != _ally:
		_fail("stronghold-battle camera target is not the deployed active creature body")
	if not _camera.current:
		_fail("another camera became active when the stronghold battle began")
	if not _rig.is_processing():
		_fail("the camera rig stopped processing when the stronghold battle began")
	if root.gui_get_focus_owner() != null:
		_fail("GUI focus is still held after the closing dialogue box started the stronghold battle: %s"
			% str(root.gui_get_focus_owner()))

	# OP23-02's actual regression: the flat 1.5m shoulder_offset is a raw,
	# uncollided sideways shift of the follow target -- safe in the open
	# meadow, not safe a couple of metres from a gauntlet room's wall.
	# `combat_manager.gd::_combat_camera_profile()` is supposed to zero it
	# whenever `_arena_bounds()` finds the fight inside a room.
	if not is_zero_approx(float(_rig.get("_shoulder"))):
		_fail((
			"the camera's shoulder offset is %.2f inside a gauntlet room; a "
			+ "sideways shift with no collision probing is exactly what pushes "
			+ "the rig through the wall"
		) % float(_rig.get("_shoulder")))

	# A spring arm that has collapsed to almost nothing is a camera jammed
	# against (or inside) geometry -- "can't see" in a testable form.
	for i in 30:
		await physics_frame
	if _rig.spring_length < 1.0:
		_fail((
			"the camera's spring length settled at %.2f inside the gauntlet room; "
			+ "the rig is jammed against geometry, not framing the fight"
		) % _rig.spring_length)

	await _assert_raw_orbit_changes("stronghold gauntlet battle vs %s" % TRAINER_ID)
	await _prove_combat_exit_restores_orbit()
	_report()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup", "Camera")


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _camera == null or _manager == null \
			or _director == null or _panel == null:
		_fail("the real world is missing Player, CameraRig/Camera3D, CombatManager, "
			+ "EncounterDirector or the dialogue panel")
		return false

	var trainers := _world.get_node_or_null(^"StrongholdTrainers")
	if trainers == null:
		_fail("the world built no StrongholdTrainers node; the gauntlet is not being placed")
		return false
	_trainer = trainers.call("body_for", TRAINER_ID) as Node3D
	if _trainer == null:
		_fail("gauntlet trainer '%s' was never stood up in the world" % TRAINER_ID)
		return false

	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false
	return true


func _stand_in_front_of_the_trainer() -> void:
	# The trainer's LIVE facing/position, not trainers.json's raw row -- the
	# gauntlet placer overrides both from stronghold.json's own layout
	# (`stronghold.gd::_place_gauntlet()`).
	var facing := _trainer.rotation.y
	var spot := _trainer.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	spot.y = _trainer.global_position.y
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := _trainer.global_position - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _challenge() -> void:
	for i in 60:
		await physics_frame

	var presses := 0
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			for n in 8:
				await physics_frame
			continue
		await physics_frame

	print("gauntlet challenge took %d presses; conversation opened and closed" % presses)
	if presses < 2:
		_fail("the gauntlet battle started without the challenge conversation being read")


func _prove_combat_exit_restores_orbit() -> void:
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("physical RB did not disengage the stronghold battle")
		return
	if _rig.get("_target") != _player or not _rig.is_processing() or not _camera.current:
		_fail("fleeing the stronghold battle did not restore the exploration camera")
	await _assert_raw_orbit_changes("exploration after stronghold battle")


func _assert_raw_orbit_changes(context: String) -> void:
	_rig.set("yaw", 0.15)
	_rig.set("pitch", -0.15)
	_rig.rotation = Vector3(-0.15, 0.15, 0.0)
	var yaw_before := float(_rig.get("yaw"))
	var pitch_before := float(_rig.get("pitch"))
	_send_axis(RIGHT_X, 0.72)
	_send_axis(RIGHT_Y, -0.58)
	for i in 18:
		await physics_frame
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	for i in 10:
		await physics_frame
	var yaw_after := float(_rig.get("yaw"))
	var pitch_after := float(_rig.get("pitch"))
	if absf(angle_difference(yaw_after, yaw_before)) < 0.08:
		_fail("%s: right-stick horizontal input did not orbit the camera" % context)
	if absf(pitch_after - pitch_before) < 0.05:
		_fail("%s: right-stick vertical input did not pitch the camera" % context)


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _press_button(index: JoyButton) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
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
	push_error(message)


func _report() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	print("")
	if _failures.is_empty():
		print("PASS: the stronghold gauntlet battle keeps the camera on its deployed "
			+ "target, un-shouldered and un-jammed inside the room, and controller "
			+ "orbit survives entry and exit")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)
