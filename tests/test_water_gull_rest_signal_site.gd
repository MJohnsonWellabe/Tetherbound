extends "res://tests/test_case.gd"

const SITE := preload("res://scripts/world/water_gull_rest_signal_site.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const WALL_MODEL := "res://assets/buildings/quaternius_medieval/Wall_Plaster_WoodGrid.gltf"
const BALCONY_MODEL := "res://assets/buildings/quaternius_medieval/Balcony_Cross_Straight.gltf"


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 20.0 + x * 0.025 + z * 0.004


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))


func test_signal_spire_is_an_installed_bounded_gull_rest_composition() -> void:
	var cfg := _config()
	assert_eq(int(cfg.schema_version), 1)
	assert_eq(str(cfg.landmark_id), "gull_rest_signal_spire")
	assert_eq(cfg.landmark_xz, [-72.615, 899.886])
	assert_eq(cfg.site_xz, [-70.0, 881.5])
	assert_eq((cfg.supports as Array).size(), 4)
	assert_eq((cfg.rails as Array).size(), 4)
	for raw: Variant in cfg.supports:
		assert_eq(str((raw as Dictionary).model), WALL_MODEL,
			"the signal shaft must use the installed textured timber-grid wall")
	for raw: Variant in cfg.rails:
		assert_eq(str((raw as Dictionary).model), BALCONY_MODEL,
			"the platform edge must use the installed modeled cross balcony")
	for raw: Variant in (cfg.supports as Array) + (cfg.rails as Array) + [cfg.platform]:
		var spec := raw as Dictionary
		assert_true(ResourceLoader.exists(str(spec.model)), "%s is not an installed model" % str(spec.model))
	assert_true(ResourceLoader.exists(str(cfg.signal.scene)), "the installed signal flame is missing")
	var site := SITE._v2(cfg.site_xz)
	var clearance := SITE.route_edge_clearance(site, float(cfg.visible_footprint_radius_m),
		float(cfg.route_width_m), cfg.route_segments)
	assert_true(clearance > float(cfg.minimum_edge_clearance_m),
		"the whole visible footprint must clear both adjacent route segments by more than six metres")
	assert_true(site.distance_to(SITE._v2(cfg.landmark_xz)) < 20.0,
		"the signal must still compose as the named waypoint's landmark")


func test_initialized_signal_site_geometry_passes_without_engine_errors() -> void:
	var run_id := "%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	var child_path := ProjectSettings.globalize_path(
		"res://tests/helpers/gull_rest_signal_site_initialized.gd")
	var log_path := ProjectSettings.globalize_path(
		"user://gull-rest-signal-site-child-%s.log" % run_id)
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", child_path,
		"--log-file", log_path], output, true)
	var result: Variant = null
	var engine_errors: Array[String] = []
	var result_lines := FileAccess.get_file_as_string(log_path).split("\n") \
		if FileAccess.file_exists(log_path) else PackedStringArray()
	for line: String in result_lines:
		var clean := line.strip_edges()
		if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:"):
			engine_errors.append(clean)
			print("[gull-rest-signal-child] " + clean)
		if line.begins_with("GULL_REST_SIGNAL_SITE_RESULT="):
			result = JSON.parse_string(line.trim_prefix("GULL_REST_SIGNAL_SITE_RESULT="))
	for chunk: String in output:
		for line: String in chunk.split("\n"):
			var clean := line.strip_edges()
			if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:"):
				engine_errors.append(clean)
				print("[gull-rest-signal-child] " + clean)
	assert_eq(engine_errors, [], "initialized signal-site child emits no engine errors")
	assert_eq(code, 0, "initialized signal-site child exits cleanly: %s" % "\n".join(output))
	assert_true(result is Dictionary, "initialized child returns structured geometry assertions")
	if result is Dictionary:
		assert_eq(int(result.get("assertions", -1)), 60,
			"initialized child executes the complete geometry assertion set")
		assert_eq(result.get("failures", []), [], "initialized signal-site geometry passes")


func _case_supports_touch_terrain_reach_one_platform_and_match_collision() -> void:
	var cfg := _config()
	var world := GroundFixture.new()
	var site := SITE.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
	world.add_child(site)
	site.build(world)
	assert_true(is_finite(site.platform_y()))
	var supports: Array[Node3D] = []
	var collisions: Array[StaticBody3D] = []
	for child: Node in site.get_children():
		if str(child.get_meta("signal_role", "")) == "terrain_support":
			supports.append(child as Node3D)
		elif str(child.get_meta("signal_role", "")) == "support_collision":
			collisions.append(child as StaticBody3D)
	assert_eq(supports.size(), 4)
	assert_eq(collisions.size(), 4)
	for support: Node3D in supports:
		var bounds := RENDER_BOUNDS.measure(support)
		assert_almost_eq(bounds.size.x, 2.0000005, 0.0001,
			"the imported wall width changed from the measured installed asset")
		assert_almost_eq(bounds.size.y, 3.1226888, 0.0001,
			"the imported wall height changed from the measured installed asset")
		assert_almost_eq(bounds.size.z, 0.4064820, 0.0001,
			"the imported wall depth changed from the measured installed asset")
		var bottom := support.position.y + bounds.position.y * support.scale.y
		var top := support.position.y + bounds.end.y * support.scale.y
		assert_almost_eq(bottom, float(support.get_meta("terrain_foot_y")), 0.001,
			"a signal support is floating above or buried below its sampled foot")
		assert_almost_eq(top, site.platform_y(), 0.001,
			"the terrain-fitted support does not meet the common platform")
		var body := site.get_node(NodePath(str(support.name) + "Collision")) as StaticBody3D
		assert_true(body != null)
		var shape_node := body.get_child(0) as CollisionShape3D
		var box := shape_node.shape as BoxShape3D
		assert_eq(box.size, Vector3(bounds.size.x * support.scale.x,
			bounds.size.y * support.scale.y, bounds.size.z * support.scale.z),
			"support collision does not match the final visible AABB")
		var expected_centre := support.position + Basis(Vector3.UP, support.rotation.y) * Vector3(
			bounds.get_center().x * support.scale.x, bounds.get_center().y * support.scale.y,
			bounds.get_center().z * support.scale.z)
		assert_true(body.position.distance_to(expected_centre) <= 0.001,
			"support collision centre does not match the transformed visible wall")
		assert_almost_eq(body.rotation.y, support.rotation.y, 0.0001,
			"support collision yaw does not match the transformed visible wall")
	var balconies: Array[Node3D] = []
	for child: Node in site.get_children():
		if str(child.get_meta("signal_role", "")) == "rail":
			balconies.append(child as Node3D)
	assert_eq(balconies.size(), 4)
	for balcony: Node3D in balconies:
		var bounds := RENDER_BOUNDS.measure(balcony)
		assert_almost_eq(bounds.size.x, 2.0000007, 0.0001,
			"the imported balcony width changed from the measured installed asset")
		assert_almost_eq(bounds.size.y, 1.2298867, 0.0001,
			"the imported balcony height changed from the measured installed asset")
		assert_almost_eq(bounds.size.z, 0.2062830, 0.0001,
			"the imported balcony depth changed from the measured installed asset")
		var bottom := balcony.position.y + bounds.position.y * balcony.scale.y
		assert_almost_eq(bottom, site.platform_y(), 0.001,
			"a modeled balcony edge does not meet the platform")
	var signal_node := site.get_node_or_null("SignalFlame") as Node3D
	var light := site.get_node_or_null("SignalLight") as OmniLight3D
	assert_true(signal_node != null and light != null)
	assert_true(light.position.y > site.platform_y() and light.omni_range <= 9.0,
		"the light must remain a bounded practical at the visible flame")
	var centre := SITE._v2(cfg.site_xz)
	var actual_radius := 0.0
	for child: Node in site.get_children():
		if child is not Node3D or str(child.get_meta("signal_role", "")) in ["support_collision", "practical_light"]:
			continue
		var piece := child as Node3D
		var bounds := RENDER_BOUNDS.measure(piece)
		var yaw := Basis(Vector3.UP, piece.rotation.y)
		for local_x: float in [bounds.position.x, bounds.end.x]:
			for local_z: float in [bounds.position.z, bounds.end.z]:
				var corner := piece.position + yaw * Vector3(local_x * piece.scale.x, 0.0,
					local_z * piece.scale.z)
				actual_radius = maxf(actual_radius, Vector2(corner.x, corner.z).distance_to(centre))
	assert_true(actual_radius > 2.3 and actual_radius <= float(cfg.visible_footprint_radius_m),
		"declared signal footprint does not contain the transformed installed meshes")
	var actual_clearance := SITE.route_edge_clearance(centre, actual_radius,
		float(cfg.route_width_m), cfg.route_segments)
	assert_true(actual_clearance > float(cfg.minimum_edge_clearance_m),
		"the transformed installed meshes do not retain six metres beyond both route edges")
	world.free()
