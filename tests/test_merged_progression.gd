extends "res://tests/test_case.gd"

## MP_STATE_SEAM.md §5 item 3: `Game.progression` is one object over two stores.
##
## `has` sees both; `set_flag` routes by scope; an unscoped id pushes an error
## AND lands in world so nothing stalls; `revision` moves when either store
## moves, because `game_state.gd::_process` polls exactly that number to decide
## whether the objective line changed.

const MERGED := preload("res://autoload/merged_progression.gd")
const FLAGS := preload("res://autoload/progression_state.gd")

var world: RefCounted = null
var player: RefCounted = null
var merged: RefCounted = null


func before_each() -> void:
	world = FLAGS.new()
	player = FLAGS.new()
	merged = MERGED.new(world, player)


# --- has / completed: either store ------------------------------------------

func test_has_sees_a_flag_in_either_store() -> void:
	world.set_flag("defeated_warden")
	player.set_flag("tam_tools_given")
	assert_true(merged.has("defeated_warden"), "a world flag is visible through the merged view")
	assert_true(merged.has("tam_tools_given"), "so is a player flag")
	assert_false(merged.has("south_bridge_open"), "and one nobody set is not")


func test_completed_is_the_same_query_as_has() -> void:
	# `progression_state.gd` keeps both spellings for objective/story call
	# sites; the merged view has to keep them agreeing.
	world.set_flag("warrens_cleared")
	assert_eq(merged.completed("warrens_cleared"), merged.has("warrens_cleared"))
	assert_eq(merged.completed("nothing_here"), merged.has("nothing_here"))


func test_either_store_alone_still_answers() -> void:
	# Wave 2 builds a PlayerState before a WorldState exists on a joining
	# client, and a headless tool may hand over only one.
	var world_only: RefCounted = MERGED.new(world, null)
	world.set_flag("defeated_warden")
	assert_true(world_only.has("defeated_warden"))
	assert_false(world_only.has("tam_tools_given"))
	var player_only: RefCounted = MERGED.new(null, player)
	player.set_flag("tam_tools_given")
	assert_true(player_only.has("tam_tools_given"))
	assert_false(player_only.has("defeated_warden"))


# --- set_flag routes by scope ------------------------------------------------

func test_set_flag_puts_a_world_id_in_the_world_store_only() -> void:
	merged.set_flag("defeated_warden")
	assert_true(world.has("defeated_warden"))
	assert_false(player.has("defeated_warden"),
		"a world fact must not be duplicated into one trainer's store")


func test_set_flag_puts_a_player_id_in_the_player_store_only() -> void:
	merged.set_flag("tam_tools_given")
	assert_true(player.has("tam_tools_given"))
	assert_false(world.has("tam_tools_given"),
		"a personal payoff must not become everyone's")


func test_set_flag_routes_a_prefixed_id_the_same_way() -> void:
	merged.set_flag("pickup:south_bridge_key")   # world prefix
	merged.set_flag("opening:beat:road")         # player prefix
	assert_true(world.has("pickup:south_bridge_key"))
	assert_false(player.has("pickup:south_bridge_key"))
	assert_true(player.has("opening:beat:road"))
	assert_false(world.has("opening:beat:road"))


func test_set_flag_false_clears_from_the_store_that_holds_it() -> void:
	# `tournament_team_fed` is the one flag the game actually CLEARS as well as
	# sets (objectives.json says so in its own entry), and it is player-scoped.
	merged.set_flag("tournament_team_fed")
	assert_true(merged.has("tournament_team_fed"))
	merged.set_flag("tournament_team_fed", false)
	assert_false(merged.has("tournament_team_fed"))
	assert_false(player.has("tournament_team_fed"))


func test_store_for_names_the_store_without_writing_to_it() -> void:
	# The four explicit-store writer sites (seam §3) resolve a store rather
	# than routing a write, so asking must not itself set anything.
	assert_true(merged.store_for("defeated_warden") == world)
	assert_true(merged.store_for("tam_tools_given") == player)
	assert_false(merged.has("defeated_warden"), "asking is not writing")


# --- the unscoped path: loud, and it still lands ----------------------------

func test_an_unscoped_id_pushes_an_error_and_lands_in_world() -> void:
	# The runtime is deliberately forgiving so a missed classification cannot
	# stall a run; `test_flag_scopes.gd` is what guarantees shipped data never
	# reaches here. The push_error below is EXPECTED output for this test.
	merged.set_flag("a_flag_nobody_ever_declared")
	assert_true(world.has("a_flag_nobody_ever_declared"),
		"an unscoped write lands in the world store rather than being dropped")
	assert_false(player.has("a_flag_nobody_ever_declared"))
	assert_true(merged.has("a_flag_nobody_ever_declared"),
		"and it reads back, so whatever gate was waiting on it still opens")


# --- all_set: the union ------------------------------------------------------

func test_all_set_is_the_union_with_no_duplicates() -> void:
	world.set_flag("defeated_warden")
	world.set_flag("south_bridge_open")
	player.set_flag("tam_tools_given")
	var all: Array = merged.all_set()
	assert_eq(all.size(), 3)
	for id: String in ["defeated_warden", "south_bridge_open", "tam_tools_given"]:
		assert_true(all.has(id), "'%s' is missing from the union" % id)


# --- revision: the poll game_state.gd::_process actually makes ---------------

func test_revision_moves_when_either_store_moves() -> void:
	var before: int = merged.revision
	world.set_flag("defeated_warden")
	var after_world: int = merged.revision
	assert_true(after_world > before, "a world flag must move the merged revision")
	player.set_flag("tam_tools_given")
	assert_true(merged.revision > after_world, "so must a player flag")


func test_revision_is_the_sum_of_both_stores() -> void:
	world.set_flag("defeated_warden")
	player.set_flag("tam_tools_given")
	player.set_flag("home_built")
	assert_eq(merged.revision, int(world.get("revision")) + int(player.get("revision")))


func test_a_redundant_write_does_not_move_the_revision() -> void:
	# `progression_state.gd`'s own contract: a poller must not redraw for
	# nothing. The merged view inherits it rather than adding a bump of its own.
	merged.set_flag("defeated_warden")
	var settled: int = merged.revision
	merged.set_flag("defeated_warden")
	assert_eq(merged.revision, settled)


# --- the v22 flat payload, until 1.C splits the file ------------------------

func test_save_data_is_the_union_in_the_flat_stores_own_shape() -> void:
	world.set_flag("defeated_warden")
	player.set_flag("tam_tools_given")
	var data: Dictionary = merged.save_data()
	assert_eq(data.keys().size(), 1, "exactly the one key the flat store wrote")
	assert_true(data.has("flags"))
	var ids: Array = data["flags"]
	assert_eq(ids.size(), 2)
	assert_true(ids.has("defeated_warden") and ids.has("tam_tools_given"))


func test_load_data_splits_a_flat_v22_list_back_by_scope() -> void:
	merged.load_data({"flags": [
		"defeated_warden", "tam_tools_given", "pickup:south_bridge_key",
		"opening:beat:road",
	]})
	assert_true(world.has("defeated_warden"))
	assert_true(world.has("pickup:south_bridge_key"))
	assert_false(world.has("tam_tools_given"))
	assert_true(player.has("tam_tools_given"))
	assert_true(player.has("opening:beat:road"))
	assert_false(player.has("defeated_warden"))


func test_load_data_replaces_both_stores_rather_than_merging_into_them() -> void:
	# Loading a save must never leave a flag standing from the run before it.
	world.set_flag("south_bridge_open")
	player.set_flag("home_built")
	merged.load_data({"flags": ["defeated_warden"]})
	assert_true(world.has("defeated_warden"))
	assert_false(world.has("south_bridge_open"), "the previous run's world flag is gone")
	assert_false(player.has("home_built"), "and so is its player flag")


func test_save_then_load_round_trips_the_split() -> void:
	world.set_flag("defeated_warden")
	world.set_flag("warrens_cleared")
	player.set_flag("tam_tools_given")
	player.set_flag("creature_bed_built_2")
	var payload: Dictionary = merged.save_data()

	var world_b: RefCounted = FLAGS.new()
	var player_b: RefCounted = FLAGS.new()
	var merged_b: RefCounted = MERGED.new(world_b, player_b)
	merged_b.load_data(payload)
	assert_eq(merged_b.save_data(), payload, "the union survives the split and the rejoin")
	assert_eq(world_b.all_set().size(), 2)
	assert_eq(player_b.all_set().size(), 2)
	assert_true(player_b.has("creature_bed_built_2"))
