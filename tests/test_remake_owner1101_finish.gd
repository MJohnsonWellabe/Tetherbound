extends "res://tests/test_case.gd"

## Cause-lane finish for the owner-rule remakes (1 Nov 2026), all OFF by default:
## coat flags remake_owner1101_glow_read / _plate_blend / _dark_lift
## (data/config/creature_coat_flags.json) and scale flags
## remake_owner1101_body_line / _judged_short (creature_scale_flags.json).
## Off changes nothing; on applies every key; no species shrinks or outgrows its
## evolution; the models (and so their clips) are untouched.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const COAT_FLAGS := ["remake_owner1101_glow_read", "remake_owner1101_plate_blend", "remake_owner1101_dark_lift"]
const SCALE_FLAGS := ["remake_owner1101_body_line", "remake_owner1101_judged_short"]
const REMAKE_DIR := "/candidate_owner1101/models/"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses to an object" % path)
	return parsed if parsed is Dictionary else {}


func _flags(path: String) -> Dictionary:
	return _json(path).get("flags", {})


func _remake_species() -> Dictionary:
	var out := {}
	var flags := _flags(SPECIES.MODEL_FLAGS_PATH)
	for flag: String in flags:
		if flag.begins_with("remake_owner1101_"):
			for id: String in (flags[flag] as Dictionary).species:
				out[id] = str((flags[flag] as Dictionary).species[id].model)
	return out


func test_finish_flags_ship_off_and_change_nothing_while_off() -> void:
	var coats := _flags(COAT_PATH)
	for flag: String in COAT_FLAGS:
		assert_true(coats.has(flag), "%s is declared" % flag)
		assert_false(bool((coats.get(flag, {}) as Dictionary).get("enabled", true)), "%s ships OFF" % flag)
	var scales := _flags(SPECIES.SCALE_FLAGS_PATH)
	for flag: String in SCALE_FLAGS:
		assert_true(scales.has(flag), "%s is declared" % flag)
		assert_false(bool((scales.get(flag, {}) as Dictionary).get("enabled", true)), "%s ships OFF" % flag)
	# Off: no remake albedo is remapped by the live coat map.
	for from_path: String in BODY.parse_coat_flags(_json(COAT_PATH)):
		assert_false(from_path.contains(REMAKE_DIR), "%s is not remapped while the finish flags are off" % from_path)


func test_enabled_coat_flags_apply_every_key() -> void:
	var coats := _flags(COAT_PATH)
	for flag: String in COAT_FLAGS:
		var entry: Dictionary = (coats.get(flag, {}) as Dictionary).duplicate(true)
		entry.enabled = true
		var resolved: Dictionary = BODY.parse_coat_flags({"flags": {flag: entry}})
		assert_eq(resolved.size(), (entry.coats as Dictionary).size(), "%s resolves every entry when on" % flag)
		for from_path: String in resolved:
			assert_true(from_path.contains(REMAKE_DIR) and from_path.ends_with("_Image_0.jpg"),
				"%s keys the remake's live albedo (%s)" % [flag, from_path])
			var spec: Dictionary = resolved[from_path]
			var source := StandardMaterial3D.new()
			source.albedo_texture = load(from_path) as Texture2D
			source.emission_enabled = true
			source.emission_energy_multiplier = 1.0
			var copy: BaseMaterial3D = BODY.coat_material(source, spec)
			if spec.has("emission"):
				var energy := float(spec.emission_energy)
				assert_true(energy > 1.0 and energy <= 4.0, "%s glow energy %.2f is a real push within the clamp" % [from_path, energy])
				assert_true(copy.emission_texture != null and copy.emission_texture.resource_path == str(spec.emission),
					"%s wears its glow map" % from_path)
				assert_almost_eq(copy.emission_energy_multiplier, energy)
			if spec.has("albedo"):
				assert_true(copy.albedo_texture != null and copy.albedo_texture.resource_path == str(spec.albedo),
					"%s wears its regraded albedo" % from_path)


func test_glow_pass_covers_every_remake_with_a_glow_mask() -> void:
	var glow: Dictionary = (_flags(COAT_PATH).get("remake_owner1101_glow_read", {}) as Dictionary).get("coats", {})
	var remakes := _remake_species()
	for id: String in remakes:
		var model := str(remakes[id])
		var mask := model.get_basename() + "_arc_emission.png"
		var albedo := model.get_basename() + "_Image_0.jpg"
		if ResourceLoader.exists(mask):
			assert_true(glow.has(albedo), "%s's glow mask is lifted by the glow pass" % id)


func test_scale_flags_only_grow_and_keep_evolution_order() -> void:
	var scales := _flags(SPECIES.SCALE_FLAGS_PATH)
	var remakes := _remake_species()
	var rows: Dictionary = SPECIES.table()
	for flag: String in SCALE_FLAGS:
		var factors: Dictionary = (scales.get(flag, {}) as Dictionary).get("species", {})
		assert_true(not factors.is_empty(), "%s names species" % flag)
		for id: String in factors:
			assert_true(remakes.has(id), "%s: %s is an owner-rule remake" % [flag, id])
			var factor := float(factors[id])
			assert_true(factor >= 1.0, "%s: %s grows (x%.2f), never shrinks" % [flag, id, factor])
			var grown := float((rows[id].placeholder as Dictionary).get("height", 1.0)) * factor
			for other: String in rows:
				if str((rows[other] as Dictionary).get("evolves_from", "")) == id:
					var evolved := float((rows[other].placeholder as Dictionary).get("height", 1.0))
					assert_true(grown < evolved, "%s: %s at %.2fm stays under its evolution %s (%.2fm)" % [flag, id, grown, other, evolved])
