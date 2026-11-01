extends "res://tests/test_case.gd"

## Coat flags (data/config/creature_coat_flags.json, read by
## creature_body.gd::parse_coat_flags / coat_material). GPU arms are judged by
## flipping `enabled`, so a flag whose data cannot apply must fail here, not in
## a GPU run that comes back "identical" with nothing logged (CO-F36-7).

const BODY := preload("res://scripts/creatures/creature_body.gd")
const FLAGS_PATH := "res://data/config/creature_coat_flags.json"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses to an object")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


## Every flag, on or off, is shaped so that flipping it applies: `coats` maps a
## live albedo path to a graded path that exists, or to known material values.
func test_every_flag_resolves_when_enabled() -> void:
	var flags := _flags()
	assert_true(not flags.is_empty(), "the file declares flags")
	for flag: String in flags:
		var entry: Dictionary = flags[flag]
		assert_true(entry.get("enabled") is bool, "%s declares enabled as a bool" % flag)
		var coats: Variant = entry.get("coats")
		assert_true(coats is Dictionary and not (coats as Dictionary).is_empty(),
			"%s maps live albedo paths (a dictionary), not a list" % flag)
		if not coats is Dictionary:
			continue
		var forced := {"flags": {flag: {"enabled": true, "coats": coats}}}
		var resolved: Dictionary = BODY.parse_coat_flags(forced)
		assert_eq(resolved.size(), (coats as Dictionary).size(), "%s resolves every entry when enabled" % flag)
		for from_path: String in coats:
			assert_true(ResourceLoader.exists(from_path), "%s source %s exists" % [flag, from_path])
			var spec: Dictionary = resolved.get(from_path, {})
			if spec.has("emission"):
				assert_true(ResourceLoader.exists(str(spec.emission)), "%s glow map %s exists" % [flag, spec.emission])
			for key: String in spec:
				assert_true(key in ["albedo", "metallic", "roughness", "specular", "emission_scale", "emission", "emission_energy"],
					"%s %s uses a known key (%s)" % [flag, from_path, key])


## OFF by default for the lane candidates: nothing changes until a flag flips.
func test_vis_candidates_ship_off() -> void:
	var flags := _flags()
	for flag: String in flags:
		if flag.begins_with("creatures_vis_"):
			assert_false(bool((flags[flag] as Dictionary).get("enabled", true)), "%s ships OFF" % flag)


func test_disabled_and_misshapen_flags_resolve_to_nothing() -> void:
	var parsed := {"flags": {
		"off": {"enabled": false, "coats": {"res://a.png": {"metallic": 0.0}}},
		"listed": {"enabled": true, "coats": ["res://a.png"]},
	}}
	assert_true(BODY.parse_coat_flags(parsed).is_empty(), "a disabled flag and a list-shaped coats apply nothing")


func test_material_values_and_emission_scale_apply() -> void:
	var source := StandardMaterial3D.new()
	source.metallic = 1.0
	source.roughness = 0.2
	source.roughness_texture = ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGB8))
	source.metallic_specular = 0.5
	source.emission_enabled = true
	source.emission_energy_multiplier = 2.0
	source.resource_name = "Material_0_field_bright"
	var spec := {"metallic": 0.0, "roughness": 0.85, "specular": 0.35, "emission_scale": 0.6}
	var copy: BaseMaterial3D = BODY.coat_material(source, spec)
	assert_almost_eq(copy.metallic, 0.0)
	assert_almost_eq(copy.roughness, 0.85)
	assert_true(copy.roughness_texture == null, "a roughness value replaces the roughness map")
	assert_almost_eq(copy.metallic_specular, 0.35)
	assert_almost_eq(copy.emission_energy_multiplier, 1.2)
	assert_eq(copy.resource_name, source.resource_name, "the copy keeps the name the field-brightness pass keys on")
	assert_almost_eq(source.emission_energy_multiplier, 2.0, 0.0001, "the source material is untouched")
	# Emission is only ever dimmed, never pushed past the source.
	var bright: BaseMaterial3D = BODY.coat_material(source, {"emission_scale": 3.0})
	assert_almost_eq(bright.emission_energy_multiplier, 2.0)


func test_trait_glow_map_lights_the_copy() -> void:
	var source := StandardMaterial3D.new()
	source.emission_enabled = false
	var glow_path := "res://icon.svg"
	var copy: BaseMaterial3D = BODY.coat_material(source, {"emission": glow_path, "emission_energy": 0.8})
	assert_true(copy.emission_enabled, "a glow map turns emission on")
	assert_eq(copy.emission_operator, BaseMaterial3D.EMISSION_OP_MULTIPLY)
	assert_true(copy.emission_texture != null and copy.emission_texture.resource_path == glow_path, "the glow map is bound")
	assert_almost_eq(copy.emission_energy_multiplier, 0.8)
	assert_false(source.emission_enabled, "the source material is untouched")
