extends "res://tests/test_case.gd"

## Visual lane (3 Nov 2026): the loft bed comforter retint (house_textiles.json)
## ships ON with its judged score, declares its scope, never tints a textile into the
## reserved red/oxblood range, and names surfaces the installed BedTwin really has.

const CONFIG := "res://data/config/house_textiles.json"


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


func _surface_names(model: String) -> Array[String]:
	var names: Array[String] = []
	var mesh := load("res://assets/props/quaternius_furniture/%s.obj" % model) as Mesh
	if mesh == null:
		return names
	for i in mesh.get_surface_count():
		var material := mesh.surface_get_material(i)
		var name := str(material.resource_name) if material != null else ""
		if name.is_empty() and mesh is ArrayMesh:
			name = (mesh as ArrayMesh).surface_get_name(i)
		names.append(name)
	return names


func test_ships_on_with_its_score_and_scope() -> void:
	var cfg := _config()
	assert_true(bool(cfg.get("enabled", false)), "house_textiles ships ON (judged gain)")
	assert_true(str(cfg.get("_why", "")).contains("5.92"), "house_textiles records its mapped score")
	assert_eq(str(cfg.get("scope", "")), "client_presentation", "the flag declares its scope")


func test_tints_stay_out_of_the_reserved_red_range() -> void:
	for model: String in (_config().get("models", {}) as Dictionary):
		var tints: Dictionary = _config().models[model]
		for surface: String in tints:
			var colour := Color(str(tints[surface]))
			var red_hue := colour.h < 0.06 or colour.h > 0.9
			assert_false(red_hue and colour.s > 0.25, "%s %s is not a red/oxblood tint" % [model, surface])


func test_named_surfaces_exist_on_the_installed_mesh() -> void:
	for model: String in (_config().get("models", {}) as Dictionary):
		var names := _surface_names(model)
		for surface: String in (_config().models[model] as Dictionary):
			assert_true(surface in names, "%s has a %s surface (found %s)" % [model, surface, names])
