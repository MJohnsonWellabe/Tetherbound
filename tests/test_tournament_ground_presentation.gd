extends "res://tests/test_case.gd"

## Focused contract for the visual-only Practice Meadow hierarchy. The large
## relic circle remains where the owner asked for it; this pins the tournament
## layer that differentiates the field without changing its gameplay surface.

const CONFIG_PATH := "res://data/config/tournament_ground_presentation.json"
const SCRIPT_PATH := "res://scripts/world/tournament_ground_presentation.gd"
const TOURNAMENT_PATH := "res://scripts/world/tournament.gd"


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	assert_true(file != null, "presentation config remains installed")
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func test_training_ground_has_one_primary_canopy_and_a_readable_lists_ring() -> void:
	var cfg := _config()
	var arena := cfg.get("arena", {}) as Dictionary
	var canopy := cfg.get("marshal_canopy", {}) as Dictionary
	assert_eq(_point(arena.get("centre", []) as Array), Vector2(20.0, 10.0),
		"the marking follows the existing tournament fight centre")
	assert_true(float(arena.get("radius_m", 0.0)) >= 6.0,
		"the lists read at field scale")
	assert_true(int(arena.get("segments", 0)) >= 24,
		"the lists ring reads continuously rather than as loose stones")
	assert_true(float(canopy.get("height_m", 0.0)) > 4.0,
		"the singular timber canopy outranks the four-metre shrine silhouettes")
	assert_true(float(canopy.get("width_m", 0.0)) > float(canopy.get("depth_m", INF)),
		"the canopy keeps a broad event silhouette instead of cloning an arch")


func test_equipment_is_asymmetric_installed_and_outside_the_fight_floor() -> void:
	var cfg := _config()
	var arena := cfg.get("arena", {}) as Dictionary
	var centre := _point(arena.get("centre", []) as Array)
	var radius := float(arena.get("radius_m", 0.0))
	var names := {}
	for raw: Variant in cfg.get("equipment", []):
		var prop := raw as Dictionary
		var name := str(prop.get("name", ""))
		assert_false(names.has(name), "%s is a unique training silhouette" % name)
		names[name] = true
		var at := _point(prop.get("at", []) as Array)
		assert_true(at.distance_to(centre) > radius + 0.5,
			"%s remains outside the marked fight floor" % name)
		var asset := "%s/%s.gltf" % [str(prop.get("dir", "")), str(prop.get("model", ""))]
		assert_true(ResourceLoader.exists(asset), "%s uses an installed asset" % name)
	assert_eq(names.size(), 3, "the equipment reads as one varied practice group")


func test_presentation_is_visual_only_and_mounted_by_the_existing_tournament() -> void:
	var cfg := _config()
	assert_true(load(SCRIPT_PATH) is Script, "presentation script parses as a production resource")
	assert_true(load(TOURNAMENT_PATH) is Script, "the mounted tournament script still parses")
	assert_false(bool(cfg.get("collision_enabled", true)),
		"the presentation contract explicitly forbids new collision")
	var source := _source(SCRIPT_PATH)
	assert_false(source.contains("StaticBody3D.new()"), "presentation creates no static body")
	assert_false(source.contains("CollisionShape3D.new()"), "presentation creates no collision shape")
	assert_false(source.contains("Area3D.new()"), "presentation creates no interaction area")
	assert_false(source.contains("INTERACTABLE.new()"), "presentation creates no prompt")
	var tournament_source := _source(TOURNAMENT_PATH)
	assert_true(tournament_source.contains("GROUND_PRESENTATION"),
		"the production tournament mounts the hierarchy")
	assert_true(tournament_source.contains("_build_board()"),
		"the existing bracket board remains built")
