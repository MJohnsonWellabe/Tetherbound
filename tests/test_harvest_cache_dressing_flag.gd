extends "res://tests/test_case.gd"

## F38#12 candidate: installed camp props stage three found rewards as a
## traveller's cache. The switch is OFF until a GPU verdict, and only the
## three judged nodes carry a block.

const DRESSING := preload("res://scripts/world/harvest_cache_dressing.gd")
const SWITCH := "res://data/config/harvest_stash_support.json"
const EXPECTED := {
	"res://data/config/bands/band1_lower_meadows/harvest.json": {1029: "orb_basic", 1030: "travel_pack"},
	"res://data/config/bands/band3_the_river_lock/harvest.json": {3019: "attack_tonic"},
}


func test_switch_is_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SWITCH))
	assert_false(bool(cfg.get("cache_dressing_enabled", true)))
	assert_false(DRESSING.switch_on())


func test_only_the_three_rewards_carry_a_block_of_installed_props() -> void:
	for path: String in EXPECTED:
		var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var expected: Dictionary = EXPECTED[path]
		var found := 0
		for node: Variant in cfg.get("nodes", []):
			var visual: Variant = (node as Dictionary).get("visual", {})
			if not visual is Dictionary or not (visual as Dictionary).has("cache_dressing_1113"):
				continue
			found += 1
			var order := int((node as Dictionary).get("order", -1))
			assert_true(expected.has(order), "order %d is a judged reward" % order)
			assert_eq(str((node as Dictionary).get("item", "")), str(expected.get(order, "")))
			var props: Array = ((visual as Dictionary).cache_dressing_1113 as Dictionary).get("props", [])
			assert_true(props.size() >= 3)
			for prop: Variant in props:
				assert_true(ResourceLoader.exists(str((prop as Dictionary).get("model", ""))), "prop is installed")
				var at: Array = (prop as Dictionary).get("at", [])
				# Clear of the reward's own footprint, inside the prompt radius.
				var reach := Vector2(float(at[0]), float(at[1])).length()
				assert_true(reach >= 0.6 and reach <= 2.2, "prop stands beside the reward")
		assert_eq(found, expected.size())


func test_nothing_is_built_while_the_switch_is_off() -> void:
	var node := Node3D.new()
	var block := {"cache_dressing_1113": {"enabled": true, "props": [
		{"model": "res://assets/props/quaternius_fantasy/Barrel.gltf", "height_m": 0.8, "at": [1.0, 0.0]}]}}
	assert_true(DRESSING.build(node, block) == null)
	assert_eq(node.get_child_count(), 0)
	node.free()


func test_a_prop_stands_on_its_offset_at_the_stated_height() -> void:
	var prop: Node3D = DRESSING._prop(
			{"model": "res://assets/props/quaternius_fantasy/Barrel.gltf", "height_m": 0.8, "at": [1.0, -0.5]})
	assert_true(prop != null)
	assert_true(prop.position.is_equal_approx(Vector3(1.0, 0.0, -0.5)))
	var bounds: AABB = DRESSING._bounds(prop.get_child(0) as Node3D)
	assert_true(absf(bounds.size.y - 0.8) < 0.01)
	assert_true(absf(bounds.position.y) < 0.01)
	prop.free()
