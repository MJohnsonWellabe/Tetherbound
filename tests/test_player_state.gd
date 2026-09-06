extends "res://tests/test_case.gd"

## MP_STATE_SEAM.md §1: `PlayerState` is one trainer and one team.
##
## Three things that used to be process-global live here now, and the tests
## that matter most are the ones proving they are genuinely per instance: the
## progression feed, the per-realm map (and its EXTENT), and the flag store.
## `Game.local` is one of these; from Wave 2 the host holds one per peer.

const PLAYER_STATE := preload("res://autoload/player_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

var db: RefCounted = null
var player: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	player = PLAYER_STATE.new()
	player.call("configure", db)


# --- what a fresh player is --------------------------------------------------

func test_skills_are_personal_survive_save_and_reset_without_historical_xp() -> void:
	player.skills.add_xp("running", 150.0)
	var other := PLAYER_STATE.new()
	assert_eq(other.skills.level("running"), 0)
	other.load_data(player.save_data())
	assert_eq(other.skills.level("running"), 1)
	assert_false(other.skills.revealed)
	other.load_data({"realm":"cloudreach"})
	assert_true(other.skills.revealed)
	assert_eq(other.skills.level("running"), 0)
	other.reset()
	assert_false(other.skills.revealed)

func test_a_fresh_player_starts_in_the_meadows_with_an_empty_bar() -> void:
	assert_eq(player.realm, "meadows")
	assert_eq(player.pending_realm_entry, "")
	assert_almost_eq(player.satiety, 100.0)
	assert_eq(player.hotbar.size(), 5)
	for slot: String in player.hotbar:
		assert_eq(slot, "")
	assert_ne(player.party, null)
	assert_ne(player.inventory, null)
	assert_ne(player.flags, null)
	assert_ne(player.feed, null)
	assert_ne(player.quest_log, null)


func test_two_players_hold_two_separate_flag_stores_and_two_separate_feeds() -> void:
	# The whole point of the split. Before it, `progression_feed.gd` was five
	# `static var`s: peer A's XP banner read peer B's level-ups.
	var other: RefCounted = PLAYER_STATE.new()
	player.flags.set_flag("tam_tools_given")
	assert_false(other.flags.has("tam_tools_given"))
	player.feed.call("push_event", "xp_gained", null, {"amount": 5})
	assert_eq(player.feed.call("newest_seq"), 1)
	assert_eq(other.feed.call("newest_seq"), 0, "the other player's log did not move")


# --- maps: per realm, per player, per extent --------------------------------

func test_map_for_builds_one_map_per_realm_and_reuses_it() -> void:
	var meadows: RefCounted = player.call("map_for", "meadows")
	var cloudreach: RefCounted = player.call("map_for", "cloudreach")
	assert_ne(meadows, null)
	assert_ne(cloudreach, null)
	assert_false(meadows == cloudreach)
	assert_true(player.call("map_for", "meadows") == meadows, "asking twice reuses the instance")


func test_map_for_refuses_a_realm_with_no_implemented_map() -> void:
	# Waterward is a distant vista, not an enterable place (CLAUDE.md's Biome 2
	# rule), so it gets no MapState rather than an empty one.
	assert_eq(player.call("map_for", "waterward"), null)
	assert_eq(player.call("map_for", ""), null)


func test_the_two_realm_maps_describe_two_differently_shaped_worlds() -> void:
	# This is what `map_state.gd` losing its `static var _grid_x/_grid_z/_origin`
	# bought: one process, two live maps, two extents.
	var meadows: RefCounted = player.call("map_for", "meadows")
	var cloudreach: RefCounted = player.call("map_for", "cloudreach")
	assert_ne(meadows.call("origin"), cloudreach.call("origin"),
		"the two realms do not share an origin")
	assert_true(float(cloudreach.call("cell_size")) > float(meadows.call("cell_size")),
		"Cloudreach is measured in bigger cells than the Meadows (cloudreach_atmosphere.json)")
	assert_ne(int(meadows.call("cell_grid_z")), int(cloudreach.call("cell_grid_z")))


func test_map_returns_the_map_of_the_realm_this_player_is_standing_in() -> void:
	assert_true(player.call("map") == player.call("map_for", "meadows"))
	player.realm = "cloudreach"
	assert_true(player.call("map") == player.call("map_for", "cloudreach"),
		"which realm a trainer is in is per player from now on")


# --- the hotbar --------------------------------------------------------------

func test_the_bar_holds_tools_consumables_and_food_and_refuses_raw_materials() -> void:
	# Owner board, "UI / SYSTEM FIXES CHECKLIST": consumables + tools only.
	assert_true(player.call("hotbar_can_hold", "axe"))
	assert_false(player.call("hotbar_can_hold", "wood"))
	assert_false(player.call("hotbar_can_hold", "an_item_nobody_authored"))
	assert_false(player.call("hotbar_can_hold", ""))


func test_assigning_an_item_already_on_the_bar_moves_it_rather_than_copying_it() -> void:
	assert_true(player.call("assign_hotbar", 0, "axe"))
	assert_true(player.call("assign_hotbar", 3, "axe"))
	assert_eq(player.hotbar[0], "", "the old slot was cleared")
	assert_eq(player.hotbar[3], "axe")
	assert_eq(player.call("hotbar_slot_of", "axe"), 3)


func test_assign_refuses_an_out_of_range_slot_and_a_refused_kind() -> void:
	assert_false(player.call("assign_hotbar", -1, "axe"))
	assert_false(player.call("assign_hotbar", 5, "axe"))
	assert_false(player.call("assign_hotbar", 0, "wood"))
	assert_eq(player.call("hotbar_slot_of", "wood"), -1)


func test_autofill_takes_usable_things_in_bag_order_and_skips_materials() -> void:
	player.inventory.call("add", "wood", 10)
	player.inventory.call("add", "axe", 1)
	player.call("autofill_hotbar")
	assert_eq(player.call("hotbar_slot_of", "axe"), 0, "the axe landed on the first free slot")
	assert_eq(player.call("hotbar_slot_of", "wood"), -1, "wood never occupies an action slot")


# --- creatures ---------------------------------------------------------------

func test_make_creature_builds_from_species_json_and_refuses_an_unknown_species() -> void:
	var creature: RefCounted = player.call("make_creature", "terrapup", "Biscuit")
	assert_ne(creature, null)
	assert_eq(str(creature.get("species_id")), "terrapup")
	assert_eq(str(creature.get("nickname")), "Biscuit")
	assert_eq(player.call("make_creature", "not_a_species"), null)


# --- save / load -------------------------------------------------------------

func test_save_data_carries_the_player_half_of_the_v22_keys() -> void:
	var data: Dictionary = player.save_data()
	for key: String in ["character_id", "display_name", "party", "inventory",
			"hotbar", "satiety", "player_pose", "realm", "pending_realm_entry",
			"realm_hearts", "realm_maps", "skills", "flags"]:
		assert_true(data.has(key), "local.save_data() is missing '%s'" % key)
	assert_eq(data.keys().size(), 13, "and nothing else -- got %s" % str(data.keys()))


func test_save_data_carries_no_world_key() -> void:
	# D100's partition: the intersection is empty. A character file that
	# carried `placed_buildings` would rebuild a friend's world from a guest's
	# memory of it.
	var data: Dictionary = player.save_data()
	for key: String in ["day", "clock_elapsed_seconds", "world_seed",
			"placed_buildings", "farm_plots", "death_satchels",
			"harvested_vegetation", "felled_vegetation"]:
		assert_false(data.has(key), "local.save_data() must not carry '%s'" % key)


func test_alpha_pins_ride_inside_the_realm_map_rather_than_at_the_top_level() -> void:
	# MP_STATE_SEAM.md §2 moved the pinned set into each map's own save_data().
	# `Game.save_game()` still emits the v22 top-level key off the active map.
	var data: Dictionary = player.save_data()
	assert_false(data.has("alpha_pins"), "not a top-level character key any more")
	var meadows: Dictionary = (data["realm_maps"] as Dictionary)["meadows"]
	assert_true(meadows.has("alpha_pins"), "it rides with the fog and the landmarks")


func test_save_then_load_round_trips_everything() -> void:
	player.character_id = "character-1"
	player.display_name = "Ren"
	player.realm = "cloudreach"
	player.pending_realm_entry = "cliff_gate"
	player.satiety = 61.5
	player.pose = {"realm": "cloudreach", "position": [1.0, 2.0, 3.0], "model_yaw": 0.5}
	player.inventory.call("add", "wood", 7)
	player.inventory.call("add", "axe", 1)
	player.call("assign_hotbar", 2, "axe")
	player.party.call("add", player.call("make_creature", "terrapup", "Biscuit"))
	player.flags.set_flag("tam_tools_given")
	player.call("map_for", "meadows").call("mark_visited", Vector3(6.0, 0.0, -22.0))
	var payload: Dictionary = player.save_data()

	var restored: RefCounted = PLAYER_STATE.new()
	restored.call("configure", db)
	restored.load_data(payload)
	assert_eq(restored.character_id, "character-1")
	assert_eq(restored.display_name, "Ren")
	assert_eq(restored.realm, "cloudreach")
	assert_eq(restored.pending_realm_entry, "cliff_gate")
	assert_almost_eq(restored.satiety, 61.5)
	assert_eq(restored.pose.get("realm"), "cloudreach")
	assert_eq(int(restored.inventory.call("count", "wood")), 7)
	assert_eq(restored.hotbar[2], "axe")
	assert_eq(int(restored.party.call("size")), 1)
	assert_eq(str((restored.party.call("at", 0) as RefCounted).get("nickname")), "Biscuit")
	assert_true(restored.flags.has("tam_tools_given"))
	assert_true(float(restored.call("map_for", "meadows").call("discovered_fraction")) > 0.0,
		"the fog trail came back with the character, not with the world")


func test_load_data_of_an_empty_dictionary_is_a_working_fresh_player() -> void:
	player.realm = "cloudreach"
	player.satiety = 3.0
	player.flags.set_flag("tam_tools_given")
	player.load_data({})
	assert_eq(player.realm, "meadows")
	assert_almost_eq(player.satiety, 100.0)
	assert_false(player.flags.has("tam_tools_given"))
	assert_eq(player.hotbar.size(), 5)


func test_load_data_survives_garbage_in_every_field() -> void:
	player.load_data({
		"party": 3, "inventory": "none", "hotbar": {}, "satiety": "full",
		"player_pose": [], "realm": 7, "realm_maps": "later", "flags": 0,
	})
	assert_almost_eq(player.satiety, 100.0)
	assert_true(player.pose.is_empty())
	assert_eq(player.hotbar.size(), 5)
	assert_true(player.flags.all_set().is_empty())


# --- reset -------------------------------------------------------------------

func test_reset_empties_the_player_but_keeps_the_flag_store_and_the_feed() -> void:
	# `merged_progression.gd` holds a reference to `flags`, and the feed's epoch
	# must keep CLIMBING across a New Game -- a presenter that cached epoch 3
	# would read a brand-new feed's epoch 0 as "no reset happened".
	var store: RefCounted = player.flags
	var feed: RefCounted = player.feed
	player.flags.set_flag("tam_tools_given")
	player.feed.call("push_event", "xp_gained", null, {"amount": 5})
	var epoch_before: int = feed.call("feed_epoch")
	player.realm = "cloudreach"
	player.call("map_for", "cloudreach")

	player.call("reset")
	assert_true(player.flags == store, "same flag store object")
	assert_true(player.feed == feed, "same feed object")
	assert_false(player.flags.has("tam_tools_given"), "emptied, not replaced")
	assert_true(int(feed.call("feed_epoch")) > epoch_before, "the epoch climbs across a New Game")
	assert_eq(int(feed.call("newest_seq")), 0)
	assert_eq(player.realm, "meadows")
	assert_true((player.maps as Dictionary).is_empty(), "a new run gets fresh fog")
