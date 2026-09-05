extends "res://tests/test_case.gd"

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")

const CANDY_COUNTS := {
	"good_candy": 60,
	"great_candy": 30,
	"rare_candy": 10,
}
const RECOVERY_COUNTS := {
	"potion_small": 30,
	"potion_large": 12,
	"revive": 18,
	"speed_mushroom": 5,
	"stamina_mushroom": 5,
	"wild_mushroom": 5,
}
const CANDY_BY_REGION := {
	"gate_lower_cliffs": 12,
	"broken_causeways": 22,
	"windscar_ravine": 16,
	"high_roost_sky_shrine": 12,
	"upper_cloudreach": 24,
	"summit_final_stronghold": 14,
}
const RECOVERY_BY_REGION := {
	"gate_lower_cliffs": 10,
	"broken_causeways": 15,
	"windscar_ravine": 13,
	"high_roost_sky_shrine": 10,
	"upper_cloudreach": 17,
	"summit_final_stronghold": 10,
}
const ITEMS_BY_REGION := {
	"gate_lower_cliffs": {"good_candy": 10, "great_candy": 2, "rare_candy": 0,
		"potion_small": 6, "potion_large": 0, "revive": 2,
		"speed_mushroom": 1, "stamina_mushroom": 1, "wild_mushroom": 0},
	"broken_causeways": {"good_candy": 15, "great_candy": 6, "rare_candy": 1,
		"potion_small": 7, "potion_large": 2, "revive": 3,
		"speed_mushroom": 1, "stamina_mushroom": 1, "wild_mushroom": 1},
	"windscar_ravine": {"good_candy": 10, "great_candy": 5, "rare_candy": 1,
		"potion_small": 5, "potion_large": 1, "revive": 3,
		"speed_mushroom": 1, "stamina_mushroom": 2, "wild_mushroom": 1},
	"high_roost_sky_shrine": {"good_candy": 5, "great_candy": 5, "rare_candy": 2,
		"potion_small": 3, "potion_large": 2, "revive": 2,
		"speed_mushroom": 1, "stamina_mushroom": 1, "wild_mushroom": 1},
	"upper_cloudreach": {"good_candy": 12, "great_candy": 9, "rare_candy": 3,
		"potion_small": 7, "potion_large": 4, "revive": 4,
		"speed_mushroom": 1, "stamina_mushroom": 0, "wild_mushroom": 1},
	"summit_final_stronghold": {"good_candy": 8, "great_candy": 3, "rare_candy": 3,
		"potion_small": 2, "potion_large": 3, "revive": 4,
		"speed_mushroom": 0, "stamina_mushroom": 0, "wild_mushroom": 1},
}
const CANONICAL_PICKUPS := {
	"cr_pickup_lower_good_candy": ["good_candy", 1, ""],
	"cr_pickup_lower_potion": ["potion_small", 2, ""],
	"cr_pickup_lower_revive": ["revive", 1, ""],
	"cr_pickup_bridge_good_candy": ["good_candy", 1, ""],
	"cr_pickup_west_great_candy": ["great_candy", 1, ""],
	"cr_pickup_arch_large_potion": ["potion_large", 1, ""],
	"cr_pickup_west_wind_tm": ["tm_wind_blade", 1, ""],
	"cr_pickup_windscar_great_candy": ["great_candy", 1, ""],
	"cr_pickup_aerie_revive": ["revive", 1, ""],
	"cr_pickup_aerie_stamina": ["stamina_mushroom", 2, "fly_traversal_unlocked"],
	"cr_pickup_shrine_rare_candy": ["rare_candy", 1, "fly_traversal_unlocked"],
	"cr_pickup_perches_heavenfall": ["tm_heavenfall", 1, "fly_traversal_unlocked"],
	"cr_pickup_shrine_revive": ["revive", 2, "fly_traversal_unlocked"],
	"cr_pickup_upper_great_candy": ["great_candy", 1, "cloudreach_upper_route_unlocked"],
	"cr_pickup_observatory_potion": ["potion_large", 2, "cloudreach_upper_route_unlocked"],
	"cr_pickup_upper_rare_candy": ["rare_candy", 1, "fly_traversal_unlocked"],
	"cr_pickup_upper_aerial_tm": ["tm_aerial_flash", 1, "cloudreach_upper_route_unlocked"],
	"cr_pickup_waterward_rare_candy": ["rare_candy", 1, "cloudreach_upper_route_unlocked"],
	"cr_pickup_summit_revive": ["revive", 2, "cloudreach_upper_route_unlocked"],
}


func test_owner_world_placement_totals_are_exact() -> void:
	var pickups: Array = RULES.read(RUNTIME.CHAPTER_PATH)["pickups"]
	assert_eq(pickups.size(), 178, "100 candy + 75 recovery + three canonical TMs")
	_assert_item_counts(pickups, CANDY_COUNTS)
	_assert_item_counts(pickups, RECOVERY_COUNTS)
	_assert_region_counts(pickups, CANDY_COUNTS.keys(), CANDY_BY_REGION)
	_assert_region_counts(pickups, RECOVERY_COUNTS.keys(), RECOVERY_BY_REGION)
	_assert_region_item_matrix(pickups)


func test_density_rows_are_stable_single_world_placements() -> void:
	var pickups: Array = RULES.read(RUNTIME.CHAPTER_PATH)["pickups"]
	var ids: Dictionary = {}
	var density_positions: Dictionary = {}
	var density_count := 0
	for raw: Variant in pickups:
		var spec := raw as Dictionary
		var id := str(spec["id"])
		assert_false(ids.has(id), "duplicate persistence id: " + id)
		ids[id] = true
		assert_true(RULES.vec(spec["position"]).is_finite(), id + " has no finite authored position")
		if CANONICAL_PICKUPS.has(id):
			var expected: Array = CANONICAL_PICKUPS[id]
			assert_eq(spec["item_id"], expected[0], id + " item changed")
			assert_eq(spec["count"], expected[1], id + " stack changed")
			assert_eq(spec["requires_unlock"], expected[2], id + " unlock changed")
			continue
		density_count += 1
		assert_eq(int(spec["count"]), 1, id + " must be one world placement, not a stack")
		assert_true(bool(spec["persistent"]) and bool(spec["one_time"]), id)
		assert_true(str(spec["placement"]) in ["route_verge", "optional_loop", "fly_only_pocket"], id)
		if str(spec["placement"]) == "fly_only_pocket":
			assert_eq(str(spec["requires_unlock"]), "fly_traversal_unlocked", id)
		var region := str(spec["region_id"])
		if not density_positions.has(region):
			density_positions[region] = []
		for other: Vector3 in density_positions[region]:
			assert_true(Vector2(other.x, other.z).distance_to(Vector2(
				float(spec["position"][0]), float(spec["position"][2]))) >= 7.5,
				id + " overlaps another density placement")
		(density_positions[region] as Array).append(RULES.vec(spec["position"]))
	assert_eq(density_count, 159)
	assert_eq(CANONICAL_PICKUPS.size(), 19)
	_assert_density_lane_counts(pickups)


func test_density_stays_clear_of_authored_interactions_camps_and_battle_entries() -> void:
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var runtime := RULES.read(RUNTIME.DATA_PATH)
	var scene := RULES.read("res://data/config/cloudreach_scene_runtime.json")
	var occupied: Array[Vector3] = []
	for spec: Dictionary in runtime["interactions"]:
		occupied.append(RULES.vec(spec["position"]))
	for spec: Dictionary in chapter["camping_contract"]["camps"]:
		occupied.append(RULES.vec(spec["position"]))
	for spec: Dictionary in scene["battle_yards"]:
		occupied.append(RULES.vec(spec["road_position"]))
	for spec: Dictionary in chapter["pickups"]:
		if CANONICAL_PICKUPS.has(str(spec["id"])):
			continue
		var at := RULES.vec(spec["position"])
		for anchor: Vector3 in occupied:
			assert_true(Vector2(at.x, at.z).distance_to(Vector2(anchor.x, anchor.z)) >= 7.5,
				str(spec["id"]) + " crowds an authored interaction/combat/camp anchor")


func _assert_item_counts(pickups: Array, expected: Dictionary) -> void:
	var found: Dictionary = {}
	for id: String in expected:
		found[id] = 0
	for spec: Dictionary in pickups:
		var item := str(spec["item_id"])
		if found.has(item):
			found[item] = int(found[item]) + 1
	for id: String in expected:
		assert_eq(int(found[id]), int(expected[id]), id)


func _assert_region_counts(pickups: Array, items: Array, expected: Dictionary) -> void:
	var found: Dictionary = {}
	for region: String in expected:
		found[region] = 0
	for spec: Dictionary in pickups:
		if items.has(str(spec["item_id"])):
			var region := str(spec["region_id"])
			found[region] = int(found.get(region, 0)) + 1
	for region: String in expected:
		assert_eq(int(found[region]), int(expected[region]), region)


func _assert_region_item_matrix(pickups: Array) -> void:
	for region: String in ITEMS_BY_REGION:
		var found: Dictionary = {}
		for spec: Dictionary in pickups:
			if str(spec["region_id"]) == region:
				var item := str(spec["item_id"])
				found[item] = int(found.get(item, 0)) + 1
		for item: String in ITEMS_BY_REGION[region]:
			assert_eq(int(found.get(item, 0)), int(ITEMS_BY_REGION[region][item]),
				region + "/" + item)


func _assert_density_lane_counts(pickups: Array) -> void:
	var candy := {"route_verge": 0, "optional_loop": 0, "fly_only_pocket": 0}
	var recovery := {"route_verge": 0, "optional_loop": 0, "fly_only_pocket": 0}
	for spec: Dictionary in pickups:
		if CANONICAL_PICKUPS.has(str(spec["id"])):
			continue
		var lane := str(spec["placement"])
		var target: Dictionary = candy if CANDY_COUNTS.has(str(spec["item_id"])) else recovery
		target[lane] = int(target[lane]) + 1
	assert_eq(candy, {"route_verge": 33, "optional_loop": 42, "fly_only_pocket": 17})
	assert_eq(recovery, {"route_verge": 31, "optional_loop": 26, "fly_only_pocket": 10})
