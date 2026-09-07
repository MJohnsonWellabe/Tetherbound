extends "res://tests/test_case.gd"

const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")

const REQUIRED_COUNTS := {
	"good_candy": 60, "great_candy": 30, "rare_candy": 10,
	"potion_small": 30, "potion_large": 18, "revive": 24,
	"speed_mushroom": 8, "stamina_mushroom": 8, "wild_mushroom": 8,
	"swift_tonic": 4, "attack_tonic": 4, "stoneguard_brew": 4,
	"orb_basic": 6, "orb_greater": 4, "orb_prime": 2,
	"tm_static_snap": 1, "tm_voltaic_whip": 1, "tm_thunder_break": 1, "tm_stormfall": 1,
	"insulated_leggings": 1, "insulated_boots": 1,
	"rootgate_release_key": 1, "dynamo_core_key": 1, "spark_of_stormwood": 1,
}
const NEW_STORMWOOD_IDS := ["tm_static_snap", "tm_voltaic_whip", "tm_thunder_break", "tm_stormfall", "insulated_leggings", "insulated_boots", "rootgate_release_key", "dynamo_core_key", "spark_of_stormwood"]
const CRITICAL_ROUTE := [[-300.0,180.0],[-350.0,450.0],[-650.0,830.0],[-590.0,1060.0],[-380.0,1400.0],[-900.0,1780.0],[-700.0,2300.0],[-560.0,2480.0],[-160.0,2700.0],[-630.0,2930.0],[-1080.0,3020.0],[-1120.0,3290.0],[-650.0,3550.0],[-450.0,3960.0],[-890.0,4490.0],[-150.0,4460.0],[-310.0,5050.0],[-100.0,5350.0],[-100.0,5470.0]]


func _load_pickups() -> Array:
	var file := FileAccess.open("res://data/config/stormwood_pickups.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed.get("pickups", []) if parsed is Dictionary else []


func test_catalogue_has_exact_total_and_category_counts() -> void:
	var pickups := _load_pickups()
	assert_eq(pickups.size(), 229)
	var counts := {}
	for pickup in pickups:
		counts[pickup.get("item_id", "")] = int(counts.get(pickup.get("item_id", ""), 0)) + int(pickup.get("count", 0))
	for item_id in REQUIRED_COUNTS:
		assert_eq(counts.get(item_id, 0), REQUIRED_COUNTS[item_id], item_id)


func test_ids_are_stable_and_items_exist() -> void:
	var pickups := _load_pickups()
	var item_file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	var items: Dictionary = JSON.parse_string(item_file.get_as_text()).get("items", {})
	var ids := {}
	for pickup in pickups:
		var pickup_id: String = pickup.get("id", "")
		assert_true(not pickup_id.is_empty())
		assert_false(ids.has(pickup_id), "duplicate pickup id %s" % pickup_id)
		ids[pickup_id] = true
		assert_true(items.has(pickup.get("item_id", "")) or pickup.get("item_id", "") in NEW_STORMWOOD_IDS, "unknown item %s" % pickup.get("item_id", ""))
		if pickup.get("runtime_kind", "") == "story_reward":
			assert_false(bool(pickup.get("collectible", true)))
	var story_ids := []
	for pickup in pickups:
		if pickup.get("runtime_kind", "") == "story_reward":
			story_ids.append(pickup.get("item_id", ""))
	assert_eq(story_ids, ["rootgate_release_key", "dynamo_core_key", "spark_of_stormwood"])


func test_distribution_and_off_path_contract() -> void:
	var pickups := _load_pickups()
	var regions := {}
	var off_path := 0
	var critical_candy := 0
	for pickup in pickups:
		var region: String = pickup.get("region_id", "")
		regions[region] = int(regions.get(region, 0)) + 1
		if _route_distance(Vector2(float(pickup.position[0]), float(pickup.position[2]))) >= 12.0:
			off_path += 1
		if pickup.get("placement", "") == "critical_route_verge" and str(pickup.get("item_id", "")).contains("candy"):
			critical_candy += int(pickup.get("count", 0))
	for region in ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]:
		assert_true(int(regions.get(region, 0)) >= 28, "region under pickup minimum: %s" % region)
	assert_true(off_path >= 184)
	assert_true(critical_candy <= 12)
	var tm_regions := {}
	for pickup in pickups:
		if str(pickup.get("item_id", "")).begins_with("tm_"):
			tm_regions[pickup.get("item_id", "")] = pickup.get("region_id", "")
	assert_eq(tm_regions.get("tm_static_snap", ""), "glowmoss_hollows")
	assert_eq(tm_regions.get("tm_voltaic_whip", ""), "hollow_crown")
	assert_eq(tm_regions.get("tm_thunder_break", ""), "deepwood")
	assert_eq(tm_regions.get("tm_stormfall", ""), "dynamo")


func test_positions_have_terrain_contact_envelope_and_crown_island_bounds() -> void:
	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	for pickup in _load_pickups():
		var p: Array = pickup.get("position", [])
		assert_eq(p.size(), 3)
		var x := float(p[0])
		var y := float(p[1])
		var z := float(p[2])
		assert_true(x >= -2560.0 and x <= 2048.0 and z >= 0.0 and z <= 6144.0)
		assert_true(absf(y - field.height_at(x, z)) <= 1.0, "pickup too far from terrain: %s" % pickup.get("id", ""))
		assert_true(field.slope_degrees_at(x, z) <= 45.0, "pickup on steep terrain: %s" % pickup.get("id", ""))
		if pickup.get("region_id", "") == "hollow_crown":
			assert_true(x >= 440.0 and x <= 960.0 and z >= 2440.0 and z <= 2960.0)


func _route_distance(point: Vector2) -> float:
	var closest := INF
	for index in range(CRITICAL_ROUTE.size() - 1):
		var a := Vector2(CRITICAL_ROUTE[index][0], CRITICAL_ROUTE[index][1])
		var b := Vector2(CRITICAL_ROUTE[index + 1][0], CRITICAL_ROUTE[index + 1][1])
		var along := clampf((point - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
		closest = minf(closest, point.distance_to(a.lerp(b, along)))
	return closest
