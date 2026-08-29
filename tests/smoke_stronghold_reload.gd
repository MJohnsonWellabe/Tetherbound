extends SceneTree

## GATE-E persistence: a save taken AFTER the finale must not respawn the
## legendary or replay the ceremony on reload.
##
##   godot --headless --path . --script tests/smoke_stronghold_reload.gd
##
## `smoke_gate_e_finale.gd` proves the finale plays through correctly in one
## continuous session; it never serializes and reloads a save, so it cannot
## catch a `build()` that runs a SECOND time -- which is exactly what
## loading a save does, since the whole world (`StrongholdClimax` included)
## is a fresh node reading flags that already say how the story ended. Two
## real windows exist:
##
##   * the roster decision is already settled (the ordinary case: the player
##     saved any time after finishing the ceremony) -- the chamber must not
##     stand a caged copy of a creature that is either walking the belt right
##     now or already gone;
##   * the lever was pulled but the decision was not yet settled (a save
##     landed between `legendary_freed` and `legendary_settled` -- rare, but
##     the dialogue panel does not pause the tree the way the ceremony's own
##     menu does, so `_tick_autosave()` can land there) -- the chamber must
##     come back FREED, not caged, and the machine's own gate must not be
##     stuck refused forever with no way left to reach the join offer again.
##
## `Game` only appears in the tree once a scene has been booted through this
## harness (`--script` mode does not eagerly attach autoloads), so a first,
## flagless world is booted purely to reach it -- the same order a real
## session takes: the engine starts, Game exists for the whole process, and
## only the WORLD gets replaced by a load. Flags are set on `Game.progression`
## (which outlives every world swap below) BEFORE each of the two scenario
## worlds is instantiated, so each one reads them exactly as a real load would.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _game: Node = null
var _progression: RefCounted = null


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("stronghold-reload FAIL: no Game autoload")
		quit(1)
		return
	_progression = _game.get("progression")
	if _progression == null:
		print("stronghold-reload FAIL: Game has no progression store")
		quit(1)
		return

	await _the_settled_ending_does_not_respawn_the_legendary()
	# `_progression` is the one autoload instance shared by every world this
	# file boots (see `_boot_world`'s own header) -- its flags do not reset
	# between scenarios on their own, so the settled ending's own flags have
	# to be cleared before staging the narrower freed-not-settled one, or the
	# second scenario would inherit `legendary_settled` from the first and
	# silently test the wrong branch.
	_progression.call("load_data", {})
	await _the_freed_but_unsettled_window_comes_back_freed_not_caged()

	print("")
	if _failures.is_empty():
		print("stronghold reload smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## The realistic post-finale save: the Warden is down, the lever was pulled,
## and the roster decision is over -- whichever way it went.
func _the_settled_ending_does_not_respawn_the_legendary() -> void:
	for flag in ["defeated_warden", "legendary_freed", "legendary_joined", "legendary_settled"]:
		_progression.call("set_flag", flag)

	var world := await _boot_world()
	var climax := world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("(settled) the world built no StrongholdClimax; nothing to inspect")
		return

	if climax.call("legendary_body") != null:
		_fail("(settled) a save with the roster decision already settled still stood the Bound Legendary back up")
	if str(climax.get("_stage")) != "done":
		_fail("(settled) the climax's stage is '%s', not 'done'" % str(climax.get("_stage")))
	var prompt := world.find_child("MachinePrompt", true, false)
	if prompt != null and bool(prompt.get("enabled")):
		_fail("(settled) the machine control is still live after the roster decision is already settled")
	else:
		print("settled ending: no Bound Legendary, stage 'done', machine control refused")


## The narrow reload window: freed, not yet settled.
func _the_freed_but_unsettled_window_comes_back_freed_not_caged() -> void:
	for flag in ["defeated_warden", "legendary_freed"]:
		_progression.call("set_flag", flag)

	var world := await _boot_world()
	var climax := world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("(freed) the world built no StrongholdClimax; nothing to inspect")
		return

	var legendary: Node3D = climax.call("legendary_body") as Node3D
	if legendary == null:
		_fail("(freed) the legendary never came back at all; the join offer can no longer be reached")
		return
	if legendary.get_node_or_null(^"ContainmentVFX") != null:
		_fail("(freed) the legendary is standing caged even though 'legendary_freed' is already set")

	for i in 12:
		await physics_frame
	if str(climax.get("_stage")) != "freed" and str(climax.get("_stage")) != "join" \
			and str(climax.get("_stage")) != "ceremony" and str(climax.get("_stage")) != "done":
		_fail("(freed) the climax's stage is '%s'; the sequence never resumed toward the join offer"
			% str(climax.get("_stage")))
	else:
		print("freed-not-settled window: the legendary came back freed, and the sequence resumed")


## One boot per scenario: the previous world (if any) is freed and a fresh
## one is instantiated so `StrongholdClimax.build()` reads whatever flags
## were just set, exactly the way a real "load game" hands a freshly-read
## save to a from-nothing scene. `Game` itself is never touched -- it is the
## one node that survives every swap, same as the real autoload does.
func _boot_world() -> Node:
	for child in root.get_children():
		if child.name != "Game":
			child.queue_free()
	for i in 4:
		await process_frame
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame
	return world
