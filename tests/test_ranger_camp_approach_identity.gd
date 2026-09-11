extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band2_stone_and_root/props.json"
const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const CAMP_CENTRE := Vector2(-259.0, 2256.5)
const APPROACH_EYE := Vector2(-242.0, 2247.0)
const SPUR_POINT := Vector2(-260.0, 2260.0)


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_ranger_camp_has_one_tight_overlapping_approach_lens() -> void:
	var lens := {}
	for raw: Variant in _read(VEGETATION_PATH).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 2004:
			lens = raw
	assert_false(lens.is_empty(), "Ranger Camp ordinary arrival has no scatter lens")
	var centre := Vector2(float(lens.get("x", INF)), float(lens.get("z", INF)))
	var radius := float(lens.get("radius", INF))
	assert_true(APPROACH_EYE.distance_to(centre) < radius,
		"approach camera still resolves outside the authored lens")
	assert_true(centre.distance_to(CAMP_CENTRE) < radius + 15.0,
		"approach lens detached from the established camp clearing")
	assert_true(radius <= 9.0, "Ranger Camp approach fix cleared a second broad field")


func test_collapsed_shelter_announces_abandonment_without_blocking_gameplay() -> void:
	var camp := {}
	for raw: Variant in _read(PROPS_PATH).get("clusters", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "ranger_camp":
			camp = raw
	assert_false(camp.is_empty(), "Ranger Camp cluster is missing")
	var shelter := {}
	for raw: Variant in camp.get("props", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "RangerCampCollapsedShelter":
			shelter = raw
	assert_false(shelter.is_empty(), "abandoned camp still has no shelter silhouette")
	assert_eq(str(shelter.get("model", "")), "camp_tent", "shelter stopped using installed camp kit")
	assert_true(ResourceLoader.exists("res://assets/props/generated_camp/camp_tent.glb"),
		"collapsed shelter model is not installed")
	assert_true(float(shelter.get("pitch_deg", 0.0)) >= 60.0,
		"shelter reads intact rather than collapsed")
	var at_raw := shelter.get("at", []) as Array
	var at := Vector2(float(at_raw[0]), float(at_raw[1]))
	var rest := camp.get("rest", {}) as Dictionary
	var rest_raw := rest.get("at", []) as Array
	var rest_at := Vector2(float(rest_raw[0]), float(rest_raw[1]))
	var craft_raw := rest.get("craft_at", []) as Array
	var craft_at := Vector2(float(craft_raw[0]), float(craft_raw[1]))
	assert_true(at.distance_to(rest_at) > float(rest.get("radius", 0.0)) + 3.0,
		"collapsed shelter blocks the functional rest circle")
	assert_true(at.distance_to(craft_at) > 5.0, "collapsed shelter blocks the craft point")
	assert_true(at.distance_to(SPUR_POINT) > 8.0, "collapsed shelter blocks the ranger spur")
