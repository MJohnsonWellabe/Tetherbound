extends "res://tests/test_case.gd"

## F13#5: every mandatory Tidewake dock gets installed-cast dock hands that are
## presentation only, never a named Tidewake NPC's body, and off the swim lane.

const RESIDENTS := preload("res://scripts/world/water_dock_residents.gd")
const CONFIG := "res://data/config/water_dock_residents.json"
const SCRIPT := "res://scripts/world/water_dock_residents.gd"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_profiles_are_installed_and_never_a_named_tidewake_body() -> void:
	var art := _json("res://data/config/art.json")
	var named := {}
	for npc: Dictionary in _json("res://data/config/water_characters.json").get("npcs", []):
		named[str(npc.get("body_profile", ""))] = true
	var profiles: Array = _json(CONFIG).get("profiles", [])
	assert_true(profiles.size() >= 2, "more than one kind of dock hand")
	for profile: Variant in profiles:
		assert_true(art.has(str(profile)), "installed art.json body: %s" % profile)
		assert_true(ResourceLoader.exists(str((art.get(str(profile), {}) as Dictionary).get("model", ""))),
			"installed model for %s" % profile)
		assert_false(named.has(str(profile)), "%s is not a named Tidewake NPC's body" % profile)


func test_layer_is_presentation_only() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT)
	for word: String in ["add_prompt", "start_conversation", "set_flag", "StaticBody3D"]:
		assert_false(source.contains(word), "residents carry no %s" % word)
	assert_true(source.contains("simulation_only"), "a simulation shell builds no residents")
	assert_true(source.contains("collider.queue_free"), "the npc body's collider is removed")


func test_every_mandatory_dock_gets_spots_off_the_lane_and_landward() -> void:
	var cfg := _json(CONFIG)
	var world := _json("res://data/config/water_world.json")
	var anchors := {}
	for anchor: Dictionary in world.get("anchors", []):
		anchors[str(anchor.id)] = anchor
	var docks := 0
	for dock: Dictionary in world.get("docks", []):
		if not bool(dock.get("mandatory", false)):
			continue
		docks += 1
		var anchor: Dictionary = anchors[str(dock.departure_anchor)]
		var safe := Vector2(float(anchor.safe_position[0]), float(anchor.safe_position[2]))
		var shore := Vector2(float(anchor.shore_position[0]), float(anchor.shore_position[2]))
		var seaward := (shore - safe).normalized()
		for sign: float in [1.0, -1.0]:
			var spots: Array = RESIDENTS.spots_for(anchor, sign, cfg)
			assert_eq(spots.size(), (cfg.spots as Array).size(), "%s has every spot" % dock.id)
			for spot: Dictionary in spots:
				assert_true(float(spot.lane_offset_m) >= 1.8, "%s resident stands off the swim lane" % dock.id)
				assert_true(((spot.at as Vector2) - safe).dot(seaward) < 0.0, "%s resident stands landward of the dock head" % dock.id)
	assert_eq(docks, 7, "seven mandatory docks")
