extends "res://tests/test_case.gd"

const SITE := preload("res://scripts/world/water_first_shore_welcome_site.gd")


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 20.0 + x * 0.004 + z * 0.002


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))


func test_welcome_beacon_realizes_the_authored_landmark_clear_of_the_route() -> void:
	var cfg := _config()
	assert_eq(int(cfg.schema_version), 1)
	assert_eq(str(cfg.landmark_id), "arrival_beacon")
	for path: String in [cfg.arch_model, cfg.banner_model, cfg.lantern_model, cfg.signal_scene]:
		assert_true(ResourceLoader.exists(path), "%s is not an installed asset" % path)
	var site := SITE._v2(cfg.site_xz)
	var viewpoint := SITE._v2(cfg.viewpoint_xz)
	assert_true(viewpoint.distance_to(site) > 18.0 and viewpoint.distance_to(site) < 21.0,
		"the beacon must remain a legible midground subject from the production viewpoint")
	var clearance := SITE.route_edge_clearance(site, float(cfg.visible_footprint_radius_m),
		float(cfg.route_width_m), cfg.route_segments)
	assert_true(clearance > float(cfg.minimum_route_edge_clearance_m),
		"the complete visible beacon footprint must stay clear of both route edges: %.3fm" % clearance)
	var markers: Array = cfg.get("approach_markers", [])
	assert_eq(markers.size(), 2, "welcome approach needs one deliberate torch pair")
	for raw_marker: Variant in markers:
		var marker := raw_marker as Dictionary
		assert_true(ResourceLoader.exists(str(marker.get("base_model", ""))),
			"welcome cairn does not use an installed rock")
		assert_true(ResourceLoader.exists(str(marker.get("torch_scene", ""))),
			"welcome marker does not use the installed practical")
		var marker_at := SITE._v2(marker.get("at", []))
		assert_true(marker_at.distance_to(viewpoint) < viewpoint.distance_to(site),
			"approach marker is not between the canonical view and beacon")
		assert_true(marker_at.distance_to(site) < viewpoint.distance_to(site),
			"approach marker does not lead onward to the beacon")
		var marker_clearance := SITE.route_edge_clearance(marker_at,
			float(cfg.approach_marker_footprint_radius_m), float(cfg.route_width_m), cfg.route_segments)
		assert_true(marker_clearance > float(cfg.minimum_marker_route_edge_clearance_m),
			"welcome marker crowds a live First Shore route edge: %.3fm" % marker_clearance)


func test_welcome_beacon_builds_an_open_collidable_arch_and_practical_light() -> void:
	var cfg := _config()
	var world := GroundFixture.new()
	var site := SITE.new()
	world.add_child(site)
	site.build(world)
	assert_true(site.get_node_or_null("WelcomeArch") is Node3D)
	assert_true(site.get_node_or_null("WelcomeBannerWest") is Node3D)
	assert_true(site.get_node_or_null("WelcomeBannerEast") is Node3D)
	assert_true(site.get_node_or_null("WelcomeLanternWest") is Node3D)
	assert_true(site.get_node_or_null("WelcomeLanternEast") is Node3D)
	assert_true(site.get_node_or_null("WelcomeSignalFlame") is Node3D)
	var light := site.get_node_or_null("WelcomeSignalLight") as OmniLight3D
	assert_true(light != null and light.omni_range <= 11.01 and light.light_energy <= 1.66,
		"the crown flame owns one bounded practical light")
	for suffix: String in ["South", "North"]:
		var base := site.get_node_or_null("WelcomeMarkerBase%s" % suffix) as Node3D
		var torch := site.get_node_or_null("WelcomeMarkerTorch%s" % suffix) as Node3D
		var marker_light := site.get_node_or_null("WelcomeMarkerLight%s" % suffix) as OmniLight3D
		assert_true(base != null and str(base.get_meta("welcome_role", "")) == "approach_cairn")
		assert_true(torch != null and str(torch.get_meta("welcome_role", "")) == "approach_torch")
		assert_true(marker_light != null and marker_light.light_energy <= 0.73 \
			and marker_light.omni_range <= 6.51,
			"approach practical exceeds its small shore-marker role")
	var west := site.get_node_or_null("WelcomePierWest") as StaticBody3D
	var east := site.get_node_or_null("WelcomePierEast") as StaticBody3D
	assert_true(west != null and east != null, "only the two visible arch piers collide")
	assert_eq(site.find_children("*", "StaticBody3D", true, false).size(), 2,
		"visual approach markers must not add route collision")
	if west != null and east != null:
		var west_box := (west.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var east_box := (east.get_child(0) as CollisionShape3D).shape as BoxShape3D
		assert_almost_eq(west_box.size.x, east_box.size.x, 0.0001)
		var actual_gap := west.position.distance_to(east.position) - west_box.size.x
		assert_almost_eq(actual_gap, float(cfg.arch_opening_width_m), 0.02,
			"the collision throat matches the authored opening")
	world.free()
