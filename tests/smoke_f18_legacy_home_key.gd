extends SceneTree

## F18 review M1: a character saved before the portal runtime finished
## Grandpa's first catch without a Home Key. Loaded from its save with portals
## on and standing in Tidewake (not Meadows), the host must journal and
## deliver exactly one key through the ordinary production path, and nothing
## more on later ticks. An unloaded in-memory character is never touched.
const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WATER_SCENE := preload("res://scenes/world/water_archipelago.tscn")
const OPENING := preload("res://scripts/net/opening_home_key.gd")
const TEST_SAVE_DIR := "user://f18_legacy_home_key"
const BUILD_DEADLINE_MS := 120000

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	var session: Node = game.get("session")
	_expect(session != null and session.call("portal_runtime_ready") == true and session.call("is_host") == true,
		"shipped config runs the portal runtime with a solo host session")
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	# Disclosed legacy fixture: the opening's own persisted beat history through
	# walk_out (past Grandpa's first catch), no Home Key, no home_key_given.
	for beat: String in ["wake", "house", "choose", "name", "return_starter", "walk_out"]:
		game.get("local").flags.call("set_flag", "opening:beat:" + beat)
	_expect(game.get("inventory").count("home_key") == 0, "fixture starts without a Home Key")
	game.set("current_realm", "water")
	game.call("bind_realm_map")
	# An in-memory character (no load, no admission) is never reconciled:
	# fixtures and fresh games keep their own journal untouched.
	var quiet_until := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < quiet_until: await process_frame
	_expect(game.get("world").reward_deliveries.is_empty(), "no grant is journalled without a load or admission")
	# The legacy character arrives the way players do: from its own save.
	_expect(bool(game.call("save_game", 0)), "legacy fixture saves through the production schema")
	game.call("reset_for_new_game")
	_expect(bool(game.call("load_game", 0)), "legacy save loads")
	_expect(game.get("inventory").count("home_key") == 0 and str(game.get("current_realm")) == "water",
		"loaded legacy character is in Tidewake without a Home Key")
	var water := WATER_SCENE.instantiate() as Node3D
	root.add_child(water)
	current_scene = water
	var deadline := Time.get_ticks_msec() + BUILD_DEADLINE_MS
	while Time.get_ticks_msec() < deadline and not (water.has_method("shell_build_complete") and water.call("shell_build_complete") == true):
		await process_frame
	var arrived := false
	deadline = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.get("inventory").count("home_key") >= 1 and game.get("local").flags.call("has", "home_key_given") == true:
			arrived = true
			break
	_expect(arrived, "legacy character standing in Tidewake received the Home Key (count=%d)" % game.get("inventory").count("home_key"))
	# Several more host ticks (2 s each) must not journal or deliver again.
	deadline = Time.get_ticks_msec() + 7000
	while Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(game.get("inventory").count("home_key") == 1, "exactly one Home Key after repeated ticks")
	var grants := 0
	for row: Variant in game.get("world").reward_deliveries.values():
		if row is Dictionary and str(row.get("source", "")) == "home_key:grant:" + str(game.get("local").character_id): grants += 1
	_expect(grants == 1, "one deterministic grant row in the world journal (found %d)" % grants)
	_expect(OPENING.host_legacy_grant(session, int(session.call("local_peer_id"))).is_empty(), "a keyed character is no longer due")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute): DirAccess.remove_absolute(absolute.path_join(file))
	if _failures.is_empty():
		print("F18 LEGACY HOME KEY OK: past-first-catch save in Tidewake received exactly one key")
		quit(0)
		return
	for failure: String in _failures: push_error("F18 LEGACY HOME KEY: " + failure)
	quit(1)
