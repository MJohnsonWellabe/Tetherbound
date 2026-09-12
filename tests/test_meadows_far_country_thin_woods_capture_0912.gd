extends "res://tests/test_case.gd"

## The visual gate for OWNER-0912 T2 #9/#10 must stay tied to production data.
## These checks are deliberately source-level: the capture itself is a GPU run,
## while this suite can still fail fast when somebody turns it into a stage,
## drops a day/night pair, or stops proving one of the named clearings.

const HARNESS := "res://tools/capture_meadows_far_country_thin_woods_0912.gd"
const RIFT_CONFIG := "res://data/config/rift_collapse.json"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const B2 := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const B3 := "res://data/config/bands/band3_the_river_lock/vegetation.json"


func _source() -> String:
	return FileAccess.get_file_as_string(HARNESS)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _clearing(path: String, id: String) -> Dictionary:
	for raw: Variant in (_json(path).get("clearings", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func test_receipt_uses_one_production_world_and_exact_named_sources() -> void:
	var source := _source()
	assert_true(source.contains('const SCENE := "res://scenes/world/meadows_playground.tscn"'),
		"capture boots the production Meadows scene")
	for required: String in [RIFT_CONFIG, TERRAIN_CONFIG, B2, B3,
			"warrens_walkable_thin_wood", "stonewater_walkable_thin_wood",
			"RiftCollapse/FarCountry", "res://tools/_capture_corridor.gd#07-band2-mid"]:
		assert_true(source.contains(required), "capture names production contract %s" % required)
	assert_true(source.contains("shell_build_complete"), "capture waits for the complete production shell")
	assert_true(source.contains("FRESH_OUTPUT.create_fresh"), "capture refuses stale/mixed output")
	assert_true(source.contains("CAPTURE_CHECK.problems"), "capture runs shared integrity checks")
	assert_true(source.contains('get_node_or_null(^"Vegetation")'), "capture reads production scatter")
	assert_true(source.contains('get("_collision_batches")'), "manifest measures live blocking scatter")
	assert_true(source.contains("update_collision_streaming"), "scatter collision follows each evidence eye")
	assert_true(source.contains('has_method("set_camera")'), "Terrain3D follows each evidence eye")


func test_receipt_is_eight_complete_ordinary_height_day_night_frames() -> void:
	var source := _source()
	var planned := [
		"01-post-warden-far-country-day", "02-post-warden-far-country-night",
		"03-warrens-thin-woods-day", "04-warrens-thin-woods-night",
		"05-stonewater-thin-woods-day", "06-stonewater-thin-woods-night",
		"07-dense-woods-control-day", "08-dense-woods-control-night",
	]
	for frame: String in planned:
		assert_true(source.contains('"%s"' % frame), "planned frame is explicit: %s" % frame)
	assert_eq(source.count("-day\""), 4, "exactly four planned day frames")
	assert_eq(source.count("-night\""), 4, "exactly four planned night frames")
	assert_true(source.contains("const EYE_HEIGHT_M := 1.70"), "all views use ordinary player eye height")
	assert_true(source.contains("actual_names == PLANNED_FRAMES"), "manifest fails closed on order/completeness")
	assert_true(source.contains("Vector2i(image.get_width(), image.get_height()) != IMAGE_SIZE"),
		"capture refuses the wrong viewport size")
	assert_true(source.contains("bytes < MIN_PNG_BYTES"), "capture refuses implausibly empty PNGs")


func test_capture_sets_real_post_warden_state_before_world_instantiation() -> void:
	var source := _source()
	var set_at := source.find('(progression as Object).call("set_flag", FAR_FLAG, true)')
	var instantiate_at := source.find("_world = packed.instantiate()")
	assert_true(set_at >= 0 and instantiate_at > set_at,
		"persisted Warden flag is set before the production world is instantiated")
	assert_true(source.contains('bool(horizon.get("collapsed", false))'),
		"receipt verifies the runtime post-Warden horizon state")
	assert_true(source.contains('float(horizon.get("storm_cover", 1.0)) > 0.01'),
		"receipt rejects a horizon where the old storm wall remains")


func test_far_country_receipt_checks_distance_contrast_and_non_gameplay_geometry() -> void:
	var source := _source()
	for required: String in ["distance\", 0.0)) < 600.0", "alpha\", 1.0)) > 0.5",
			"distance < 600.0", "alpha > 0.5",
			"CollisionObject3D", "CollisionShape3D", "NavigationRegion3D",
			"NavigationLink3D", "NavigationObstacle3D", 'has_method("interact")',
			"max_mesh_height_fraction", "0.28"]:
		assert_true(source.contains(required), "far-country capture gate includes %s" % required)
	var rift := _json(RIFT_CONFIG)
	assert_eq(str(rift.get("flag", "")), "legendary_freed")
	assert_eq(str(rift.get("spoke", "")), "storm_road")
	var found_spoke := false
	for raw: Variant in (_json(TERRAIN_CONFIG).get("spokes", {}).get("routes", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "storm_road":
			found_spoke = not ((raw as Dictionary).get("road", []) as Array).is_empty() \
				and (raw as Dictionary).get("far_road", {}) is Dictionary
	assert_true(found_spoke, "the capture's far-country eye resolves from the authored storm-road seam")


func test_thin_wood_views_are_inside_named_partial_clearings_and_control_is_outside() -> void:
	for spec: Array in [
		[B2, "warrens_walkable_thin_wood", Vector2(15.0, -28.0), Vector2(-20.0, 20.0)],
		[B3, "stonewater_walkable_thin_wood", Vector2(-25.0, -30.0), Vector2(20.0, 30.0)],
	]:
		var clearing := _clearing(str(spec[0]), str(spec[1]))
		assert_false(clearing.is_empty(), "%s remains authored" % str(spec[1]))
		var radius := float(clearing.get("radius", 0.0))
		assert_true((spec[2] as Vector2).length() < radius, "thin-wood eye stays inside clearing")
		assert_true((spec[3] as Vector2).length() < radius, "thin-wood look stays inside clearing")
		assert_between(float(clearing.get("retain_fraction", 0.0)), 0.2, 0.5,
			"named clearing remains partial rather than bald or dense")
	var control := Vector2(-5.0, 2142.0)
	for path: String in [B2, B3]:
		for raw: Variant in (_json(path).get("clearings", []) as Array):
			var clearing := raw as Dictionary
			var centre := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
			assert_true(control.distance_to(centre) >= float(clearing.get("radius", 0.0)),
				"dense control sample stays outside clearing order %s" % str(clearing.get("order", "?")))


func test_capture_cannot_inject_visual_or_gameplay_fixtures() -> void:
	var source := _source()
	for forbidden: String in ["MeshInstance3D.new()", "StandardMaterial3D.new()",
			"DirectionalLight3D.new()", "OmniLight3D.new()", "SpotLight3D.new()",
			"WorldEnvironment.new()", "CollisionShape3D.new()", "Area3D.new()"]:
		assert_false(source.contains(forbidden), "capture must not inject %s" % forbidden)
	assert_false(source.contains("_far_country.visible = true"),
		"capture cannot reveal the subject by visibility override")
