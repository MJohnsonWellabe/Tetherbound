extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const CAPTURE_PATH := "res://tools/capture_grandpa_yard_identity.gd"
const DOOR := Vector2(-15.7, -16.0)


func _config(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s did not parse as a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _entry(entries: Array, order: int) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == order:
			return raw as Dictionary
	return {}


func test_grandpa_work_yard_has_one_coherent_domestic_cluster() -> void:
	var cluster := _entry(_config(PROPS_PATH).get("clusters", []), 1035)
	assert_false(cluster.is_empty(), "Grandpa's south-east yard has no domestic work nook")
	if cluster.is_empty():
		return
	var props: Array = cluster.get("props", [])
	assert_eq(props.size(), 4, "Grandpa's work nook should stay compact, not become prop scatter")
	var models: Array[String] = []
	for raw: Variant in props:
		var prop := raw as Dictionary
		models.append(str(prop.get("model", "")))
		var at: Array = prop.get("at", [])
		assert_eq(at.size(), 2, "a Grandpa-yard prop has no world position")
		if at.size() != 2:
			continue
		var point := Vector2(float(at[0]), float(at[1]))
		assert_true(point.y <= -20.4,
			"Grandpa-yard dressing drifted north into the house or door approach")
		assert_true(point.distance_to(DOOR) >= 4.0,
			"Grandpa-yard dressing blocks the opening/starter doorway lane")
	assert_true(models.has("Bench") and models.has("FarmCrate_Apple") and
		models.has("Bucket_Wooden_1") and models.has("Stool"),
		"the domestic harvest/wash/seat hierarchy is incomplete")


func test_grandpa_work_yard_uses_installed_assets() -> void:
	var cluster := _entry(_config(PROPS_PATH).get("clusters", []), 1035)
	for raw: Variant in cluster.get("props", []):
		var prop := raw as Dictionary
		var directory := str(prop.get("dir", "res://assets/props/quaternius_fantasy"))
		var model := str(prop.get("model", ""))
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [directory, model]),
			"Grandpa-yard prop %s is not an installed asset" % model)


func test_grandpa_domestic_apron_is_bounded_off_progression_space() -> void:
	var footprints: Array = _config(VEGETATION_PATH).get("footprints", [])
	var footprint := _entry(footprints, 1001)
	assert_false(footprint.is_empty(),
		"the oversized foreground clump still has no bounded exclusion footprint")
	if footprint.is_empty():
		return
	var centre := Vector2(float(footprint.get("x", 0.0)), float(footprint.get("z", 0.0)))
	var radius := float(footprint.get("radius", 0.0))
	assert_between(radius, 2.8, 3.4,
		"Grandpa's domestic apron is either too small to work or a broad bald clearing")
	assert_true(centre.distance_to(Vector2(-16.7, -21.2)) <= 0.1,
		"Grandpa's apron drifted off the south-east work yard")
	assert_true(centre.distance_to(DOOR) - radius >= 1.8,
		"Grandpa's apron reaches the east-door opening/starter lane")
	for plot_z in [-9.0, -6.6]:
		for plot_x in [-24.4, -22.0, -19.6]:
			assert_true(centre.distance_to(Vector2(plot_x, plot_z)) > radius,
				"Grandpa's apron reaches an interactive farm plot")


func test_grandpa_foreground_berry_keeps_content_but_not_oversized_scale() -> void:
	var harvest := _config(
		"res://data/config/bands/band1_lower_meadows/harvest.json")
	var berry := _entry(harvest.get("nodes", []), 1036)
	assert_false(berry.is_empty(), "Grandpa's early-game berry node was removed")
	if berry.is_empty():
		return
	assert_eq(str(berry.get("item", "")), "berries",
		"Grandpa's early-game berry content changed")
	assert_eq(int(berry.get("amount", 0)), 3,
		"Grandpa's early-game berry yield changed")
	assert_eq(berry.get("at", []), [-9.0, -19.0],
		"Grandpa's berry prompt moved back into a civilian interaction contest")
	assert_between(float(berry.get("model_scale", 0.0)), 0.42, 0.55,
		"Grandpa's foreground berry bush is missing or oversized again")


func test_grandpa_capture_freezes_the_requested_clock_and_hides_water_overlay() -> void:
	var source := FileAccess.get_file_as_string(CAPTURE_PATH)
	assert_true(source.find('look.call("apply_time", time_name)') >= 0,
		"Grandpa evidence does not apply its authored day/night clock")
	assert_true(source.find('look.call("apply_time", time_name)') <
		source.find('look.call("set_clock_frozen", true)'),
		"Grandpa evidence freezes the clock before applying the requested time")
	assert_true(source.find('^"Water/SubmersionOverlay"') >= 0,
		"Grandpa evidence can leak the independent submersion tint")
	assert_true(source.find("func _surface") >= 0 and
		source.find("stand_ground + 0.45") >= 0,
		"Grandpa evidence can park the player under analytic ground")
