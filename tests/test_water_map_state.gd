extends "res://tests/test_case.gd"

## Personal discovery payload tests. No realm-key, dock unlock, rendering or
## network transport claims: these exercise the production PlayerState maps.
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const WORLD_PATH := "res://data/config/water_world.json"
const FIRST_SHORE := Vector3(0.0, 1.929, 162.0)
const VEILFALL := Vector3(384.311, 1.929, 3805.405)
var world: Dictionary
var player: RefCounted
var water: RefCounted

func before_each() -> void:
	world = JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH))
	player = PLAYER_STATE.new()
	player.configure(ITEM_DB.new())
	water = player.map_for("water")

func test_water_extent_and_authored_destinations_are_independent_of_meadows() -> void:
	assert_ne(water, null)
	if water == null:
		return
	var meadows: RefCounted = player.map_for("meadows")
	var meadow_origin: Vector2 = meadows.origin()
	var bounds: Dictionary = world.world_bounds
	assert_eq(water.origin(), Vector2(bounds.min_x, bounds.min_z))
	assert_eq(water.world_bounds(), bounds)
	assert_eq(water.map_display_name(), "Water Archipelago")
	assert_true(water.origin().x + water.grid_x() * water.cell_size() >= float(bounds.max_x))
	assert_true(water.origin().y + water.grid_z() * water.cell_size() >= float(bounds.max_z))
	assert_eq(water.landmarks().size(), world.landmarks.size())
	assert_eq(water.regions().size(), world.islands.size())
	assert_eq(meadows.origin(), meadow_origin)
	assert_ne(meadows.origin(), water.origin())
	assert_true(player.map_for("water") == water)
	assert_false(water.is_discovered(FIRST_SHORE))
	assert_false(water.is_discovered(VEILFALL))

func test_two_characters_on_different_islands_never_share_fog_regions_or_pins() -> void:
	var other := PLAYER_STATE.new()
	other.configure(ITEM_DB.new())
	var other_water: RefCounted = other.map_for("water")
	assert_ne(water, other_water)
	if water == null or other_water == null:
		return
	var flags_before: Dictionary = player.flags.save_data()
	water.mark_visited(FIRST_SHORE)
	water.update_region(FIRST_SHORE)
	water.pin_alpha(49001, "aquaryn", "Aquaryn", FIRST_SHORE, "")
	other_water.mark_visited(VEILFALL)
	other_water.update_region(VEILFALL)
	assert_true(water.is_discovered(FIRST_SHORE))
	assert_false(other_water.is_discovered(FIRST_SHORE))
	assert_false(water.is_discovered(VEILFALL))
	assert_true(other_water.is_discovered(VEILFALL))
	assert_true(water.is_alpha_pinned(49001))
	assert_false(other_water.is_alpha_pinned(49001))
	assert_eq(water.take_pending_region_announcement(), "First Shore")
	assert_eq(other_water.take_pending_region_announcement(), "The Veilfall")
	assert_eq(player.flags.save_data(), flags_before, "Discovery does not spend keys or unlock docks")

func test_character_json_roundtrip_keeps_water_fog_landmark_region_and_alpha_pin() -> void:
	if water == null:
		assert_ne(water, null)
		return
	player.realm = "water"
	var landmark: Dictionary = world.landmarks[0]
	water.mark_visited(FIRST_SHORE)
	water.discover_landmark(str(landmark.id))
	water.update_region(FIRST_SHORE)
	water.pin_alpha(49001, "aquaryn", "Aquaryn", FIRST_SHORE, "")
	var payload: Dictionary = player.save_data()
	assert_true(payload.realm_maps.has("water"))
	assert_true(payload.realm_maps.water.has("visited_b64"))
	assert_true(payload.realm_maps.water.has("alpha_pins"))
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(payload))
	var restored := PLAYER_STATE.new()
	restored.configure(ITEM_DB.new())
	restored.load_data(decoded)
	var loaded: RefCounted = restored.map_for("water")
	assert_true(restored.map() == loaded)
	assert_true(loaded.is_discovered(FIRST_SHORE))
	assert_false(loaded.is_discovered(VEILFALL))
	assert_true(loaded.is_landmark_discovered(str(landmark.id)))
	assert_true(loaded.is_alpha_pinned(49001))
	loaded.update_region(FIRST_SHORE)
	assert_eq(loaded.take_pending_region_announcement(), "", "Already visited island does not announce again after load")
	loaded.mark_visited(VEILFALL)
	assert_false(water.is_discovered(VEILFALL), "Restored maps hold their own fog bytes")

func test_old_character_without_water_map_starts_hidden_and_preserves_meadows_map() -> void:
	var meadows: RefCounted = player.map_for("meadows")
	meadows.mark_visited(Vector3.ZERO)
	var payload: Dictionary = player.save_data()
	payload.realm_maps.erase("water")
	payload["realm"] = "meadows"
	var restored := PLAYER_STATE.new()
	restored.configure(ITEM_DB.new())
	restored.load_data(JSON.parse_string(JSON.stringify(payload)))
	var fresh_water: RefCounted = restored.map_for("water")
	assert_ne(fresh_water, null)
	assert_true(restored.map_for("meadows").is_discovered(Vector3.ZERO))
	assert_false(fresh_water.is_discovered(FIRST_SHORE))
	assert_false(fresh_water.is_discovered(VEILFALL))
	assert_eq(fresh_water.alpha_pin_count(), 0)
	assert_eq(fresh_water.discovered_landmark_count(), 0)
