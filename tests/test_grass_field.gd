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


## The flag is an OWNER decision. What is pinned is that the flag and the
## suppression list always agree about which system owns the ground.
##
## This test previously asserted the field ships OFF, and that was right while
## the question was open. No container in this project can measure GPU cost --
## `PERF-ROG-GPU` records that the Compatibility renderer counts MultiMesh
## batches rather than instances and that this box rasterises in software -- so
## "it looked fine here" was never evidence about the only hardware that
## matters, and the flag was reserved for the owner.
##
## The owner turned it on for handheld evaluation on 2026-08-27. That is the
## decision the old assertion existed to reserve, so continuing to pin the flag
## to one value would now block the owner rather than a lane. Reverting is still
## a one-word edit, which is the safety story the flag was built for.
##
## What no frame catches, and what is still guarded here, is the flag and the
## suppression list DISAGREEING. Either system alone dresses the ground; both at
## once is z-fighting at every blade, and neither at all is a bare meadow. So
## the flag may be either value and the suppression must follow it.
func test_the_flag_and_the_suppression_list_agree() -> void:
	var names: Array = FIELD.config().get("suppress_scatter_layers", [])
	var suppressed: Dictionary = FIELD.suppressed_layers()
	if FIELD.is_enabled():
		for entry: Variant in names:
			assert_true(suppressed.has(str(entry)),
				"the field is ON but '%s' is not suppressed -- the scatter carpet " % str(entry) +
				"and the shader carpet would both dress the same ground")
		assert_eq(suppressed.size(), names.size(),
			"the field is ON and suppressed_layers() does not match " +
			"suppress_scatter_layers exactly")
	else:
		# Off means ABSENT, not cheap. A disabled field that still suppressed
		# layers would leave the meadow barer than either system alone.
		assert_true(suppressed.is_empty(),
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


## FAR COVER. The cheap tier beyond the ring, and the two things about it that a
## frame cannot catch.
##
## The first is the grid step. `far_cell` has to be a whole multiple of `snap`,
## because the node hops in `snap` and the sheet is offset back onto its own
## fixed world grid by the difference -- a step that did not divide would leave
## the sheet resampling different ground at every hop, and the far meadow would
## swim exactly the way the whole STABLE RING work exists to stop. That defect
## is invisible in a still frame and obvious in motion, which is the worst
## combination this project has: it is how `the grass rerenders like every step`
## survived to an owner playtest.
##
## The second is the OVERLAP. The tier exists to hide the line at `field_radius`,
## and it only does that if it is already coming up before the grass has gone.
## A sheet that started at 72m would put a fresh seam exactly where the old one
## was and every capture would still look like a hand-over, so the relationship
## between the two rings is pinned here rather than left to whoever next tunes a
## number.
func test_the_far_sheet_grid_divides_the_ring_snap() -> void:
	var cfg := FIELD.config()
	var far: Dictionary = cfg.get("far_cover", {})
	if not bool(far.get("enabled", false)):
		return
	var snap := float(cfg.get("snap", 2.0))
	var cell := FIELD.far_lattice_cell(cfg)
	assert_true(cell >= snap,
		"far_cover.far_cell (%.2f) is finer than the ring's own snap (%.2f); " % [cell, snap] +
		"the sheet cannot keep a fixed world grid inside a cell the ring moves in")
	assert_true(absf(cell / snap - round(cell / snap)) < 0.001,
		"far_cover.far_cell (%.2f) is not a whole multiple of snap (%.2f). " % [cell, snap] +
		"The node hops in whole snap steps and the sheet is offset back onto its own " +
		"grid by the difference; a step that does not divide leaves it sampling " +
		"different ground every hop, and the far ground swims as you walk.")


func test_the_far_sheet_overlaps_the_ring_it_is_hiding() -> void:
	var cfg := FIELD.config()
	var far: Dictionary = cfg.get("far_cover", {})
	if not bool(far.get("enabled", false)):
		return
	var fade_start := float(cfg.get("fade_start", 42.0))
	var field_radius := float(cfg.get("field_radius", 72.0))
	var in_start := float(far.get("fade_in_start", 52.0))
	var in_end := float(far.get("fade_in_end", 84.0))
	var out_start := float(far.get("fade_out_start", 320.0))
	var far_radius := float(far.get("far_radius", 640.0))

	assert_true(in_start < field_radius,
		"far_cover starts at %.0fm and the grass ring ends at %.0fm, so the sheet " % [in_start, field_radius] +
		"arrives after the blades have gone. That is the original hard line with a " +
		"second one behind it, which is the one outcome this tier must not produce.")
	assert_true(in_start > fade_start,
		"far_cover starts at %.0fm, inside the grass ring's %.0fm fade start -- it " % [in_start, fade_start] +
		"would be washing ground the near field still covers densely, which changes " +
		"the look of grass the owner asked to leave alone")
	assert_true(in_end > in_start and out_start > in_end and far_radius > out_start,
		"far_cover's radii are not in order (in %.0f-%.0f, out %.0f-%.0f)" % [
			in_start, in_end, out_start, far_radius])
	# Do not trade one hard line for two. The far edge has no grass to hide
	# behind, so the only thing making it invisible is how slowly it happens.
	assert_true(far_radius - out_start > (in_end - in_start) * 2.0,
		"far_cover fades OUT over %.0fm and IN over %.0fm. The outer edge has no " % [
			far_radius - out_start, in_end - in_start] +
		"other tier to hand over to, only its own slowness and the haze; a fade-out " +
		"no wider than the fade-in is a second readable line at the far end.")


## Same rule as the grass tier's own forbidden ground, and it bites harder here:
## the sheet is a colour wash over whole hillsides, so a wash that covered the
## routes would erase the lines the chapter is navigated by at exactly the
## distance a player is using them to navigate.
func test_the_far_sheet_refuses_the_paths() -> void:
	var cfg := FIELD.config()
	var far: Dictionary = cfg.get("far_cover", {})
	if not bool(far.get("enabled", false)):
		return
	var forbidden: Array = far.get("forbidden_ground", cfg.get("forbidden_ground", []))
	assert_true("path" in forbidden,
		"the far cover sheet does not refuse 'path'. It is a colour wash over the " +
		"ground; over the routes it erases the chapter's wayfinding at distance.")


## The far shader is a real file and carries every uniform `grass_field.gd` sets
## on it by name. Same reasoning as the grass tier's own version of this test: a
## rename sets nothing, fails silently, and the tier renders wrong rather than
## not at all.
func test_the_far_shader_exists_and_carries_its_uniforms() -> void:
	assert_true(ResourceLoader.exists(FIELD.FAR_SHADER_PATH),
		"the far cover shader is missing at %s" % FIELD.FAR_SHADER_PATH)
	var shader: Shader = load(FIELD.FAR_SHADER_PATH) as Shader
	assert_true(shader != null, "%s did not load as a Shader" % FIELD.FAR_SHADER_PATH)
	for uniform: String in [
		"_region_map", "_region_size", "_region_texel_size", "_region_map_size",
		"_vertex_density", "field_centre", "far_cell", "fade_in_start",
		"fade_in_end", "fade_out_start", "far_radius", "strength", "lift",
		"tint_base", "tint_tip", "ground_blend", "drift_scale", "drift_contrast",
		"mottle_scale", "mottle_strength", "forbidden_base_mask",
		"built", "built_count", "built_bounds",
	]:
		assert_true(shader.code.contains("uniform") and shader.code.contains(uniform),
			"the far cover shader has no uniform named '%s', but grass_field.gd sets it" % uniform)


## The far tier must not be reachable by adding blades. The whole point is that
## it is cheap BECAUSE it is not geometry, and the way that guarantee would be
## lost is somebody deciding the sheet looks better with a few tufts on it.
## `field_radius` is the only number that puts blades on the ground, so pin it
## against the value the owner refused to raise again.
func test_the_far_tier_did_not_grow_the_expensive_one() -> void:
	var cfg := FIELD.config()
	assert_true(float(cfg.get("field_radius", 0.0)) <= 72.0,
		"field_radius is %.0fm. The blade ring is the most expensive tier in the " % float(cfg.get("field_radius", 0.0)) +
		"game and _comment_ring records its last increase as a 43%% vertex rise, " +
		"unmeasured on the device. The far tier exists so this number does not " +
		"have to move; growing it defeats the whole change.")
	assert_true(int(cfg.get("tuft_count", 0)) <= 300000,
		"tuft_count is %d. Same reasoning as field_radius above." % int(cfg.get("tuft_count", 0)))
