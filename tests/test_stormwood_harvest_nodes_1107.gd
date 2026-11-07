extends "res://tests/test_case.gd"

## F41#9 (LANE-SW, 7 Nov 2026): the Blender storm-glass, crown and glowmoss
## harvest nodes. They ship ON (CPU 5.64 -> 6.31), load with their named
## material surfaces and carry no collider; hero2_for returns them only when ON.

const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const HERO2 := "res://data/config/stormwood_harvest_hero2.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const SURFACES := {
	"stormglass": ["storm_glass", "storm_copper", "storm_basalt"],
	"stormglass_crown": ["storm_glass", "storm_copper", "storm_basalt"],
	"glowmoss": ["glow_moss", "glow_cap"],
}


func _lane() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HERO2))
	return (parsed as Dictionary).get("lane_sw_1107", {}) if parsed is Dictionary else {}


func test_nodes_ship_on_with_score_and_hero2_returns_them() -> void:
	var lane := _lane()
	assert_false(lane.is_empty(), "lane_sw_1107 is declared")
	assert_true(bool(lane.get("enabled", false)), "lane_sw_1107 ships ON (judged gain)")
	assert_true(str(lane.get("_why_on", "")).contains("5.64 -> 6.31"), "records its judged score")
	for item: String in SURFACES:
		var hero := RUNTIME.hero2_for(item)
		assert_false(hero.is_empty(), "%s: hero while ON" % item)
		var model := str((hero.get("models", [{}]) as Array)[0].get("model", ""))
		assert_true(model.ends_with("_r3.glb") if item == "glowmoss" else model.ends_with("_r2.glb"), "%s uses its latest shipped Blender node (%s)" % [item, model])
	var r2: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(HERO2)) as Dictionary).get("lane_sw_1107_r2", {})
	assert_true(bool(r2.get("enabled", false)), "lane_sw_1107_r2 ships ON (judged gain)")
	assert_true(str(r2.get("_why_on", "")).contains("5.52 -> 6.00"), "r2 records its judged score")
	var r3: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(HERO2)) as Dictionary).get("lane_sw_1107_r3", {})
	assert_true(bool(r3.get("enabled", false)), "lane_sw_1107_r3 ships ON (judged gain)")
	assert_true(str(r3.get("_why_on", "")).contains("4.98 -> 5.65"), "r3 records its judged score")


func test_node_models_load_with_named_surfaces_and_no_collider() -> void:
	var items: Dictionary = _lane().get("items", {})
	for item: String in SURFACES:
		var entry: Dictionary = ((items.get(item, {}) as Dictionary).get("models", [{}]) as Array)[0]
		var model := HERO_PROP.load_model(str(entry.get("model", "")))
		assert_true(model != null, "%s model loads" % item)
		if model == null:
			continue
		var names: Array[String] = []
		for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for surface in visual.mesh.get_surface_count():
				var material := visual.mesh.surface_get_material(surface)
				names.append(material.resource_name if material != null else "")
		for wanted: String in SURFACES[item]:
			assert_true(names.has(wanted), "%s carries %s" % [item, wanted])
		assert_eq(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "%s: no collider" % item)
		model.free()
