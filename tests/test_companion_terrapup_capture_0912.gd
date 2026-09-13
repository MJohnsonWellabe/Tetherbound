extends "res://tests/test_case.gd"

## Static/source contracts for the OWNER-0912 companion evidence instrument.
## Rendering remains the production command in the capture tool's header; these
## checks keep a later cleanup from quietly replacing real controller/rest paths
## with posed fixture shortcuts while leaving plausible-looking PNGs behind.

const TOOL_PATH := "res://tools/capture_companion_terrapup_0912.gd"
const OPENING_PATH := "res://data/config/opening.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const CANDIDATES_PATH := "res://tests/fixtures/terrapup_rest_candidates_r34.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _source() -> String:
	return FileAccess.get_file_as_string(TOOL_PATH)


func test_capture_is_fresh_and_has_the_complete_eight_frame_plan() -> void:
	var source := _source()
	assert_true(source.contains("FRESH_OUTPUT.create_fresh"),
		"every run requires a new explicit evidence directory")
	assert_true(source.contains("manifest.json"), "the run writes a manifest")
	assert_true(source.contains("_planned_frames.size()"),
		"completion is checked against the authored plan")
	for frame: String in [
		"01-formation-settled-day", "02-formation-settled-night",
		"03-formation-left-motion-day", "04-formation-right-motion-day",
		"05-terrapup-lay-side-day", "06-terrapup-lay-three-quarter-day",
		"07-terrapup-lay-side-night", "08-terrapup-lay-three-quarter-night",
	]:
		assert_true(source.contains(frame), "capture plan retains %s" % frame)


func test_formation_uses_production_party_director_camera_and_input() -> void:
	var source := _source()
	for seam: String in [
		"meadows_playground.tscn", "EncounterDirector", "adopt_starter",
		"_party.call(\"add\"", "CameraRig/Camera3D", "Input.action_press",
		"move_forward", "move_left", "move_right", "is_closing",
	]:
		assert_true(source.contains(seam), "formation capture retains production seam %s" % seam)
	assert_true(source.contains("station_error_xz_m"),
		"manifest measures authored-station error")
	assert_true(source.contains("resolved_side_offset")
		and source.contains("authored_side_clearance_m"),
		"receipt measures the visual-envelope-aware centre target and authored clearance separately")
	assert_true(source.contains("resolved_forward_offset_m")
		and source.contains("resolved_station_distance_m")
		and source.contains("authored_visual_lead_height_ratio")
		and source.contains("target_camera_depth_m")
		and source.contains("actual_camera_depth_m"),
		"receipt proves the tall-body camera depth and complete production station")
	assert_true(source.contains("camera_axis_surface_clearance_m"),
		"manifest measures companion clearance from the camera/player axis")
	assert_true(source.contains("projected_frame_width_frac")
		and source.contains("projected_frame_area_frac")
		and source.contains("inside_fraction")
		and source.contains("MAX_FORMATION_PROJECTED_WIDTH_FRAC")
		and source.contains("MAX_FORMATION_PROJECTED_AREA_FRAC")
		and source.contains("MIN_FORMATION_INSIDE_FRAC"),
		"a giant body must fit by complete projected bounds instead of passing through viewport clipping")
	assert_true(source.contains("_formation_visual_problems(metrics)")
		and source.contains("refused camera-blocked production formation"),
		"camera-blocking formation frames fail closed before the shutter")
	assert_true(source.contains("func _wait_for_station() -> bool")
		and source.contains("companion station settle timed out"),
		"an obstructed formation fails with measured diagnostics instead of shipping warning-only frames")
	assert_true(source.contains("station_resume_distance")
		and source.contains("not bool(_companion.call(\"is_closing\"))"),
		"a settled companion is judged against the shipped hysteresis hold, not a tighter invented radius")
	var follower_source := FileAccess.get_file_as_string(
		"res://scripts/creatures/follower_creature.gd")
	var presence_source := FileAccess.get_file_as_string(
		"res://scripts/creatures/companion_presence.gd")
	assert_true(follower_source.contains("func safe_presence_approach_distance")
		and follower_source.contains("maxf(authored_distance, resolved_station_distance())")
		and follower_source.contains("func _safe_camera_forward()")
		and follower_source.contains("camera_depth_forward(camera_forward, fallback)")
		and presence_source.contains("safe_presence_approach_distance"),
		"late presence motion or diagonal travel cannot undo either camera-safe station axis")
	assert_true(follower_source.contains("func station_should_close")
		and follower_source.contains("leader_speed > 0.1")
		and source.contains("authored_moving_station_stop_m"),
		"moving frames do not prove the tighter production station response")
	assert_true(source.contains("const STAGE := Vector2(-145.0, 3390.0)")
		and source.contains("Stonewater walkable")
		and source.contains("final-far-country-thin-woods-03"),
		"formation runs in a native-frame-verified production clearing, not the lists stall or forested legacy stand")


func test_rest_uses_party_assignment_recall_and_the_real_resting_body() -> void:
	var source := _source()
	for seam: String in [
		"Stronghold", "recovery_point", "assign_creature", "RestingCreature",
		"_director.call(\"ally_body\") == null", "assigned_animation",
		"surface_get_arrays", "get_bone_global_pose", "get_bind_pose",
	]:
		assert_true(source.contains(seam), "rest capture retains production seam %s" % seam)
	assert_false(source.contains(".seek("), "capture must not inject an animation pose")
	assert_false(source.contains("set(\"resting\""),
		"capture must not bypass Party/CreatureBed with a direct resting write")
	assert_false(source.contains("call(\"play_rest\")"),
		"capture lets creature_bed.gd, not the instrument, trigger play_rest")


func test_rest_completion_requires_the_production_authored_prone_rest() -> void:
	var source := _source()
	assert_true(source.contains("rest_transition")
		and source.contains("rest_active")
		and source.contains("EXPECTED_REST_MODE")
		and source.contains("clip_role"),
		"the production bed receipt must activate the authored prone rest")
	assert_true(source.contains("rest_pose_receipt")
		and source.contains("pose_config.get(\"mode\"")
		and source.contains("pose_config.get(\"clip_role\"")
		and source.contains("posed_visual_height_ratio")
		and source.contains("min_ground_offset_m")
		and source.contains("max_ground_offset_m"),
		"rest capture fails closed on the authored clip and grounded live bounds")
	assert_false(source.contains(".seek("),
		"the evidence tool never injects a selected animation frame")


func test_r34_candidate_retains_r33_b_limbs_and_continues_the_core_roll() -> void:
	var source := _source()
	var fixture := _json(CANDIDATES_PATH)
	var candidates := fixture.get("candidates", []) as Array
	assert_eq(candidates.size(), 1, "R34 is one focused continuation of height-passing R33-B")
	assert_almost_eq(float(fixture.get("target_ground_offset_m", 99.0)), -0.10, 0.001,
		"the complete visible minimum targets shallow mattress penetration")
	assert_true(source.contains("--candidate-sheet")
		and source.contains("_capture_rest_candidate_sheet")
		and source.contains("assign_creature")
		and source.contains("RestingCreature")
		and source.contains("_begin_authored_rest_pose"),
		"one Meadows boot reaches the real bed before using the production pose function")
	assert_true(source.contains("expected_anchor.y + target - raw_posed.position.y")
		and source.contains("grounding_calibration_m")
		and source.contains("torso_lower_quartile_offset_m")
		and source.contains("torso_weight / total >= 0.35")
		and source.contains("posed_region_bounds")
		and source.contains("_posed_region_bounds(expected_anchor.y)"),
		"full-minimum grounding and independent torso/per-region receipts coexist")
	var candidate_source := source.get_slice("func _apply_and_ground_candidate", 1).get_slice(
		"func _wait_for_authored_pose", 0)
	assert_true(candidate_source.count(
		"_posed_total_vertices != _posed_skinned_vertices + _posed_unskinned_vertices") == 2
		and candidate_source.count("not _posed_surface_failures.is_empty()") == 2
		and candidate_source.contains("first pass produced incomplete posed bounds")
		and candidate_source.contains("grounded pass produced incomplete posed bounds"),
		"both candidate measurements fail closed unless every mesh surface is accounted for")
	assert_true(source.contains("strict_failures")
		and source.contains("strict_pass")
		and source.contains("captured obstructed/degraded diagnostic candidate frame")
		and source.contains("await _save_frame(frame_name, record)"),
		"a failed recipe remains a disclosed non-pass while both diagnostic views render")
	assert_false(source.contains("posed height ratio %.3f exceeds strict %.3f\" % [candidate_id"),
		"height rejection must not return before the review frames are written")
	for raw: Variant in candidates:
		var candidate := raw as Dictionary
		var config := candidate.get("config", {}) as Dictionary
		assert_eq(config.get("clip_role", ""), "faint",
			"R34 retains the production completed faint clip")
		assert_almost_eq(float(config.get("max_height_ratio", 99.0)), 0.82, 0.001,
			"R34 cannot loosen the height gate R33-B passed")
		assert_almost_eq(float(config.get("max_torso_contact_offset_m", 99.0)), 0.20, 0.001,
			"R34 cannot loosen the broad torso-contact gate")
		assert_almost_eq(float(config.get("min_ground_offset_m", 99.0)), -0.22, 0.001,
			"R34 keeps the complete-visible minimum floor")
		assert_almost_eq(float(config.get("max_ground_offset_m", 99.0)), 0.08, 0.001,
			"R34 keeps the complete-visible minimum ceiling")
		assert_eq(config.get("model_rotation_deg", []), [0.0, 0.0, 0.0],
			"R34 does not spend R33-B's height margin on a whole-model roll")
		var bones := config.get("bones", {}) as Dictionary
		assert_eq(bones.size(), 8, "%s changes only core and retained R33-B joints" % candidate.get("id", ""))
		for bone_name: String in bones:
			assert_true(bone_name in ["pelvis", "spine", "neck", "head", "front_upper_r",
				"front_lower_r", "rear_upper_r", "rear_lower_r"],
				"R34 excludes left limbs and unrelated anatomy")
			if bone_name.ends_with("_r"):
				var adjustment := bones.get(bone_name, {}) as Dictionary
				assert_true(not adjustment.has("position_offset")
					or adjustment.get("position_offset", []) == [0.0, 0.0, 0.0],
					"R34 cannot translate a paw away")
				for component: Variant in adjustment.get("rotation_deg", []):
					assert_true(absf(float(component)) <= 35.0,
						"R34 retained near-side fold stays within the restrained joint bound")
		var pelvis_rotation := (bones.get("pelvis", {}) as Dictionary).get("rotation_deg", []) as Array
		var spine_rotation := (bones.get("spine", {}) as Dictionary).get("rotation_deg", []) as Array
		var spine_position := (bones.get("spine", {}) as Dictionary).get("position_offset", []) as Array
		assert_true(float(pelvis_rotation[1]) <= -88.0
			and float(pelvis_rotation[1]) >= -94.0
			and absf(float(pelvis_rotation[2])) <= 8.0
			and float(spine_rotation[1]) <= -20.0
			and float(spine_rotation[1]) >= -32.0
			and float(spine_position[2]) <= -0.28
			and float(spine_position[2]) >= -0.36
			and absf(float(spine_rotation[2])) <= 8.0,
			"the pelvis/spine continue the proven side axis and settle the broad torso subset")
		var neck_rotation := (bones.get("neck", {}) as Dictionary).get("rotation_deg", []) as Array
		var head_rotation := (bones.get("head", {}) as Dictionary).get("rotation_deg", []) as Array
		assert_true(absf(float(neck_rotation[1])) <= 24.0
			and absf(float(head_rotation[1])) <= 36.0
			and absf(float(head_rotation[2])) <= 16.0,
			"neck/head finish remains bounded after the structural hierarchy turn")
		assert_eq((bones.get("front_upper_r", {}) as Dictionary).get("rotation_deg", []), [30.0, 6.0, 8.0],
			"R34 changes R33-B front-upper polarity")
		assert_eq((bones.get("front_lower_r", {}) as Dictionary).get("rotation_deg", []), [-35.0, 0.0, 8.0],
			"R34 changes R33-B front-lower polarity")
		assert_eq((bones.get("rear_upper_r", {}) as Dictionary).get("rotation_deg", []), [34.0, 8.0, 10.0],
			"R34 changes R33-B rear-upper polarity")
		assert_eq((bones.get("rear_lower_r", {}) as Dictionary).get("rotation_deg", []), [-35.0, 0.0, 8.0],
			"R34 changes R33-B rear-lower polarity")
	for required_region: String in ["torso", "head", "front_leg_l", "front_leg_r",
			"rear_leg_l", "rear_leg_r", "tail"]:
		assert_true(source.contains('"%s"' % required_region),
			"R34 reports and fail-closes the %s region" % required_region)
	assert_true(source.contains("cannot weaken the production faint/contact acceptance")
		and source.contains("permits only the measured R33-B hierarchy")
		and source.contains("must preserve R33-B's zero model adjustment")
		and source.contains("translation_limit := 0.05 if is_limb else 0.36")
		and source.contains("rotation_limit := 35.0 if is_limb else 40.0")
		and source.contains("pelvis_rotation.y > -88.0")
		and source.contains("must retain R33-B limb polarity exactly")
		and source.contains("spine must continue the core roll into broad contact"),
		"future fixture edits cannot weaken gates, translate limbs, or broaden the experiment")
	assert_true(source.contains("lowest_visible_region")
		and source.contains("grounding_control_regions")
		and source.contains("minimum <= ground_offset + 0.12"),
		"R34 names the anatomy controlling complete-visible-min grounding")


func test_rest_camera_uses_interior_seats_and_refuses_every_capture_diagnostic() -> void:
	var source := _source()
	assert_true(source.contains("var direction := -side if view == \"side\"")
		and source.contains("(-side - forward * 0.90).normalized()")
		and source.contains("view_direction"),
		"rest views stay on the room interior side of the west-wall bed")
	assert_true(source.contains("_terrain.call(\"set_camera\", camera)"),
		"Terrain3D must stream around the active rest evidence camera")
	assert_true(source.contains("CAPTURE_CHECK.fit_distance")
		and source.contains("Terrapup live rest pose")
		and source.contains("production creature bed"),
		"the camera fits both the measured live pose and its shipped bed")
	assert_true(source.contains("node is GeometryInstance3D")
		and source.contains("CampFillLight")
		and not source.contains("if node is VisualInstance3D:"),
		"bed framing cannot mistake a Light3D influence volume for visible bed geometry")
	assert_true(source.contains("CAPTURE_CHECK.readable_problems_for_camera")
		and source.contains("refused obstructed/degraded rest frame"),
		"subject framing, solid occlusion and every capture diagnostic fail closed")


func test_posed_bounds_accept_the_imported_float_bone_index_payload() -> void:
	var source := _source()
	assert_true(source.contains("func _bone_indices(raw: Variant) -> PackedInt32Array")
		and source.contains("raw is PackedFloat32Array")
		and source.contains("_bone_indices(raw_bones)"),
		"posed bounds normalize the production GLTF's integral-float bone indices")
	assert_false(source.contains(
		"arrays[Mesh.ARRAY_BONES] as PackedInt32Array"),
		"the capture must not repeat the Compatibility-renderer cast that aborted final-companion-03")
	assert_true(source.contains("posed_bone_payload_types")
		and source.contains("_record_payload_type(_posed_bone_payload_types, raw_bones)")
		and source.contains("type_string(typeof(raw))"),
		"a failed posed-bounds measurement identifies the imported bone payload type")


func test_posed_bounds_accept_paired_nil_unskinned_surfaces_without_weakening_skin_checks() -> void:
	var source := _source()
	assert_true(source.contains("var raw_weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]")
		and source.contains("func _bone_weights(raw: Variant) -> PackedFloat32Array")
		and source.contains("_bone_weights(raw_weights)"),
		"weights are normalized from Variant instead of crashing on a Nil surface slot")
	assert_false(source.contains(
		"arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array"),
		"the capture cannot repeat final-companion-05's unconditional Nil-to-packed cast")
	assert_true(source.contains("if raw == null:")
		and source.contains("if bones.is_empty() and weights.is_empty():")
		and source.contains("_posed_unskinned_vertices += vertices.size()"),
		"paired Nil bone/weight payloads use the honest MeshInstance transform")
	assert_true(source.contains("if bones.is_empty() != weights.is_empty():")
		and source.contains("bones.size() != weights.size()")
		and source.contains("unweighted_vertices")
		and source.contains("_posed_total_vertices != _posed_skinned_vertices + _posed_unskinned_vertices")
		and source.contains("or not _posed_surface_failures.is_empty()"),
		"malformed or incomplete skin payloads still fail the posed-bounds acceptance gate")
	assert_true(source.contains("posed_weight_payload_types")
		and source.contains("posed_surface_failures"),
		"failed reruns disclose both payload types and exact rejected surfaces")


func test_authored_formation_and_terrapup_rest_contracts_still_match_the_receipt() -> void:
	var opening := _json(OPENING_PATH)
	var follower := opening.get("follower", {}) as Dictionary
	assert_almost_eq(float(follower.get("side_offset", 0.0)), 1.8, 0.001,
		"the shipped companion station keeps 1.8m clear beyond its visual envelope")
	assert_almost_eq(float(follower.get("visual_clearance_height_ratio", 0.0)), 0.8, 0.001,
		"large-body visual extent grows the station without shrinking the creature")
	assert_almost_eq(float(follower.get("visual_lead_height_ratio", 0.0)), 1.6, 0.001,
		"large bodies retain enough rear-camera depth in motion without changing scale")
	assert_almost_eq(float(follower.get("back_offset", 0.0)), 0.5, 0.001,
		"the ordinary half-step authoring remains explicit before height-aware lead")
	assert_almost_eq(float(follower.get("moving_station_stop_distance", 0.0)), 0.35, 0.001,
		"moving giant companions cannot fall through the settled 1.6m hold band")
	assert_true(float(follower.get("side_offset", 0.0)) > float(follower.get("back_offset", 0.0)),
		"formation remains beside-not-behind")

	var species := _json(SPECIES_PATH).get("species", {}) as Dictionary
	var terrapup := (species.get("terrapup", {}) as Dictionary).get("placeholder", {}) as Dictionary
	assert_almost_eq(float(terrapup.get("rest_roll_deg", -999.0)), 0.0, 0.001,
		"Terrapup does not rotate its complete standing body")
	assert_true(bool(terrapup.get("rest_use_body_pose", false)),
		"bed and deployed-companion rest share the reversible CreatureBody path")
	var pose := terrapup.get("rest_pose", {}) as Dictionary
	assert_eq(str(pose.get("clip_role", "")), "faint",
		"the prone finish starts from the only suitable installed authored motion")
	var bones := pose.get("bones", {}) as Dictionary
	for bone_name: String in ["pelvis", "spine", "neck", "head",
			"front_upper_l", "front_upper_r", "rear_upper_l", "rear_upper_r"]:
		assert_true(bones.has(bone_name), "the contact pose includes %s" % bone_name)
	assert_true(float(pose.get("min_ground_offset_m", -99.0)) <= -0.20
		and float(pose.get("max_ground_offset_m", 99.0)) >= 0.0,
		"production evidence retains a bounded mattress-contact gate")
