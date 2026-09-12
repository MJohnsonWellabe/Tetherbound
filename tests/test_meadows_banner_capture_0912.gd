extends "res://tests/test_case.gd"

## Static evidence-integrity contracts for OWNER-0912 Tier 2 #4. Runtime
## rendering remains the explicit command in the capture tool's header.

const TOOL_PATH := "res://tools/capture_meadows_banner_treatments_0912.gd"
const BAND1_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const RELAY_PATH := "res://data/config/tether_relay.json"
const TOURNAMENT_PATH := "res://data/config/tournament_ground_presentation.json"
const STRONGHOLD_PATH := "res://scripts/world/stronghold.gd"


func _source() -> String:
	return FileAccess.get_file_as_string(TOOL_PATH)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_capture_has_a_fresh_complete_sixteen_frame_plan() -> void:
	var source := _source()
	assert_true(source.contains("FRESH_OUTPUT.create_fresh"),
		"capture requires a fresh explicit output directory")
	assert_true(source.contains("manifest.json"), "capture writes a manifest")
	assert_true(source.contains("PLANNED_FRAMES.size()"),
		"completion is checked against the complete plan")
	for subject: String in [
		"roadside-full-standard", "relay-mounted-full-standard",
		"canopy-cloth-variants", "hall-hanging-banner",
	]:
		for view: String in ["ordinary", "close-oblique"]:
			for time_name: String in ["day", "night"]:
				assert_true(source.contains("%s-%s-%s" % [subject, view, time_name]),
					"plan retains %s/%s/%s" % [subject, view, time_name])


func test_capture_resolves_real_production_subjects_and_fails_closed() -> void:
	var source := _source()
	for seam: String in [
		"meadows_playground.tscn",
		"Props/tether_waypost/Banner_1",
		"TetherRelay/Gate/GateStandard_west",
		"Tournament/GroundPresentation/MarshalCanopy",
		"CanopyClothAccent_0", "CanopyClothAccent_1",
		"ExteriorBanner", "BannerBar", "BannerCloth",
		"planned subject '%s' is missing", "missing required production nodes",
		"CAPTURE_CHECK.problems", "readable_problems_for_camera",
	]:
		assert_true(source.contains(seam), "capture retains production seam %s" % seam)
	assert_true(source.contains('"body": focus'),
		"a production banner's own collision hierarchy is identified as its body, not a visual occluder")
	assert_true(source.contains("_pose_clear_camera"),
		"camera framing searches for a readable production-world seat")
	assert_true(source.contains("_camera_solid_at"),
		"camera seating rejects walls and other production solids before the shutter")
	assert_true(source.contains('"collision_free": true'),
		"the manifest records that each accepted seat was checked outside solids")
	assert_true(source.contains("ordinary_distance_scale"),
		"the tall Hall subject has a bounded contextual distance rather than crossing its room wall")
	assert_true(source.contains("close_distance_scale"),
		"complete standards are pulled back enough to remain subjects in a scene")


func test_capture_does_not_build_or_restyle_display_subjects() -> void:
	var source := _source()
	for forbidden: String in [
		"MeshInstance3D.new", "BoxMesh.new", "QuadMesh.new", "PlaneMesh.new",
		"apply_retint", "set_surface_override_material", "material_override =",
		"set_shader_parameter", "subject.duplicate", "visible = true",
	]:
		assert_false(source.contains(forbidden),
			"capture instrument must not inject or restyle subjects: %s" % forbidden)
	assert_true(source.contains("diagnostic evidence camera; production subject unchanged"),
		"manifest discloses the audit camera")


func test_selected_sites_still_consume_the_shipped_banner_families() -> void:
	var band1 := _json(BAND1_PATH)
	var waypost: Dictionary = {}
	for raw: Variant in band1.get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == "tether_waypost":
			waypost = cluster
			break
	assert_false(waypost.is_empty(), "production tether waypost remains authored")
	var standard := (waypost.get("props", []) as Array)[1] as Dictionary
	assert_eq(str(standard.get("model", "")), "Banner_1",
		"roadside subject remains the complete installed standard")
	assert_eq(str((standard.get("retint", {}) as Dictionary).get("MI_Banner", "")), "#7a2430",
		"roadside subject retains the shared oxblood cloth treatment")

	var relay := _json(RELAY_PATH)
	var heraldry := ((relay.get("gate", {}) as Dictionary).get("heraldry", {}) as Dictionary)
	assert_eq(str(heraldry.get("model", "")), "Banner_1",
		"Relay subject remains the same complete installed standard")
	assert_eq((heraldry.get("list", []) as Array).size(), 2,
		"Relay gate retains its authored mounted pair")

	var tournament := _json(TOURNAMENT_PATH)
	var canopy := tournament.get("marshal_canopy", {}) as Dictionary
	assert_eq(canopy.get("accent_models", []) as Array,
		["Banner_1_Cloth", "Banner_2_Cloth"],
		"capture still covers both installed cloth-only variants")

	var stronghold_source := FileAccess.get_file_as_string(STRONGHOLD_PATH)
	assert_true(stronghold_source.contains("const BANNER_CLOTH_SHADER"),
		"Hall hanging subject still consumes the shared cloth shader")
	assert_true(stronghold_source.contains(
		'm.set_shader_parameter("tails", 1.0 if torn else 2.0)'),
		"Hall subject retains its authored swallow-tail silhouette")
