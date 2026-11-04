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
