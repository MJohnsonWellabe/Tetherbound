extends "res://tests/test_case.gd"

## F39#4 shiny remake textures (creatures_visual.json `shiny_remake_textures`,
## creature_visual.gd shiny_remake_texture, creature_body.gd _texture_for).
## OFF: the shiny lookup is unchanged. ON: each live remake albedo resolves to
## its own secondary-region repaint and each glow map to itself.

const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const KEY := "shiny_remake_textures"

var _saved: Variant = null


func before_each() -> void:
	_saved = (VISUAL.config().get(KEY, {}) as Dictionary).duplicate(true)


func after_each() -> void:
	VISUAL.config()[KEY] = _saved


func _map() -> Dictionary:
	return (VISUAL.config().get(KEY, {}) as Dictionary).get("map", {})


func test_every_mapped_texture_exists_and_glow_maps_keep_themselves() -> void:
	var map := _map()
	assert_true(map.size() >= 6, "three albedos and three glow maps are mapped")
	for from: String in map:
		assert_true(ResourceLoader.exists(from), "%s exists" % from)
		assert_true(ResourceLoader.exists(str(map[from])), "%s exists" % map[from])
		if from.ends_with("_arc_emission.png"):
			assert_eq(str(map[from]), from, "the glow map keeps itself, so only the glow lines glow")
		else:
			assert_true(str(map[from]).ends_with("_shiny_plates.png"), "%s maps to its repaint" % from)


func test_off_leaves_the_shiny_lookup_unchanged() -> void:
	var cfg: Dictionary = VISUAL.config()[KEY]
	cfg["enabled"] = false
	for from: String in _map():
		assert_eq(VISUAL.shiny_remake_texture(from), "", "OFF maps nothing (%s)" % from.get_file())
		var tex := load(from) as Texture2D
		var got: Texture2D = BODY._texture_for(tex, "aquaryn", "shiny")
		if got != null:
			assert_false(got.resource_path.ends_with("_shiny_plates.png"), "OFF never reaches a repaint")


func test_on_maps_each_albedo_to_its_repaint_and_only_for_shiny() -> void:
	var cfg: Dictionary = VISUAL.config()[KEY]
	cfg["enabled"] = true
	for from: String in _map():
		var tex := load(from) as Texture2D
		var got: Texture2D = BODY._texture_for(tex, "aquaryn", "shiny")
		assert_true(got != null, "ON resolves %s" % from.get_file())
		if got != null:
			assert_eq(got.resource_path, str(_map()[from]), "ON: %s -> its mapped texture" % from.get_file())
		var vivid: Texture2D = BODY._texture_for(tex, "aquaryn", "vivid")
		if vivid != null:
			assert_false(vivid.resource_path.ends_with("_shiny_plates.png"), "the vivid lookup never takes a shiny repaint")


func _model_wearing(albedo_path: String) -> Node3D:
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(albedo_path) as Texture2D
	mesh.mesh.surface_set_material(0, material)
	root.add_child(mesh)
	return root


func test_the_shiny_finish_stands_down_only_for_a_worn_repaint() -> void:
	const FINISH := preload("res://scripts/creatures/creature_surface_finish.gd")
	var repaint := ""
	for from: String in _map():
		if str(_map()[from]).ends_with("_shiny_plates.png") and from.contains("aquaryn"):
			repaint = str(_map()[from])
	assert_true(repaint != "", "the Aquaryn repaint is mapped")
	var cfg: Dictionary = VISUAL.config()[KEY]
	cfg["enabled"] = true
	var on := _model_wearing(repaint)
	FINISH.apply(on, "aquaryn", true)
	var on_mesh := on.get_child(0) as MeshInstance3D
	assert_eq(on_mesh.get_surface_override_material(0), null, "ON: the hue-shift finish leaves the repaint alone")
	on.free()
	cfg["enabled"] = false
	var off := _model_wearing(repaint)
	FINISH.apply(off, "aquaryn", true)
	var off_mesh := off.get_child(0) as MeshInstance3D
	assert_true(off_mesh.get_surface_override_material(0) != null, "OFF: the shiny finish applies as before")
	off.free()


func test_the_map_ships_on_with_its_score() -> void:
	var cfg: Dictionary = _saved
	assert_true(bool(cfg.get("enabled", false)), "shiny_remake_textures ships ON (judged gain)")
	assert_true(str(cfg.get("_why_on", "")).contains("6.76"), "it records its mapped score")
