extends "res://tests/test_case.gd"

const DUNES := preload("res://scripts/world/water_dune_cover.gd")
const VEGETATION := preload("res://scripts/world/water_vegetation.gd")
const GRASS := preload("res://scripts/world/grass_field.gd")


func test_disabled_profile_and_veilfall_preserve_original_inputs() -> void:
	var source := {"tuft_count": 54000, "cover_tiers": [{"name": "strand_bushes", "count": 2200}]}
	var settings := {"enabled": false, "ground_cover": {"tuft_count": 100},
		"layers": {"trees": {"clusters": 2}}}
	var unchanged := DUNES.ground_profile(source, settings)
	assert_eq(unchanged, source)
	unchanged.cover_tiers[0].count = 1
	assert_eq(source.cover_tiers[0].count, 2200, "even disabled outputs own their nested dictionaries")
	settings.enabled = true
	var trees := {"clusters": 16, "models": ["original"]}
	assert_eq(DUNES.layer_profile(trees, "trees", "veilfall", settings), trees)
	assert_false(DUNES.applies_to_island("veilfall", settings))


func test_enabled_copies_preserve_clearances_and_unrelated_layers() -> void:
	var settings := DUNES.config()
	settings.enabled = true
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_ground_cover.json"))
	var original := source.duplicate(true)
	var candidate := DUNES.ground_profile(source, settings)
	assert_true(candidate.tuft_count <= source.tuft_count, "colony cores stay within the source profile's requested tuft count")
	assert_true(candidate.height_near > source.height_near)
	assert_eq(candidate.anchor_clear_radius_m, source.anchor_clear_radius_m)
	assert_eq(candidate.camp_clear_radius_m, source.camp_clear_radius_m)
	assert_eq(candidate.min_ground_height, source.min_ground_height)
	assert_eq(candidate.forbidden_ground, source.forbidden_ground)
	assert_eq(candidate.cover_tiers[0].ground, source.cover_tiers[0].ground)
	assert_true(candidate.cover_tiers[0].count < source.cover_tiers[0].count)
	assert_eq(source, original, "never edit source profile or nested cover tiers")
	var rocks := {"clusters": 12, "align_to_slope": true}
	assert_eq(DUNES.layer_profile(rocks, "rocks", "first_shore", settings), rocks)
	var grass := {"models": ["broad_leaf"], "min_height_m": 1.35}
	var dune_grass := DUNES.layer_profile(grass, "groundcover", "first_shore", settings)
	assert_true(str(dune_grass.models[0]).ends_with("Grass_Wispy_Tall.gltf"))
	assert_eq(grass.models, ["broad_leaf"])
	assert_eq(dune_grass.min_height_m, grass.min_height_m)


func test_colony_and_arc_overrides_bind_only_to_the_dune_material() -> void:
	var settings := DUNES.config()
	assert_true(bool(settings.enabled), "reviewed dune cover is enabled")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_ground_cover.json"))
	var original := source.duplicate(true)
	var candidate := DUNES.ground_profile(source, settings)
	var ordinary := GRASS.new()
	var dunes := GRASS.new()
	for field in [ordinary, dunes]:
		field.configure_profile(source, ["grass", "shore", "rock"])
		field._material = ShaderMaterial.new()
		field._material.shader = load(GRASS.SHADER_PATH)
	ordinary._apply_config(source)
	dunes._apply_config(candidate)
	for key: String in ["clump_patch_start", "clump_patch_full"]:
		var ordinary_value: Variant = ordinary._material.get_shader_parameter(key)
		assert_true(ordinary_value == null or is_equal_approx(float(ordinary_value), 0.0),
			"ordinary profile keeps the disabled shader default: " + key)
		assert_almost_eq(float(dunes._material.get_shader_parameter(key)), float(candidate[key]))
	# The dummy renderer cannot report an unassigned shader uniform's default.
	# Test the absence of an override, rather than converting that null to float.
	var ordinary_arc: Variant = ordinary._material.get_shader_parameter("blade_arc_angle")
	assert_true(ordinary_arc == null or is_equal_approx(float(ordinary_arc), 1.047198),
		"ordinary grass curvature has no new material override")
	assert_almost_eq(float(dunes._material.get_shader_parameter("blade_arc_angle")), float(candidate.blade_arc_angle))
	assert_true(float(candidate.clump_patch_full) > float(candidate.clump_patch_start))
	assert_almost_eq(float(dunes._material.get_shader_parameter("clump_contrast")), 1.0,
		0.0001, "threshold gaps retain zero keep probability")
	assert_eq(source, original)
	assert_false(source.has("clump_patch_start"))
	assert_false(source.has("blade_arc_angle"))
	assert_true(bool(dunes._material.get_shader_parameter("dune_tussock")))
	assert_true(bool(dunes._material.get_shader_parameter("dune_colony_shape")))
	assert_eq(int(dunes._material.get_shader_parameter("dune_pioneer_base_mask")), 2)
	assert_eq(dunes._material.get_shader_parameter("dune_gap_offset"),
		Vector2(float(candidate.dune_gap_offset[0]), float(candidate.dune_gap_offset[1])))
	for key: String in ["dune_gap_scale", "dune_gap_warp_scale", "dune_gap_warp_m", "dune_gap_start", "dune_gap_full",
			"dune_pioneer_start", "dune_pioneer_probability", "dune_shore_probability",
			"dune_shore_dry_start_y", "dune_shore_dry_full_y", "dune_stabilized_height_y"]:
		assert_almost_eq(float(dunes._material.get_shader_parameter(key)), float(candidate[key]))
	assert_true(ordinary._material.get_shader_parameter("dune_colony_shape") in [null, false])
	assert_true(float(candidate.dune_stabilized_height_y) > float(candidate.dune_shore_dry_full_y))
	var ordinary_tussock: Variant = ordinary._material.get_shader_parameter("dune_tussock")
	assert_true(ordinary_tussock == null or ordinary_tussock == false)
	ordinary.free()
	dunes.free()


func test_rooted_tussocks_have_pointed_tips_and_stable_lod_roots() -> void:
	var field := GRASS.new()
	var near: ArrayMesh = field._tuft_mesh(5, 4, -1, true)
	var far: ArrayMesh = field._tuft_mesh(5, 2, 3, true)
	var near_arrays := near.surface_get_arrays(0)
	var near_vertices: PackedVector3Array = near_arrays[Mesh.ARRAY_VERTEX]
	var far_vertices: PackedVector3Array = far.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for blade in 5:
		var first := blade * 10
		assert_true(near_vertices[first].length() < 0.07, "roots form a compact tussock")
		assert_eq(near_vertices[first + 8], near_vertices[first + 9], "each leaf ends in one point")
		if blade < 3:
			assert_eq(far_vertices[blade * 6], near_vertices[first], "LOD preserves each root")
			assert_eq(far_vertices[blade * 6 + 4], near_vertices[first + 8], "LOD preserves each tip")
	var indices: PackedInt32Array = near_arrays[Mesh.ARRAY_INDEX]
	for triangle in indices.size() / 3:
		var a := near_vertices[indices[triangle * 3]]
		var b := near_vertices[indices[triangle * 3 + 1]]
		var c := near_vertices[indices[triangle * 3 + 2]]
		assert_true((b - a).cross(c - a).length() > 0.000001, "pointed tips retain only nondegenerate triangles")
	field.free()


func test_json_basal_indices_shorten_only_the_selected_dune_leaves() -> void:
	# Godot's JSON numbers are floats; Array.has does not match them to ints.
	var recipe: Dictionary = JSON.parse_string(
		'{"basal_blades":[0,3,6],"basal_height_scale":0.6}')
	var field := GRASS.new()
	var plain := field._tuft_mesh(8, 4, -1, true).surface_get_arrays(0)
	var shaped := field._tuft_mesh(8, 4, -1, true, recipe).surface_get_arrays(0)
	var integer_recipe := recipe.duplicate(true)
	integer_recipe.basal_blades = [0, 3, 6]
	assert_eq(shaped, field._tuft_mesh(8, 4, -1, true, integer_recipe).surface_get_arrays(0),
		"JSON and native integer recipes generate identical meshes")
	for blade in 8:
		var factor := 0.6 if blade in [0, 3, 6] else 1.0
		var first := blade * 10
		assert_almost_eq(shaped[Mesh.ARRAY_TEX_UV2][first].y,
			plain[Mesh.ARRAY_TEX_UV2][first].y * factor, 0.000001,
			"shader receives the requested leaf height")
		assert_almost_eq(shaped[Mesh.ARRAY_VERTEX][first + 8].y,
			plain[Mesh.ARRAY_VERTEX][first + 8].y * factor, 0.000001,
			"mesh tip follows the same height as the shader")
	assert_eq(field._tuft_mesh(8, 4, -1, false, recipe).surface_get_arrays(0),
		field._tuft_mesh(8, 4, -1, false).surface_get_arrays(0),
		"a dune recipe never alters ordinary grass")
	field.free()


func test_shelter_leaves_windward_ground_open_without_affecting_ordinary_layers() -> void:
	var settings := {"enabled": true}
	var sheltered := {"_dune_sheltered": true}
	assert_true(DUNES.accepts_shelter(Vector2(35, 10), Vector2.ZERO, 100.0, sheltered, settings))
	assert_false(DUNES.accepts_shelter(Vector2(-35, -10), Vector2.ZERO, 100.0, sheltered, settings))
	assert_false(DUNES.accepts_shelter(Vector2(90, 0), Vector2.ZERO, 100.0, sheltered, settings))
	assert_true(DUNES.accepts_shelter(Vector2(-35, -10), Vector2.ZERO, 100.0, {}, settings))
	assert_true(DUNES.accepts_shelter(Vector2(-35, -10), Vector2.ZERO, 100.0, sheltered, {}))


func test_ordinary_and_dune_batches_never_share_modified_imported_materials() -> void:
	var vegetation := VEGETATION.new()
	vegetation._dune_settings = DUNES.config()
	vegetation._dune_settings.enabled = true
	var source := MeshInstance3D.new()
	source.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.resource_name = "Grass"
	var original_texture := load("res://assets/environment/stylized_nature/Grass.png") as Texture2D
	material.albedo_texture = original_texture
	source.mesh.surface_set_material(0, material)
	var ordinary := vegetation._presentation_mesh(source, "grass", false)
	var dune := vegetation._presentation_mesh(source, "grass", true)
	var dune_material := dune.surface_get_material(0) as StandardMaterial3D
	assert_ne(dune_material, material)
	assert_eq(source.mesh.surface_get_material(0), material, "imported material reference is untouched")
	assert_eq(material.albedo_texture, original_texture, "source texture is never replaced")
	assert_ne(dune_material.albedo_texture, original_texture)
	assert_eq(dune_material.albedo_texture.resource_path, vegetation._dune_settings.grass_texture)
	var ordinary_material := ordinary.surface_get_material(0) as StandardMaterial3D
	assert_eq(ordinary_material.albedo_texture.resource_path, original_texture.resource_path)
	source.free()
	vegetation.free()


func test_pioneer_eligibility_tracks_only_the_requested_shore_texture() -> void:
	var cfg := {"dune_colony_shape": true, "dune_pioneer_ground": ["shore", "rock", "grass"]}
	assert_eq(GRASS.pioneer_ground_mask(["grass", "shore", "rock"], cfg), 2)
	assert_eq(GRASS.pioneer_ground_mask(["rock", "grass", "shore"], cfg), 4)
	assert_eq(GRASS.pioneer_ground_mask(["grass", "rock"], cfg), 0)
	cfg.dune_pioneer_ground = ["grass"]
	assert_eq(GRASS.pioneer_ground_mask(["grass", "shore", "rock"], cfg), 0)
	cfg.dune_colony_shape = false
	assert_eq(GRASS.pioneer_ground_mask(["grass", "shore", "rock"], cfg), 0)
