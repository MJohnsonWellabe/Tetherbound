extends "res://tests/test_case.gd"

## F38#20 (LANE-SW, 7 Nov 2026): the Blender hill the keep crowns and its curtain
## wall (both ON, CPU 6.38 -> 6.78). Each is placed through the hero-gatehouse
## companion loader only when its flag is ON,
## and it never rises into the hall's footprint or in front of the gate mouth.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const CONFIG := "res://data/config/stronghold.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func _has_hill(gatehouse: Dictionary) -> bool:
	for companion: Variant in gatehouse.get("companions", []):
		if companion is Dictionary and str((companion as Dictionary).get("id", "")) == "keep_hill":
			return true
	return false


func test_keep_hill_ships_on_with_score_and_joins_only_when_on() -> void:
	var cfg := _cfg()
	var hill: Dictionary = cfg.get("keep_hill_1107", {})
	assert_false(hill.is_empty(), "keep_hill_1107 is declared")
	assert_true(bool(hill.get("enabled", false)), "keep_hill_1107 ships ON (judged gain)")
	assert_true(str(hill.get("_why_on", "")).contains("6.38 -> 6.78"), "records its judged score")
	assert_true(_has_hill(STRONGHOLD.p2_003_gatehouse(cfg)), "ON: the hill joins the keep's companions")
	hill.enabled = false
	assert_false(_has_hill(STRONGHOLD.p2_003_gatehouse(cfg)), "OFF: no hill companion")
	hill.enabled = true
	assert_true(_has_hill(STRONGHOLD.p2_003_gatehouse(cfg)), "ON: the hill joins the keep's companions")


func test_keep_walls_ship_on_with_score_and_join_when_on() -> void:
	var cfg := _cfg()
	var walls: Dictionary = cfg.get("keep_walls_1107", {})
	assert_false(walls.is_empty(), "keep_walls_1107 is declared")
	assert_true(bool(walls.get("enabled", false)), "keep_walls_1107 ships ON (judged gain)")
	assert_true(str(walls.get("_why_on", "")).contains("6.38 -> 6.78"), "records its judged score")
	walls.enabled = true
	var found := false
	for companion: Variant in STRONGHOLD.p2_003_gatehouse(cfg).get("companions", []):
		if companion is Dictionary and str((companion as Dictionary).get("id", "")) == "keep_walls":
			found = true
	assert_true(found, "ON: the walls join the keep's companions")


func test_keep_hill_stays_under_the_hall_floor_in_its_footprint() -> void:
	_check_footprint("keep_hill_1107")


func test_keep_walls_stay_out_of_the_hall_footprint() -> void:
	_check_footprint("keep_walls_1107")


func _check_footprint(key: String) -> void:
	var companion: Dictionary = (_cfg().get(key, {}) as Dictionary).get("companion", {})
	var scene := load(str(companion.get("path", ""))) as PackedScene
	assert_true(scene != null, "hill model loads")
	if scene == null:
		return
	var model := scene.instantiate() as Node3D
	var bounds := RENDER_BOUNDS.measure(model)
	assert_almost_eq(bounds.size.x, float(companion.get("width_m", 0.0)), 1.0, "width_m equals the mesh width (scale 1)")
	var offset: Array = companion.get("offset", [])
	var sink := -float(offset[1])
	var centre := bounds.get_center()
	assert_eq(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "presentation only: no collider")
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			for v: Vector3 in visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var w := visual.transform * v
				# stronghold-local: x from the bbox centre, z from the gate mouth, y from the hall floor
				var x := w.x - centre.x + float(offset[0])
				var z := w.z - centre.z + float(offset[2])
				var y := w.y - bounds.position.y - sink
				if absf(x) < 70.0 and z < 125.0:
					assert_true(y <= -2.5, "hall footprint stays under the floor (x %.0f z %.0f y %.1f)" % [x, z, y])
					if y > -2.5:
						model.free()
						return
	model.free()
