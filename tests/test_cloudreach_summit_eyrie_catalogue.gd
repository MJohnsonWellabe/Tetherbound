extends "res://tests/test_case.gd"

const TELEPORTS_PATH := "res://data/config/debug_teleport_spots.json"
const AVIARY_PATH := "res://data/config/cloudreach_aviary.json"
const EYRIE_CENTRE := Vector2(100.0, 5350.0)
const ROAD_START := Vector2(300.0, 5100.0)
const ROAD_END := EYRIE_CENTRE


func test_summit_eyrie_catalogue_uses_the_authored_final_approach() -> void:
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
			if str(band.get("id", "")) != "summit_final_stronghold":
				continue
			for spot_raw: Variant in band.get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Summit Eyrie":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [134.4, 5307.0])
	assert_almost_eq(float(found.get("view_heading_deg", NAN)), -38.7, 0.01)

	var stand := Vector2(134.4, 5307.0)
	var road := ROAD_END - ROAD_START
	var t := (stand - ROAD_START).dot(road) / road.length_squared()
	var road_point := ROAD_START + road * t
	assert_true(t > 0.0 and t < 1.0, "arrival must remain within the authored final road segment")
	assert_almost_eq(stand.distance_to(road_point), 0.0, 0.01,
		"arrival must remain on production ground supplied by the upper summit road")
	assert_true(stand.distance_to(EYRIE_CENTRE) > 50.0,
		"production spring arm must start outside the 27 m aviary drum and route wings")


func test_summit_eyrie_heading_targets_the_aviary_centre() -> void:
	var stand := Vector2(134.4, 5307.0)
	var toward_centre := (EYRIE_CENTRE - stand).normalized()
	var heading := deg_to_rad(-38.7)
	var catalogue_forward := Vector2(sin(heading), cos(heading))
	assert_true(catalogue_forward.dot(toward_centre) > 0.999,
		"catalogue camera must face down the approach into the aviary")


func test_summit_eyrie_retires_the_malformed_static_songbird_proxies() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AVIARY_PATH))
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var interior: Dictionary = (parsed as Dictionary).get("interior", {})
	var birds: Dictionary = interior.get("birds", {})
	assert_eq(int(birds.get("count", -1)), 0,
		"the coral horizontal imported meshes must not remain frozen aviary scenery")
	assert_true(int(interior.get("log_perches", {}).get("count", 0)) >= 8)
	assert_true(int(interior.get("cables", {}).get("count", 0)) >= 6)
	assert_true(int(interior.get("wall_lanterns", {}).get("count", 0)) >= 4)
	assert_true(int(interior.get("stores", {}).get("count", 0)) >= 6,
		"removing malformed bird proxies must not empty the working aviary")
