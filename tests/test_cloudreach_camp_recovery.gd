extends "res://tests/test_case.gd"

## Cloudreach's physical camps deliberately reuse the shared authored-rest
## mechanic. These are data/runtime-shape checks; the input-driven night and
## HP trade-off live in smoke_cloudreach_camp_recovery.gd.

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const REST := preload("res://scripts/world/rest_point.gd")


func _chapter() -> Dictionary:
	return RULES.read(RUNTIME.CHAPTER_PATH)


func test_every_cloudreach_recovery_camp_has_one_unique_reserved_bed() -> void:
	var camps: Array = _chapter().get("camping_contract", {}).get("camps", [])
	assert_eq(camps.size(), 5)
	var indices: Array[int] = []
	var bed_positions: Array[Vector2] = []
	for value: Variant in camps:
		var camp := value as Dictionary
		var id := str(camp.get("id", "?"))
		var services: Array = camp.get("services", [])
		assert_true(services.has("rest"), "camp '%s' lost player rest" % id)
		assert_true(services.has("creature_recovery"), "camp '%s' has no recovery service" % id)
		var raw: Variant = camp.get("creature_bed", {})
		assert_true(raw is Dictionary and not (raw as Dictionary).is_empty(), "camp '%s' has no authored bed" % id)
		if not raw is Dictionary:
			continue
		var bed := raw as Dictionary
		var index := int(bed.get("bed_index", 0))
		assert_true(index <= REST.AUTHORED_BED_INDEX_CEILING,
			"camp '%s' bed index %d is not reserved" % [id, index])
		assert_false(indices.has(index), "camp '%s' shares bed index %d" % [id, index])
		indices.append(index)
		var at: Variant = bed.get("at", [])
		assert_true(at is Array and (at as Array).size() == 2, "camp '%s' bed has no world [x,z]" % id)
		if at is Array and (at as Array).size() == 2:
			var position := Vector2(float((at as Array)[0]), float((at as Array)[1]))
			bed_positions.append(position)
			var camp_at: Array = camp.get("position", [])
			if camp_at.size() >= 3:
				assert_true(position.distance_to(Vector2(float(camp_at[0]), float(camp_at[2]))) > 2.0,
					"camp '%s' bed overlaps the camp rest/dressing centre" % id)
	assert_eq(indices.size(), camps.size(), "each recovery camp needs its own bed index")
	assert_eq(bed_positions.size(), camps.size(), "each recovery camp needs a grounded bed coordinate")


func test_camp_rest_payload_opts_creature_recovery_in_without_changing_rest_or_craft() -> void:
	var camp: Dictionary = (_chapter()["camping_contract"]["camps"] as Array)[0]
	var resolved := Vector3(-280.0, 180.0, 520.0)
	var payload := RUNTIME.camp_rest_spec(camp, resolved)
	assert_eq(payload["at"], [-280.0, 520.0])
	assert_eq(payload["height"], 180.0)
	assert_true(bool(payload["craft"]), "recovery wiring removed camp crafting")
	assert_true(payload.has("creature_bed"), "recovery service did not pass the bed to REST.build")
	assert_eq(int((payload["creature_bed"] as Dictionary)["bed_index"]), -21)

	var player_only := camp.duplicate(true)
	player_only["services"] = ["save", "rest", "cook"]
	var player_payload := RUNTIME.camp_rest_spec(player_only, resolved)
	assert_false(player_payload.has("creature_bed"), "a camp without creature_recovery gained a hidden bed")
	assert_true(bool(player_payload["craft"]), "player-only camp lost crafting")
	assert_eq(player_payload["at"], [-280.0, 520.0])
