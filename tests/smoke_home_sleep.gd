extends SceneTree

## OWNER-0901: "Still no way for a person to sleep." night_rest.gd's
## `rest()`/`pass_the_night()` and the `player_slept_at_home` flag it sets
## already reach every AUTHORED camp (`smoke_authored_camps.gd`) and the
## player's own buildable camp (`smoke_gateb_flags.gd`), but the loft bed the
## opening itself puts the player in — the one bed a player who never builds
## a camp and never wanders as far as an authored one is guaranteed to have
## met — carried no interactable of its own once the wake beat ended.
## `sequence_director.gd`'s own "BedPrompt" is the wake beat's "Get up" exit
## and is disabled for the rest of the game, never a sleep trigger.
##
## This drives the real trigger METHOD directly (party size, the same
## compatibility inference `_restore_opening_beat()` already reads for a
## continuing save) rather than replaying the whole physical opening --
## `tests/helpers/gate_a_opening_drive.gd` owns that end-to-end walk, and
## `smoke_gateb_flags.gd` already established the "drive the trigger, not the
## controller" pattern for exactly this class of downstream-system check.
##
##   godot --headless --path . --script tests/smoke_home_sleep.gd
##
## What it asserts, in the order a player would meet it:
##
##   * before the player is free to leave the house, the bed's Sleep prompt
##     is not offered at all -- sleeping out from under an unfinished opening
##     beat would be a stranger bug than not being able to sleep yet
##   * once free to leave (the same beat gate the front door itself uses),
##     standing at the loft bed offers "Sleep"
##   * pressing it passes the night through the one shared `night_rest.gd`
##     entry point: the day advances and `player_slept_at_home` clears

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SEQUENCE_DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const STARTER_SPECIES := "terrapup"

const SETTLE_FRAMES := 240
## The prompt's own radius is 2.2m; stood off far enough that the arbiter's
## sight-line test is a real ray rather than a zero-length one.
const STAND_OFF_M := 1.5

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("home sleep FAIL: no Game autoload")
		quit(1)
		return
	var progression: RefCounted = game.get("progression")
	progression.call("load_data", {})
	var party: RefCounted = game.get("party")
	# Two party members is `_restore_opening_beat()`'s own compatibility
	# inference for "the old tutorial catch has already happened" -- the
	# same shape a real continuing save reaches, set BEFORE the world (and
	# its SequenceDirector) enters the tree so `_ready()` reads it honestly
	# rather than this test reaching into the beat machine's private state.
	for species_id in [STARTER_SPECIES, STARTER_SPECIES]:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null or not bool(party.call("add", creature)):
			_fail("could not seed a two-creature party before boot")
			quit(1)
			return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	var sequence := _find_by_script(world, SEQUENCE_DIRECTOR_SCRIPT)
	var arbiter: Node = get_first_node_in_group(&"interaction_arbiter")
	if player == null or house == null or sequence == null or arbiter == null:
		print("home sleep FAIL: the scene has no Player, GrandpaHouse, SequenceDirector or interaction arbiter")
		quit(1)
		return

	var bed := house.call("marker", "bed") as Vector3
	var sleep_prompt := house.get_node_or_null(^"SleepPrompt")
	if sleep_prompt == null:
		_fail("GrandpaHouse built no SleepPrompt at all; the loft bed offers nothing")
		_finish()
		return

	if str(sequence.call("beat")) != "free_play":
		_fail("seeding two party members did not restore the 'free_play' beat (got '%s')"
			% str(sequence.call("beat")))
	await _stand_beside(player, bed)
	var offered := str(arbiter.call("prompt"))
	if not offered.contains("Sleep"):
		_fail("standing %.1fm from the player's own bed with the house unlocked, the game offers '%s', not 'Sleep'"
			% [STAND_OFF_M, offered if not offered.is_empty() else "nothing"])
	else:
		print("home bed offers '%s'" % offered)

	progression.call("set_flag", "player_slept_at_home", false)
	var day_before := int(game.get("day"))
	if not bool(arbiter.call("activate")):
		_fail("pressing interact at the home bed activated nothing")
		_finish()
		return
	# night_rest.gd's fade is 1.2s and the night passes at its midpoint; give
	# it the whole tween plus a margin, the same budget the authored-camps
	# and gateb-flags smokes give the shared path.
	for i in 150:
		await physics_frame

	var day_after := int(game.get("day"))
	if day_after <= day_before:
		_fail("sleeping at home did not advance the day (%d -> %d)" % [day_before, day_after])
	else:
		print("slept at home: day %d -> %d" % [day_before, day_after])
	if not bool(progression.call("has", "player_slept_at_home")):
		_fail("sleeping at home did not clear the objective ladder's rest rung")

	_finish()


func _stand_beside(player: CharacterBody3D, at: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = at + Vector3(STAND_OFF_M, 0.2, 0.0)
	for i in 20:
		await physics_frame


func _find_by_script(node: Node, path: String) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("home sleep smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
