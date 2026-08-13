extends "res://tests/test_case.gd"

## `GameState.register_building` — BG1 added an optional `yaw_deg` parameter
## alongside the existing `id`/`position` (docs/decisions/D28, `ralph/BACKLOG.md`
## `BG1`). `tests/test_save_format.gd` proves the round trip through a save
## file; this proves the accessor's own contract in isolation, the same split
## `test_free_build.gd` uses for `GameState`'s other accessors.
##
## GameState is instantiated directly rather than through the `Game` autoload
## for the same reason `test_free_build.gd` does: the runner shares one
## process across every test file, and `register_building` mutates
## `placed_buildings` in place.

const GAME_STATE := preload("res://autoload/game_state.gd")

var game: Node = null


func before_each() -> void:
	# _ready() is never called: it would mount the pause menu into a tree this
	# test does not have, and register_building touches nothing _ready() sets
	# up.
	game = GAME_STATE.new()


func after_each() -> void:
	if game != null:
		game.free()
		game = null


func test_register_building_defaults_yaw_to_zero() -> void:
	game.register_building("wall", Vector3(2.0, 0.0, 4.0))
	assert_eq(game.placed_buildings.size(), 1)
	var entry: Dictionary = game.placed_buildings[0]
	assert_almost_eq(float(entry.get("yaw_deg", -1.0)), 0.0)


func test_register_building_stores_the_given_yaw() -> void:
	game.register_building("wall", Vector3(2.0, 0.0, 4.0), 270.0)
	var entry: Dictionary = game.placed_buildings[0]
	assert_almost_eq(float(entry.get("yaw_deg", -1.0)), 270.0)


func test_register_building_still_stores_position_as_a_three_element_array() -> void:
	# The pre-BG1 shape must not have shifted underneath everything else that
	# reads placed_buildings (build_placer.gd::restore_from_game, save_game.gd).
	game.register_building("floor", Vector3(1.5, 0.25, -3.0), 180.0)
	var entry: Dictionary = game.placed_buildings[0]
	assert_eq(str(entry.get("id")), "floor")
	assert_eq(entry.get("position"), [1.5, 0.25, -3.0])


func test_multiple_registrations_each_keep_their_own_yaw() -> void:
	game.register_building("wall", Vector3.ZERO, 0.0)
	game.register_building("wall", Vector3(2.0, 0.0, 0.0), 90.0)
	assert_almost_eq(float((game.placed_buildings[0] as Dictionary).get("yaw_deg")), 0.0)
	assert_almost_eq(float((game.placed_buildings[1] as Dictionary).get("yaw_deg")), 90.0)
