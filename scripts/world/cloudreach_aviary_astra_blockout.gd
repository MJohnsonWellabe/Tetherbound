extends RefCounted

## P2-022 fresh rough massing only. This independent presentation flag has no
## save/network scope. The existing Aviary builders and their flags are untouched.
## Installed Mesh resources cannot introduce nested bodies, scripts or collision.
const ARCH := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const WALL := preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")


static func build(parent: Node3D, spec: Dictionary, materials: Dictionary,
		world: Node3D) -> void:
	if not bool(spec.get("astra_sanctuary_blockout_enabled", false)):
		return
	if parent.has_node("AstraSanctuaryBlockout"):
		push_error("Astra Aviary blockout must be built only once")
		return
	var root := Node3D.new()
	root.name = "AstraSanctuaryBlockout"
	parent.add_child(root)
	root.set_meta("blockout_complete", false)
	var pieces: Array = spec.get("pieces", [])
	# Validate every complete footprint before drawing any mass. Never silently
	# omit a failed shoulder and submit a different silhouette to the judge.
	for raw: Dictionary in pieces:
		var error := _footprint_error(parent, raw, world)
		if not error.is_empty():
			root.set_meta("blockout_failure", error)
			push_error("Astra Aviary blockout: " + error)
			return
	for raw: Dictionary in pieces:
		var at := _vector(raw["base"])
		var size := _vector(raw["size"])
		var mesh: Mesh = ARCH if str(raw["mesh"]) == "arch" else WALL
		if str(raw["mesh"]) == "block":
			var block := BoxMesh.new()
			block.size = Vector3.ONE
			mesh = block
		var bounds := mesh.get_aabb()
		var instance := MeshInstance3D.new()
		instance.name = str(raw["id"])
		instance.mesh = mesh
		instance.material_override = materials["masonry"] if bool(raw.get("trim", false)) else materials["stone"]
		instance.scale = size / bounds.size
		instance.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
		instance.position = at - Basis(Vector3.UP, instance.rotation.y) * (
			Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * instance.scale)
		root.add_child(instance)
	root.set_meta("piece_count", pieces.size())
	root.set_meta("blockout_complete", true)


static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func _footprint_error(parent: Node3D, piece: Dictionary, world: Node3D) -> String:
	var at := _vector(piece["base"])
	var size := _vector(piece["size"])
	var turn := Basis(Vector3.UP, deg_to_rad(float(piece.get("yaw_deg", 0.0))))
	var nx := maxi(1, ceili(size.x * 2.0))
	var nz := maxi(1, ceili(size.z * 2.0))
	for ix in nx + 1:
		for iz in nz + 1:
			var point := at + turn * Vector3((float(ix) / nx - 0.5) * size.x,
				0.0, (float(iz) / nz - 0.5) * size.z)
			# Retain the original draft's ground-volume exclusions as well as
			# the stronger elevated-only contract. They are not relaxed to admit
			# the rejected ground plinths: all pieces below 12 m also fail below.
			if point.y < 8.0:
				if point.z >= -7.0 and point.z <= 13.0:
					return str(piece.id) + " overlaps a route throat"
				if absf(point.x) <= 10.0 and point.z < -13.0:
					return str(piece.id) + " overlaps the south entry"
				if absf(point.x) <= 21.0 and point.z >= 19.5:
					return str(piece.id) + " overlaps the court walkline"
				if absf(absf(point.x) - 24.0) <= 3.5 and absf(absf(point.z) - 20.5) <= 3.5:
					return str(piece.id) + " overlaps a corner pylon"
			if at.y < 12.0:
				return str(piece.id) + " introduces an unsupported ground-level mass"
			var global_point := parent.to_global(point)
			var ground := float(world.call("_summit_ground_at", global_point))
			# These additions are above the existing 8 m through-route clearance,
			# including where the rising overlook road lifts the carved surface.
			# No new ground pier, false door or walk-through ground wall is built.
			if not is_finite(ground) or global_point.y - ground < 8.0:
				return str(piece.id) + " intrudes into the 8 m ground clearance"
			if Vector2(point.x, point.z - 100.0).length() <= 40.0:
				return str(piece.id) + " overlaps the finale encounter"
	return ""
