extends "res://tests/test_case.gd"

const TELEPORTS_PATH := "res://data/config/debug_teleport_spots.json"
const WORLD_PATH := "res://scripts/world/cloudreach_world.gd"
const SHRINE_CENTRE := Vector2(1110.0, 2940.0)


func test_sky_shrine_catalogue_uses_the_south_crown_overview() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TELEPORTS_PATH))
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var found := {}
	for biome_raw: Variant in (parsed as Dictionary).get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "cloudreach":
			continue
		for band_raw: Variant in biome.get("bands", []):
			var band := band_raw as Dictionary
			if str(band.get("id", "")) != "high_roost_sky_shrine":
				continue
			for spot_raw: Variant in band.get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Sky Shrine":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [1110.0, 2885.0])
	assert_almost_eq(float(found.get("view_heading_deg", NAN)), 180.0, 0.001)
	var stand := Vector2(1110.0, 2885.0)
	assert_almost_eq(stand.distance_to(SHRINE_CENTRE), 55.0, 0.001)
	assert_true(stand.y < SHRINE_CENTRE.y,
		"the catalogue must approach from the south instead of spawning inside the pedestal")


func test_sky_shrine_retains_a_complete_authored_sanctuary_hierarchy() -> void:
	var source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(source.contains("Vector3(26.0, 1.3, 20.0)"), "the broad masonry dais must remain")
	assert_true(source.contains("\"InnerSanctuaryArch\""), "the installed sanctuary arch must remain")
	assert_true(source.contains("\"LintelWindCarving\""), "the lintel carvings must remain")
	assert_true(source.contains("\"AncientWindArmature%d\""), "the heartstone armatures must remain")
	assert_true(source.contains("\"ShrineRetainingWing\""), "the approach retaining wings must remain")
	assert_true(source.contains("_plant_floor_pocket(root,Vector3(side*11.0"),
		"the authored shrine planting must remain")


func test_heartstone_owns_a_bounded_local_night_focal_light() -> void:
	var source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(source.contains("heart_light.name = \"HeartstoneFocalLight\""))
	assert_true(source.contains("heart_light.light_color = Color(\"#70cfd0\")"))
	assert_true(source.contains("heart_light.light_energy = 1.45"))
	assert_true(source.contains("heart_light.omni_range = 24.0"))
	assert_true(source.contains("heart_light.omni_attenuation = 1.35"))
	assert_false(source.contains("heart_light.omni_range = 100"),
		"the shrine focal must remain local rather than flattening Cloudreach night")
