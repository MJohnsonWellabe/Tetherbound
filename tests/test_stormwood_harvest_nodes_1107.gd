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


func test_floor2_presence_ships_on_as_judged() -> void:
	# F41#9 (LANE-FLOOR2, 11 Nov 2026): larger nodes ringed by small copies of
	# themselves. G-floor2-harvest-presence-confirm, GPU High 5.81 -> 6.81, 3/3.
	var presence: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(HERO2)) as Dictionary).get("floor2_presence", {})
	assert_true(bool(presence.get("enabled", false)), "floor2_presence ships ON (judged gain)")
	assert_true(str(presence.get("_why_on", "")).contains("5.81 -> 6.81"), "records its judged score")
	var lane_models := {}
	for item: String in SURFACES:
		var row: Dictionary = RUNTIME.presence_for(item)
		assert_true(float(row.get("height_scale", 1.0)) > 1.0, "%s grows" % item)
		for key: String in row:
			assert_false(key.begins_with("light_"), "%s: no ground light ships (%s)" % [item, key])
		var satellites: Dictionary = row.get("satellites", {})
		assert_true(int(satellites.get("count", 0)) >= 5, "%s has its ring of copies" % item)
		# Keep-out: the copies ring inside the node's own footprint, never on
		# the ground a player stands on beside it.
		var of_main := float(satellites.get("ring_of_main", 0.0))
		assert_true(of_main > 0.0 and of_main <= 1.0, "%s copies stay on the node's base (%.2f)" % [item, of_main])
		var models: Array = RUNTIME.hero2_for(item).get("models", [])
		assert_eq(models.size(), 2, "%s: the node and its copies" % item)
		var copies: Dictionary = models[1]
		assert_eq(str(copies.get("model", "")), str((models[0] as Dictionary).get("model", "")), "%s copies are the node's own model" % item)
		assert_true(bool(copies.get("no_collision", false)), "%s copies carry no collider" % item)
		assert_true(float((copies.height_m as Array)[1]) < float(((models[0] as Dictionary).height_m as Array)[0]) * 0.6, "%s copies are clearly smaller" % item)
		lane_models[item] = models
	assert_eq(lane_models.size(), 3, "all three judged nodes are covered")


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
