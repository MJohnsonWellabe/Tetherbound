extends SceneTree

## OP-0905-20 / OP-0905-21.
##
##   godot --headless --path . --script tests/smoke_realm_teleport.gd
##
## Two owner playtest complaints, one fixture, because the debug-menu crossing
## exercises `enter_realm()`'s loading overlay on real production scenes. The
## original smoke covered Meadows <-> Cloudreach; FOUR-BIOME-BUILD now walks
## Meadows -> Cloudreach -> Stormwood -> Water -> Meadows so every shipped
## realm is an actual menu-reachable scene rather than a catalogue-only row.
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
	for locked_realm: String in ["cloudreach", "stormwood", "water"]:
		_expect(not bool(game.call("can_enter_realm", locked_realm)),
			"fixture already held the %s realm key -- the no-key case proves nothing" % locked_realm)

	_expect(bool(game.call("set_debug_teleport", true)), "debug teleport toggle refused to turn on")
	for destination_realm: String in ["cloudreach", "stormwood", "water", "meadows"]:
		if not await _cross_to(game, destination_realm):
			_finish(game)
			return

	_finish(game)


func _cross_to(game: Node, destination_realm: String) -> bool:
	var destinations: Array = game.call("debug_teleport_destinations")
	var crossing := _first_realm_entry(destinations, destination_realm)
	if crossing.is_empty():
		_fail("no %s entry in the debug teleport list from %s" % [destination_realm, game.get("current_realm")])
		return false
	var display_name := str(crossing.get("display_name", ""))
	var realm_spec: Dictionary = game.realm_hearts.call("realm", destination_realm)
	var realm_display := str(realm_spec.get("display_name", destination_realm))
	_expect(display_name.begins_with("%s — " % realm_display),
		"%s row '%s' is not labelled as a crossing" % [destination_realm, display_name])
	_expect(str(crossing.get("entry_id", "")) != "", "%s row carried no entry id" % destination_realm)
	var target: Vector2 = crossing.get("position", Vector2.ZERO)

	# Watch concurrently: the overlay must appear before the blocking scene
	# swap and disappear only after the destination has drawn and settled.
	_saw_overlay = false
	_watch_for_overlay()
	var ok: bool = await game.call("debug_teleport_to", target.x, target.y,
		str(crossing.get("realm", "")), str(crossing.get("entry_id", "")))
	_expect(ok, "debug_teleport_to refused the crossing to %s" % destination_realm)
	if not ok:
		return false
	_expect(_saw_overlay, "the loading overlay never appeared during the crossing to %s" % destination_realm)
	_expect(root.get_node_or_null(^"LoadingOverlay") == null,
		"the loading overlay remained after the crossing to %s" % destination_realm)
	_expect(str(game.get("current_realm")) == destination_realm,
		"Game did not finish the crossing in %s" % destination_realm)
	_expect(str(game.get("pending_realm_entry")) == "", "%s did not settle its pending entry" % destination_realm)

	var player := game.call("find_player") as Node3D
	if player == null:
		_fail("no live Player after the crossing to %s" % destination_realm)
		return false
	var pos: Vector3 = player.global_position
	_expect(is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z),
		"%s player landed at a non-finite position (%s)" % [destination_realm, pos])
	var world := current_scene
	var ground: float = float(world.call("ground_height_at", target.x, target.y)) \
		if world != null and world.has_method("ground_height_at") else NAN
	var expected_y := ground + float(GAME.DEBUG_TELEPORT_CLEARANCE)
	_expect(not is_nan(ground), "%s reported no ground at the chosen destination" % destination_realm)
	_expect(is_equal_approx(pos.x, target.x) and is_equal_approx(pos.z, target.y),
		"%s landed at (%.1f,%.1f), expected (%.1f,%.1f)" % [destination_realm, pos.x, pos.z, target.x, target.y])
	_expect(is_equal_approx(pos.y, expected_y),
		"%s landed at y=%.2f, expected ground(%.2f) + clearance = %.2f" % [destination_realm, pos.y, ground, expected_y])
	return true


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
		print("REALM TELEPORT OK: menu crossings Meadows -> Cloudreach -> Stormwood -> Water -> Meadows")
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
