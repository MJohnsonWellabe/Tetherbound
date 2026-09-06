extends SceneTree

## OP-0905-20 / OP-0905-21.
##
##   godot --headless --path . --script tests/smoke_realm_teleport.gd
##
## Two owner playtest complaints, one fixture, because the second complaint's
## fix (a debug-menu crossing into Cloudreach) exercises the first complaint's
## fix (`enter_realm()`'s loading overlay) on the very same real production
## crossing:
##
##   OP-0905-20: "When I press enter cloudreach cliffs the game froze for a
##   while. It should tell you it's loading." Proven by watching for the
##   `LoadingOverlay` CanvasLayer `enter_realm()` adds to `root` BEFORE its
##   blocking `change_scene_to_file()`, and confirming it is gone again once
##   the crossing settles.
##
##   OP-0905-21: "I didn't think I can teleport to the second biome in the
##   menu and I should be able to." Proven against the real
##   `GameState.debug_teleport_destinations()`/`debug_teleport_to()` contract:
##   a Cloudreach row appears while standing in the Meadows WITHOUT the
##   `realm_key_cloudreach` entitlement (debug teleport is a settings escape
##   hatch, not a second copy of the story gate), and pressing it actually
##   lands the player, grounded, in the real Cloudreach scene.
##
## This uses the real production `cloudreach_cliffs.tscn` (the same scene
## tests/smoke_cloudreach_transition.gd crosses into), not a stand-in — the
## whole point is the real scene swap, the real overlay, and the real
## destination `ground_height_at`.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TEST_SAVE_DIR := "user://realm_teleport_smoke"

## Generous headroom for the real Cloudreach scene's synchronous procedural
## build, the same order of magnitude smoke_cloudreach_transition.gd already
## budgets for the identical crossing.
const OVERLAY_WATCH_FRAMES := 600

var _failures: Array[String] = []
var _saw_overlay := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))

	# A bare placeholder scene, exactly as smoke_cloudreach_transition.gd
	# uses -- `change_scene_to_file` needs SOME current scene to replace, and
	# nothing about the destinations list or the crossing itself needs the
	# full Meadows world built (map/landmark data comes straight off JSON via
	# `bind_realm_map()`, not off the scene).
	var source := Node3D.new()
	source.name = "RealmTeleportSmokeSource"
	root.add_child(source)
	current_scene = source
	await process_frame

	_expect(str(game.get("current_realm")) == "meadows", "fresh game did not start in the Meadows")
	_expect(not bool(game.call("can_enter_realm", "cloudreach")),
		"fixture already held the Cloudreach realm key -- the no-key case below proves nothing")

	_expect(bool(game.call("set_debug_teleport", true)), "debug teleport toggle refused to turn on")

	var destinations: Array = game.call("debug_teleport_destinations")
	var crossing := _first_realm_entry(destinations, "cloudreach")
	if crossing.is_empty():
		_fail("no Cloudreach entry in the debug teleport list while standing in the Meadows and lacking the realm key -- OP-0905-21 regressed")
		_finish(game)
		return
	var display_name := str(crossing.get("display_name", ""))
	_expect(display_name.begins_with("Cloudreach Cliffs — "),
		"Cloudreach row '%s' is not labelled as a crossing" % display_name)
	_expect(str(crossing.get("entry_id", "")) != "", "Cloudreach row carried no entry id")
	var target: Vector2 = crossing.get("position", Vector2.ZERO)

	# OP-0905-20: watch for the overlay concurrently with the teleport call
	# below rather than after it -- it is meant to appear BEFORE the blocking
	# scene swap and disappear once the destination has drawn a frame, a
	# window this real crossing holds open for several frames, not one.
	_watch_for_overlay()

	var ok: bool = await game.call("debug_teleport_to", target.x, target.y,
		str(crossing.get("realm", "")), str(crossing.get("entry_id", "")))
	_expect(ok, "debug_teleport_to refused the Cloudreach crossing")

	_expect(_saw_overlay, "the 'Loading Cloudreach Cliffs…' overlay never appeared during the crossing")
	_expect(root.get_node_or_null(^"LoadingOverlay") == null,
		"the loading overlay was not removed once the crossing settled")

	_expect(str(game.get("current_realm")) == "cloudreach", "Game did not finish the crossing in Cloudreach")
	_expect(str(game.get("pending_realm_entry")) == "", "Cloudreach did not settle its pending entry")

	var player := game.call("find_player") as Node3D
	if player == null:
		_fail("no live Player after the Cloudreach crossing")
	else:
		var pos: Vector3 = player.global_position
		_expect(is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z),
			"player landed at a non-finite position (%s)" % pos)
		var world := current_scene
		var ground: float = float(world.call("ground_height_at", target.x, target.y)) if world != null else NAN
		var expected_y := ground + float(GAME.DEBUG_TELEPORT_CLEARANCE)
		_expect(not is_nan(ground), "Cloudreach reported no ground at the chosen destination")
		_expect(is_equal_approx(pos.x, target.x) and is_equal_approx(pos.z, target.y),
			"player landed at (%.1f,%.1f), expected the chosen destination (%.1f,%.1f)" % [pos.x, pos.z, target.x, target.y])
		_expect(is_equal_approx(pos.y, expected_y),
			"player landed at y=%.2f, expected ground(%.2f) + clearance = %.2f" % [pos.y, ground, expected_y])

	# Symmetry: the list built from inside Cloudreach must offer a way back,
	# and taking it must actually land at the CHOSEN destination -- not the
	# Storm Road anchor. The Meadows arrival runs its own settle coroutine
	# (`playground_world.gd::_settle_meadows_realm_arrival`) that re-asserts
	# that anchor position a few physics frames after `_place_player()`, so
	# this is the one direction that would actually catch
	# `_debug_teleport_cross_realm` overriding x/z too early and quietly
	# losing that race.
	var return_destinations: Array = game.call("debug_teleport_destinations")
	var return_crossing := _first_realm_entry(return_destinations, "meadows")
	if return_crossing.is_empty():
		_fail("no Meadows entry in the debug teleport list while standing in Cloudreach")
		_finish(game)
		return
	var return_target: Vector2 = return_crossing.get("position", Vector2.ZERO)
	_saw_overlay = false
	_watch_for_overlay()
	var return_ok: bool = await game.call("debug_teleport_to", return_target.x, return_target.y,
		str(return_crossing.get("realm", "")), str(return_crossing.get("entry_id", "")))
	_expect(return_ok, "debug_teleport_to refused the return crossing to the Meadows")
	_expect(_saw_overlay, "the loading overlay never appeared during the return crossing")
	_expect(root.get_node_or_null(^"LoadingOverlay") == null,
		"the loading overlay was not removed once the return crossing settled")
	_expect(str(game.get("current_realm")) == "meadows", "Game did not finish the return crossing in the Meadows")

	var returned_player := game.call("find_player") as Node3D
	if returned_player == null:
		_fail("no live Player after the return crossing to the Meadows")
	else:
		var return_pos: Vector3 = returned_player.global_position
		_expect(is_equal_approx(return_pos.x, return_target.x) and is_equal_approx(return_pos.z, return_target.y),
			("player landed back in the Meadows at (%.1f,%.1f), expected the chosen destination (%.1f,%.1f) " +
				"-- the anchor settle coroutine likely won the race and overrode it") % [
					return_pos.x, return_pos.z, return_target.x, return_target.y])

	_finish(game)


func _watch_for_overlay() -> void:
	for _frame in OVERLAY_WATCH_FRAMES:
		if root.get_node_or_null(^"LoadingOverlay") != null:
			_saw_overlay = true
			return
		await process_frame


func _first_realm_entry(destinations: Array, realm_id: String) -> Dictionary:
	for entry: Variant in destinations:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str((entry as Dictionary).get("realm", "")) == realm_id:
			return entry as Dictionary
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _finish(game: Node) -> void:
	if game != null:
		game.call("set_debug_teleport", false)
	_cleanup_test_saves()
	if _failures.is_empty():
		print("REALM TELEPORT OK: OP-0905-20 loading overlay, OP-0905-21 cross-realm debug teleport")
		quit(0)
		return
	for failure: String in _failures:
		push_error("REALM TELEPORT: %s" % failure)
	quit(1)


func _cleanup_test_saves() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute)
