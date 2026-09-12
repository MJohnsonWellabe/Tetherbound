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
	assert_true(float(approach.get("rut_lift_m", 99.0)) <= 0.035,
		"The worn tracks are no longer seated as embedded earth")
	assert_true(Color(str(approach.get("rut_colour", "#000000"))).get_luminance() >= 0.3,
		"The route guidance regressed to near-black ribbons")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var start := source.find("func _build_approach_ruts")
	var finish := source.find("func _approach_model", start)
	var rut_source := source.substr(start, finish - start) if start >= 0 and finish > start else ""
	assert_true(rut_source.contains("WET_EARTH_ALBEDO") and
		rut_source.contains("RutCorridorClear"),
		"Ruts lost their earth-family material or continuous local grass exclusion")
	assert_false(rut_source.contains("randf_range"),
		"Per-row random jitter brings back the serrated rut edge")


func test_facade_is_an_earth_moss_family_with_a_decisively_asymmetric_brow() -> void:
	var bank: Dictionary = _warrens_config().get("bank", {})
	var approach: Dictionary = bank.get("approach_composition", {})
	var palette: Array = approach.get("earth_moss_palette", [])
	assert_true(palette.size() >= 3, "Facade ribs lost the shared earth/moss palette")
	for raw: Variant in palette:
		var colour := Color(str(raw))
		assert_true(colour.get_luminance() >= 0.35 and colour.get_luminance() <= 0.72,
			"Facade palette reintroduced a near-black or pale-white slab")
	var left := float(bank.get("brow_left_width_scale", 1.0))
	var right := float(bank.get("brow_right_width_scale", 1.0))
	assert_true(left >= 1.3 and right <= 0.75 and left - right >= 0.55,
		"Brow mass no longer breaks the centered circular-portal silhouette")
	assert_true(float(bank.get("brow_seam_overlap_m", 0.0)) >= 0.15,
		"Outer brow no longer tucks under the bank to close bright facade seams")
	assert_true(float(bank.get("brow_turf_end_frac", 1.0)) <= 0.78,
		"Turf reverted to an evenly decorated arch wreath")
	var roots: Array = bank.get("brow_root_meshes", [])
	assert_eq(roots.size(), 2, "Brow root composition changed unexpectedly")
	if roots.size() == 2:
		var large: Dictionary = roots[0]
		var small: Dictionary = roots[1]
		assert_true(float(large.get("at_deg", 90.0)) >= 125.0 and
			float(small.get("at_deg", 90.0)) <= 50.0,
			"Root masses returned to a centered crown pair")
		assert_true(float(large.get("scale", 0.0)) >= float(small.get("scale", 0.0)) * 1.8,
			"Root silhouettes no longer establish a dominant and subordinate side")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	assert_true(source.contains("_approach_earth_moss_material") and
		source.contains("_brow_asymmetry_scale") and source.contains("backfill"),
		"Production facade is not consuming its material/asymmetry/seam contract")


func test_threshold_uses_a_restrained_inner_practical_without_route_collision() -> void:
	var bank: Dictionary = _warrens_config().get("bank", {})
	var model := str(bank.get("threshold_practical_model", ""))
	assert_true(ResourceLoader.exists(model), "Threshold practical is not an installed prop")
	assert_true(float(bank.get("threshold_practical_depth_m", 0.0)) >= 1.8,
		"Threshold practical moved onto the facade")
	assert_true(float(bank.get("threshold_practical_energy", 99.0)) <= 1.0 and
		float(bank.get("threshold_practical_range_m", 99.0)) <= 4.5 and
		float(bank.get("threshold_practical_attenuation", 0.0)) >= 2.5,
		"Threshold light regressed into a facade wash")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var start := source.find("func _build_threshold_practical")
	var finish := source.find("func _build_mouth_brow", start)
	var practical_source := source.substr(start, finish - start) \
		if start >= 0 and finish > start else ""
	assert_true(practical_source.contains('light.name = "ThresholdPracticalFill"'),
		"Production mouth does not build the shielded threshold light")
	assert_false(practical_source.contains("CollisionShape3D") or
		practical_source.contains("create_trimesh_collision"),
		"Threshold practical changed the accepted walked route")


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
