extends Node3D

## F39 P2-011 candidate under the OFF Tidewake look gate: named destinations
## that read as bare slopes gain their reference-backed building
## (`landmark_models` in tidewake_look.json; Meshy assets with provenance
## beside each GLB). Each model is fitted to its authored height, grounded at
## the lowest point under its footprint and keeps an optional box collider
## inside that footprint. No interaction, route, encounter or durable state.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func build(water_world: Node3D) -> void:
	if bool(water_world.get("simulation_only")):
		return
	var look := preload("res://scripts/world/tidewake_look_profile.gd").settings()
	if not bool(look.get("enabled", false)):
		return
	var landmarks := {}
	for raw: Variant in (water_world.get("config") as Dictionary).get("landmarks", []):
		landmarks[str((raw as Dictionary).get("id", ""))] = raw
	# `landmark_props_candidate` (judged, ON) and `veilfall_hero_candidate`
	# (unjudged, OFF in play) add props by absolute `position_xz_m` as well as
	# by landmark offset.
	var specs: Array = (look.get("landmark_models", []) as Array) + (look.get("landmark_props_candidate", []) as Array) \
		+ (look.get("veilfall_hero_candidate", []) as Array) + (look.get("veilfall_facade_candidate", []) as Array)
	# `first_shore_declutter_candidate` (OFF in play) drops named props by id.
	var dropped: Array = (look.get("first_shore_declutter_candidate", {}) as Dictionary).get("drop_landmark_props", [])
	for raw: Variant in specs:
		var spec := raw as Dictionary
		if dropped.has(str(spec.get("id", ""))):
			continue
		var landmark: Dictionary = landmarks.get(str(spec.get("landmark_id", "")), {})
		var at_raw: Array = landmark.get("position", [])
		if spec.has("position_xz_m"):
			var placed: Array = spec.position_xz_m
			at_raw = [float(placed[0]), 0.0, float(placed[1])]
		if at_raw.size() < 3:
			push_warning("landmark model has no authored landmark: %s" % spec.get("landmark_id", ""))
			continue
		var offset: Array = spec.get("offset_xz_m", [0.0, 0.0])
		var at := Vector2(float(at_raw[0]) + float(offset[0]), float(at_raw[2]) + float(offset[1]))
		var model := _instantiate(str(spec.get("model", "")))
		if model == null:
			push_error("landmark model missing: %s" % spec.get("model", ""))
			continue
		_apply_surfaces(model, spec.get("surfaces", []))
		var bounds := RENDER_BOUNDS.measure(model)
		if bounds.size.y <= 0.001:
			model.free()
			continue
		var factor := float(spec.get("height_m", 5.0)) / bounds.size.y
		var holder := Node3D.new()
		holder.name = "Landmark_%s" % str(spec.get("landmark_id", "prop"))
		model.scale = Vector3.ONE * factor
		model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
		holder.add_child(model)
		var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		var half := Vector2(bounds.size.x, bounds.size.z) * factor * 0.5
		holder.rotation.y = yaw
		# `lift_m` raises a piece set into a steep slope, where the lowest footprint
		# point would bury most of it (close-1024 vf2, the upper Veilfall tier).
		holder.position = Vector3(at.x, _floor(water_world, at, yaw, half) - float(spec.get("sink_m", 0.15))
			+ float(spec.get("lift_m", 0.0)), at.y)
		add_child(holder)
		var box: Array = spec.get("collider_fraction", [])
		if box.size() == 3:
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var size := Vector3(half.x * 2.0 * float(box[0]), float(spec.get("height_m", 5.0)) * float(box[1]),
				half.y * 2.0 * float(box[2]))
			shape.shape = BoxShape3D.new()
			(shape.shape as BoxShape3D).size = size
			shape.position = Vector3(0.0, size.y * 0.5, 0.0)
			body.add_child(shape)
			holder.add_child(body)


## Optional per-surface materials, by surface index (the installed castle kit's
## .obj meshes import as flat grey): {texture, tint, uv_scale} as a triplanar
## world-scaled material, so a fitted model keeps its grain at any height.
func _apply_surfaces(node: Node, surfaces: Array) -> void:
	if surfaces.is_empty():
		return
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := node as MeshInstance3D
		for index in mesh.mesh.get_surface_count():
			var cfg: Dictionary = surfaces[mini(index, surfaces.size() - 1)]
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(str(cfg.get("tint", "#ffffff")))
			material.roughness = float(cfg.get("roughness", 0.9))
			var texture_path := str(cfg.get("texture", ""))
			if not texture_path.is_empty():
				material.albedo_texture = load(texture_path)
				material.uv1_triplanar = true
				material.uv1_world_triplanar = true
				material.uv1_scale = Vector3.ONE * float(cfg.get("uv_scale", 0.5))
			mesh.set_surface_override_material(index, material)
	for child in node.get_children():
		_apply_surfaces(child, surfaces)


## A scene, or a bare mesh (the installed castle kit ships .obj meshes).
func _instantiate(path: String) -> Node3D:
	var resource := load(path)
	if resource is PackedScene:
		return (resource as PackedScene).instantiate() as Node3D
	if resource is Mesh:
		var instance := MeshInstance3D.new()
		instance.mesh = resource
		return instance
	return null


## Lowest terrain under the rotated footprint, so no corner floats.
func _floor(world: Node3D, centre: Vector2, yaw: float, half: Vector2) -> float:
	var right := Vector2(cos(yaw), -sin(yaw))
	var back := Vector2(sin(yaw), cos(yaw))
	var low := INF
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var p := centre + right * half.x * u + back * half.y * v
			var y := float(world.call("ground_height_at", p.x, p.y))
			if is_finite(y):
				low = minf(low, y)
	return low if is_finite(low) else 0.0
