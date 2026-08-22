extends SceneTree

## OP21-05 regression. `smoke_combat_camera.gd` proves the orbit rig survives
## entry/switch/aim/exit for a WILD encounter, entered through EncounterDirector's
## own X-button engage. It never drives a TRAINER battle, and the two paths
## diverge earlier than combat: a trainer fight opens from a closing dialogue
## box (`sequence_director.gd::_maybe_start_battle`, `trainer_npc.gd::
## _on_conversation_finished`), not from a direct engage press. If the dialogue
## panel ever left stray focus/state behind on close, a wild-only test could
## never see it.
##
## Uses the real FIRST village trainer the owner would actually walk up to --
## Mira (data/config/bands/band1_lower_meadows/trainers.json order 1, fought
## through village_npcs.gd's greeting_when -> sequence_director.gd's
## `battle:trainer_mira` effect, per that file's own header comment -- NOT
## trainer_npc.gd's placement/prompt system, which only stands up the
## `practice_trainer` placeholder kept for smoke_trainer_battle.gd's own
## coverage). `mira_shop_open` is set directly on progression so her real
## `village_mira_challenge` conversation is reachable without also proving the
## shop-intro dialogue, which is not this test's concern.
##
##   godot --headless --path . --script tests/smoke_trainer_battle_camera.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const RIGHT_X := JOY_AXIS_RIGHT_X
const RIGHT_Y := JOY_AXIS_RIGHT_Y
const MIRA_FLAG := "mira_shop_open"
const MIRA_CONVERSATION := "village_mira_challenge"

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _manager: Node = null
var _director: Node = null
var _sequence: Node = null
var _dialogue: Node = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	if not await _collect_and_stage():
		_report()
		return

	await _start_mira_battle_through_dialogue()
	if not bool(_manager.call("is_fighting")):
		_fail("Mira's real village_mira_challenge conversation never started a trainer battle")
		_report()
		return
	_ally = _director.call("ally_body") as Node3D

	print("trainer battle active; camera target=%s current=%s processing=%s" % [
		_node_label(_rig.get("_target")), _camera.current, _rig.is_processing()])
	if _ally == null or _rig.get("_target") != _ally:
		_fail("trainer-battle camera target is not the deployed active creature body")
	if not _camera.current:
		_fail("another camera became active when the trainer battle began")
	if not _rig.is_processing():
		_fail("the camera rig stopped processing when the trainer battle began")
	if root.gui_get_focus_owner() != null:
		_fail("GUI focus is still held after the closing dialogue box started the trainer battle: %s" \
			% str(root.gui_get_focus_owner()))

	await _assert_raw_orbit_changes("trainer battle vs Mira")
	await _prove_combat_exit_restores_orbit()
	_report()


func _collect_and_stage() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_sequence = _find_by_script(_world, "res://scripts/story/sequence_director.gd")
	_dialogue = get_first_node_in_group("dialogue_panel")
	if _game == null or _player == null or _rig == null or _camera == null \
			or _manager == null or _director == null or _sequence == null or _dialogue == null:
		_fail("the real world is missing Game, Player, CameraRig/Camera3D, CombatManager, EncounterDirector, SequenceDirector or the dialogue panel")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup", "Camera")
	if _director.call("ally_instance") == null:
		_fail("the production encounter could not stage a starter ally")
		return false

	# Mira's real challenge branch requires the shop-intro to already be spent.
	# Setting the flag directly is faithful to the real branch table
	# (greeting_when's second entry) without re-proving the shop-intro line,
	# which smoke_save_persistence.gd and the village_npcs tests already cover.
	(_game.get("progression") as RefCounted).call("set_flag", MIRA_FLAG)
	return true


## Opens Mira's real challenge conversation through the same panel a physical
## interact press reaches, then closes it exactly the way a player would --
## advancing every line -- and lets SequenceDirector's own per-frame
## `_maybe_start_battle()` poll (the production seam, not a direct call) open
## the fight once the box is gone.
func _start_mira_battle_through_dialogue() -> void:
	if not bool(_dialogue.call("start", MIRA_CONVERSATION)):
		_fail("Mira's real production conversation '%s' was refused" % MIRA_CONVERSATION)
		return
	var guard := 0
	while bool(_dialogue.call("is_open")) and guard < 96:
		await process_frame
		_dialogue.call("advance")
		guard += 1
	if guard >= 96:
		_fail("Mira's challenge conversation never closed")
		return
	for i in 60:
		if bool(_manager.call("is_fighting")):
			break
		await physics_frame


## CONTROLLER-MAP, ralph/OWNER_DIRECTIVES_2026-08-22.md section 1: "Fleeing is
## RB. Putting the creature away IS disengaging; flee gets no button of its
## own." `combat_run` kept its keyboard Escape and lost its pad button, and
## `combat_manager.gd::_flee_pressed()` reaches the pad through
## `creature_recall` (RB) instead. B is `hotbar_1`/`build_cancel` now and
## disengages nothing, so this pressed a button with no bearing on the fight
## and reported the fight still running -- which it correctly was.
func _prove_combat_exit_restores_orbit() -> void:
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("physical RB did not disengage the trainer battle")
		return
	if _rig.get("_target") != _player or not _rig.is_processing() or not _camera.current:
		_fail("fleeing the trainer battle did not restore the exploration camera")
	await _assert_raw_orbit_changes("exploration after trainer battle")


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


func _find_by_script(from: Node, path: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path) == path:
		return from
	for child in from.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	print("")
	if _failures.is_empty():
		print("PASS: the real Mira trainer battle keeps the camera on its deployed target, GUI focus clears, and controller orbit survives entry and exit")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)
