extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band2_stone_and_root/props.json"
const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const CAMP_CENTRE := Vector2(-259.0, 2256.5)
const SPUR_POINT := Vector2(-260.0, 2260.0)
const CAMERA_BACK_M := 5.2
const APPROACH_VIEWS := [
	{"stand": Vector2(-245.0, 2250.0), "target": Vector2(-256.4, 2260.1)},
	{"stand": Vector2(-245.0, 2247.0), "target": Vector2(-254.5, 2255.5)},
]
# Measured from camp_tent.glb's imported POSITION bounds after the authored
# 68-degree pitch and 8-degree roll. These make grounding/clearance assertions
# match the transformed mesh instead of treating its origin as its lower edge.
const TENT_TRANSFORMED_MIN_Y_AT_UNIT_SCALE := -1.146817
const TENT_PLANAR_RADIUS_AT_UNIT_SCALE := 1.240116


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _third_person_camera(stand: Vector2, target: Vector2) -> Vector2:
	return stand - (target - stand).normalized() * CAMERA_BACK_M


func test_ranger_camp_has_one_tight_overlapping_approach_lens() -> void:
	var lens := {}
	for raw: Variant in _read(VEGETATION_PATH).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 2004:
			lens = raw
	assert_false(lens.is_empty(), "Ranger Camp ordinary arrival has no scatter lens")
	var centre := Vector2(float(lens.get("x", INF)), float(lens.get("z", INF)))
	var radius := float(lens.get("radius", INF))
	for view: Dictionary in APPROACH_VIEWS:
		var camera := _third_person_camera(view.stand, view.target)
		assert_true(camera.distance_to(centre) <= radius - 3.0,
			"real third-person camera still lacks a useful scatter-free margin")
	assert_true(centre.distance_to(CAMP_CENTRE) < radius + 15.0,
		"approach lens detached from the established camp clearing")
	assert_eq(radius, 9.0, "Ranger Camp approach fix widened into a second field")


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
	var scale := float(shelter.get("scale", 0.0))
	assert_true(scale >= 1.0 and scale <= 1.1,
		"collapsed shelter scale is no longer a restrained silhouette correction")
	var lower_edge_above_ground := -float(shelter.get("sink_m", 0.0)) \
		+ TENT_TRANSFORMED_MIN_Y_AT_UNIT_SCALE * scale
	assert_true(lower_edge_above_ground >= -0.05 and lower_edge_above_ground <= 0.02,
		"rotated shelter is visibly buried or floating instead of terrain-grounded")
	var at_raw := shelter.get("at", []) as Array
	var at := Vector2(float(at_raw[0]), float(at_raw[1]))
	var footprint_radius := TENT_PLANAR_RADIUS_AT_UNIT_SCALE * scale
	var rest := camp.get("rest", {}) as Dictionary
	var rest_raw := rest.get("at", []) as Array
	var rest_at := Vector2(float(rest_raw[0]), float(rest_raw[1]))
	var craft_raw := rest.get("craft_at", []) as Array
	var craft_at := Vector2(float(craft_raw[0]), float(craft_raw[1]))
	assert_true(at.distance_to(rest_at) - footprint_radius > float(rest.get("radius", 0.0)) + 3.0,
		"collapsed shelter blocks the functional rest circle")
	assert_true(at.distance_to(craft_at) - footprint_radius > 5.0,
		"collapsed shelter blocks the craft point")
	assert_true(at.distance_to(SPUR_POINT) - footprint_radius > 8.0,
		"collapsed shelter blocks the ranger spur")
