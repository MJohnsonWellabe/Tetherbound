extends "res://tests/test_case.gd"

## Static evidence-integrity contracts for OWNER-0912 Tier 2 #4. Runtime
## rendering remains the explicit command in the capture tool's header.

const TOOL_PATH := "res://tools/capture_meadows_banner_treatments_0912.gd"
const BAND1_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const RELAY_PATH := "res://data/config/tether_relay.json"
const TOURNAMENT_PATH := "res://data/config/tournament_ground_presentation.json"
const STRONGHOLD_PATH := "res://scripts/world/stronghold.gd"
const STRONGHOLD_CONFIG_PATH := "res://data/config/stronghold.json"
const PREFAB_PATH := "res://scripts/world/building_prefabs.gd"
const STANDARD_CLOTH_SHADER := \
	"res://assets/props/quaternius_fantasy/banner_dimensional_cloth.gdshader"


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
	assert_true(source.contains('"body": _production_collision_owner(focus)'),
		"a production banner's exact collision ownership is identified as its body, not a visual occluder")
	assert_true(source.contains('NodePath("%s_Collision" % focus.name)')
		and source.contains("sibling is CollisionObject3D"),
		"props.gd's sibling collision contract is handled without excluding unrelated cluster props")
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
	assert_true(source.contains("minimum_horizontal_depth_m")
		and source.contains("production cloth depth"),
		"Hall proof fails closed if production geometry regresses to a shallow plane")


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
	var roadside_cloth := (standard.get("retint", {}) as Dictionary).get(
		"MI_Banner", {}) as Dictionary
	assert_eq(str(roadside_cloth.get("color", "")), "#7a2430",
		"roadside subject retains the shared oxblood cloth treatment")
	assert_eq(str(roadside_cloth.get("profile", "")), "dimensional_cloth",
		"roadside subject no longer colour-multiplies the dark/cyan cloth atlas")

	var relay := _json(RELAY_PATH)
	var heraldry := ((relay.get("gate", {}) as Dictionary).get("heraldry", {}) as Dictionary)
	assert_eq(str(heraldry.get("model", "")), "Banner_1",
		"Relay subject remains the same complete installed standard")
	assert_eq((heraldry.get("list", []) as Array).size(), 2,
		"Relay gate retains its authored mounted pair")
	assert_eq(str(heraldry.get("cloth_profile", "")), "dimensional_cloth",
		"Relay pair consumes the shared dimensional cloth profile")

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
	assert_true(stronghold_source.contains("func _folded_banner_mesh")
		and stronghold_source.contains("panel.mesh = _folded_banner_mesh")
		and stronghold_source.contains('set_shader_parameter("authored_relief", 1.0)'),
		"Hall cloth is authored as a folded ArrayMesh instead of a shallow QuadMesh")


func test_shared_standard_profile_preserves_colour_weave_and_geometry() -> void:
	assert_true(ResourceLoader.exists(STANDARD_CLOTH_SHADER),
		"dimensional standard cloth shader remains installed")
	var shader_source := FileAccess.get_file_as_string(STANDARD_CLOTH_SHADER)
	for seam: String in [
		"source_value", "cloth_colour", "cloth_wave", "VERTEX.z +=",
		"weave", "emission_floor",
	]:
		assert_true(shader_source.contains(seam), "standard cloth retains %s" % seam)
	var prefab_source := FileAccess.get_file_as_string(PREFAB_PATH)
	assert_true(prefab_source.contains('profile == "dimensional_cloth"')
		and prefab_source.contains('_surface_bounds(mi.mesh, surface)')
		and prefab_source.contains('set_shader_parameter("source_texture"'),
		"production retint path installs the profile from real surface bounds and atlas detail")


func test_canopy_night_exposure_is_bounded_and_instance_local() -> void:
	var tournament := _json(TOURNAMENT_PATH)
	var canopy := tournament.get("marshal_canopy", {}) as Dictionary
	assert_between(float(canopy.get("cloth_emission_floor", 0.0)), 0.03, 0.08,
		"canopy cloth keeps a restrained night exposure floor")
	assert_true(float(canopy.get("lantern_emission_energy", 99.0)) <= 0.65,
		"visible canopy lantern cannot return to round 05's clipped source")
	assert_between(float(canopy.get("lantern_below_roof_m", 0.0)), 1.15, 1.35,
		"the visible globe clears the lower valance instead of being sliced at its equator")
	assert_between(float(canopy.get("lantern_visible_side_offset_m", 0.0)), 0.5, 0.75,
		"the globe sits on the visible interior side rather than behind the front swag")
	assert_between(float(canopy.get("lantern_hanger_length_m", 0.0)), 0.2, 0.36,
		"the separated globe retains a restrained readable attachment")
	assert_true(float(canopy.get("light_range_m", 99.0)) <= 5.0,
		"existing practical remains bounded to the canopy")
	var production := FileAccess.get_file_as_string(
		"res://scripts/world/tournament_ground_presentation.gd")
	for seam: String in ["_apply_canopy_cloth_exposure(stall, spec)",
			"_apply_canopy_cloth_exposure(accent, spec)",
			'source.resource_name != "MI_Banner"', "source.duplicate()",
			"material.emission_texture = material.albedo_texture",
			"material.backlight_enabled = true",
			'lantern_drop := float(spec.get("lantern_below_roof_m"',
			'lantern_visible_side := float(spec.get("lantern_visible_side_offset_m"',
			'hanger.name = "MarshalLanternHanger"',
			"set_surface_override_material(surface, material)"]:
		assert_true(production.contains(seam), "canopy production retains %s" % seam)
	assert_false(production.contains("surface_set_material(surface, material)"),
		"canopy treatment cannot mutate the shared kit mesh material")


func test_hall_banner_foliage_cleanup_is_bounded_to_the_breach_growth() -> void:
	var stronghold := _json(STRONGHOLD_CONFIG_PATH)
	var arena_growth := 0
	var reclaim := (((stronghold.get("hall_occupation", {}) as Dictionary).get(
		"reclaim", {}) as Dictionary).get("ivy", []) as Array)
	assert_false(reclaim.is_empty(), "Hall reclaim layer remains production-authored")
	for raw: Variant in reclaim:
		var band := raw as Dictionary
		if str(band.get("_comment_0912", "")).contains("BANNER-TREATMENT"):
			arena_growth += int(band.get("count", 0))
			assert_true(float(band.get("scale_max", 99.0)) <= 1.55,
				"breach foliage stays below banner-obscuring scale")
	assert_eq(arena_growth, 14,
		"breach foliage cannot return to the 32 oversized leaves that obscured heraldry")
