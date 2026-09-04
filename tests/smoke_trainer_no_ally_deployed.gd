extends SceneTree

## G3-OPENING-FIX-0904 (2.10). Companion to
## `smoke_trainer_no_usable_ally.gd`, which proves the FAINTED half of
## `no_usable_ally()`'s two causes opens the honest "get it back on its feet"
## line. This proves the other half: a healthy party with nothing currently
## deployed opens a DIFFERENT line -- "call one out first" -- rather than the
## same "a bed will do it" wording, which told a player whose creature was
## not even hurt to go find a bed it did not need.
##
## GATE2-EVIDENCE-0903's own finding: a fresh handoff (S05-09a's "a load
## restores the party and deploys nothing") reaches this exact state on a
## fully healthy five-creature party, and both Old Bram and the South Bridge
## gatekeeper answered with the fainted-creature line regardless.
##
##   godot --headless --path . --script tests/smoke_trainer_no_ally_deployed.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const TRAINER_ID := "practice_trainer"
const SETTLE_FRAMES := 300
const NO_USABLE_CREATURE_CONVERSATION := "trainer_no_usable_creature"
const NO_ALLY_DEPLOYED_CONVERSATION := "trainer_no_ally_deployed"

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
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

	# Put the ally away WITHOUT fainting it -- the healthy-but-undeployed
	# state a fresh load leaves. `dismiss_active_creature()` carries no
	# fainted guard, so this reaches it directly.
	var ally: RefCounted = _director.call("ally_instance")
	if ally == null:
		_fail("the player has no deployed ally to dismiss; nothing to test")
		_report()
		return
	if bool(ally.get("fainted")):
		_fail("the ally is fainted before this test even dismisses it; the healthy-undeployed "
			+ "state cannot be set up")
		_report()
		return
	if not bool(_director.call("dismiss_active_creature")):
		_fail("could not dismiss the ally to set up the undeployed state")
		_report()
		return

	await _the_undeployed_ally_opens_the_call_out_line()
	_no_battle_started_and_the_trainer_is_not_recorded_as_beaten()
	_report()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _progression() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, combat manager, director or dialogue panel")
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
		_fail("the player has no creature to fight with, even before this test dismisses one")
		return false
	if bool(_progression().call("has", str(_spec.get("defeat_flag", "")))):
		_fail("the defeat flag is already set on a fresh boot; this test needs a never-fought trainer")
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


func _the_undeployed_ally_opens_the_call_out_line() -> void:
	_stand_in_front_of_the_trainer()
	for i in 60:
		await physics_frame

	if bool(_director.call("can_challenge", _spec)):
		_fail("can_challenge() is true with nothing deployed; the fix under test never gets exercised")
		return
	if not bool(_director.call("no_usable_ally")):
		_fail("no_usable_ally() is false with nothing deployed; it should be true")
		return
	if str(_director.call("usable_ally_blocker")) != "undeployed":
		_fail("usable_ally_blocker() reports '%s', expected 'undeployed'" % [
			str(_director.call("usable_ally_blocker"))])
		return

	await _press("interact")
	for n in 30:
		await physics_frame

	if not bool(_panel.call("is_open")):
		_fail("standing at a never-fought trainer with nothing deployed opened no dialogue at all")
		return
	var opened := str(_panel.call("runner").call("conversation_id"))
	if opened == str(_spec.get("defeated", "")):
		_fail("an undeployed ally opened the DEFEATED line ('%s')" % opened)
	elif opened == NO_USABLE_CREATURE_CONVERSATION:
		_fail("an undeployed but HEALTHY ally opened the fainted-creature line "
			+ "('%s' -- 'get it back on its feet... a bed will do it'), which is not the "
			+ "problem this player has" % opened)
	elif opened != NO_ALLY_DEPLOYED_CONVERSATION:
		_fail("an undeployed ally opened '%s', not the expected '%s'" % [
			opened, NO_ALLY_DEPLOYED_CONVERSATION])
	else:
		print("undeployed-but-healthy ally correctly opened '%s', naming the real reason" % opened)


func _no_battle_started_and_the_trainer_is_not_recorded_as_beaten() -> void:
	if bool(_manager.call("is_fighting")):
		_fail("a fight started against an undeployed-ally challenge; that should be impossible")
	if bool(_progression().call("has", str(_spec.get("defeat_flag", "")))):
		_fail("the trainer's defeat flag got set without a real fight ever starting")


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
		print("trainer no-ally-deployed dialogue: OK — an undeployed but healthy ally gets "
			+ "'call one out', not the fainted-creature line.")
		quit(0)
		return
	for line in _failures:
		print("trainer no-ally-deployed dialogue FAIL: %s" % line)
	quit(1)
