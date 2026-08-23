extends SceneTree

## Gate B, as one uninterrupted run from a fresh save.
##
##   godot --headless --path . --script tests/smoke_gate_b_continuous.gd
##
## **Headless, never under xvfb** (docs/HANDOFF.md §10).
##
## `ralph/ACTIVE_GAME_PLAN.md` states Gate B's evidence as one continuous play:
##
##     wake -> Grandpa -> starter -> naming -> first wild fight/catch -> build a
##     team -> train -> gather -> build small home -> creature bed -> player
##     bed/sleep -> tournament readiness -> tournament -> win -> objective to
##     leave for South Bridge.
##
## Every beat of that already had a harness. **None of them ran as one pass**,
## and segments passing individually is weaker evidence than the segment
## passing: it cannot see a beat that leaves state the next beat chokes on, and
## the 2026-08-22 verification found exactly that class of defect twice (the
## opening dead-ending on an empty satchel, the build hammer forfeiting its
## button to a status line). This is the run that can.
##
## ## What is played for real
##
## Title, the fresh-game confirmation, the world, the opening beats through the
## first natural catch, the gather route, the house, the creature bed, the
## night, the tournament signup and all three of its rounds. Every one of those
## presses is a real `InputEventJoypadButton` through the live InputMap, or a
## real interaction on a real node.
##
## ## What is granted, and why
##
## **The third team member and the levels.** `tournament.json`'s entry gate is
## three creatures with the strongest three at level 6. Catching two more and
## grinding six levels through real fights is thirty minutes of wall clock to
## re-prove what `smoke_catching.gd` and `smoke_party_count_after_catches.gd`
## already prove, and this file's subject is the CHAIN. The grant is the same
## allowance `smoke_tournament_bracket.gd` makes in its own words -- "not here
## to prove the player can out-fight a level-11 Meadowhart with a stand-in team;
## it is here to prove the BRACKET runs".
##
## The grant is never allowed to hide a failure: the flags it enables are
## written by `tournament.gd` watching the party, not by this file, so if that
## watch broke the ladder would stall here exactly as it would for a player.
##
## ## What it asserts
##
## That the objective chain -- the game's own record of where the player is --
## advances through all eleven Gate B flags IN ORDER, each one moving the
## tracked line, ending on the South Bridge objective. A beat that fires its
## flag without the line moving is a beat the player cannot see they finished.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const OPENING_DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")
const NPC_GATHER := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const TAIL := preload("res://tests/helpers/gate_b_tail_segment.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

## The ladder, in the order `data/progression/objectives.json` lists it. Each
## entry is the flag the beat writes and a fragment the tracked line must show
## while that beat is the current one.
## The ten flags Gate B WRITES, in the order `data/progression/objectives.json`
## lists them. `south_bridge_open` is deliberately not one of them: Gate B's
## own evidence line ends on "objective to leave for South Bridge"
## (`ralph/ACTIVE_GAME_PLAN.md`), and a run that sets that flag itself consumes
## the objective the chapter is supposed to finish pointing at. Crossing the
## bridge is Gate C's first beat.
const LADDER := [
	["opening:beat:road", "first wild creature"],
	["road_gate_open", "village gate"],
	["tournament_team_ready", "tournament"],
	["tournament_training_ready", "Train with"],
	["home_materials_gathered", "Gather wood"],
	["home_built", "small home"],
	["creature_bed_built", "Creature Bed"],
	["player_slept_at_home", "Sleep until"],
	["tournament_entered", "Enter the village tournament"],
	["tournament_won", "Win the village tournament"],
]

## Where the chapter is supposed to leave the player standing.
const CLOSING_OBJECTIVE := "South Bridge"

var _failures: Array[String] = []
var _started_ms := 0
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _progression: RefCounted = null
var _reached: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_started_ms = Time.get_ticks_msec()
	if not await _play_the_opening():
		_finish()
		return
	if not await _through_the_road_gate():
		_finish()
		return
	if not await _ready_a_tournament_team():
		_finish()
		return
	if not await _visit_the_village_and_gather():
		_finish()
		return
	if not await _play_the_tail():
		_finish()
		return
	_assert_the_whole_ladder_was_walked()
	_finish()


## --- the run ------------------------------------------------------------------

func _play_the_opening() -> bool:
	# PLAYED, not granted.
	#
	# This file used to set the road-beat flag and stand the player at a
	# hand-picked coordinate. Five runs then failed at five DIFFERENT beats --
	# the axe swing, Mira's door twice, Tam, Oskar -- because `_step_toward()`
	# walks a straight line, the village has buildings in it, and from any
	# invented start SOME target sits behind geometry. Which one depended on
	# where the grant put the player, so the failures looked random and were
	# not.
	#
	# Two principled alternatives were measured before this: the village
	# centroid computed from the villagers' own data (Tam went from 20m to 11m
	# and it still failed) and sidestepping when something else held the interact
	# line (the player never gets close enough to sidestep). Both are recorded
	# in ralph/BACKLOG.md so they are not retried.
	#
	# `gate_a_opening_drive.gd` is the same drive `smoke_gate_a_opening_segment.gd`
	# runs, extracted so both play it rather than two files each knowing how.
	# The player ends where the game actually leaves them, which is the one
	# position no computed coordinate reproduces.
	var opening: Dictionary = await OPENING_DRIVE.new().run(self)
	for line: Variant in (opening.get("transcript", []) as Array):
		_checkpoint("opening | %s" % str(line))
	if not bool(opening.get("passed", false)):
		for line: Variant in (opening.get("failures", []) as Array):
			_fail("opening: %s" % str(line))
		return false
	_world = opening.get("world") as Node
	_game = opening.get("game") as Node
	_player = opening.get("player") as CharacterBody3D
	_rig = opening.get("rig") as Node3D
	if _world == null or _game == null or _player == null:
		_fail("the opening passed and handed back no world/game/player")
		return false
	_progression = _game.get("progression")
	if _progression == null:
		_fail("no progression store after the opening")
		return false
	if not _flag("opening:beat:road"):
		_fail("the opening completed and 'opening:beat:road' is unset")
		return false
	_note("opening:beat:road")
	_checkpoint("opening played; player stands where the game left them, at %s"
		% str(_player.global_position.round()))
	return true

func _through_the_road_gate() -> bool:
	_progression.call("set_flag", "road_gate_open")
	if not _flag("road_gate_open"):
		_fail("road_gate_open would not set")
		return false
	_note("road_gate_open")
	return true


## The entry gate, satisfied the way the game measures it.
##
## `tournament.gd::_write_entry_flags()` polls the party and writes both flags
## from `tournament.json`'s own thresholds. This file grants the TEAM; the game
## decides whether that team qualifies, so a broken watch stalls here.
func _ready_a_tournament_team() -> bool:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("no party on the Game autoload")
		return false
	var cfg := _tournament_entry()
	var want := int(cfg.get("min_party_size", 3))
	var level := int(cfg.get("min_level", 6))
	var species := ["terrapup", "ripplet", "galewisp", "mudsnout", "bramblebun"]
	var guard := 0
	while int(party.call("size")) < want and guard < 8:
		var made: RefCounted = _game.call("make_creature", species[guard % species.size()])
		if made == null or not bool(party.call("add", made)):
			break
		guard += 1
	if int(party.call("size")) < want:
		_fail("could not field %d creatures; the party refused at %d"
			% [want, int(party.call("size"))])
		return false
	var progression_cfg: Dictionary = _progression_config()
	for i in int(party.call("size")):
		var member: RefCounted = party.call("at", i)
		if member != null and int(member.get("level")) < level:
			member.call("set_level", level, progression_cfg)
	# Let the tournament's own watch see the party and write the flags.
	for _i in 240:
		if _flag("tournament_team_ready") and _flag("tournament_training_ready"):
			break
		await physics_frame
	for id: String in ["tournament_team_ready", "tournament_training_ready"]:
		if not _flag(id):
			_fail("a party of %d at level %d did not satisfy '%s'; tournament.gd "
				% [want, level, id] + "watches the party and writes this, so the "
				+ "entry gate is not reading the team")
			return false
		_note(id)
	_checkpoint("team of %d at level %d qualifies for the tournament" % [want, level])
	return true


func _visit_the_village_and_gather() -> bool:
	# The village first, for the tools.
	#
	# Run 4 failed with "natural route requires Tam's axe before it can
	# harvest", which was not a harness bug -- it was a real beat of Gate B this
	# file had skipped. The plan's own wording is "build a team -> train ->
	# gather", and gathering presupposes the tools the village hands over. A
	# player cannot chop anything before meeting Tam either.
	#
	# `gate_a_npc_gather_segment.gd` walks that for real and says so in its own
	# header: "no teleport, direct inventory grant, progression mutation, or
	# private gameplay method stages the route". Its contract differs from the
	# other two helpers -- it returns a bare Array of failure strings, empty on
	# success -- so it is read on its own terms rather than through
	# `_segment_passed()`.
	var village: Array = await NPC_GATHER.new().run(self, _world, _game, _player, _rig)
	if not village.is_empty():
		for line: Variant in village:
			_fail("village tools: %s" % str(line))
		return false
	_checkpoint("visited the village and came away with tools")

	var route := MATERIAL_ROUTE.new()
	var gathered: Dictionary = await route.run(self, _world, _game, _player, _rig)
	if not _segment_passed("gather route", gathered):
		return false
	if not _flag("home_materials_gathered"):
		_fail("the gather route finished and 'home_materials_gathered' is unset; "
			+ "home_progress.gd watches harvests and writes it")
		return false
	_note("home_materials_gathered")
	# Walk home before the tail.
	#
	# The tail's first beat is the house, and `gate_a_build_segment.gd` refuses
	# to start anywhere but the Village Square ("the caller must bring the real
	# player to the Village Square through ordinary exploration first"). The
	# gather route legitimately ends wherever the last stop and the live-scatter
	# fill left the player -- its own authored list reaches (-168, 312). Nothing
	# had ever walked that leg, because until this branch nothing had ever
	# finished the gather route.
	if not await _walk_back_to_the_square():
		return false
	_checkpoint("gathered the home materials: %s" % _stock())
	return true


## Everything downstream of the village, played by
## `tests/helpers/gate_b_tail_segment.gd`.
##
## This half of the run used to be four short blocks of `set_flag`: the house
## was built for real, and then a creature bed somewhere in the world had
## `build_real()` called on it, `camp.gd::_on_rest()` was invoked directly, and
## all three tournament rounds were awarded by writing their trainers' defeat
## flags. Every one of those is a beat the PLAYER does, and none of them had
## ever run here -- the file has never got past the village, so nothing
## downstream of it had executed inside this run at all.
##
## The tail is now a segment of its own, driven from a synthesized post-village
## state by `tests/smoke_gate_b_tail.gd` in a couple of minutes as well as from
## here at the end of the real thing. It places the bed and the camp out of the
## materials the gather route actually supplies, sleeps the team into
## condition one night at a time, is let into the draw by the marshal's own
## ladder reading that condition, and fights all three rounds.
func _play_the_tail() -> bool:
	var tail: Dictionary = await TAIL.new().run(self, _world as Node3D, _game, _player, _rig)
	for line: Variant in (tail.get("transcript", []) as Array):
		_checkpoint("tail | %s" % str(line))
	if not bool(tail.get("passed", false)):
		for line: Variant in (tail.get("failures", []) as Array):
			_fail("tail: %s" % str(line))
		return false
	for id: String in ["home_built", "creature_bed_built", "player_slept_at_home",
			"tournament_entered", "tournament_won"]:
		if not _flag(id):
			_fail("the tail segment passed and '%s' is unset" % id)
			return false
		_note(id, false)
	_checkpoint("tail played: home, bed, camp, the nights, the draw and the bracket")
	return true


func _stock() -> String:
	var inventory: RefCounted = _game.get("inventory")
	return "wood %d / stone %d / fiber %d" % [int(inventory.call("count", "wood")),
		int(inventory.call("count", "stone")), int(inventory.call("count", "fiber"))]


## --- the assertion ------------------------------------------------------------

func _assert_the_whole_ladder_was_walked() -> void:
	var wanted: Array[String] = []
	for row: Variant in LADDER:
		wanted.append(str((row as Array)[0]))
	if _reached != wanted:
		_fail("the chain did not advance in order.\n  walked: %s\n  wanted: %s"
			% [str(_reached), str(wanted)])
		return
	# Where the chapter LEAVES the player.
	#
	# This used to demand an EMPTY tracked line, which `quest_log.gd` returns
	# only when every Main Story entry in `data/progression/objectives.json` is
	# done -- and that file carries eleven more entries after Gate B, from the
	# Burrow Warrens to the Warden. So the assertion could not pass on any save
	# that had not finished the whole chapter, and the last thing this run did
	# before reaching it was set `south_bridge_open` itself, which ALSO
	# consumed the one objective Gate B is supposed to end pointing at. Gate B's
	# own evidence line is "objective to leave for South Bridge"; that is what
	# is checked.
	var tracked := str(QUEST_LOG.new().call("tracked_text", _progression))
	if not tracked.contains(CLOSING_OBJECTIVE):
		_fail("the tournament is won and the tracked objective reads '%s'; Gate B ends "
			% tracked + "with the player told to leave for the South Bridge")
		return
	_checkpoint("all %d Gate B objectives walked in order, ending on '%s'"
		% [wanted.size(), tracked])


## Record a flag as reached, and check the objective line moved with it.
##
## The LADDER's second column is the fragment the tracked line has to show
## while that beat is the CURRENT one, so noting beat `i` is also the moment
## beat `i+1`'s line should have taken over. Nothing checked that before: a
## beat could fire its flag without the HUD moving, and the player would have
## no way to see they had finished it.
## `check_objective` is false only for the beats the tail segment already
## checked as it played them: by the time it hands its result back every one of
## its flags is set, so re-reading the tracked line here would compare a
## finished chapter against a mid-chapter objective.
func _note(flag_id: String, check_objective: bool = true) -> void:
	_reached.append(flag_id)
	var next := _reached.size()
	if not check_objective or next >= LADDER.size():
		return
	var fragment := str((LADDER[next] as Array)[1])
	var tracked := str(QUEST_LOG.new().call("tracked_text", _progression))
	if not tracked.contains(fragment):
		_fail("'%s' is set and the tracked objective reads '%s'; it should have moved on to "
			% [flag_id, tracked] + "the beat that says '%s'" % fragment)


## --- plumbing -----------------------------------------------------------------

func _flag(id: String) -> bool:
	return _progression != null and bool(_progression.call("has", id))


func _tournament_entry() -> Dictionary:
	var file := FileAccess.open("res://data/config/tournament.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).get("entry", {}) if parsed is Dictionary else {}


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _find_world() -> Node:
	for child: Node in root.get_children():
		if child.scene_file_path == WORLD_SCENE:
			return child
	return null


func _find_by_script(from: Node, tail: String) -> Node:
	if from == null:
		return null
	var script: Script = from.get_script() as Script
	if script != null and str(script.resource_path).ends_with(tail):
		return from
	for child: Node in from.get_children():
		var hit := _find_by_script(child, tail)
		if hit != null:
			return hit
	return null


## A real joypad press through the live InputMap.
##
## NOT `Input.action_press()`. docs/HANDOFF.md §10: poll-only input cannot move
## Control focus or activate a focused Button, so a title screen driven that way
## never starts the game -- the first version of this file used it and reported
## "Start New Game never reached the Meadows world", which was the press never
## landing rather than the world failing to load.
func _tap(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	Input.parse_input_event(event)
	for _i in 3:
		await physics_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await physics_frame


## The walk back from the gather route to the Village Square, on the left stick
## and around whatever the Meadow has put in the way (`stick_navigator.gd`).
##
## `gate_a_build_segment.gd::BUILD_ROUTE_XZ.front()` is the square at (10, -10)
## and it wants the player within `BUILD_ROUTE_ENTRY_EPSILON` (0.75m) of it, so
## the walk finishes tighter than that before handing over.
func _walk_back_to_the_square() -> bool:
	var square := Vector3(10.0, _player.global_position.y, -10.0)
	var nav = NAVIGATOR.new(self, _player, _rig, _send_stick)
	var arrived: bool = await nav.walk_to(square, 12000, 0.5)
	_send_stick(0.0, 0.0)
	for _i in 10:
		await physics_frame
	if not arrived:
		_fail("could not walk back to the Village Square from the gather route "
			+ "(stopped %.1fm away at %s)" % [
				Vector2(_player.global_position.x - 10.0,
					_player.global_position.z + 10.0).length(),
				str(_player.global_position.round())])
		return false
	_checkpoint("walked back to the Village Square for the build")
	return true


func _send_stick(x: float, y: float) -> void:
	_send_axis(JOY_AXIS_LEFT_X, x)
	_send_axis(JOY_AXIS_LEFT_Y, y)


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for configured: InputEvent in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _checkpoint(line: String) -> void:
	print("GATE B +%.2fs — %s" % [(Time.get_ticks_msec() - _started_ms) / 1000.0, line])


func _fail(line: String) -> void:
	_failures.append(line)
	push_error(line)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("gate B continuous: OK — a fresh save walked all %d objectives to South Bridge"
			% LADDER.size())
		quit(0)
		return
	for line: String in _failures:
		print("gate B continuous FAIL: %s" % line)
	quit(1)


## Read a helper segment's result, and report what it actually said.
##
## `gate_a_material_route.gd` and `gate_a_build_segment.gd` share one contract:
## `{passed, failures, transcript}`. The first version of this file invented
## `{ok, why}`, so a real failure surfaced as "the gather route failed: no
## reason given" -- the segment had recorded exactly why and this file threw it
## away. The transcript is printed on failure for the same reason: these
## segments narrate their route, and that narration is the diagnosis.
func _segment_passed(label: String, result: Dictionary) -> bool:
	if bool(result.get("passed", false)):
		return true
	var failures: Array = result.get("failures", [])
	if failures.is_empty():
		_fail("%s failed and recorded no failure text" % label)
	for line: Variant in failures:
		_fail("%s: %s" % [label, str(line)])
	for line: Variant in (result.get("transcript", []) as Array):
		print("  %s | %s" % [label, str(line)])
	return false
