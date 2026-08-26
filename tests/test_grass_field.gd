extends "res://tests/test_case.gd"

## GRASS-FIELD. What the flag promises, pinned.
##
##   godot --headless --path . --script tests/run_tests.gd -- --only=grass_field
##
## The change this guards is not the shader -- a shader defect shows up in a
## frame and a blind critic catches it. What no frame catches is the FLAG going
## wrong: the field shipping on by default before a handheld pass has approved
## it, or the suppression list drifting away from the layers the field actually
## replaces so the two systems both dress the same ground, or a layer that must
## stay scatter quietly ending up on the suppression list.
##
## That last one is the one worth being strict about. The field is the right
## instrument for what the player walks THROUGH and the wrong one for what they
## walk INTO: trees, rocks and bushes carry collision and harvest points and are
## the landmarks the eye navigates by. Suppressing one of those would delete a
## collider, not a decoration.

const FIELD := preload("res://scripts/world/grass_field.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

## Layers that must never be suppressed, and why each: everything here either
## collides, is harvestable, or is a landmark. Read off `vegetation.json` rather
## than typed, so a layer that GAINS collision later is covered without anyone
## remembering to come back here.
func _must_stay_scatter() -> Array[String]:
	var out: Array[String] = []
	var layers: Dictionary = RULES.config().get("layers", {})
	for name: String in layers.keys():
		var layer: Dictionary = layers[name]
		if bool(layer.get("collides", false)) or str(layer.get("harvest_item", "")) != "":
			out.append(name)
	return out


## The default is OFF, and it stays off until a real ROG Ally says otherwise.
##
## This is the whole safety story for the change and it is a one-word edit to
## break. No container in this project can measure GPU cost -- `PERF-ROG-GPU`
## records that the Compatibility renderer counts MultiMesh batches rather than
## instances and that this box rasterises in software -- so "it looked fine
## here" is not evidence about the only hardware that matters.
func test_the_field_ships_off_until_a_handheld_pass_says_otherwise() -> void:
	assert_false(FIELD.is_enabled(),
		"data/config/grass_field.json has `enabled` true. The grass field replaces " +
		"the ground plane with a shader carpet whose cost cannot be measured in " +
		"this container at all (PERF-ROG-GPU). It ships off until an ROG Ally " +
		"pass says it is affordable; turning it on is an owner decision, not a " +
		"lane's.")


## Off means ABSENT, not cheap. A disabled field that still built a 170,000
## instance MultiMesh and skipped drawing it would be the worst of both.
func test_disabled_means_no_layers_are_suppressed() -> void:
	assert_true(FIELD.suppressed_layers().is_empty(),
		"the field is disabled but suppressed_layers() is non-empty -- vegetation.gd " +
		"would drop ground cover that nothing replaces, leaving the meadow barer " +
		"than either system alone")


## Every name on the suppression list has to be a layer that actually exists.
## A typo here is silent: `by_layer.erase("gras")` does nothing, the layer keeps
## building, and the two systems double up on the same ground.
func test_every_suppressed_layer_name_is_a_real_layer() -> void:
	var layers: Dictionary = RULES.config().get("layers", {})
	var names: Array = FIELD.config().get("suppress_scatter_layers", [])
	assert_true(names.size() > 0,
		"grass_field.json names no layers to suppress; with the field on, the " +
		"scatter carpet and the shader carpet would both dress the same ground")
	for entry: Variant in names:
		assert_true(layers.has(str(entry)),
			"grass_field.json suppresses '%s', which is not a layer in vegetation.json -- " % str(entry) +
			"the erase would silently do nothing and both systems would draw")


## The rule that matters: nothing you collide with or harvest may be replaced by
## a shader carpet.
func test_no_colliding_or_harvestable_layer_is_ever_suppressed() -> void:
	var protected := _must_stay_scatter()
	assert_true(protected.size() > 0,
		"no layer in vegetation.json collides or is harvestable, which cannot be " +
		"right -- this test would pass vacuously")
	var names: Array = FIELD.config().get("suppress_scatter_layers", [])
	for entry: Variant in names:
		assert_false(str(entry) in protected,
			"grass_field.json suppresses '%s', which collides or is harvestable. " % str(entry) +
			"The field is ground cover you walk through; replacing a layer you " +
			"walk into or chop would delete a collider and a harvest point, not " +
			"a decoration.")


## The shader is a real file and the config points at something loadable. Cheap,
## and it catches a rename that would otherwise only show up as an untextured
## field in a capture nobody runs.
func test_the_shader_exists_and_compiles_into_a_material() -> void:
	assert_true(ResourceLoader.exists(FIELD.SHADER_PATH),
		"the grass field's shader is missing at %s" % FIELD.SHADER_PATH)
	var shader: Shader = load(FIELD.SHADER_PATH) as Shader
	assert_true(shader != null, "%s did not load as a Shader" % FIELD.SHADER_PATH)
	var material := ShaderMaterial.new()
	material.shader = shader
	# The uniforms the field binds by name. A rename in the shader that is not
	# mirrored in grass_field.gd sets nothing and fails silently -- the field
	# renders, flat, at y=0, which reads as "the terrain lookup is broken".
	for uniform: String in [
		"_region_map", "_region_size", "_region_texel_size", "_region_map_size",
		"_vertex_density", "field_centre", "field_radius", "fade_start",
		"forbidden_base_mask", "wind_time",
	]:
		assert_true(material.get_shader_parameter(uniform) != null
				or shader.code.contains("uniform") and shader.code.contains(uniform),
			"the shader has no uniform named '%s', but grass_field.gd sets it" % uniform)


## The ground the field refuses is named, not numbered, and the names have to
## resolve against the terrain's own texture list -- whose ORDER is what assigns
## the ids. A lane reordering that list must not silently move the mask onto the
## wrong surface.
func test_forbidden_ground_names_resolve_against_the_terrain_textures() -> void:
	var file := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	assert_true(file != null, "terrain_playground.json is missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var names: Array = []
	for entry: Variant in (parsed as Dictionary).get("textures", []):
		names.append(str((entry as Dictionary).get("name", "")))
	for entry: Variant in FIELD.config().get("forbidden_ground", []):
		assert_true(str(entry) in names,
			"grass_field.json forbids ground named '%s', which is not in " % str(entry) +
			"terrain_playground.json's texture list (%s) -- the mask would be " % ", ".join(names) +
			"built with that bit unset and grass would grow on it")
	assert_true("path" in FIELD.config().get("forbidden_ground", []),
		"'path' is no longer forbidden ground. The routes are the chapter's " +
		"wayfinding; grass growing over them is not a cosmetic regression.")
