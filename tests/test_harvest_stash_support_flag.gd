extends "res://tests/test_case.gd"

## F38#12 candidate: the band-3 stashed tonic on a crate. The switch file is
## OFF until a GPU verdict, and only that one node carries the block.


func test_switch_is_off() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/harvest_stash_support.json"))
	assert_false(bool(cfg.get("enabled", true)))


func test_only_the_stashed_tonic_carries_the_block() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/bands/band3_the_river_lock/harvest.json"))
	var found := 0
	for node: Variant in cfg.get("nodes", []):
		var visual: Variant = (node as Dictionary).get("visual", {})
		if visual is Dictionary and (visual as Dictionary).has("stash_support_1113"):
			found += 1
			assert_eq(str((node as Dictionary).get("item", "")), "attack_tonic")
			var stash: Dictionary = (visual as Dictionary).stash_support_1113
			assert_true(ResourceLoader.exists(str(stash.get("model", ""))), "the support prop is installed")
			assert_true(float(stash.get("reward_height_m", 0.0)) > 0.4)
	assert_eq(found, 1)
