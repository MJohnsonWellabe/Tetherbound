extends SceneTree

## Does the meadow have anything dangerous in it, and is it only the dangerous
## thing that is dangerous?
##
##   godot --headless --path . --script tests/smoke_aggression.gd
##
## Two halves, and the SECOND is the important one.
##
## The first asserts that an aggressive wild pal will close on the trainer and
## start a fight with no button press — GAME_DESIGN.md §14 lists "Aggressive pal
## initiates" beside the player's own routes in.
##
## The second asserts that a PEACEFUL one will not, no matter how long you stand
## next to it. That is a regression guard on the other line in the same list:
## "**Not** simple proximity for peaceful pals." A bug that makes every creature
## aggressive would sail past the first half of this test and would not be
## noticed until someone wondered why the meadow felt hostile.

const SCENE := "res://scenes/world/meadows_playground.tscn"

const SETTLE_FRAMES := 300
## How long to stand next to a creature waiting for something to happen. At the
## configured chase speed this is far more than enough for an aggressive pal to
## cross its notice range.
const PATIENCE_FRAMES := 900

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	# Peaceful first, deliberately. Run the ambush half first and the aggressive
	# pal is still awake and near the trainer for the second half, so it chases
	# them across the meadow and the fight it starts gets blamed on the creature
	# standing next to them. The order is the fix; the species check below is the
	# belt to its braces.
	await _a_peaceful_pal_never_does()
	await _an_aggressive_pal_starts_the_fight_itself()
	_report()


## Which creature the current fight is against. Combat holds the live instance,
## and the instance knows its species, so this does not depend on which node
## happens to be nearest.
func _fighting_species() -> String:
	var foe: RefCounted = _manager.call("enemy")
	return "" if foe == null else str(foe.species_id)


## `meadows_playground.tscn` now always carries a `SequenceDirector` (R0.9),
## and its `_ready()` unconditionally calls `suspend_default_starter()` in the
## one frame window that exists to call it off — the opening always decides
## which pal the player gets, never the sandbox default. This test is not the
## opening and never drives it, so the encounter director's own
## `default_starter` never spawns here either. An aggressive pal starting a
## fight still needs the player to have something to fight WITH, so this gets
## a pal directly, the same call `sequence_director.gd` makes once a name is
## confirmed.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		_fail("scene is missing the player, camera rig, combat manager or director")
		return false

	var aggressive: Node3D = _director.call("aggressive_pal") as Node3D
	var peaceful: Node3D = _director.call("wild_pal") as Node3D
	if aggressive == null:
		_fail("no aggressive pal was spawned; nothing in the meadow can threaten the trainer")
		return false
	if peaceful == null:
		_fail("no peaceful pal was spawned; the second half of this test cannot run")
		return false
	if not bool(aggressive.get("aggressive")):
		_fail("the pal spawned as the aggressive one does not carry the flag")
		return false
	if bool(peaceful.get("aggressive")):
		_fail("the practice pal is flagged aggressive; it is supposed to be safe to walk up to")
		return false
	return true


## Walk within notice range and then stop. Nothing is pressed after this point.
func _an_aggressive_pal_starts_the_fight_itself() -> void:
	var wild: Node3D = _director.call("aggressive_pal") as Node3D
	await _walk_towards(wild, 10.0)

	var started := false
	var closed_from := _player.global_position.distance_to(wild.global_position)
	for i in PATIENCE_FRAMES:
		await physics_frame
		if bool(_manager.call("is_fighting")):
			started = true
			break

	if not started:
		_fail("stood %.1fm from %s for %d frames without pressing anything and it never attacked" % [
			closed_from, str(wild.get("display_name")), PATIENCE_FRAMES
		])
		return
	if _fighting_species() != str(wild.get("species_id")):
		_fail("a fight started, but against %s rather than the aggressive pal" % _fighting_species())
		return
	print("%s started the fight on its own, from %.1fm" % [str(wild.get("display_name")), closed_from])

	# It must be a real fight, not just a state flag: the same setup the player's
	# own engage produces.
	if bool(_player.call("locomotion_enabled")):
		_fail("an ambush did not suspend the trainer's locomotion")
	if _manager.call("arena") == null:
		_fail("an ambush opened no arena")
	var ally: Node3D = _director.call("ally_body") as Node3D
	if ally == null or not ally.visible:
		_fail("an ambush did not deploy the player's pal")

	# Leave, so the next half starts from exploration. The wait is flow's
	# input_guard: a fight ignores input for a moment after it opens, so a
	# player mashing B the instant they are ambushed has the first press eaten.
	for i in 30:
		await physics_frame
	await _press("combat_run")
	for i in 200:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break
	if bool(_manager.call("is_fighting")):
		_fail("could not Run out of an ambush")


## The half that matters. §14 forbids proximity starting a fight with a peaceful
## pal, and this is the only thing standing between that rule and a one-word
## edit to species.json.
func _a_peaceful_pal_never_does() -> void:
	if bool(_manager.call("is_fighting")):
		# The previous half left a fight running, so anything measured here would
		# be about that fight rather than about this creature. Said plainly
		# rather than reported as the peaceful pal misbehaving.
		_fail("still in combat from the ambush; the peaceful-pal check could not run")
		return

	var wild: Node3D = _director.call("wild_pal") as Node3D
	await _walk_towards(wild, 2.5)

	var distance := _player.global_position.distance_to(wild.global_position)
	var species := str(wild.get("species_id"))
	for i in PATIENCE_FRAMES:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			continue
		if _fighting_species() == species:
			_fail("%s started a fight by itself after %d frames; peaceful pals must never initiate" % [
				str(wild.get("display_name")), i
			])
		else:
			_fail("something else (%s) reached the trainer mid-test; the peaceful check is inconclusive" % _fighting_species())
		return

	print("stood %.1fm from %s for %d frames and it did nothing, as it should" % [
		distance, str(wild.get("display_name")), PATIENCE_FRAMES
	])

	# And it is still engageable by choice — "it never initiates" must not have
	# been achieved by breaking it.
	if str(_director.call("prompt")) == "":
		_fail("no engage prompt next to the peaceful pal; it cannot be fought at all")


func _walk_towards(wild: Node3D, stop_at: float) -> void:
	for i in 2000:
		var to := wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= stop_at:
			break
		if bool(_manager.call("is_fighting")):
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


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
		print("aggression: OK — the dangerous one initiates, the peaceful one never does.")
		quit(0)
		return
	for line in _failures:
		print("aggression FAIL: %s" % line)
	quit(1)
