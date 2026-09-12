extends "res://tests/test_case.gd"

const WARRENS_PATH := "res://data/config/burrow_warrens.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const TRAINER_HEIGHT_M := 1.80


func _warrens_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WARRENS_PATH))
	assert_true(parsed is Dictionary, "Burrow Warrens config did not parse")
	return parsed as Dictionary if parsed is Dictionary else {}


func test_guardian_scale_fits_the_approved_den_after_the_global_creature_pass() -> void:
	var warrens_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(WARRENS_PATH))
	var species_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPECIES_PATH))
	assert_true(warrens_raw is Dictionary, "Burrow Warrens config did not parse")
	assert_true(species_raw is Dictionary, "Creature species config did not parse")
	if not warrens_raw is Dictionary or not species_raw is Dictionary:
		return
	var warrens := warrens_raw as Dictionary
	var guardian: Dictionary = warrens.get("guardian", {})
	var species_id := str(guardian.get("species", ""))
	var species_table: Dictionary = (species_raw as Dictionary).get("species", {})
	var species: Dictionary = species_table.get(species_id, {})
	var placeholder: Dictionary = species.get("placeholder", {})
	var source_height := float(placeholder.get("height", 0.0))
	var source_radius := float(placeholder.get("radius", 0.0))
	var scale_value := float(guardian.get("scale", 1.0))
	var guardian_height := source_height * scale_value
	var guardian_diameter := source_radius * scale_value * 2.0

	assert_true(source_height > TRAINER_HEIGHT_M,
		"Ordinary Burrowback regressed below the fixed trainer")
	assert_true(scale_value >= 1.25,
		"Warren Guardian no longer reads larger than an ordinary Burrowback")
	assert_true(guardian_height >= TRAINER_HEIGHT_M * 2.0,
		"Warren Guardian no longer has a boss-scale silhouette")

	var den_height := 0.0
	for raw: Variant in warrens.get("chambers", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "den":
			den_height = float((raw as Dictionary).get("height", 0.0))
	var passage_height := 0.0
	var passage_width := 0.0
	for raw: Variant in warrens.get("passages", []):
		if not raw is Dictionary:
			continue
		var passage := raw as Dictionary
		if str(passage.get("from", "")) == "hall" and str(passage.get("to", "")) == "den":
			passage_height = float(passage.get("height", 0.0))
			passage_width = float(passage.get("width", 0.0))
	assert_true(den_height - guardian_height >= 2.5,
		"Post-scale guardian crowds the approved den ceiling")
	assert_true(passage_height - guardian_height >= 0.35,
		"Post-scale guardian no longer clears its authored den threshold")
	assert_true(passage_width - guardian_diameter >= 0.25,
		"Post-scale guardian no longer fits the authored den threshold width")


func test_approach_rebuild_has_an_asymmetric_root_and_strata_reveal() -> void:
	var warrens := _warrens_config()
	var bank: Dictionary = warrens.get("bank", {})
	var approach: Dictionary = bank.get("approach_composition", {})
	assert_true(not approach.is_empty(), "The rejected Warrens approach has no replacement composition")
	assert_true((bank.get("accent_boulders", []) as Array).is_empty() and
		(bank.get("face_outcrops", []) as Array).is_empty(),
		"The rejected loose plastic-rock cluster is still stacked under the new approach")
	var clear_half := float(approach.get("clear_half_width_m", 0.0))
	assert_true(clear_half >= 3.8,
		"The approach no longer preserves the authored trainer-and-creature sightline lane")

	var ribs: Array = approach.get("stone_ribs", [])
	assert_true(ribs.size() >= 3, "The approach lost its road-to-brow strata cadence")
	var ids: Dictionary = {}
	var models: Dictionary = {}
	var heights: Array[float] = []
	var near_sides: Dictionary = {}
	for raw: Variant in ribs:
		assert_true(raw is Dictionary, "Every approach rib must be authored data")
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var id := str(spec.get("id", ""))
		var model := str(spec.get("model", ""))
		var offset: Array = spec.get("offset", [])
		var size: Array = spec.get("size_m", [])
		assert_true(not id.is_empty() and not ids.has(id), "Approach rib ids must be unique")
		ids[id] = true
		models[model] = true
		assert_true(ResourceLoader.exists(model), "%s is not an installed strata mesh" % model)
		assert_eq(offset.size(), 2, "%s needs an explicit local approach offset" % id)
		assert_eq(size.size(), 3, "%s needs explicit final XYZ bounds" % id)
		if offset.size() == 2 and size.size() == 3:
			var x := float(offset[0])
			var z := float(offset[1])
			var half_width := float(size[0]) * 0.5
			heights.append(float(size[1]))
			assert_true(absf(x) - half_width >= clear_half,
				"%s crowds the open approach lane" % id)
			assert_true(z <= -8.0 and z >= -24.0,
				"%s no longer stages the threshold-to-road reveal" % id)
			if z > -15.0:
				near_sides[signf(x)] = true
	assert_true(models.size() >= 3, "The silhouette regressed to repeated copies of one prop")
	heights.sort()
	assert_true(heights.size() >= 3 and heights[-1] >= 6.5 and heights[0] <= 4.0,
		"The strata ribs lost their low-road / tall-brow hierarchy")
	assert_true(near_sides.has(-1.0) and near_sides.has(1.0),
		"The threshold lost one of its two readable shoulders")

	var windfall: Array = approach.get("windfall", [])
	assert_true(windfall.size() >= 2, "Stone no longer transitions into Meadows root language")
	for raw: Variant in windfall:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var model := str(spec.get("model", ""))
		var offset: Array = spec.get("offset", [])
		var size: Array = spec.get("size_m", [])
		assert_true(ResourceLoader.exists(model), "%s is not an installed windfall mesh" % model)
		assert_true(offset.size() == 2 and size.size() == 3,
			"Every windfall piece needs bounded size and placement")
		if offset.size() == 2 and size.size() == 3:
			assert_true(absf(float(offset[0])) - float(size[0]) * 0.5 >= clear_half,
				"Windfall dressing crowds the open approach lane")


func test_approach_ruts_are_restrained_guidance_not_another_ground_slab() -> void:
	var approach: Dictionary = _warrens_config().get("bank", {}).get("approach_composition", {})
	var offsets: Array = approach.get("rut_offsets_m", [])
	assert_eq(offsets.size(), 2, "The approach should read as two narrow worn tracks")
	if offsets.size() == 2:
		assert_true(float(offsets[0]) < 0.0 and float(offsets[1]) > 0.0,
			"The two worn tracks no longer straddle the route centre")
	assert_true(float(approach.get("rut_length_m", 0.0)) >= 20.0,
		"The approach guidance no longer reaches a plausible road-distance stand")
	assert_true(float(approach.get("rut_width_m", 99.0)) <= 0.7,
		"The worn tracks regressed into a broad painted threshold slab")
	assert_true(float(approach.get("rut_lift_m", 99.0)) <= 0.06,
		"The worn tracks float visibly above the production ground")


func test_approach_layer_is_exterior_only_and_does_not_reopen_the_interior() -> void:
	var warrens := _warrens_config()
	var site: Dictionary = warrens.get("site", {})
	assert_eq(site.get("earth_clad_interiors", []), ["mouth"],
		"The exterior recovery changed the accepted interior material boundary")
	assert_eq(site.get("earth_clad_walls", []), ["hall", "warren", "den", "vault"],
		"The exterior recovery changed the accepted chamber treatment")
	var chamber_ids: Array[String] = []
	for raw: Variant in warrens.get("chambers", []):
		if raw is Dictionary:
			chamber_ids.append(str((raw as Dictionary).get("id", "")))
	assert_eq(chamber_ids, ["mouth", "hall", "warren", "den", "vault"],
		"The exterior recovery changed the five-chamber Warrens layout")

	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var mount := source.find("\t_build_warrens_approach_composition()")
	var mouth := source.find("\t_build_bank_mouth()")
	var interior := source.find("\t_build_deposits()")
	assert_true(mouth >= 0 and mount > mouth and interior > mount,
		"The approach composition is not mounted in the exterior build phase")
	assert_true(source.contains('holder.name = "ApproachComposition"') and
		source.contains('holder.set_meta(EXTERIOR_META, true)'),
		"The approach layer can leak into the cave's interior-only ambient")
	var start := source.find("func _build_warrens_approach_composition()")
	var finish := source.find("func _build_approach_ruts", start)
	var solid_builders := source.substr(start, finish - start) if start >= 0 and finish > start else ""
	assert_false(solid_builders.contains("create_trimesh_collision") or
		solid_builders.contains("CollisionShape3D"),
		"Visual approach staging must not change the accepted walked route")
