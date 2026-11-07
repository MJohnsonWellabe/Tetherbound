extends "res://tests/test_case.gd"

## F41#9 (LANE-SW, 7 Nov 2026): the Blender storm-glass, crown and glowmoss
## harvest nodes. They ship OFF until judged, load with their named material
## surfaces and carry no collider; hero2_for only returns them when ON.

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


func test_nodes_ship_off_and_hero2_stays_empty() -> void:
	var lane := _lane()
	assert_false(lane.is_empty(), "lane_sw_1107 is declared")
	assert_false(bool(lane.get("enabled", true)), "lane_sw_1107 ships OFF until judged")
	for item: String in SURFACES:
		assert_true(RUNTIME.hero2_for(item).is_empty(), "%s: no hero while OFF" % item)


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
