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
	for raw: Variant in look.get("landmark_models", []):
		var spec := raw as Dictionary
		var landmark: Dictionary = landmarks.get(str(spec.get("landmark_id", "")), {})
		var at_raw: Array = landmark.get("position", [])
		if at_raw.size() < 3:
			push_warning("landmark model has no authored landmark: %s" % spec.get("landmark_id", ""))
			continue
		var offset: Array = spec.get("offset_xz_m", [0.0, 0.0])
		var at := Vector2(float(at_raw[0]) + float(offset[0]), float(at_raw[2]) + float(offset[1]))
		var model := _instantiate(str(spec.get("model", "")))
		if model == null:
			push_error("landmark model missing: %s" % spec.get("model", ""))
			continue
		var bounds := RENDER_BOUNDS.measure(model)
		if bounds.size.y <= 0.001:
			model.free()
			continue
		var factor := float(spec.get("height_m", 5.0)) / bounds.size.y
		var holder := Node3D.new()
		holder.name = "Landmark_%s" % str(spec.landmark_id)
		model.scale = Vector3.ONE * factor
		model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
		holder.add_child(model)
		var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		var half := Vector2(bounds.size.x, bounds.size.z) * factor * 0.5
		holder.rotation.y = yaw
		holder.position = Vector3(at.x, _floor(water_world, at, yaw, half) - float(spec.get("sink_m", 0.15)), at.y)
		add_child(holder)
		var box: Array = spec.get("collider_fraction", [])
		if box.size() == 3:
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var size := Vector3(half.x * 2.0 * float(box[0]), float(spec.height_m) * float(box[1]),
				half.y * 2.0 * float(box[2]))
			shape.shape = BoxShape3D.new()
			(shape.shape as BoxShape3D).size = size
			shape.position = Vector3(0.0, size.y * 0.5, 0.0)
			body.add_child(shape)
			holder.add_child(body)


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
