extends "res://tests/test_case.gd"

const AMBIENCE := preload("res://scripts/world/cloudreach_atmosphere.gd")
const MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const LEGACY := preload("res://autoload/map_state.gd")
const MINIMAP := preload("res://scripts/ui/minimap.gd")
const TAB := preload("res://scripts/ui/tab_map.gd")


func _map(flags: RefCounted) -> RefCounted:
	var map := MAP.new()
	map.configure_cloudreach(AMBIENCE.read_json("res://data/config/cloudreach_world.json"),
		AMBIENCE.read_json("res://data/config/cloudreach_chapter.json"), flags)
	return map


func test_realms_have_distinct_extent_and_ui_preserves_legacy_fallback() -> void:
	var legacy := LEGACY.new()
	legacy.configure({})
	var map := _map(FLAGS.new())
	assert_eq(TAB.bounds_for_map(legacy), TAB.bounds_for_map(null))
	assert_eq(MINIMAP.bounds_for_map(legacy), MINIMAP.bounds_for_map(null))
	assert_eq(TAB.bounds_for_map(map), map.world_bounds())
	assert_eq(MINIMAP.bounds_for_map(map), map.world_bounds())
	assert_eq(map.world_to_cell(Vector3(-1600, 0, -500)), Vector2i.ZERO)
	assert_eq(map.map_display_name(), "Cloudreach Cliffs")
	assert_true(map.mark_visited(Vector3(1400, 1000, 5500)))
	assert_true(map.is_discovered(Vector3(1400, 1000, 5500)))
	assert_false(legacy.is_discovered(Vector3(1400, 1000, 5500)))


func test_navigation_gates_waterward_and_reload_preserves_only_this_realm() -> void:
	var flags := FLAGS.new()
	var map := _map(flags)
	map.sync_navigation(flags, Vector3(0, 160, 300))
	assert_true(map.is_landmark_discovered("realm_gate_crag"))
	assert_false(map.discover_landmark("sky_shrine_heartstone"))
	flags.set_flag("fly_traversal_unlocked")
	map.sync_navigation(flags, Vector3(0, 160, 300))
	assert_true(map.is_landmark_discovered("sky_shrine_heartstone"))
	flags.set_flag("waterward_route_revealed")
	map.sync_navigation(flags, Vector3(0, 160, 300))
	assert_false(map.is_landmark_discovered("waterward_overlook"))
	flags.set_flag("captain_veyra_defeated")
	flags.set_flag("cloudreach_winds_restored")
	map.sync_navigation(flags, Vector3(0, 160, 300))
	assert_true(map.is_landmark_discovered("waterward_overlook"))
	var revision: int = map.revision
	map.sync_navigation(flags, Vector3(0, 160, 300))
	assert_eq(map.revision, revision)
	map.mark_visited(Vector3(0, 160, 300))
	var copy := _map(flags)
	copy.load_data(JSON.parse_string(JSON.stringify(map.save_data())))
	assert_true(copy.is_discovered(Vector3(0, 160, 300)))
	assert_true(copy.is_landmark_discovered("waterward_overlook"))
	copy.load_data({"realm_id": "meadows", "landmarks": ["waterward_overlook"]})
	assert_false(copy.is_landmark_discovered("waterward_overlook"))
	assert_false(copy.is_discovered(Vector3(0, 160, 300)))


func test_mix_and_presentation_do_not_invent_rewards() -> void:
	var flags := FLAGS.new()
	var data := AMBIENCE.read_json(AMBIENCE.CONFIG_PATH)
	var before := AMBIENCE.mix_for(data, "summit_final_stronghold", flags, true, false)
	assert_true(float(before["boss_zone_escalation"]) > 0)
	assert_true(float(before["boss_music"]) > 0)
	assert_eq(float(before["distant_bird_calls"]), 0.0)
	flags.set_flag("storm_anchor_network_disabled")
	assert_eq(float(AMBIENCE.mix_for(data, "summit_final_stronghold", flags, true, false)["boss_zone_escalation"]), 0.0)
	assert_false(AMBIENCE.presentation_for(flags)["returning_travelers"])
	flags.set_flag("cloudreach_winds_restored")
	var restored := AMBIENCE.mix_for(data, "summit_final_stronghold", flags, true, false)
	assert_eq(float(restored["boss_music"]), 0.0)
	assert_true(float(restored["distant_bird_calls"]) > 0)
	assert_true(AMBIENCE.presentation_for(flags)["returning_travelers"])
	assert_false(AMBIENCE.presentation_for(flags)["waterward_enterable"])
	assert_false(flags.has("realm_key_water"))
