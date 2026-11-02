extends RefCounted

## F38 L6 (close-1024, OFF until judged): textured stone portal surrounds for
## the Hall's travel arches (coordinator Meshy, tb/meshy-1024). Each piece is
## fitted to `size_m` (width, height) around its arch slot, base on the floor,
## a little proud of the wall and facing into the room (+z in slot space).
## Presentation only: no collision, route, portal state, save or network
## change. `crossing_hall.json arch_facades.enabled` gates it.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


static func build(hall: Node3D, cfg: Dictionary, arches: Dictionary) -> int:
	if not bool(cfg.get("enabled", false)):
		return 0
	var built := 0
	var pieces: Dictionary = cfg.get("pieces", {})
	for id: String in pieces.keys():
		if not arches.has(id):
			continue
		var row: Dictionary = pieces[id]
		var scene := load(str(row.get("path", ""))) as PackedScene
		if scene == null:
			push_warning("arch facade '%s': %s did not load" % [id, row.get("path", "")])
			continue
		var model := scene.instantiate() as Node3D
		var holder := Node3D.new()
		holder.name = "ArchFacade_" + id
		(arches[id] as Node3D).add_child(holder)
		holder.add_child(model)
		model.rotation.y = deg_to_rad(float(row.get("yaw_deg", 0.0)))
		var bounds := RENDER_BOUNDS.measure(model)
		if bounds.size.x <= 0.001 or bounds.size.y <= 0.001:
			holder.queue_free()
			continue
		var size: Array = row.get("size_m", [4.4, 5.2])
		# Bounds are the model's own (unscaled, unrotated) space, as for the
		# locked doors in crossing_hall.gd; yaw is meant for 0 or 180.
		var across := maxf(bounds.size.x, 0.001)
		# `depth_scale` (HALL-2, default 1) thins the surround's depth into the
		# room, so the piers stop reading as near-field posts down the nave.
		var fit := Vector3(float(size[0]) / across, float(size[1]) / bounds.size.y,
				float(size[0]) / across * float(cfg.get("depth_scale", 1.0)))
		model.scale = fit
		# Seat the back face on the wall plane and centre across the arch; a
		# 180-degree yaw mirrors local x and z into slot space.
		var centre := bounds.get_center()
		var flipped := absf(float(row.get("yaw_deg", 0.0))) >= 90.0
		var back := bounds.end.z if flipped else -bounds.position.z
		var across_offset := centre.x if flipped else -centre.x
		# `sink_m` buries the delivered models' thin threshold slab in the floor.
		model.position = Vector3(across_offset * fit.x, -bounds.position.y * fit.y - float(row.get("sink_m", 0.0)),
				float(row.get("z_m", 0.12)) + back * fit.z)
		built += 1
	print("[crossing_hall] arch facades: %d built" % built)
	return built
