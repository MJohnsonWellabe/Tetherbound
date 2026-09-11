extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band3_the_river_lock/props.json"
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"


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
		assert_true(at.size() == 2, "Long Water prop %s has no world position" % name)
		if at.size() != 2:
			continue
		var z := float(at[1])
		near_bank += int(z <= 4184.0)
		far_bank += int(z >= 4208.0)
		assert_true(z < 4185.0 or z > 4205.0,
			"Long Water prop %s intrudes into the open channel" % name)
	assert_true(rocks >= 8, "Long Water needs enough stone shelves to break both straight rims")
	assert_true(reeds >= 10, "Long Water lacks a readable reed rhythm")
	assert_true(near_bank >= 8 and far_bank >= 8,
		"Long Water dressing must author both banks, not one decorative foreground")


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
