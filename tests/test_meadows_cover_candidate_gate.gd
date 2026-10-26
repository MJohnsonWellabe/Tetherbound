extends "res://tests/test_case.gd"

## F38 L4 / P2-005 (close-1024): the Meshy ground-cover tiers and the blade
## carpet ship OFF until the GPU pass judges them, and every cover tier names a
## mesh that is installed, so turning the flag on is config only.

const CONFIG := "res://data/config/grass_field.json"


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


func test_candidates_ship_off() -> void:
	var cfg := _config()
	assert_false(bool((cfg.get("cover_candidate", {}) as Dictionary).get("enabled", true)), "cover candidate OFF until judged")
	assert_false(bool((cfg.get("carpet_candidate", {}) as Dictionary).get("enabled", true)), "carpet candidate OFF")


func test_every_cover_tier_mesh_is_installed() -> void:
	var tiers: Array = (_config().get("cover_candidate", {}) as Dictionary).get("tiers", [])
	assert_true(tiers.size() >= 10, "ten Meshy cover tiers")
	for tier: Variant in tiers:
		var path := str((tier as Dictionary).get("mesh_path", ""))
		assert_true(ResourceLoader.exists(path), "installed: " + path)
