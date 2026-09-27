extends SceneTree

## F15#2 witness tool, Meadows leg of the measured physical return.
## DRY RUN — fixture start, does not count. (The declared start is the Meadows
## scene built with the production `meadows_cloudreach_gate_return` pending
## entry, plus `opening:beat:free_play` so the Player accepts input. A counting
## run starts from the earned save instead.)
##
## The walk is stick input only, along the same path
## `tests/test_tidewake_return_cadence.gd::_meadows_segments` computes: from the
## Cloudreach-return arrival to Grandpa's door, taking the one-way quarry haul
## road. There are no pose, flag or inventory writes after the start. It walks
## at the production walk speed and never sprints.
##
## Every physics frame it records what the running world actually offers:
##   - encounter: a live wild creature within the director's engage range,
##   - prompt: an actionable interaction winning the arbiter,
##   - camp: inside a band camp's rest radius (same data as the model).
## It prints the offer timeline and every interval with no offer, in game
## seconds, against A7's 120 s. Evidence only: nothing is asserted.
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_tidewake_return_walk_meadows.gd [-- --json=<file>]
const SAVE := preload("res://scripts/save/save_game.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const CADENCE := preload("res://tests/test_tidewake_return_cadence.gd")
const MEADOWS_SCENE := "res://scenes/world/meadows_playground.tscn"
const RETURN_ENTRY := "meadows_cloudreach_gate_return"
const A7_LIMIT_S := 120.0
const LABEL := "DRY RUN — fixture start, does not count"

var _t := 0.0
var _last_offer_t := 0.0
var _last_offer := "meadows:arrive"
var _gaps: Array = []
var _offers: Array = []
var _seen_kind: Dictionary = {}
var _player: CharacterBody3D
var _world: Node
var _game: Node
var _engage := 6.0
var _camps: Array = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--json="): out = arg.trim_prefix("--json=")
	print("TIDEWAKE RETURN WALK MEADOWS: " + LABEL)
	await process_frame
	_game = root.get_node("Game")
	_game.set("save_system", SAVE.new("user://tidewake_return_walk_%d/" % Time.get_ticks_usec()))
	_game.call("reset_for_new_game")
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_game.set("pending_realm_entry", RETURN_ENTRY)
	if change_scene_to_file(MEADOWS_SCENE) != OK:
		_finish(out, "scene request failed")
		return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") \
				and bool(current_scene.call("shell_build_complete")) and str(_game.get("pending_realm_entry")).is_empty():
			break
	_world = current_scene
	_player = _game.call("find_player") as CharacterBody3D
	if _world == null or _player == null:
		_finish(out, "Meadows did not mount with a player")
		return
	for frame in 60:
		await physics_frame
	var cadence: Object = CADENCE.new()
	var path: Array = (cadence.call("_meadows_segments", true) as Array)[0].points
	_engage = float((JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json")) as Dictionary).get("flow", {}).get("engage_range", 6.0))
	for source: Dictionary in cadence.call("_meadows_sources", false):
		if str(source.kind) == "camp":
			_camps.append(source)
	print("TIDEWAKE RETURN WALK MEADOWS start pose=%s path_points=%d first=%s last=%s" % [
		_player.global_position, path.size(), path[0], path[-1]])
	var rig: Node3D = _world.get_node_or_null("CameraRig")
	var navigator := NAV.new(self, _player, rig, _stick)
	physics_frame.connect(_observe)
	var failed := ""
	for index in range(1, path.size()):
		var p: Vector2 = path[index]
		var target := Vector3(p.x, float(_world.call("ground_height_at", p.x, p.y)) + 0.2, p.y)
		var metres := Vector2(_player.global_position.x, _player.global_position.z).distance_to(p)
		if not await navigator.walk_to(target, maxi(600, int(metres * 40.0)), 2.0):
			failed = "stick walk stalled toward path point %d %s at %s" % [index, str(p), str(_player.global_position)]
			break
	_stick(0, 0)
	physics_frame.disconnect(_observe)
	_close_gap("meadows:end")
	_finish(out, failed)


func _observe() -> void:
	_t += 1.0 / Engine.physics_ticks_per_second
	var at := _player.global_position
	var offer := ""
	var director: Node = _world.get_node_or_null("EncounterDirector")
	var wilds: Array = director.call("wild_creatures") if director != null and director.has_method("wild_creatures") else []
	for body: Variant in wilds:
		if is_instance_valid(body) and (body as Node3D).is_inside_tree() and (body as Node3D).visible \
				and not bool(body.get("engaged")) and (body as Node3D).global_position.distance_to(at) <= _engage + 1.0:
			offer = "encounter:%s" % str((body as Node).name)
			break
	if offer.is_empty():
		var arbiter: Node = _world.get_node_or_null("InteractionArbiter")
		if arbiter != null:
			var winner: Dictionary = arbiter.call("winner")
			if not winner.is_empty() and bool(winner.get("actionable", false)):
				offer = "prompt:%s" % str(winner.get("label", ""))
	if offer.is_empty():
		for camp: Dictionary in _camps:
			if Vector2(at.x, at.z).distance_to(camp.at) <= float(camp.radius):
				offer = str(camp.id)
				break
	if offer.is_empty():
		return
	if offer != _last_offer or _t - _last_offer_t > 1.0:
		_close_gap(offer)
	_last_offer_t = _t
	_last_offer = offer


func _close_gap(next_offer: String) -> void:
	var gap := _t - _last_offer_t
	if gap >= 1.0:
		var at := _player.global_position
		_gaps.append({"from": _last_offer, "to": next_offer, "gap_s": snappedf(gap, 0.1),
			"ended_at": [snappedf(at.x, 0.1), snappedf(at.z, 0.1)], "t": snappedf(_t, 0.1)})
	if next_offer != _last_offer and not next_offer.begins_with("meadows:end"):
		_offers.append({"t": snappedf(_t, 0.1), "offer": next_offer})


func _stick(x: float, y: float) -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	if x < 0.0: Input.action_press("move_left", -x)
	elif x > 0.0: Input.action_press("move_right", x)
	if y < 0.0: Input.action_press("move_forward", -y)
	elif y > 0.0: Input.action_press("move_back", y)


func _finish(out: String, failed: String) -> void:
	var over: Array = _gaps.filter(func(g: Dictionary) -> bool: return float(g.gap_s) > A7_LIMIT_S)
	var worst := 0.0
	for gap: Dictionary in _gaps:
		worst = maxf(worst, float(gap.gap_s))
	var summary := {"label": LABEL, "walked_s": snappedf(_t, 0.1), "offers": _offers.size(),
		"worst_gap_s": snappedf(worst, 0.1), "over_a7": over, "failed": failed,
		"final_pose": [snappedf(_player.global_position.x, 0.1), snappedf(_player.global_position.z, 0.1)] if _player != null else []}
	print("TIDEWAKE RETURN WALK MEADOWS " + JSON.stringify(summary))
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"summary": summary, "gaps": _gaps, "offers": _offers}, "  "))
	quit(0)
