extends "res://tests/test_case.gd"

## F41#1 (LANE-SW, 7 Nov 2026): the Blender root vault under the OuterWorks deck
## is declared, presentation-only, and its model loads with named bark and vein
## surfaces. It ships ON with its judged score (CPU 4.75 -> 5.24).

const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")


func _cfg() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	return (parsed as Dictionary).get("root_vault_1107", {}) if parsed is Dictionary else {}


func test_root_vault_declared_on_with_score_and_presentation_only() -> void:
	var cfg := _cfg()
	assert_false(cfg.is_empty(), "root_vault_1107 must be declared")
	assert_true(bool(cfg.get("enabled", false)), "root_vault_1107 ships ON (judged gain)")
	assert_true(str(cfg.get("_why_on", "")).contains("4.75 -> 5.24"), "records its judged score")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")


func test_root_vault_model_has_bark_and_vein_surfaces_and_no_collider() -> void:
	var model := HERO_PROP.load_model(str(_cfg().get("model", "")))
	assert_true(model != null, "vault model loads")
	if model == null:
		return
	var names: Array[String] = []
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var material := visual.mesh.surface_get_material(surface)
			names.append(material.resource_name if material != null else "")
	assert_true(names.has("vault_bark"), "bark surfaces named vault_bark")
	assert_true(names.has("vault_vein"), "vein surfaces named vault_vein")
	assert_eq(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "presentation only: no collider")
	var bounds := HERO_PROP.BOUNDS.measure(model)
	assert_true(bounds.end.y <= 6.0, "the vault stays under the 6 m OuterWorks slab")
	assert_true(bounds.position.y >= -0.15, "wall flares rest on the floor (sunk at most 0.15 m)")
	model.free()


## Round 2: the heart cradle (crystal core in braided roots) in the heart cleft.
func test_heart_cradle_declared_off_outside_the_hollow_floor() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	var cfg: Dictionary = (parsed as Dictionary).get("heart_cradle_1107", {})
	assert_false(cfg.is_empty(), "heart_cradle_1107 must be declared")
	assert_false(bool(cfg.get("enabled", true)), "heart_cradle_1107 ships OFF until judged")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	assert_true(model != null, "cradle model loads")
	if model == null:
		return
	var names: Array[String] = []
	var min_r := INF
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var material := visual.mesh.surface_get_material(surface)
			names.append(material.resource_name if material != null else "")
			var arrays := visual.mesh.surface_get_arrays(surface)
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var w := visual.transform * v
				min_r = minf(min_r, Vector2(w.x, w.z).length())
	for wanted in ["cradle_bark", "cradle_vein", "core_crystal"]:
		assert_true(names.has(wanted), "surface %s present" % wanted)
	assert_eq(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "presentation only: no collider")
	assert_true(min_r >= 44.0, "nothing enters the 44 m hollow floor (min r %.2f)" % min_r)
	model.free()
