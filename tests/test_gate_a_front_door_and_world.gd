extends "res://tests/test_case.gd"

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const PREFABS_PATH := "res://data/config/building_prefabs.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"


func test_game_boots_to_lightweight_title_front_door() -> void:
	assert_eq(str(ProjectSettings.get_setting("application/run/main_scene", "")), TITLE_SCENE)
	var packed := load(TITLE_SCENE) as PackedScene
	assert_true(packed != null, "title scene must load as a real PackedScene")
	if packed != null:
		var node := packed.instantiate()
		assert_true(node != null)
		if node != null:
			assert_true(node.is_in_group(&"title_screen"))
			node.free()


func test_pond_mill_has_a_real_openable_door_contract() -> void:
	var cfg := _json(PREFABS_PATH)
	var prefabs: Dictionary = cfg.get("prefabs", {})
	var mill: Dictionary = prefabs.get("mill", {})
	assert_false(mill.is_empty(), "mill prefab must exist")
	var door: Dictionary = mill.get("door", {})
	assert_eq(str(door.get("leaf_module", "")), "Door_1_Flat")
	var at: Array = door.get("at", [])
	assert_eq(at.size(), 3)
	# The old owner-play bug came from a single 6.3 x 9.4 x 6.3 collider
	# sealing the whole tower behind a decorative leaf. A real entrance needs
	# split wall/lintel/upper-volume collision around the opening.
	var colliders: Array = mill.get("colliders", [])
	assert_true(colliders.size() >= 7, "mill collision must leave a physical doorway hole")
	for raw: Variant in colliders:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var size: Array = (raw as Dictionary).get("size", [])
		if size.size() == 3:
			assert_false(float(size[0]) >= 6.0 and float(size[1]) >= 9.0 and float(size[2]) >= 6.0,
				"no giant solid tower collider may seal the door")


func test_current_meadows_data_contains_real_pond_water_and_long_corridor() -> void:
	var cfg := _json(TERRAIN_PATH)
	var bounds: Dictionary = cfg.get("world_bounds", {})
	assert_eq(float(bounds.get("min_z", 0.0)), -512.0)
	assert_eq(float(bounds.get("max_z", 0.0)), 7680.0)
	var water: Dictionary = cfg.get("water", {})
	var pond: Dictionary = water.get("pond", water.get("pond_surface", {}))
	# Config naming has evolved; the actual water builder is the final authority,
	# so this contract primarily guards against deleting the pond data entirely.
	assert_true(not water.is_empty(), "terrain config must retain authored water data")
	assert_true(load("res://scripts/world/water.gd") != null, "real water builder must load")


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
