extends "res://tests/test_case.gd"

## F10#0 / WORLD Stormwood `stormwood_dark_arches` target payoff: "Those
## physical routes become reusable and visible on known map." A relit dark
## pair (both ends lit) is drawn on this player's Stormwood map as one marker
## per end, derived from the world's paid lit flags. The map saves them with
## its existing dynamic markers only as a derived cache; each sync re-derives.

const PROGRESSION := preload("res://autoload/progression_state.gd")
const REALM_MAP := preload("res://scripts/world/realm_map_state.gd")
const ARCH_RUNTIME := preload("res://scripts/world/stormwood_arch_runtime.gd")
const RULES := preload("res://scripts/world/stormwood_arch_rules.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _map(flags: RefCounted) -> RefCounted:
	var map := REALM_MAP.new()
	map.configure_realm("stormwood", {"display_name": "The Stormwood"},
		_json("res://data/config/stormwood_world.json"), {}, {}, flags)
	return map


func _arch_markers(map: RefCounted) -> Dictionary:
	var out := {}
	for entry: Dictionary in map.landmarks():
		if bool(entry.get("dynamic", false)) and str(entry.id).begins_with(ARCH_RUNTIME.DARK_MAP_PREFIX):
			out[str(entry.id)] = entry
	return out


func test_relit_dark_roads_appear_on_the_known_map_only_when_both_ends_answer() -> void:
	var flags := PROGRESSION.new()
	var map := _map(flags)
	flags.set_flag("stormwood:ashfoot_arch_relit")
	flags.set_flag("stormwood:rootgate_released")
	ARCH_RUNTIME.sync_dark_arch_map(map, flags)
	assert_true(_arch_markers(map).is_empty(), "Dark arches are not a known road yet")
	flags.set_flag(RULES.lit_flag("c_rodline"))
	ARCH_RUNTIME.sync_dark_arch_map(map, flags)
	assert_true(_arch_markers(map).is_empty(), "One lit end is not a reusable road")
	flags.set_flag(RULES.lit_flag("c_lantern"))
	assert_true(ARCH_RUNTIME.sync_dark_arch_map(map, flags))
	var markers := _arch_markers(map)
	assert_eq(markers.size(), 2, "Both ends of the Rodline-Lantern Hollow road are on the map")
	var rodline: Dictionary = markers.get(ARCH_RUNTIME.DARK_MAP_PREFIX + "c_rodline", {})
	assert_eq(str(rodline.get("icon", "")), ARCH_RUNTIME.DARK_MAP_ICON)
	assert_eq(rodline.get("position"), Vector2(-720, 2260), "Marker sits on the authored arch")
	assert_true(str(rodline.get("display_name", "")).contains("Lantern Hollow"),
		"The Rodline end names where its road goes")
	assert_true(bool(rodline.get("discovered", false)), "A dynamic road marker is drawn, not fogged")
	var revision := int(map.get("revision"))
	assert_false(ARCH_RUNTIME.sync_dark_arch_map(map, flags), "A repeated sync is a no-op")
	assert_eq(int(map.get("revision")), revision)
	flags.set_flag(RULES.lit_flag("d_hall"))
	flags.set_flag(RULES.lit_flag("d_giant"))
	ARCH_RUNTIME.sync_dark_arch_map(map, flags)
	assert_eq(_arch_markers(map).size(), 4, "Old Hall-Fallen Giant joins the known map too")


func test_story_arches_are_not_dark_road_markers_and_stale_markers_leave() -> void:
	var flags := PROGRESSION.new()
	var map := _map(flags)
	flags.set_flag("stormwood:rootgate_released")
	for id: String in ["a_ashfoot", "a_pools", "b_pools", "b_rodline", "c_rodline", "c_lantern"]:
		flags.set_flag(RULES.lit_flag(id))
	ARCH_RUNTIME.sync_dark_arch_map(map, flags)
	assert_eq(_arch_markers(map).keys().size(), 2, "Only dark-arch roads, never story pairs A/B or the Crown")
	# The same character entering a world whose arches are still dark: the
	# derived markers follow that world's flags rather than a previous world's.
	var other := PROGRESSION.new()
	assert_true(ARCH_RUNTIME.sync_dark_arch_map(map, other))
	assert_true(_arch_markers(map).is_empty())


func test_markers_are_derived_not_a_new_durable_fact() -> void:
	var flags := PROGRESSION.new()
	var map := _map(flags)
	flags.set_flag("stormwood:rootgate_released")
	flags.set_flag(RULES.lit_flag("d_hall"))
	flags.set_flag(RULES.lit_flag("d_giant"))
	ARCH_RUNTIME.sync_dark_arch_map(map, flags)
	# The saved cache alone does not decide: a save carrying the markers,
	# loaded into a world whose arches are dark, shows none after a sync.
	var cached := _map(PROGRESSION.new())
	cached.load_data(map.save_data())
	assert_eq(_arch_markers(cached).size(), 2, "precondition: the save carried the cached markers")
	ARCH_RUNTIME.sync_dark_arch_map(cached, PROGRESSION.new())
	assert_true(_arch_markers(cached).is_empty(), "a dark world clears a stale saved cache")
	# And a save WITHOUT the cache re-derives both ends from the lit flags.
	var payload: Dictionary = map.save_data()
	payload.erase("dynamic_markers")
	var restored := _map(PROGRESSION.new())
	restored.load_data(payload)
	assert_true(_arch_markers(restored).is_empty(), "precondition: no cached markers loaded")
	ARCH_RUNTIME.sync_dark_arch_map(restored, flags)
	assert_eq(_arch_markers(restored).size(), 2, "a reload re-derives the same two road ends from the flags")
