extends "res://tests/test_case.gd"

## F41#1 (LANE-BELOW6, 11 Nov 2026): the Blender heartwood on the hollow's axis
## is declared OFF until GPU-judged, its model carries named bark, vein and core
## surfaces, and above the floor flare it stays inside the 18 m deck opening
## (clear of the ascent ramp at r 22-30 m). With the flag on, the tree gains one
## static body on the axis, on simulation shells too; with it off, none.

const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const STORMHEART := preload("res://scripts/world/stormheart_tree.gd")


func _cfg() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	return (parsed as Dictionary).get("heartwood_1111", {}) if parsed is Dictionary else {}


func test_heartwood_declared_off_until_judged() -> void:
	var cfg := _cfg()
	assert_false(cfg.is_empty(), "heartwood_1111 must be declared")
	assert_false(bool(cfg.get("enabled", true)), "heartwood_1111 ships OFF until GPU-judged")
	assert_true(str(cfg.get("scope", "")).begins_with("shared_world"), "the axis body is shared world state")


func test_heartwood_model_surfaces_and_clearances() -> void:
	var model := HERO_PROP.load_model(str(_cfg().get("model", "")))
	assert_true(model != null, "heartwood model loads")
	if model == null:
		return
	var names: Array[String] = []
	var max_r_above := 0.0
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var material := visual.mesh.surface_get_material(surface)
			names.append(material.resource_name if material != null else "")
			var arrays := visual.mesh.surface_get_arrays(surface)
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var w := visual.transform * v
				if w.y > 4.5:
					max_r_above = maxf(max_r_above, Vector2(w.x, w.z).length())
	for wanted in ["heartwood_bark", "heartwood_vein", "heartwood_core"]:
		assert_true(names.has(wanted), "surface %s present" % wanted)
	assert_eq(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "the model itself carries no collider")
	assert_true(max_r_above <= 16.0, "above 4.5 m everything stays inside the 18 m deck opening (max r %.2f)" % max_r_above)
	model.free()


func test_axis_body_follows_the_flag() -> void:
	var tree := STORMHEART.new()
	tree.simulation_only = true
	tree.build()
	var expected := 1 if bool(_cfg().get("enabled", false)) else 0
	assert_eq(tree.find_children("HeartwoodBody", "StaticBody3D", true, false).size(), expected,
		"the axis body exists exactly when heartwood_1111 is on")
	tree.free()
