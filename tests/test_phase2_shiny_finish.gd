extends "res://tests/test_case.gd"

const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
var saved_config: Dictionary
var saved_variants: Dictionary


func before_each() -> void:
	saved_config = VISUAL._config.duplicate(true)
	saved_variants = BODY._variant_materials.duplicate()
	BODY._variant_materials.clear()


func after_each() -> void:
	VISUAL._config = saved_config
	BODY._variant_materials = saved_variants


func test_gate_defaults_off_without_affecting_existing_colourways() -> void:
	VISUAL._config = {"shiny_chance": 0.0078}
	for species: String in VISUAL.PHASE2_SHINY_SPECIES:
		assert_false(VISUAL.shiny_colourway_allowed(species), species)
	for species: String in ["terrapup", "ripplet", "mosshell", "cloudfang", "galecrest"]:
		assert_true(VISUAL.shiny_colourway_allowed(species), species)
	VISUAL._config.phase2_shiny_finish_enabled = true
	for species: String in VISUAL.PHASE2_SHINY_SPECIES:
		assert_true(VISUAL.shiny_colourway_allowed(species), species)


func test_tidewake_allowlist_uses_repaints_without_enabling_other_phase2_species() -> void:
	VISUAL._config = {"phase2_shiny_finish_enabled": false,
		"phase2_shiny_finish_species": ["aquaryn", "cannonback", "riptusk", "tidecoil"]}
	for species: String in VISUAL._config.phase2_shiny_finish_species:
		assert_true(VISUAL.shiny_colourway_allowed(species), species)
	for species: String in ["voltwig", "staticub", "solmane"]:
		assert_false(VISUAL.shiny_colourway_allowed(species), species)


func test_disabled_gate_retints_source_once_after_ordinary_override() -> void:
	VISUAL._config = {"phase2_shiny_finish_enabled": false}
	var body := BODY.new()
	var model := Node3D.new()
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var source := StandardMaterial3D.new()
	source.resource_name = "source"
	source.albedo_color = Color(0.4, 0.6, 0.8)
	source.emission_enabled = true
	source.emission = Color(0.1, 0.2, 0.3)
	mesh.material = source
	instance.mesh = mesh
	model.add_child(instance)
	body.add_child(model)
	body.set("_model", model)
	body.set("_has_model", true)
	body.set("species_id", "water_aquaryn")
	body.set("_ordinary_colourway_species", "aquaryn")
	body.set("shiny", true)
	var vivid := source.duplicate() as StandardMaterial3D
	vivid.albedo_color = Color.GREEN
	instance.set_surface_override_material(0, vivid)
	for _repeat in 2:
		body.call("_refresh_shiny_tint")
		var active := instance.get_active_material(0) as BaseMaterial3D
		assert_true(active.albedo_color.is_equal_approx(source.albedo_color * BODY.SHINY_PLACEHOLDER_TINT),
			"disabled candidate must derive from source, never vivid or a previous tint")
		assert_true(active.emission.is_equal_approx(source.emission * BODY.SHINY_PLACEHOLDER_TINT))
	assert_true(source.albedo_color.is_equal_approx(Color(0.4, 0.6, 0.8)), "source is never mutated")
	body.free()
