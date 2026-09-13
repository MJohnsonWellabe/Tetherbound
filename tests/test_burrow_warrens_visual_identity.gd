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


func test_facade_is_a_laterally_weighted_earth_cut_not_a_portal_assembly() -> void:
	var bank: Dictionary = _warrens_config().get("bank", {})
	assert_true(float(bank.get("crown_offset_x_m", 0.0)) <= -3.0 and
		float(bank.get("crown_superellipse_power", 0.0)) >= 2.6 and
		float(bank.get("crown_profile_power", 9.0)) <= 0.9,
		"The landmark crown regressed to a centered steep cone")
	assert_true(float(bank.get("crown_erosion_amount", 0.0)) >= 0.15 and
		float(bank.get("surface_noise_amount", 0.0)) >= 0.15 and
		float(bank.get("macro_noise_amount", 0.0)) >= 0.15,
		"The broad bank lost its shallow eroded material variation")
	var facade: Dictionary = bank.get("facade_cut", {})
	assert_true(bool(facade.get("enabled", false)),
		"The throat outer end is no longer buried in a production bank cut")
	var shoulders: Array = facade.get("earth_shoulders", [])
	assert_true(shoulders.size() >= 3,
		"The facade regressed from overlapping shoulders to one smooth cone")
	var west_weight := 0.0
	var east_weight := 0.0
	for entry_v: Variant in shoulders:
		if not entry_v is Dictionary:
			continue
		var shoulder := entry_v as Dictionary
		var height := float(shoulder.get("height_m", 0.0))
		var width := float(shoulder.get("radius_x_m", 0.0))
		assert_true(height >= 3.0 and width >= 6.0 and
			float(shoulder.get("radius_z_m", 0.0)) >= 6.0,
			"A facade shoulder is too small to read as earth massing")
		assert_true(float(shoulder.get("superellipse_power", 0.0)) >= 2.4,
			"A facade shoulder regressed to a radial cone profile")
		if float(shoulder.get("offset_x_m", 0.0)) < 0.0:
			west_weight += height * width
		else:
			east_weight += height * width
	assert_true(west_weight >= east_weight * 2.5,
		"Outer bank lost the decisive west-heavy silhouette")
	var front_mounds := 0
	for mound_v: Variant in bank.get("mounds", []):
		if mound_v is Dictionary and float(((mound_v as Dictionary).get("offset", [0.0, 99.0]) as Array)[1]) < 18.0:
			front_mounds += 1
	assert_eq(front_mounds, 0,
		"Separate additive cones returned to the outer facade")
	assert_true(float(facade.get("erosion_amount", 0.0)) >= 0.2,
		"Facade shoulders lost their broad erosion variation")
	assert_eq(float(bank.get("brow_thickness_m", -1.0)), 0.0,
		"The separate pale annular brow returned")
	assert_eq(float(bank.get("lip_thickness_m", -1.0)), 0.0,
		"The recessed complete mouth ring returned to the road view")
	assert_true((bank.get("brow_root_meshes", []) as Array).is_empty() and
		(bank.get("root_masses", []) as Array).is_empty() and
		(bank.get("roots", []) as Array).is_empty(),
		"Installed-tree shelves or separate snag teeth returned to the facade")
	var exterior_deadtrees := 0
	for piece_v: Variant in _warrens_config().get("roots", {}).get("pieces", []):
		if piece_v is Dictionary and bool((piece_v as Dictionary).get("exterior", false)):
			exterior_deadtrees += 1
	assert_eq(exterior_deadtrees, 0,
		"Cut-ended DeadTree crowns returned as vertical teeth over the mouth")

	assert_true((facade.get("root_runs", []) as Array).is_empty(),
		"Separate tapered root tubes returned as teeth across the exterior bank")
	for piece_v: Variant in _warrens_config().get("roots", {}).get("pieces", []):
		if piece_v is Dictionary:
			assert_ne(str((piece_v as Dictionary).get("chamber", "")), "mouth",
				"An interior DeadTree crown can still escape through the mouth as a toothed apron")
	# These are real footprint invariants, not a label check: at least two broad
	# height-field shoulders must overlap across the complete throat width, and
	# adjacent shoulder intervals must overlap instead of forming prop-like cones.
	var throat_half := float(bank.get("arch_width_m", 0.0)) * 0.5
	var throat_cover_count := 0
	var intervals: Array[Vector2] = []
	for entry_v: Variant in shoulders:
		if not entry_v is Dictionary:
			continue
		var shoulder := entry_v as Dictionary
		var cx := float(shoulder.get("offset_x_m", 0.0))
		var rx := float(shoulder.get("radius_x_m", 0.0))
		intervals.append(Vector2(cx - rx, cx + rx))
		if cx - rx <= -throat_half and cx + rx >= throat_half:
			throat_cover_count += 1
	assert_true(throat_cover_count >= 2,
		"The mouth is no longer embedded in overlapping terrain-width shoulders")
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for i in range(1, intervals.size()):
		assert_true(intervals[i].x < intervals[i - 1].y,
			"Facade shoulder footprints separated into independent applied mounds")
	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var mouth_start := source.find("func _build_bank_mouth")
	var mouth_end := source.find("func _build_warrens_approach_composition", mouth_start)
	var mouth_source := source.substr(mouth_start, mouth_end - mouth_start)
	var brow_start := source.find("func _build_mouth_brow")
	var brow_end := source.find("func _brow_rim_samples", brow_start)
	var brow_source := source.substr(brow_start, brow_end - brow_start)
	assert_true(mouth_source.contains("_build_mouth_brow") and
		brow_source.contains("pass") and
		not brow_source.contains("_build_buried_facade_roots") and
		not mouth_source.contains("_build_bank_lip_ring") and
		not brow_source.contains("_build_brow_earth_ring") and
		not brow_source.contains("_build_brow_root_meshes"),
		"Production mouth returned to separate portal or prop facade pieces")
	var height_start := source.find("func _bank_height_shaped")
	var height_end := source.find("func _bank_normal_at", height_start)
	var height_source := source.substr(height_start, height_end - height_start)
	assert_true(height_source.contains("h = maxf(h, _bank_facade_cut_term(x, z))") and
		height_source.find("_bank_facade_cut_term") < height_source.find("h = lerp(h, 0.0, settled)"),
		"Outer facade is not part of the bank height field before route suppression")
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
	assert_true(cap_source.contains("cap.material_override = _bank_earth_material()") and
		not cap_source.contains("cap.material_override = _bank_material()"),
		"The narrow safety seal regressed to a separate pale awning")


func test_first_interior_uses_non_colliding_organic_earth_finish() -> void:
	var warrens := _warrens_config()
	var finish: Dictionary = warrens.get("organic_entry_finish", {})
	assert_true(bool(finish.get("enabled", false)),
		"The first-interior organic finish is disabled")
	assert_eq(finish.get("chambers", []), ["mouth", "hall", "den"],
		"The organic canopy no longer masks the complete visible acceptance route")
	assert_eq(finish.get("passages", []), ["mouth>hall", "hall>den"],
		"The organic liner no longer masks the two acceptance-route passages")
	assert_true(int(finish.get("arc_segments", 0)) >= 16 and
		int(finish.get("length_segments", 0)) >= 6 and
		float(finish.get("side_wobble_m", 0.0)) >= 0.2 and
		float(finish.get("chamber_width_wobble_m", 0.0)) >= 0.3 and
		float(finish.get("passage_curve_m", 0.0)) >= 0.5 and
		float(finish.get("passage_width_wobble_m", 0.0)) >= 0.15 and
		float(finish.get("portal_hood_depth_m", 0.0)) >= 1.8 and
		int(finish.get("portal_hood_rings", 0)) >= 6 and
		float(finish.get("portal_flare_side_m", 0.0)) >= 1.5 and
		float(finish.get("portal_flare_crown_m", 0.0)) >= 0.8 and
		float(finish.get("portal_uneven_m", 0.0)) >= 0.2,
		"The entry finish regressed to a shallow frame or mathematically straight prism")

	var source := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	var organic_start := source.find("func _build_organic_entry_finish")
	var organic_end := source.find("func _structure_colour", organic_start)
	var organic_source := source.substr(organic_start, organic_end - organic_start) \
		if organic_start >= 0 and organic_end > organic_start else ""
	assert_true(organic_source.contains('holder.name = "OrganicEntryFinish"') and
		organic_source.contains('canopy.name = "OrganicCanopy_') and
		organic_source.contains('liner.name = "OrganicPassage_') and
		organic_source.contains('surround.name = "OrganicPortal_') and
		organic_source.contains("_organic_portal_hood_mesh") and
		organic_source.contains("Mesh.PRIMITIVE_TRIANGLES") and
		organic_source.contains("_interior_cladding_material().duplicate()"),
		"Production lost the arched earth canopy or passage liner")
	assert_false(organic_source.contains("CollisionShape3D") or
		organic_source.contains("create_trimesh_collision") or
		organic_source.contains("_box("),
		"Organic visual finish changed the accepted collision route or returned to boxes")
	assert_true(organic_source.contains("_floor_y + 0.02") and
		organic_source.contains("roomward * depth * eased") and
		organic_source.contains("side_flare * eased") and
		organic_source.contains("crown_flare * eased") and
		organic_source.contains("curve * sin(t * PI)") and
		organic_source.contains("portal_uneven_m") and
		organic_source.contains("for ix in columns - 1:") and
		organic_source.contains("for point_i in point_count - 1:"),
		"Organic finish no longer covers planar walls with indexed flared hood geometry")
	var structure_start := source.find("func _build_structure")
	var structure_end := source.find("func _build_organic_entry_finish", structure_start)
	var structure_source := source.substr(structure_start, structure_end - structure_start) \
		if structure_start >= 0 and structure_end > structure_start else ""
	assert_true(structure_source.contains("organic_chambers.has(id)") and
		structure_source.contains("organic_passages.has") and
		structure_source.contains('"openings": structure_openings'),
		"Square ceiling beams or passage reveals can return beneath the organic finish")


func test_capture_serializes_final_pose_and_keeps_threshold_step_judgeable() -> void:
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_burrow_warrens_visual_identity.gd")
	assert_true(source.contains('"03a-threshold-step", threshold_step_a') and
		source.contains("2.35, 2.05, 1.55, 66.0"),
		"Threshold step camera regressed to the trainer-blocked shoulder composition")
	var capture_start := source.find("func _capture_exterior")
	var capture_end := source.find("func _write_frame", capture_start)
	var capture_source := source.substr(capture_start, capture_end - capture_start)
	var wait_at := capture_source.find("await process_frame")
	var receipt_at := capture_source.find("var seated_surface", wait_at)
	var write_at := capture_source.find("await _write_frame", receipt_at)
	assert_true(wait_at >= 0 and receipt_at > wait_at and write_at > receipt_at,
		"Capture receipt no longer samples the final pose immediately before serialization")
	assert_true(source.contains('"geometry_revision": "BURROW-WARRENS-IDENTITY-R9"') and
		source.contains('"facade_root_holder_present"') and
		source.contains('"organic_portal_hood_count"') and
		source.contains('final-warrens-09'),
		"Capture serializer did not advance to the R9 geometry receipt")


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
