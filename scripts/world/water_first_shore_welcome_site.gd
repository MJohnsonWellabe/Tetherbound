extends Node3D

## Runtime presentation for Water's authored `arrival_beacon` landmark. The
## landmark coordinate remains the nearby gameplay-camera viewpoint; this open
## signal arch sits ahead and clear of the authored First Shore route.

const CONFIG_PATH := "res://data/config/water_first_shore_welcome_site.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false
var _arch_bounds := AABB()


func build(water_world: Node3D) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("First Shore welcome site config is invalid")
		return
	var cfg := parsed as Dictionary
	var site := _v2(cfg.get("site_xz", []))
	var ground := _ground(water_world, site)
	if not is_finite(ground):
		push_error("First Shore welcome site received a non-finite terrain sample")
		return
	var yaw := deg_to_rad(float(cfg.get("facing_yaw_deg", 0.0)))
	var arch := _fit_height(str(cfg.get("arch_model", "")),
		float(cfg.get("arch_height_m", 5.4)), "WelcomeArch")
	if arch == null:
		return
	_arch_bounds = RENDER_BOUNDS.measure(arch)
	arch.position = Vector3(site.x, ground - _arch_bounds.position.y * arch.scale.y, site.y)
	arch.rotation.y = yaw
	arch.set_meta("welcome_role", "open_arch")
	add_child(arch)
	_add_pier_collision(arch, cfg)

	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	for side in [-1.0, 1.0]:
		var banner := _fit_height(str(cfg.get("banner_model", "")), 3.8,
			"WelcomeBannerWest" if side < 0.0 else "WelcomeBannerEast")
		if banner != null:
			var banner_bounds := RENDER_BOUNDS.measure(banner)
			banner.position = Vector3(site.x, ground - banner_bounds.position.y * banner.scale.y,
				site.y) + right * side * 2.65
			banner.rotation.y = yaw
			banner.set_meta("welcome_role", "banner")
			add_child(banner)
		var lantern := _fit_height(str(cfg.get("lantern_model", "")), 0.82,
			"WelcomeLanternWest" if side < 0.0 else "WelcomeLanternEast")
		if lantern != null:
			var lantern_bounds := RENDER_BOUNDS.measure(lantern)
			lantern.position = Vector3(site.x,
				ground + 2.75 - lantern_bounds.position.y * lantern.scale.y, site.y) \
				+ right * side * 1.65
			lantern.rotation.y = yaw
			lantern.set_meta("welcome_role", "lantern")
			add_child(lantern)
	_add_signal(cfg, Vector3(site.x, ground + float(cfg.get("arch_height_m", 5.4)), site.y))
	_add_approach_markers(cfg, water_world)


func _add_pier_collision(arch: Node3D, cfg: Dictionary) -> void:
	var opening := float(cfg.get("arch_opening_width_m", 2.0))
	var total_width := _arch_bounds.size.x * arch.scale.x
	var pier_width := maxf((total_width - opening) * 0.5, 0.25)
	var depth := maxf(_arch_bounds.size.z * arch.scale.z, 0.25)
	var height := _arch_bounds.size.y * arch.scale.y
	for side in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.name = "WelcomePierWest" if side < 0.0 else "WelcomePierEast"
		body.rotation.y = arch.rotation.y
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(pier_width, height, depth)
		shape_node.shape = shape
		body.add_child(shape_node)
		var local_x: float = side * (opening * 0.5 + pier_width * 0.5)
		body.position = arch.position + Basis(Vector3.UP, arch.rotation.y) * Vector3(
			local_x, _arch_bounds.get_center().y * arch.scale.y, 0.0)
		body.set_meta("welcome_role", "pier_collision")
		add_child(body)


func _add_signal(cfg: Dictionary, crown: Vector3) -> void:
	var packed := load(str(cfg.get("signal_scene", ""))) as PackedScene
	if packed == null:
		push_error("First Shore welcome signal scene is missing")
		return
	var signal_node := packed.instantiate() as Node3D
	if signal_node == null:
		push_error("First Shore welcome signal has no Node3D root")
		return
	signal_node.name = "WelcomeSignalFlame"
	signal_node.scale = Vector3.ONE * 1.45
	signal_node.position = crown + Vector3.UP * 0.06
	signal_node.set_meta("welcome_role", "signal_flame")
	add_child(signal_node)
	var light := OmniLight3D.new()
	light.name = "WelcomeSignalLight"
	light.position = crown + Vector3.UP * 1.2
	light.light_color = Color("f4a64a")
	light.light_energy = 1.65
	light.omni_range = 11.0
	light.shadow_enabled = false
	light.set_meta("welcome_role", "practical_light")
	add_child(light)


func _add_approach_markers(cfg: Dictionary, water_world: Node3D) -> void:
	var markers: Array = cfg.get("approach_markers", [])
	for index in markers.size():
		var spec := markers[index] as Dictionary
		var at := _v2(spec.get("at", []))
		if not is_finite(at.x) or not is_finite(at.y):
			push_error("First Shore welcome marker %d has no finite position" % index)
			continue
		var ground := _ground(water_world, at)
		if not is_finite(ground):
			push_error("First Shore welcome marker %d received non-finite ground" % index)
			continue
		var suffix := "South" if index == 0 else "North" if index == 1 else str(index)
		var base := _fit_height(str(spec.get("base_model", "")),
			float(spec.get("base_height_m", 1.0)), "WelcomeMarkerBase%s" % suffix)
		if base != null:
			var base_bounds := RENDER_BOUNDS.measure(base)
			base.position = Vector3(at.x, ground - base_bounds.position.y * base.scale.y, at.y)
			base.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
			base.set_meta("welcome_role", "approach_cairn")
			add_child(base)
		var torch := _fit_height(str(spec.get("torch_scene", "")),
			float(spec.get("torch_height_m", 2.1)), "WelcomeMarkerTorch%s" % suffix)
		if torch != null:
			var torch_bounds := RENDER_BOUNDS.measure(torch)
			torch.position = Vector3(at.x, ground + float(spec.get("torch_base_offset_m", 0.35)) \
				- torch_bounds.position.y * torch.scale.y, at.y)
			torch.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
			torch.set_meta("welcome_role", "approach_torch")
			add_child(torch)
		var light := OmniLight3D.new()
		light.name = "WelcomeMarkerLight%s" % suffix
		light.position = Vector3(at.x, ground + float(spec.get("torch_height_m", 2.1)), at.y)
		light.light_color = Color("f4a64a")
		light.light_energy = float(spec.get("light_energy", 0.72))
		light.omni_range = float(spec.get("light_range_m", 6.5))
		light.shadow_enabled = false
		light.set_meta("welcome_role", "approach_practical")
		add_child(light)


func _fit_height(path: String, height: float, id: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("First Shore welcome model missing: %s" % path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("First Shore welcome model has no Node3D root: %s" % path)
		return null
	node.name = id
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.y <= 0.001:
		node.free()
		push_error("First Shore welcome model has no measurable height: %s" % path)
		return null
	var factor := height / bounds.size.y
	node.scale = Vector3.ONE * factor
	node.position.y = -bounds.position.y * factor
	return node


func _ground(water_world: Node3D, at: Vector2) -> float:
	if water_world == null or not water_world.has_method("ground_height_at"):
		return NAN
	return float(water_world.call("ground_height_at", at.x, at.y))


static func point_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var delta := end - start
	if delta.length_squared() <= 0.000001:
		return point.distance_to(start)
	var amount := clampf((point - start).dot(delta) / delta.length_squared(), 0.0, 1.0)
	return point.distance_to(start + delta * amount)


static func route_edge_clearance(site: Vector2, footprint_radius: float,
		route_width: float, segments: Array) -> float:
	var clearance := INF
	for raw: Variant in segments:
		if raw is Array and (raw as Array).size() == 2:
			var segment := raw as Array
			clearance = minf(clearance, point_segment_distance(site,
				_v2(segment[0]), _v2(segment[1])) - footprint_radius - route_width * 0.5)
	return clearance


static func _v2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2.INF
