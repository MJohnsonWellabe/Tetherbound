extends SceneTree

## N04-DIALOGUE-PORTRAITS, 2026-09-05. The generic "your creature can't fight
## like this" refusal is ONE conversation in data/dialogue/trainers.json said
## by every trainer in the chapter, so its JSON can only name a neutral
## speaker ("Trainer") and a neutral plate (villager_male.png). W04-PORTRAITS
## found it live: walk up to Bryn with a fainted ally and the box is labelled
## "Trainer" over a stranger's face. `trainer_npc.gd` now hands the panel the
## challenged trainer's own name and plate for the duration.
##
## This proves it in the booted world, not on a bare panel: the same stand-up
## as tests/smoke_trainer_no_usable_ally.gd (which owns the "which
## conversation opens" half and is left alone), then the panel is asked what
## it is actually drawing.
##
##   godot --headless --path . --script tests/smoke_trainer_refusal_portrait.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const TRAINER_ID := "practice_trainer"
const SETTLE_FRAMES := 300
const NO_USABLE_CREATURE_CONVERSATION := "trainer_no_usable_creature"

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _director: Node = null
var _panel: Node = null
var _trainer: Node3D = null
var _spec: Dictionary = {}


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
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	var ally: RefCounted = _director.call("ally_instance")
	if ally == null:
		_fail("the player has no deployed ally to faint; nothing to test")
		_report()
		return
	ally.set("fainted", true)
	ally.set("hp", 0.0)

	await _the_refusal_wears_the_trainers_own_face()

	ally.set("fainted", false)
	ally.set("hp", float(ally.get("max_hp")))
	_report()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, director or dialogue panel")
		return false
	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("the world built no Trainers node; trainers.json is not being placed")
		return false
	_trainer = trainers.call("body_for", TRAINER_ID) as Node3D
	if _trainer == null:
		_fail("trainer '%s' was never stood up in the world" % TRAINER_ID)
		return false
	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with, even before this test faints one")
		return false
	return true


func _stand_in_front_of_the_trainer() -> void:
	var facing := deg_to_rad(float(_spec.get("facing_deg", 0.0)))
	var spot := _trainer.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := _trainer.global_position - _player.global_position
	to.y = 0.0
	_rig.set("yaw", atan2(-to.x, -to.z))


func _the_refusal_wears_the_trainers_own_face() -> void:
	_stand_in_front_of_the_trainer()
	for i in 60:
		await physics_frame
	if not bool(_director.call("no_usable_ally")):
		_fail("no_usable_ally() is false with the ally fainted and deployed; the refusal never opens")
		return

	await _press("interact")
	for n in 30:
		await physics_frame

	if not bool(_panel.call("is_open")):
		_fail("standing at a never-fought trainer with a fainted ally opened no dialogue at all")
		return
	var opened := str(_panel.call("runner").call("conversation_id"))
	if opened != NO_USABLE_CREATURE_CONVERSATION:
		_fail("expected the refusal '%s' to open, got '%s'" % [NO_USABLE_CREATURE_CONVERSATION, opened])
		return

	# What the trainer's own challenge line wears is what the refusal must
	# wear -- read off the real table, the way trainer_npc.gd reads it.
	var own_plate := str((RUNNER.table().get(str(_spec.get("challenge", "")), {}) as Dictionary).get("portrait", ""))
	var neutral_plate := str((RUNNER.table().get(NO_USABLE_CREATURE_CONVERSATION, {}) as Dictionary).get("portrait", ""))
	var shown := str(_panel.call("current_portrait"))
	var labelled := str(_panel.call("current_speaker"))
	print("refusal opened by '%s': plate=%s speaker='%s' (own=%s neutral=%s)" % [
		TRAINER_ID, shown.get_file(), labelled, own_plate.get_file(), neutral_plate.get_file()])
	if own_plate == "":
		_fail("trainer '%s' has no challenge plate in the table to compare against" % TRAINER_ID)
	elif shown != own_plate:
		_fail("the refusal drew %s, not %s's own plate %s" % [shown.get_file(), str(_spec.get("name", "")), own_plate.get_file()])
	if shown == neutral_plate and own_plate != neutral_plate:
		_fail("the refusal is still wearing the neutral villager_male plate -- the W04 finding, unfixed")
	if labelled != str(_spec.get("name", "")):
		_fail("the refusal is labelled '%s', not '%s'" % [labelled, str(_spec.get("name", ""))])

	while bool(_panel.call("is_open")):
		await _press("interact")
		for n in 8:
			await physics_frame

	# And the identity is gone with the conversation: the panel's next line
	# is whoever's it says it is.
	if str(_panel.call("current_portrait")) != "" or str(_panel.call("current_speaker")) != "":
		_fail("the panel still reports a plate/speaker after the refusal closed")


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("trainer refusal portrait: OK — the generic refusal wears the challenged trainer's own name and face, and drops them when it closes.")
		quit(0)
		return
	for line in _failures:
		print("trainer refusal portrait FAIL: %s" % line)
	quit(1)
