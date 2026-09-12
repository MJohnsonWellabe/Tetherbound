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


func test_approach_rebuild_retires_solid_shoulders_and_preserves_open_wear_lane() -> void:
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

	assert_true(not approach.has("stone_ribs") and not approach.has("windfall"),
		"Rejected stretched slab/panel props returned to the approach")
	assert_true((approach.get("root_shoulders", []) as Array).is_empty(),
		"The oblique-rejected DeadTree shoulder slabs returned beside the route")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var start := source.find("func _build_approach_root_shoulders")
	var finish := source.find("func _build_approach_ruts", start)
	var shoulder_source := source.substr(start, finish - start) if start >= 0 and finish > start else ""
	assert_true(shoulder_source.contains("Vector3.ONE * float(spec.get(\"scale\"") and
		not shoulder_source.contains("wanted_size") and not shoulder_source.contains("size_m"),
		"The optional shoulder mechanism can regress to nonuniform slab scaling")


func test_approach_ruts_are_one_feathered_embedded_wear_field() -> void:
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
	assert_true(float(approach.get("rut_lift_m", 99.0)) <= 0.015,
		"The worn tracks are no longer seated as embedded earth")
	assert_true(float(approach.get("rut_edge_feather_m", 0.0)) >= 0.6 and
		float(approach.get("rut_lane_alpha", 1.0)) <= 0.7 and
		float(approach.get("rut_centre_alpha", 1.0)) <= 0.25,
		"Approach wear lost its broad transparent edge or restrained internal compression")
	assert_true(Color(str(approach.get("rut_colour", "#000000"))).get_luminance() >= 0.3,
		"The route guidance regressed to near-black ribbons")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var start := source.find("func _build_approach_ruts")
	var finish := source.find("func _throat_curve_offset", start)
	var rut_source := source.substr(start, finish - start) if start >= 0 and finish > start else ""
	assert_true(rut_source.contains("WET_EARTH_ALBEDO") and
		rut_source.contains("RutCorridorClear") and
		rut_source.contains('ruts.name = "ApproachRuts"') and
		rut_source.contains("st.set_color") and
		rut_source.contains("TRANSPARENCY_ALPHA"),
		"Ruts lost their earth-family material or continuous local grass exclusion")
	assert_false(rut_source.contains("randf_range"),
		"Per-row random jitter brings back the serrated rut edge")


func test_facade_is_an_earth_moss_family_with_a_decisively_asymmetric_brow() -> void:
	var bank: Dictionary = _warrens_config().get("bank", {})
	var left := float(bank.get("brow_left_width_scale", 1.0))
	var right := float(bank.get("brow_right_width_scale", 1.0))
	assert_true(left >= 1.8 and right <= 0.2 and left - right >= 1.5,
		"Brow mass no longer breaks the centered circular-portal silhouette")
	assert_true(float(bank.get("brow_span_start_frac", 0.0)) > 0.0 and
		float(bank.get("brow_span_end_frac", 1.0)) <= 0.8 and
		float(bank.get("brow_span_taper_frac", 0.0)) >= 0.08,
		"The brow returned to a complete ring instead of a tapered hooked facade")
	assert_true(float(bank.get("brow_seam_overlap_m", 0.0)) >= 0.35,
		"Outer brow no longer tucks under the bank to close bright facade seams")
	assert_true(float(bank.get("brow_turf_end_frac", 1.0)) <= 0.65,
		"Turf reverted to an evenly decorated arch wreath")
	assert_eq(float(bank.get("lip_thickness_m", -1.0)), 0.0,
		"The recessed complete mouth ring returned to the road view")
	var roots: Array = bank.get("brow_root_meshes", [])
	assert_eq(roots.size(), 2, "Brow root composition changed unexpectedly")
	if roots.size() == 2:
		var large: Dictionary = roots[0]
		var small: Dictionary = roots[1]
		assert_true(float(large.get("at_deg", 90.0)) >= 130.0 and
			float(small.get("at_deg", 90.0)) >= 60.0 and
			float(small.get("at_deg", 90.0)) <= 85.0,
			"Root masses returned to a centered crown pair")
		assert_true(float(large.get("scale", 0.0)) >= float(small.get("scale", 0.0)) * 1.8,
			"Root silhouettes no longer establish a dominant and subordinate side")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var mouth_start := source.find("func _build_bank_mouth")
	var mouth_end := source.find("func _build_warrens_approach_composition", mouth_start)
	var mouth_source := source.substr(mouth_start, mouth_end - mouth_start)
	assert_true(source.contains("_brow_asymmetry_scale") and source.contains("backfill") and
		source.contains("brow_span_end_frac") and source.contains("span_taper") and
		not mouth_source.contains("_build_bank_lip_ring"),
		"Production facade is not consuming its material/asymmetry/seam contract")
	var collar_start := source.find("func _build_bank_doorway_collar")
	var collar_end := source.find("func _build_bank_lamp_and_cable", collar_start)
	assert_true(source.substr(collar_start, collar_end - collar_start).contains("_throat_material()"),
		"The deep doorway collar can regress to a bright portal ring")


func test_threshold_uses_a_restrained_inner_practical_without_route_collision() -> void:
	var bank: Dictionary = _warrens_config().get("bank", {})
	var model := str(bank.get("threshold_practical_model", ""))
	assert_true(ResourceLoader.exists(model), "Threshold practical is not an installed prop")
	assert_true(float(bank.get("threshold_practical_depth_m", 0.0)) >= 1.8,
		"Threshold practical moved onto the facade")
	assert_true(float(bank.get("threshold_practical_energy", 99.0)) <= 1.1 and
		float(bank.get("threshold_practical_range_m", 99.0)) <= 5.5 and
		float(bank.get("threshold_practical_attenuation", 0.0)) >= 2.5,
		"Threshold light regressed into a facade wash")
	assert_true(float(bank.get("threshold_bounce_energy", 99.0)) <= 0.4 and
		float(bank.get("threshold_bounce_range_m", 99.0)) <= 5.0 and
		float(bank.get("threshold_bounce_depth_m", 0.0)) >= 3.0,
		"Reflected threshold fill is no longer restrained and recessed")
	assert_true(float(bank.get("threshold_shell_fill_energy", 99.0)) <= 0.5 and
		float(bank.get("threshold_shell_fill_range_m", 99.0)) <= 5.5 and
		float(bank.get("threshold_shell_fill_attenuation", 0.0)) >= 3.0,
		"Outer shell readability regressed into an unbounded facade wash")
	assert_true(float(bank.get("threshold_liner_inset_m", 0.0)) >= 0.05 and
		int(bank.get("threshold_liner_arc_segments", 0)) >= 20 and
		float(bank.get("threshold_liner_emission", 1.0)) <= 0.1,
		"The threshold liner lost its smooth, restrained night-readability contract")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var start := source.find("func _build_threshold_practical")
	var finish := source.find("func _build_mouth_brow", start)
	var practical_source := source.substr(start, finish - start) \
		if start >= 0 and finish > start else ""
	assert_true(practical_source.contains('light.name = "ThresholdPracticalFill"'),
		"Production mouth does not build the shielded threshold light")
	assert_true(practical_source.contains('bounce.name = "ThresholdReflectedFill"'),
		"Production mouth lost the low-energy reflected threshold fill")
	assert_true(practical_source.contains('shell_fill.name = "ThresholdShellFill"'),
		"Production mouth lost the bounded outer shell fill")
	assert_false(practical_source.contains("CollisionShape3D") or
		practical_source.contains("create_trimesh_collision"),
		"Threshold practical changed the accepted walked route")
	var liner_start := source.find("func _build_threshold_earth_liner")
	var liner_end := source.find("func _threshold_liner_material", liner_start)
	var liner_source := source.substr(liner_start, liner_end - liner_start) \
		if liner_start >= 0 and liner_end > liner_start else ""
	assert_true(liner_source.contains('liner.name = "ThresholdEarthLiner"') and
		not liner_source.contains("create_trimesh_collision") and
		not liner_source.contains("CollisionShape3D"),
		"The visual liner is missing or changed the smoke-proven collision shell")
	var cap_start := source.find("func _build_bank_cap")
	var cap_end := source.find("func _make_trimesh_two_sided", cap_start)
	var cap_source := source.substr(cap_start, cap_end - cap_start) \
		if cap_start >= 0 and cap_end > cap_start else ""
	assert_false(cap_source.contains("if above == 0"),
		"The outer throat cap can reopen bright threshold wedges")
	assert_true(cap_source.contains("cap_half") and cap_source.contains("_bank_cap_height_at") and
		cap_source.contains("sqrt(") and cap_source.contains("shoulder_t"),
		"The sealed cap regressed to a broad constant-height slab across the facade")


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
