extends Node3D

## Open, terrain-fitted replacement for the solid Windscar beacon skin.

const CONFIG_PATH := "res://data/config/cloudreach_windscar_beacon_visual.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false
var _frame_base_y := NAN
var _world_anchor := Vector3.ZERO


func build(world: Node3D, masonry: Material, world_anchor: Vector3) -> void:
	if _built:
		return
	_built = true
	_world_anchor = world_anchor
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Windscar beacon visual config is invalid")
		return
	var cfg := parsed as Dictionary
	var arch_packed := load(str(cfg.arch_scene)) as PackedScene
	var brace_packed := load(str(cfg.brace_scene)) as PackedScene
	var signal_packed := load(str(cfg.signal_scene)) as PackedScene
	if arch_packed == null or brace_packed == null or signal_packed == null:
		push_error("Windscar beacon installed visual kit is incomplete")
		return
	var heading := _v2(cfg.stand_heading_xz).normalized()
	var right := Vector2(heading.y, -heading.x)
	var site_offset := heading * float(cfg.forward_offset_m)
	var scale_values := cfg.arch_scale as Array
	var arch_scale := Vector3(float(scale_values[0]), float(scale_values[1]), float(scale_values[2]))
	var aperture := cfg.source_aperture_rect_m as Dictionary
	var post_centre_x := (1.0 + float(aperture.half_width)) * 0.5 * arch_scale.x
	var frame_depths := cfg.frame_depth_offsets_m as Array
	var feet: Array[Dictionary] = []
	for raw_depth: Variant in frame_depths:
		var depth := float(raw_depth)
		for side: float in [-1.0, 1.0]:
			var xz := site_offset + right * (post_centre_x * side) + heading * depth
			var ground := _ground(world, _world_anchor.x + xz.x, _world_anchor.z + xz.y)
			if not is_finite(ground):
				push_error("Windscar beacon received non-finite support terrain")
				return
			feet.append({"xz": xz, "ground": ground, "depth": depth, "side": side})
	_frame_base_y = float(feet[0].ground)
	for foot: Dictionary in feet:
		_frame_base_y = maxf(_frame_base_y, float(foot.ground))
	var local_base_y := _frame_base_y - _world_anchor.y
	for frame_index in frame_depths.size():
		_add_arch_frame(arch_packed, frame_index, float(frame_depths[frame_index]), heading,
			right, site_offset, arch_scale, local_base_y, aperture)
	for foot: Dictionary in feet:
		_add_foundation(foot, local_base_y, masonry, cfg)
	_add_upper_braces(brace_packed, heading, right, site_offset, arch_scale, local_base_y, frame_depths)
	_add_route_banners(cfg, heading, right, site_offset, arch_scale, local_base_y)
	_add_grounding_outcrops(world, masonry, heading, right, cfg)
	_add_signal(signal_packed, site_offset, local_base_y + arch_scale.y * 3.0, cfg)


func frame_base_y() -> float:
	return _frame_base_y


func _add_arch_frame(packed: PackedScene, index: int, depth: float, heading: Vector2,
		right: Vector2, site_offset: Vector2, arch_scale: Vector3, base_y: float,
		aperture: Dictionary) -> void:
	var arch := packed.instantiate() as Node3D
	arch.name = "WindGateFrame%d" % index
	arch.scale = arch_scale
	arch.rotation.y = atan2(heading.x, heading.y)
	arch.position = Vector3(site_offset.x + heading.x * depth, base_y,
		site_offset.y + heading.y * depth)
	arch.set_meta("beacon_role", "arch_frame")
	add_child(arch)
	var thickness := 0.06404569 * arch_scale.z
	var clear_half := float(aperture.half_width) * arch_scale.x
	var clear_height := float(aperture.minimum_height) * arch_scale.y
	var full_width := 2.0 * arch_scale.x
	var full_height := 3.0 * arch_scale.y
	var post_width := arch_scale.x - clear_half
	for side: float in [-1.0, 1.0]:
		_add_collision_box("Frame%dPost%s" % [index, "L" if side < 0.0 else "R"],
			arch.position + Vector3(right.x * side * (clear_half + post_width * 0.5),
				clear_height * 0.5, right.y * side * (clear_half + post_width * 0.5)),
			Vector3(post_width, clear_height, thickness), arch.rotation.y, "arch_solid")
	_add_collision_box("Frame%dHeader" % index,
		arch.position + Vector3(0.0, clear_height + (full_height - clear_height) * 0.5, 0.0),
		Vector3(full_width, full_height - clear_height, thickness), arch.rotation.y, "arch_solid")


func _add_foundation(foot: Dictionary, local_base_y: float, masonry: Material,
		cfg: Dictionary) -> void:
	var ground_local := float(foot.ground) - _world_anchor.y
	var extra := float(cfg.foundation_extra_depth_m)
	var height := local_base_y - ground_local + extra
	var size_values := cfg.foundation_size_xz_m as Array
	var mesh := MeshInstance3D.new()
	mesh.name = "GroundedFoot_%s_%s" % [str(foot.depth).replace("-", "N"), "L" if float(foot.side) < 0.0 else "R"]
	var box := BoxMesh.new()
	box.size = Vector3(float(size_values[0]), height, float(size_values[1]))
	mesh.mesh = box
	mesh.material_override = masonry
	var xz := foot.xz as Vector2
	mesh.position = Vector3(xz.x, ground_local - extra + height * 0.5, xz.y)
	mesh.set_meta("beacon_role", "terrain_foundation")
	mesh.set_meta("sampled_ground_y", float(foot.ground))
	add_child(mesh)
	_add_collision_box(mesh.name + "Collision", mesh.position, box.size, 0.0, "foundation_collision")


func _add_upper_braces(packed: PackedScene, heading: Vector2, right: Vector2,
		site_offset: Vector2, arch_scale: Vector3, base_y: float, depths: Array) -> void:
	for side: float in [-1.0, 1.0]:
		var brace := packed.instantiate() as Node3D
		brace.name = "CrownDepthBrace%s" % ("L" if side < 0.0 else "R")
		var bounds := RENDER_BOUNDS.measure(brace)
		var span := absf(float(depths[1]) - float(depths[0]))
		brace.scale = Vector3(2.0, 1.0, span / maxf(bounds.size.z, 0.001))
		brace.rotation.y = atan2(heading.x, heading.y)
		var side_xz := right * side * (arch_scale.x - 0.55)
		brace.position = Vector3(site_offset.x + side_xz.x,
			base_y + arch_scale.y * 3.0 - bounds.end.y * brace.scale.y,
			site_offset.y + side_xz.y)
		brace.set_meta("beacon_role", "crown_brace")
		add_child(brace)


## Three terrain-fitted medium masses connect the thin arch feet to the crown
## instead of leaving the landmark floating in an uninterrupted green field.
## They flank the eight-metre passage; they neither replace nor add route
## collision and use the same masonry family as the arch foundations.
func _add_grounding_outcrops(world: Node3D, masonry: Material, heading: Vector2,
		right: Vector2, cfg: Dictionary) -> void:
	for index in (cfg.get("grounding_outcrops", []) as Array).size():
		var spec := (cfg.grounding_outcrops as Array)[index] as Dictionary
		var packed := load(str(spec.scene)) as PackedScene
		if packed == null:
			push_error("Windscar grounding outcrop asset is missing")
			return
		var xz := heading * float(spec.forward_m) + right * float(spec.right_m)
		var ground := _ground(world, _world_anchor.x + xz.x, _world_anchor.z + xz.y)
		if not is_finite(ground):
			push_error("Windscar grounding outcrop received non-finite support terrain")
			return
		var model := packed.instantiate() as Node3D
		var bounds := RENDER_BOUNDS.measure(model)
		var factor := float(spec.width_m) / maxf(maxf(bounds.size.x, bounds.size.z), 0.01)
		var holder := Node3D.new()
		holder.name = "GroundedOutcrop%02d" % (index + 1)
		holder.position = Vector3(xz.x,
			ground - _world_anchor.y - float(spec.bury_m), xz.y)
		holder.rotation.y = atan2(heading.x, heading.y) + deg_to_rad(float(spec.yaw_deg))
		holder.set_meta("beacon_role", "grounding_outcrop")
		holder.set_meta("sampled_ground_y", ground)
		holder.set_meta("bury_m", float(spec.bury_m))
		add_child(holder)
		model.scale = Vector3.ONE * factor
		model.position = -Vector3(bounds.get_center().x, bounds.position.y,
			bounds.get_center().z) * factor
		holder.add_child(model)
		_override_material(model, masonry)


func _override_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child: Node in node.get_children():
		_override_material(child, material)


func _add_signal(packed: PackedScene, site_offset: Vector2, crown_y: float,
		cfg: Dictionary) -> void:
	var signal_node := packed.instantiate() as Node3D
	signal_node.name = "WindscarSignalFlame"
	var signal_scale := float(cfg.signal_scale)
	signal_node.scale = Vector3.ONE * signal_scale
	signal_node.position = Vector3(site_offset.x, crown_y + float(cfg.signal_base_lift_m), site_offset.y)
	signal_node.set_meta("beacon_role", "signal_flame")
	add_child(signal_node)
	var light_cfg := cfg.light as Dictionary
	var light := OmniLight3D.new()
	light.name = "WindscarSignalLight"
	light.light_color = Color(str(light_cfg.colour))
	light.light_energy = float(light_cfg.energy)
	light.omni_range = float(light_cfg.range_m)
	light.shadow_enabled = bool(light_cfg.shadow_enabled)
	light.position = signal_node.position + Vector3.UP * 1.4 * signal_scale
	light.set_meta("beacon_role", "signal_light")
	add_child(light)


func _add_route_banners(cfg: Dictionary, heading: Vector2, right: Vector2,
		site_offset: Vector2, arch_scale: Vector3, base_y: float) -> void:
	var packed := load(str(cfg.get("banner_scene", ""))) as PackedScene
	if packed == null:
		push_error("Windscar beacon banner asset is missing")
		return
	for side: float in [-1.0, 1.0]:
		var banner := packed.instantiate() as Node3D
		banner.name = "WindscarRouteBanner%s" % ("L" if side < 0.0 else "R")
		var bounds := RENDER_BOUNDS.measure(banner)
		var factor := float(cfg.get("banner_height_m", 3.4)) / maxf(bounds.size.y, 0.01)
		banner.scale = Vector3.ONE * factor
		banner.rotation.y = atan2(heading.x, heading.y)
		var xz := site_offset + right * side * (arch_scale.x + 1.25)
		banner.position = Vector3(xz.x, base_y + arch_scale.y * 1.7, xz.y) \
			- Vector3(bounds.get_center().x, bounds.get_center().y, bounds.get_center().z) * factor
		banner.set_meta("beacon_role", "route_banner")
		add_child(banner)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(str(cfg.get("banner_blue", "#315f9a"))) if side < 0.0 \
			else Color(str(cfg.get("banner_gold", "#d6ad52")))
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 0.82
		_override_material(banner, material)


func _add_collision_box(label: String, centre: Vector3, size: Vector3, yaw: float,
		role: String) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = centre
	body.rotation.y = yaw
	body.set_meta("beacon_role", role)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)


func _ground(world: Node3D, x: float, z: float) -> float:
	if world == null or not world.has_method("ground_height_at"):
		return NAN
	return float(world.call("ground_height_at", x, z, _world_anchor.y))


static func passage_width(cfg: Dictionary) -> float:
	return 2.0 * float((cfg.source_aperture_rect_m as Dictionary).half_width) \
		* float((cfg.arch_scale as Array)[0])


static func passage_minimum_height(cfg: Dictionary) -> float:
	return float((cfg.source_aperture_rect_m as Dictionary).minimum_height) \
		* float((cfg.arch_scale as Array)[1])


static func _v2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2.INF
