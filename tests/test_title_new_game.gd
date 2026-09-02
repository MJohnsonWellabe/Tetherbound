extends "res://tests/test_case.gd"

## The title's Start New Game action resets the live Game autoload but must
## never erase save slots.  This pure-state half complements
## smoke_title_new_game.gd, which presses the real focused title button with a
## joypad event and observes the scene transition.

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const TEST_DIR := "user://test_title_new_game_saves/"

var game: Node
var saver: RefCounted


func before_each() -> void:
	_wipe_test_dir()
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	game.reset_for_new_game()


func after_each() -> void:
	if game != null:
		game.free()
		game = null
	_wipe_test_dir()


func test_new_game_clears_loaded_progress_but_preserves_save_slots() -> void:
	game.day = 8
	game.inventory.add("berries", 12)
	game.party.add(game.make_creature("terrapup", "Keeper"))
	game.hotbar[0] = "berries"
	game.placed_buildings = [{"id": "tent", "position": [1.0, 2.0, 3.0], "yaw_deg": 0.0}]
	game.farm_plots = [{"state": "ripe", "ripe_on_day": 8}]
	game.death_satchels = [{"position": [2.0, 0.0, 2.0], "state": []}]
	game.harvested_vegetation = {"trees": "AQ=="}
	game.felled_vegetation = {"trees#0": {"item": "wood", "amount": 2}}
	game.saved_player_pose = {
		"position": [4.0, 5.0, 6.0],
		"model_yaw": 0.1,
		"camera_yaw": 0.2,
		"camera_pitch": -0.1,
	}
	game.progression.set_flag("warden_defeated")
	game.map.mark_visited(Vector3.ZERO)
	game.satiety = 24.0
	game.pending_build = "wall"
	game.pending_catch = game.make_creature("ripplet")
	game.equipped_tool = "axe"

	assert_true(saver.save(game, 2), "fixture save must reach the real slot writer")
	var saved_info: Dictionary = saver.slot_info(2)
	game.free_build = true
	game.debug_teleport = true
	game.reset_for_new_game()

	assert_eq(game.day, 1)
	assert_eq(game.inventory.used_slots(), 0)
	assert_eq(game.party.size(), 0)
	assert_eq(game.hotbar, ["", "", "", "", ""])
	assert_true(game.placed_buildings.is_empty())
	assert_true(game.farm_plots.is_empty())
	assert_true(game.death_satchels.is_empty())
	assert_true(game.harvested_vegetation.is_empty())
	assert_true(game.felled_vegetation.is_empty())
	assert_true(game.saved_player_pose.is_empty())
	assert_true(game.progression.all_set().is_empty())
	# NOT zero: the owner's 2026-08-22 §3 ruling seeds the village and the roads
	# out of it into a fresh fog grid, so a new game legitimately starts with a
	# little revealed. What this test is actually about is that a NEW game
	# discards the LOADED map, so compare against a fresh state's own fraction
	# rather than against a constant that stopped being true.
	var pristine: RefCounted = game.map.get_script().new()
	pristine.configure(game._map_landmarks_config())
	assert_almost_eq(game.map.discovered_fraction(), pristine.discovered_fraction())
	assert_true(game.map.discovered_fraction() < 0.05,
		"a new game reveals %.2f%% of the world; the seed is the home town, not a head start"
		% (game.map.discovered_fraction() * 100.0))
	assert_almost_eq(game.satiety, 100.0)
	assert_eq(game.pending_build, "")
	assert_eq(game.pending_catch, null)
	assert_eq(game.equipped_tool, "")
	assert_true(game.free_build, "New Game must preserve the player's settings")
	assert_true(game.debug_teleport, "New Game must preserve the player's settings")
	assert_true(saver.has_slot(2), "New Game must not delete existing slots")
	assert_eq(saver.slot_info(2), saved_info)


func test_fresh_party_still_enforces_the_five_creature_limit() -> void:
	for i in 5:
		assert_true(game.party.add(game.make_creature("terrapup", "Pal %d" % i)))
	assert_false(game.party.add(game.make_creature("ripplet", "Sixth")))
	assert_eq(game.party.size(), 5)


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
