extends "res://tests/test_case.gd"

## STAGE B 0.E — characterization fence for the flag-id string builders D-MP5
## needs classified in `data/progression/flag_scopes.json` (1.A). If any of
## these literal formats moves, every existing save's "already taken"/
## "already cleared" state silently stops matching and every pickup, harvest
## node and once-only encounter reappears. Pins the LITERAL strings, not just
## that a function returns non-empty.

const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const KEY_PICKUP := preload("res://scripts/world/key_pickup.gd")
const TM_PICKUP := preload("res://scripts/world/tm_pickup.gd")
const RIDING_CONTROLLER := preload("res://scripts/world/riding_controller.gd")
const ENCOUNTER_DIRECTOR_PATH := "res://scripts/combat/encounter_director.gd"


# --- item_cache_pickup.gd::flag_id() — three cases --------------------------

func test_cache_flag_id_for_a_meadows_placement_is_cache_colon_placement_id() -> void:
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "clearing_cache_3", "meadows"),
		"cache:clearing_cache_3")


func test_cache_flag_id_for_a_placement_in_another_realm_is_realm_qualified() -> void:
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "clearing_cache_3", "cloudreach"),
		"cache:cloudreach:clearing_cache_3")


func test_cache_flag_id_for_a_bare_item_with_no_placement_is_cache_colon_item_id() -> void:
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy"), "cache:good_candy")
	# The realm argument is irrelevant once there is no placement id at all.
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "", "cloudreach"), "cache:good_candy")


func test_cache_flag_id_defaults_realm_to_meadows() -> void:
	# Calling with only item_id + placement_id (the common two-arg call site)
	# must produce the unqualified Meadows form, not silently realm-qualify.
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "clearing_cache_3"),
		"cache:clearing_cache_3")


# --- band_pickups.gd::flag_id() — the same cache prefix, keyed on placement --

func test_band_pickups_flag_id_delegates_to_the_cache_prefix_keyed_on_the_pickup_id() -> void:
	assert_eq(BAND_PICKUPS.flag_id("band2_orb_12"), "cache:band2_orb_12")
	assert_eq(BAND_PICKUPS.flag_id("band2_orb_12"), ITEM_CACHE_PICKUP.flag_id("band2_orb_12"),
		"same prefix as every other cache, per the file's own comment")


# --- harvest_node.gd::flag_id() ---------------------------------------------

func test_harvest_node_flag_id_is_harvest_node_colon_node_id() -> void:
	assert_eq(HARVEST_NODE.FLAG_PREFIX, "harvest_node:")
	assert_eq(HARVEST_NODE.flag_id("berry_bush_14"), "harvest_node:berry_bush_14")


# --- key_pickup.gd — FLAG_PREFIX + flag_id() --------------------------------

func test_key_pickup_flag_id_is_pickup_colon_item_id() -> void:
	assert_eq(KEY_PICKUP.FLAG_PREFIX, "pickup:")
	assert_eq(KEY_PICKUP.flag_id("rusty_key"), "pickup:rusty_key")


# --- tm_pickup.gd — FLAG_PREFIX (no dedicated flag_id() helper exists) ------

func test_tm_pickup_flag_prefix_is_tm_colon() -> void:
	# tm_pickup.gd builds its flag inline (`FLAG_PREFIX + tm_id`) in both
	# was_taken() and its own pickup handler rather than through a shared
	# static helper -- pin the constant itself, which is what both call sites
	# actually depend on.
	assert_eq(TM_PICKUP.FLAG_PREFIX, "tm:")


# --- riding_controller.gd::saddle_fitted_flag() -----------------------------

func test_saddle_fitted_flag_is_saddle_fitted_underscore_species_id() -> void:
	assert_eq(RIDING_CONTROLLER.saddle_fitted_flag("galecrest"), "saddle_fitted_galecrest")
	assert_eq(RIDING_CONTROLLER.saddle_fitted_flag("terrapup"), "saddle_fitted_terrapup")


# --- encounter_director.gd's "wild_once_<order>" once-only flag ------------
#
## WARRENS-ONCE (owner playtest 2026-09-03 item 9): a named alpha/elder must
## not respawn after it is beaten/caught/freed. The flag string is built
## inline at the spawn site (`"wild_once_%d" % int(spawn.get("order", index))`)
## rather than through an exposed static helper, so unlike the pickups above
## this cannot be called directly from a unit test without standing up a full
## band spawn + world scene. Pinning the literal FORMAT by reading the source
## is the same technique test_pickup_glow.gd already uses in this suite to pin
## a call-site string without a scene.
func test_wild_once_flag_format_is_literally_wild_once_percent_d_on_the_spawn_order() -> void:
	var file := FileAccess.open(ENCOUNTER_DIRECTOR_PATH, FileAccess.READ)
	assert_true(file != null, "encounter_director.gd must be readable")
	if file == null:
		return
	var source := file.get_as_text()
	assert_true(source.contains("\"wild_once_%d\" % int(spawn.get(\"order\", index))"),
		"the once-only flag format for a named alpha/elder must stay 'wild_once_<order>' " +
		"-- an existing save's cleared-alpha flags depend on this literal string")
