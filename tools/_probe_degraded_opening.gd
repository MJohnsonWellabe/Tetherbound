extends SceneTree

## Does the opening chain DEGRADE SAFELY?
##
##   godot --headless --path . --script tools/_probe_degraded_opening.gd
##
## Gate F run 3, check-in 17 (`ralph/reports/gate-f-lane-log.md`): S02 recorded
## zero `combat_*` and zero `catch_throw` events — the chapter's first fight
## never staged and the first wild catch never happened — and the segment still
## handed off. `S02-exit.json` is that handoff, and it is a REAL degraded state
## rather than a hypothetical one:
##
##   party: 1 (the starter)
##   flags: opening:beat:wake, opening:beat:house, opening:beat:choose,
##          opening:starter_granted, opening:beat:name, tournament_team_fed,
##          opening:beat:walk_out
##
## Two things are wrong with that flag set, and both are this lane's business:
##
##   1. `opening:beat:return_starter` is MISSING while `opening:beat:walk_out` is
##      present — a beat skipped in the middle of an ordered chain. OP-0830-4's
##      `_persist_beat_history()` is supposed to heal exactly this on load.
##   2. no `opening:beat:road`, no `road_gate_open` — the player never caught
##      anything and never opened the gate.
##
## The question the coordinator routed, and the one this answers: **is a player
## in that state stuck forever with no indication, exactly as they were stuck in
## Grandpa's house?** Same defect shape as OP-0830-4, and worth answering as one
## problem rather than two.
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

## Copied verbatim from
## `ralph/reports/gate-f-run-20260827T025303Z/S02/saves/S02-exit.json`. Not
## invented, and deliberately including the skipped beat and the stray
## `tournament_team_fed`: the point is to reproduce the state the rig actually
## handed off, not a tidied version of it.
const S02_EXIT_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "tournament_team_fed",
	"opening:beat:walk_out",
]

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")

var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _director: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	for child: Node in _world.get_children():
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("sequence_director.gd"):
			_director = child
	if _game == null or _player == null or _director == null:
		print("missing game/player/director; probe cannot run")
		quit(1)
		return

	var progression: RefCounted = _game.get("progression")
	print("--- entering the S02-exit state (party 1, first catch never happened) ---")
	for flag: String in S02_EXIT_FLAGS:
		progression.call("set_flag", flag)
	# The load path, not a poke: this is what a real Load does, and it is where
	# `_persist_beat_history()` gets its chance to heal the skipped beat.
	_director.call("restore_progression_from_game", _game)
	for i in 30:
		await physics_frame

	print("  beat restored to: %s" % str(_director.call("beat")))
	print("\n--- 1. did the skipped beat heal? ---")
	for beat: String in ["wake", "house", "choose", "name", "return_starter", "walk_out", "road"]:
		var flag := "opening:beat:" + beat
		var was := S02_EXIT_FLAGS.has(flag)
		var now := bool(progression.call("has", flag))
		var note := ""
		if now and not was:
			note = "  <- HEALED (was missing in the handed-off save)"
		elif not now:
			note = "  <- still unset"
		print("  %-32s save=%s now=%s%s" % [flag, str(was), str(now), note])

	print("\n--- 2. what is the player told? ---")
	var quest_log: RefCounted = _game.get("quest_log")
	print("  tracked objective: '%s'" % str(quest_log.call("tracked_text", progression)))
	print("  hint:              '%s'" % str(quest_log.call("tracked_hint", progression)))
	var guided: Array = quest_log.call("guided_entries", progression)
	print("  guided ladder shows %d rung(s); the open one is '%s'" % [
		guided.size(),
		str((guided[guided.size() - 1] as Dictionary).get("label", "")) if not guided.is_empty() else ""])

	print("\n--- 3. is the player confined, and if so does anything end it? ---")
	var house := _world.get_node_or_null(^"GrandpaHouse")
	if house != null:
		var gate := house.get_node_or_null(^"DoorGate")
		var solid := true
		for child: Node in gate.get_children() if gate != null else []:
			if child is CollisionShape3D:
				solid = not (child as CollisionShape3D).disabled
		print("  Grandpa's door: %s" % ("STILL SOLID" if solid else "open"))
	var outline := BOUNDARY.outline(BOUNDARY.load_config())
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	print("  inside the village boundary: %s" % str(BOUNDARY.contains(outline, here)))

	# The two things that must still be reachable from here, or the chain really
	# is a dead end: the practice creature to catch, and the key that opens the
	# gate. Both are asked of the world, not assumed.
	var bramblebun := Vector2(30.0, -40.0)
	print("  the practice bramblebun (30,-40) is inside the boundary: %s" % str(BOUNDARY.contains(outline, bramblebun)))
	var key := _world.find_child("GateKey", true, false) as Node3D
	if key == null:
		print("  the gate key: NOT IN THE WORLD (already taken, or never spawned)")
	else:
		var key_xz := Vector2(key.global_position.x, key.global_position.z)
		print("  the gate key at (%.1f, %.1f), inside the boundary: %s" % [
			key_xz.x, key_xz.y, str(BOUNDARY.contains(outline, key_xz))])
	var road_gate := _world.find_child("RoadGate", true, false)
	if road_gate != null:
		print("  the village gate is open: %s (it needs the key, not the catch)" % str(road_gate.call("is_open")))

	print("\n--- 4. can the player still finish the chain from here? ---")
	# Take the key and try the gate, exactly as a player would, and confirm the
	# objective ladder moves. If the catch is genuinely the only blocker, this
	# still advances -- and that is what "degrades safely" means.
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "castle_gate_key", 1)
	if road_gate != null:
		road_gate.call("_on_tried")
		for i in 20:
			await physics_frame
		print("  after opening the gate with the key:")
		print("    road_gate_open: %s" % str(progression.call("has", "road_gate_open")))
		print("    tracked objective: '%s'" % str(quest_log.call("tracked_text", progression)))
	quit(0)
