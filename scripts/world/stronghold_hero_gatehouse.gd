extends RefCounted

## F38 P2-003 (close-1024, OFF until judged): the coordinator's Meshy hero
## gatehouse in front of the Meadows Hall's gate, so the stronghold reads as a
## fortress on the skyline rather than "a small dark ruin behind dominant
## pylons". Visual only: no collision, so the existing gate, ramp, doors and
## walkable route are unchanged. Uniform scale to `width_m`, base at the hall
## floor, centred on the gate mouth plus `offset` (local metres).

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


static func build(stronghold: Node3D, cfg: Dictionary, floor_y: float, mouth_z: float) -> Node3D:
	if not bool(cfg.get("enabled", false)):
		return null
	var holder := _place(stronghold, cfg, floor_y, mouth_z, "HeroGatehouse")
	# `companions` (r7): further hero pieces in the same frame, each with its own
	# path, width_m, offset, yaw and lit-window emission -- the lit keep gives the
	# skyline its mass and windows, a spire behind it gives the height.
	var index := 0
	for companion: Variant in cfg.get("companions", []):
		if companion is Dictionary:
			_place(stronghold, companion as Dictionary, floor_y, mouth_z, "HeroGatehouseCompanion%d" % index)
		index += 1
	return holder


static func _place(stronghold: Node3D, cfg: Dictionary, floor_y: float, mouth_z: float, node_name: String) -> Node3D:
	var scene := load(str(cfg.get("path", ""))) as PackedScene
	if scene == null:
		push_warning("stronghold hero gatehouse: %s did not load" % cfg.get("path", ""))
		return null
	var model := scene.instantiate() as Node3D
	_light_windows(model, cfg)
	var holder := Node3D.new()
	holder.name = node_name
	stronghold.add_child(holder)
	holder.add_child(model)
	var bounds := RENDER_BOUNDS.measure(model)
	if bounds.size.x <= 0.001:
		holder.queue_free()
		return null
	var fit := float(cfg.get("width_m", 28.0)) / bounds.size.x
	model.scale = Vector3.ONE * fit
	model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * fit
	var offset: Array = cfg.get("offset", [0.0, 0.0, -4.0])
	holder.position = Vector3(float(offset[0]), floor_y + float(offset[1]), mouth_z + float(offset[2]))
	holder.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	print("[stronghold] hero gatehouse: %.1f x %.1f x %.1f m" % [
		bounds.size.x * fit, bounds.size.y * fit, bounds.size.z * fit])
	return holder


## `emission_texture` (optional): a mask of the model's lit windows and
## braziers (black elsewhere) so the keep reads warm against the night sky
## rather than as a pale silhouette. Applied to every surface's material copy.
static func _light_windows(model: Node3D, cfg: Dictionary) -> void:
	var path := str(cfg.get("emission_texture", ""))
	var mask: Texture2D = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	# `albedo_tint` multiplies the stone darker: the judges read the bare Meshy
	# keep as bleached white rather than the key art's weathered dark hall.
	var tint := Color(str(cfg.get("albedo_tint", "#ffffff")))
	if mask == null and tint == Color.WHITE:
		return
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var lit := source.duplicate() as StandardMaterial3D
			lit.albedo_color = source.albedo_color * tint
			if mask == null:
				mesh_instance.set_surface_override_material(surface, lit)
				continue
			lit.emission_enabled = true
			# The default emission operator ADDS the colour to the texture, so a
			# white base lit the whole keep; black leaves only the masked windows.
			lit.emission = Color.BLACK
			lit.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
			# `emission_colour` (P2-003 r2, optional): multiply the window mask by
			# a colour instead of adding it, so the lit windows burn that hue.
			if cfg.has("emission_colour"):
				lit.emission = Color(str(cfg["emission_colour"]))
				lit.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			lit.emission_texture = mask
			lit.emission_energy_multiplier = float(cfg.get("emission_energy", 2.5))
			mesh_instance.set_surface_override_material(surface, lit)
