extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band3_the_river_lock/props.json"
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func test_long_water_has_an_authored_open_bank_rhythm() -> void:
	var props_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	assert_true(props_raw is Dictionary, "Band 3 props did not parse")
	if not props_raw is Dictionary:
		return
	var target: Dictionary = {}
	for raw: Variant in (props_raw as Dictionary).get("clusters", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "long_water_reach":
			target = raw as Dictionary
			break
	assert_false(target.is_empty(), "The Long Water has no authored presentation cluster")
	if target.is_empty():
		return

	var rocks := 0
	var reeds := 0
	var near_bank := 0
	var far_bank := 0
	var waterline_shelves := 0
	var rim_outcrops := 0
	var overlook_height := 0.0
	var names: Dictionary = {}
	for raw: Variant in target.get("props", []):
		if not raw is Dictionary:
			continue
		var prop := raw as Dictionary
		var name := str(prop.get("name", ""))
		assert_false(name.is_empty(), "Long Water prop lacks a stable authored name")
		assert_false(names.has(name), "Long Water repeats authored prop name %s" % name)
		names[name] = true
		var model := str(prop.get("model", ""))
		rocks += int(model.begins_with("Rock_Medium_"))
		reeds += int(model in ["Grass_Wheat", "Grass_Wide_Tall", "Grass_Wispy_Tall"])
		var at: Array = prop.get("at", [])
		var scale_xyz: Array = prop.get("scale_xyz", [])
		if name.begins_with("OverlookCrown") and scale_xyz.size() == 3:
			overlook_height = maxf(overlook_height, float(scale_xyz[1]))
		assert_true(at.size() == 2, "Long Water prop %s has no world position" % name)
		if at.size() != 2:
			continue
		if name.begins_with("FarShelf") and scale_xyz.size() == 3:
			waterline_shelves += int(float(at[1]) >= 4203.0 and float(at[1]) <= 4204.8
				and float(scale_xyz[1]) >= 0.75 and float(scale_xyz[1]) <= 1.30)
		if name.begins_with("FarRimOutcrop") and scale_xyz.size() == 3:
			rim_outcrops += int(float(at[1]) >= 4211.0 and float(scale_xyz[1]) >= 0.80)
		var z := float(at[1])
		near_bank += int(z <= 4184.0)
		far_bank += int(z >= 4203.0)
		assert_true(z < 4185.0 or z > 4205.0 or name.begins_with("FarShelf"),
			"Long Water prop %s intrudes into the open channel without being an authored waterline shelf" % name)
	assert_true(rocks >= 11, "Long Water needs enough stone shelves to break both straight rims")
	assert_true(reeds >= 10, "Long Water lacks a readable reed rhythm")
	assert_true(near_bank >= 8 and far_bank >= 8,
		"Long Water dressing must author both banks, not one decorative foreground")
	assert_true(waterline_shelves >= 3,
		"Long Water needs three moderate ground-seated shelves at the far waterline")
	assert_true(rim_outcrops >= 3,
		"Long Water needs separate ground-seated rim outcrops to break the top silhouette")
	assert_true(overlook_height >= 1.25,
		"Long Water overlook crown is too low to read as an authored destination")


func test_long_water_overlook_is_open_and_isolated_from_old_mill() -> void:
	var vegetation_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_PATH))
	assert_true(vegetation_raw is Dictionary, "Band 3 vegetation did not parse")
	if not vegetation_raw is Dictionary:
		return
	var target: Dictionary = {}
	for raw: Variant in (vegetation_raw as Dictionary).get("clearings", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "long_water_overlook":
			target = raw as Dictionary
			break
	assert_false(target.is_empty(), "Long Water has no deliberate sightline clearing")
	if target.is_empty():
		return
	assert_eq(int(target.get("order", -1)), 3004,
		"Long Water clearing moved onto an occupied Band 3 merge order")
	assert_true(float(target.get("radius", 0.0)) >= 20.0,
		"Long Water clearing does not span both banks of the local cross-section")
	var dx := float(target.get("x", 0.0)) - -152.0
	var dz := float(target.get("z", 0.0)) - 4203.0
	assert_true(Vector2(dx, dz).length() - float(target.get("radius", 0.0)) > 95.0,
		"Long Water clearing reaches the separately named Old Mill Crossing")

	var lens: Dictionary = {}
	for raw: Variant in (vegetation_raw as Dictionary).get("clearings", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "long_water_camera_lens":
			lens = raw as Dictionary
			break
	assert_false(lens.is_empty(), "The Long Water overlook has no third-person camera keyhole")
	if lens.is_empty():
		return
	assert_eq(int(lens.get("order", -1)), 3005,
		"Long Water camera lens moved onto an occupied Band 3 merge order")
	assert_true(float(lens.get("radius", 0.0)) <= 6.0,
		"Long Water camera lens became a broad second clearing")
	var overlap := Vector2(
		float(lens.get("x", 0.0)) - float(target.get("x", 0.0)),
		float(lens.get("z", 0.0)) - float(target.get("z", 0.0))).length()
	assert_true(overlap < float(lens.get("radius", 0.0)) + float(target.get("radius", 0.0)),
		"Long Water camera keyhole no longer overlaps the authored overlook")


func test_long_water_bank_wander_changes_landform_without_opening_a_crossing() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	assert_true(raw is Dictionary, "Terrain config did not parse")
	if not raw is Dictionary:
		return
	var course: Array = ((raw as Dictionary).get("river", {}) as Dictionary).get("course", [])
	assert_true(course.size() >= 11, "River course is missing the Long Water / Old Mill stations")
	if course.size() < 11:
		return
	assert_true(float((course[4] as Dictionary).get("bank_wobble_m", 0.0)) >= 2.0,
		"Long Water west approach lacks metre-space bank wander")
	assert_true(float((course[5] as Dictionary).get("bank_wobble_m", 0.0)) >= 3.0,
		"Long Water hero station lacks a visible bank-wander amplitude")
	for index: int in [7, 8, 9, 10]:
		assert_almost_eq(float((course[index] as Dictionary).get("bank_wobble_m", 0.0)), 0.0, 0.001,
			"Long Water bank repair leaked into the Old Mill Crossing narrows at index %d" % index)

	var field := HEIGHTFIELD.new()
	var inferred_wanders: Array[float] = []
	var weakest_wall_angle := INF
	for t: float in [0.15, 0.32, 0.49, 0.66, 0.83]:
		var a: Dictionary = course[4]
		var b: Dictionary = course[5]
		var pa := Vector2(float((a.at as Array)[0]), float((a.at as Array)[1]))
		var pb := Vector2(float((b.at as Array)[0]), float((b.at as Array)[1]))
		var centre := pa.lerp(pb, t)
		var across := Vector2(-(pb - pa).y, (pb - pa).x).normalized()
		var half := lerpf(float(a.half_width), float(b.half_width), t)
		var rim := lerpf(float(a.rim), float(b.rim), t)
		var amplitude := lerpf(float(a.bank_wobble_m), float(b.bank_wobble_m), t)
		var cutoff := half
		var d := half
		while d <= half + rim + amplitude + 1.0:
			var point := centre + across * d
			if float(field.river_factor(point.x, point.y)) <= 0.01:
				cutoff = d
				break
			d += 0.25
		var inferred := cutoff - half - rim * 0.6
		inferred_wanders.append(inferred)
		assert_true(inferred >= -0.3 and inferred <= amplitude + 0.3,
			"Long Water bank wander escaped its authored amplitude")

		var steepest := 0.0
		d = half
		while d < half + rim + amplitude:
			var p0 := centre + across * d
			var p1 := centre + across * (d + 0.5)
			var rise := absf(float(field.height_at(p1.x, p1.y)) - float(field.height_at(p0.x, p0.y)))
			steepest = maxf(steepest, rad_to_deg(atan2(rise, 0.5)))
			d += 0.5
		weakest_wall_angle = minf(weakest_wall_angle, steepest)
	assert_true(inferred_wanders.max() - inferred_wanders.min() >= 0.75,
		"Long Water bank edge remains effectively straight across the hero reach")
	assert_true(weakest_wall_angle >= 48.0,
		"Long Water landform repair opened a walkable bank (weakest %.1f degrees)" % weakest_wall_angle)
