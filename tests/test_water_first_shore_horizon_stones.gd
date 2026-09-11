extends "res://tests/test_case.gd"

const SITE := preload("res://scripts/world/water_first_shore_horizon_stones.gd")
const WATER_WORLD := preload("res://scripts/world/water_world.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const WORLD_CONFIG := "res://data/config/water_world.json"


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 20.0 + x * 0.004 + z * 0.002


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))


func test_horizon_stones_frame_the_authored_view_clear_of_the_live_route() -> void:
	var cfg := _config()
	assert_eq(int(cfg.schema_version), 1)
	assert_eq(str(cfg.landmark_id), "first_shore_horizon_stones")
	var viewpoint := SITE._v2(cfg.viewpoint_xz)
	var site := SITE._v2(cfg.site_xz)
	var heading := SITE._v2(cfg.view_heading_xz).normalized()
	var to_site := (site - viewpoint).normalized()
	assert_true(viewpoint.distance_to(site) >= 19.0 and viewpoint.distance_to(site) <= 22.0,
		"the stones must read as a midground frame from the catalogue seat")
	assert_true(heading.dot(to_site) > 0.98,
		"the stone aperture drifted out of the authored northward horizon view")
	var clearance := SITE.route_edge_clearance(site, float(cfg.visible_footprint_radius_m),
		float(cfg.route_width_m), cfg.route_segments)
	assert_true(clearance > float(cfg.minimum_route_edge_clearance_m),
		"the complete visual footprint crowds the live First Shore exploration spine: %.3fm" % clearance)
	var stones: Array = cfg.get("stones", [])
	assert_eq(stones.size(), 3, "the named location needs its asymmetric three-stone identity")
	var heights: Array[float] = []
	var outer_markers: Array[Dictionary] = []
	for raw: Variant in stones:
		var spec := raw as Dictionary
		assert_true(ResourceLoader.exists(str(spec.model)), "%s is not an installed rock" % str(spec.model))
		var size: Array = spec.get("size_m", [])
		assert_eq(size.size(), 3, "%s needs explicit final XYZ bounds" % str(spec.id))
		if size.size() == 3:
			heights.append(float(size[1]))
			assert_true(float(size[0]) <= 2.4 and float(size[2]) <= 1.8,
				"%s can regress into a giant slab" % str(spec.id))
		if str(spec.id) != "SightStone":
			outer_markers.append(spec)
	heights.sort()
	assert_true(heights[0] < 2.0 and heights[2] >= 6.3,
		"the low sighting stone and tall horizon marker lost their silhouette hierarchy")
	var west := outer_markers[0]
	var east := outer_markers[1]
	var open_gap := absf(float(east.offset_xz[0]) - float(west.offset_xz[0])) \
		- float(west.size_m[0]) * 0.5 - float(east.size_m[0]) * 0.5
	assert_true(open_gap >= 8.0, "the two uprights no longer leave a real open horizon aperture")


func test_horizon_stones_build_grounded_visuals_and_bounded_night_practicals() -> void:
	var world := GroundFixture.new()
	var presentation := SITE.new()
	world.add_child(presentation)
	presentation.build(world)
	for id: String in ["WestMarker", "EastMarker", "SightStone"]:
		var stone := presentation.get_node_or_null(NodePath(id)) as Node3D
		assert_true(stone != null, "horizon composition lost %s" % id)
		if stone != null:
			assert_true(is_finite(float(stone.get_meta("terrain_contact_y", NAN))),
				"%s no longer records a finite terrain contact" % id)
			var expected: Array = stone.get_meta("authored_size_m", [])
			var source_bounds := RENDER_BOUNDS.measure(stone)
			var actual := source_bounds.size * stone.scale
			assert_true(expected.size() == 3 and actual.is_equal_approx(Vector3(
				float(expected[0]), float(expected[1]), float(expected[2]))),
				"%s does not render at its bounded trainer-scale silhouette" % id)
	for id: String in ["WestLantern", "EastLantern"]:
		assert_true(presentation.get_node_or_null(NodePath(id)) is Node3D,
			"horizon composition lost %s" % id)
		var light := presentation.get_node_or_null(NodePath("%sLight" % id)) as OmniLight3D
		assert_true(light != null and light.light_energy <= 1.03 and light.omni_range <= 8.51,
			"%s exceeds its small base-practical budget" % id)
	assert_true(presentation.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"viewpoint dressing changed First Shore traversal collision")
	world.free()


func test_production_mount_and_authoritative_landmark_remain_registered() -> void:
	assert_true(WATER_WORLD != null, "production Water world no longer parses")
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG))
	var landmark := _entry(world.get("landmarks", []), "first_shore_horizon_stones")
	assert_eq(landmark.get("position", []), [-63.636, 24.812, 75.838],
		"the authoritative map/catalogue viewpoint moved during visual recovery")
	assert_eq(str(landmark.get("role", "")), "viewpoint_to_veilfall",
		"the stones lost their authored horizon-view role")
	var source := FileAccess.get_file_as_string("res://scripts/world/water_world.gd")
	assert_true(source.contains('horizon_stones.name = "FirstShoreHorizonStones"') and
		source.contains("horizon_stones.build(self)"),
		"production Water does not mount the Horizon Stones presentation")


func _entry(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == wanted:
			return raw as Dictionary
	return {}
