extends SceneTree

## CAP-1 reproduction and its fix, on the real Meadows scene.
##
##   godot --headless --path . --script tools/_probe_cap1_faint_floor.gd
##
## `ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md`: the capstone's tutorial
## catch ended with the starter fainted and the chapter walked on. This asks the
## three questions that decide whether that state is recoverable, from inside a
## live world with the real autoloads:
##
##   1. with the starter fainted at the opening's encounter beat, does anything
##      put it back up?
##   2. is the follower body the player has to look at actually visible again?
##   3. does the game offer a fight again -- `encounter_director::_engageable()`
##      is what refused ten times in a row in the capstone's S03.
##
## Then it forces the beat PAST the opening and faints the party again, to show
## the floor does not follow the player out of the tutorial.
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

var _world: Node = null
var _game: Node = null
var _director: Node = null
var _encounter: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	for child: Node in _world.get_children():
		var script: Script = child.get_script()
		if script == null:
			continue
		var path := str(script.resource_path)
		if path.ends_with("sequence_director.gd"):
			_director = child
		elif path.ends_with("encounter_director.gd"):
			_encounter = child
	if _encounter == null:
		_encounter = _world.get_tree().get_first_node_in_group("encounter_director")
	if _director == null or _game == null or _encounter == null:
		print("no director/game/encounter; probe cannot run")
		quit(1)
		return

	print("\n=== the starter, adopted and deployed the way the opening does ===")
	_force("encounter")
	var adopted: bool = await _encounter.call("adopt_starter", "ripplet", "Moss")
	print("  adopt_starter: %s" % str(adopted))
	var starter: RefCounted = _encounter.call("ally_instance")
	if starter == null:
		print("  no ally instance; probe cannot run")
		quit(1)
		return
	var party: RefCounted = _game.get("party")
	party.call("add", starter)
	for i in 20:
		await physics_frame
	_report("before the fight is lost")

	print("\n=== the capstone's state: 18 unanswered hits, the starter down ===")
	starter.call("take_damage", float(starter.get("max_hp")) * 10.0)
	print("  party all_fainted: %s" % str(party.call("all_fainted")))
	# CombatManager hides the deployed body on the way out of every fight; do the
	# same here so the probe reports on the state a real lost fight leaves behind
	# rather than a tidier one.
	var body: Node3D = _encounter.call("ally_body") as Node3D
	if body != null:
		body.visible = false
	for i in 60:
		await physics_frame
	_report("one second after the fight would have ended")

	print("\n=== and past the opening, where losing is supposed to cost ===")
	_force("free_play")
	starter.call("take_damage", float(starter.get("max_hp")) * 10.0)
	print("  party all_fainted: %s" % str(party.call("all_fainted")))
	for i in 60:
		await physics_frame
	_report("one second later, outside the tutorial")
	quit(0)


func _report(when: String) -> void:
	var party: RefCounted = _game.get("party")
	var starter: RefCounted = party.call("at", 0)
	var body: Node3D = _encounter.call("ally_body") as Node3D
	print("  %s:" % when)
	print("    beat:              %s" % str(_director.call("beat")))
	print("    starter fainted:   %s   hp %.1f / %.1f" % [
		str(starter.get("fainted")), float(starter.get("hp")), float(starter.get("max_hp"))
	])
	print("    follower visible:  %s" % (str(body.visible) if body != null else "<no body>"))
	print("    a fight is offered: %s" % str(not bool(_encounter.call("no_usable_ally"))))
	print("    world message:     '%s'" % str(_game.call("take_pending_world_message")))


func _force(beat: String) -> void:
	var progression: RefCounted = _game.get("progression")
	if progression != null:
		progression.call("set_flag", "opening:beat:" + beat)
	_director.call("_force_restore_beat", beat)
