extends "res://tests/test_case.gd"

const CAMPS := preload("res://scripts/world/stormwood_camps.gd")
const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")


func test_camp_data_has_six_safe_full_service_sites_and_reserved_beds() -> void:
	var errors := CAMPS.validate(CAMPS.load_config(), _read(CAMPS.SURGE_PATH), _read(CAMPS.NPCS_PATH), _read(CAMPS.SETTLEMENTS_PATH))
	assert_eq(errors, [], "\n".join(errors))
	var indices := []
	for camp: Dictionary in CAMPS.load_config().get("camps", []):
		assert_eq((camp.get("services", []) as Array).size(), 4)
		indices.append(int((camp.get("creature_bed", {}) as Dictionary).get("bed_index", 0)))
	indices.sort()
	assert_eq(indices, [-36, -35, -34, -33, -32, -31])


func test_rest_adapter_preserves_shared_rest_and_grounded_bed_contract() -> void:
	var field := HEIGHTFIELD.new()
	for camp: Dictionary in CAMPS.load_config().get("camps", []):
		var at: Array = camp.at
		var ground := field.height_at(float(at[0]), float(at[1]))
		var payload := CAMPS.rest_spec(camp, ground)
		assert_true(bool(payload.craft), str(camp.id) + " retains shared crafting")
		assert_eq(payload.craft_label, "Cook and craft")
		assert_almost_eq(float(payload.height), ground, 0.001, str(camp.id) + " rest is heightfield-resolved")
		assert_true(payload.has("creature_bed"), str(camp.id) + " passes recovery to RestPoint")
		var bed: Dictionary = payload.creature_bed
		var bed_at: Array = bed.at
		assert_true(is_finite(field.height_at(float(bed_at[0]), float(bed_at[1]))), str(camp.id) + " bed has terrain ground")


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
