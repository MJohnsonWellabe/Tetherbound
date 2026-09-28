extends "res://tests/test_case.gd"

const DUNES := preload("res://scripts/world/water_dune_cover.gd")
const VEGETATION := preload("res://scripts/world/water_vegetation.gd")


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
	assert_true(candidate.tuft_count < source.tuft_count)
	assert_true(candidate.height_near > source.height_near)
	assert_eq(candidate.anchor_clear_radius_m, source.anchor_clear_radius_m)
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
