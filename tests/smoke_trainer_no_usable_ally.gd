extends SceneTree

## Dark-features T1 / T2-GATEF-RUN4. `can_challenge()` is false for four
## distinct reasons (already beaten, no usable ally, mid-battle, malformed
## spec) and `trainer_npc.gd::_on_challenged` used to collapse all of them
## into the trainer's "defeated" line -- so a player whose only creature had
## just fainted got told they had already won a fight that never happened.
## This proves the fix live: a fainted, deployed ally opens the new generic
## "no usable creature" conversation instead, no battle starts, the trainer
## is NOT recorded as beaten, and healing the ally restores the ordinary
## challenge flow on the very same trainer, in the very same session.
##
##   godot --headless --path . --script tests/smoke_trainer_no_usable_ally.gd
##
## Companion to tests/smoke_trainer_battle.gd, whose world stand-up and node
## collection this follows, but this file never fights the trainer at all --
## the whole point is that a fight must NOT start while the ally is fainted.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const TRAINER_ID := "practice_trainer"
const SETTLE_FRAMES := 300
const NO_USABLE_CREATURE_CONVERSATION := "trainer_no_usable_creature"

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

	# Fault the ally the same way a real fainted-in-the-field creature would
	# read: same instance `_ally` already tracks (`ally_instance()` returns
	# the live reference, not a copy -- confirmed against
	# tools/gate_f/probe_stranding_cause.gd's identical technique), still
	# deployed (never dismissed), just fainted.
	var ally: RefCounted = _director.call("ally_instance")
	if ally == null:
		_fail("the player has no deployed ally to faint; nothing to test")
		_report()
		return
	ally.set("fainted", true)
	ally.set("hp", 0.0)

	await _the_fainted_ally_opens_the_honest_line()
	await _no_battle_started_and_the_trainer_is_not_recorded_as_beaten()

	# Heal in place -- `creature_bed.gd`'s own recovery path, per
	# FINDING-T2-STRANDING-2026-08-30.md, sets fainted back to false and hp to
	# max_hp with nothing else touched. Reproduced directly here rather than
	# building a real bed, since the bed's own placement/interaction sequence
	# is a different lane's concern (T2-BUILDPLACE) and not what this test is
	# about.
	ally.set("fainted", false)
	ally.set("hp", float(ally.get("max_hp")))

	await _the_healed_ally_restores_the_ordinary_challenge()
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
		_fail("the player has no creature to fight with, even before this test faints one")
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


func _the_fainted_ally_opens_the_honest_line() -> void:
	_stand_in_front_of_the_trainer()
	for i in 60:
		await physics_frame

	if bool(_director.call("can_challenge", _spec)):
		_fail("can_challenge() is true with the ally fainted; the fix under test never gets exercised")
		return
	if not bool(_director.call("no_usable_ally")):
		_fail("no_usable_ally() is false with the ally fainted and deployed; it should be true")
		return

	await _press("interact")
	for n in 30:
		await physics_frame

	if not bool(_panel.call("is_open")):
		_fail("standing at a never-fought trainer with a fainted ally opened no dialogue at all")
		return
	var opened := str(_panel.call("runner").call("conversation_id"))
	if opened == str(_spec.get("defeated", "")):
		_fail("a fainted ally opened the DEFEATED line ('%s') -- the exact dark-features T1 bug, not fixed" % opened)
	elif opened != NO_USABLE_CREATURE_CONVERSATION:
		_fail("a fainted ally opened '%s', neither the honest no-usable-creature line nor the old bug" % opened)
	else:
		print("fainted ally correctly opened '%s', not the defeated line" % opened)

	# Close the panel however this world's runner exposes it, so the next
	# scenario in this file starts clean.
	while bool(_panel.call("is_open")):
		await _press("interact")
		for n in 8:
			await physics_frame


func _no_battle_started_and_the_trainer_is_not_recorded_as_beaten() -> void:
	if bool(_manager.call("is_fighting")):
		_fail("a fight started against a fainted-ally challenge; that should be impossible")
	if bool(_progression().call("has", str(_spec.get("defeat_flag", "")))):
		_fail("the trainer's defeat flag got set without a real fight ever starting")


func _the_healed_ally_restores_the_ordinary_challenge() -> void:
	if not bool(_director.call("can_challenge", _spec)):
		_fail("can_challenge() is still false after healing the ally back to full HP")
		return

	_stand_in_front_of_the_trainer()
	for i in 30:
		await physics_frame
	await _press("interact")
	for n in 30:
		await physics_frame

	if not bool(_panel.call("is_open")):
		_fail("a healed ally at a never-fought trainer opened no dialogue at all")
		return
	var opened := str(_panel.call("runner").call("conversation_id"))
	if opened != str(_spec.get("challenge", "")):
		_fail("a healed ally opened '%s' instead of the real challenge conversation" % opened)
	else:
		print("healed ally correctly reopened the ordinary challenge conversation")


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
		print("trainer no-usable-ally dialogue: OK — a fainted ally gets the honest line, not a false 'defeated', and healing restores the ordinary challenge.")
		quit(0)
		return
	for line in _failures:
		print("trainer no-usable-ally dialogue FAIL: %s" % line)
	quit(1)
