extends RefCounted

## P2-022 accepted rough massing with owner-authorized masonry/lighting detail.
## This independent presentation flag has no
## save/network scope. The existing Aviary builders and their flags are untouched.
## Installed Mesh resources cannot introduce nested bodies, scripts or collision.
const ARCH := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const WALL := preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")
const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const BOUNDS := preload("res://scripts/world/building_prefabs.gd")


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
	var detail: Dictionary = spec.get("detail", {})
	var detail_error := _detail_error(parent, detail, world)
	if not detail_error.is_empty():
		root.set_meta("blockout_failure", detail_error)
		push_error("Astra Aviary detail: " + detail_error)
		return
	var tree_receipt := preload("res://scripts/world/cloudreach_aviary_astra_trees.gd").apply(
		world, spec.get("approach_trees", {}))
	root.set_meta("approach_tree_receipt", tree_receipt)
	if not bool(tree_receipt.get("complete", false)):
		root.set_meta("blockout_failure", str(tree_receipt.get("failure", "Tree binding failed")))
		push_error("Astra Aviary approach trees: " + str(tree_receipt.get("failure", "Tree binding failed")))
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
	_build_detail(root, detail, materials)
	root.set_meta("piece_count", pieces.size())
	root.set_meta("blockout_complete", true)
	root.set_meta("detail_complete", true)
	root.set_meta("detail_masonry_count", detail.get("masonry", []).size())
	root.set_meta("detail_lantern_count", detail.get("lanterns", []).size())


static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func _detail_error(parent: Node3D, detail: Dictionary, world: Node3D) -> String:
	for piece: Dictionary in detail.get("masonry", []):
		var error := _footprint_error(parent, piece, world)
		if not error.is_empty():
			return error
	var model := LANTERN.instantiate() as Node3D
	var bounds: AABB = BOUNDS.new().combined_aabb(model)
	model.free()
	if bounds.size.y <= 0.0:
		return "Installed lantern has no measurable visual bounds"
	var scale_factor := float(detail.get("lantern_height_m", 1.6)) / bounds.size.y
	var size := bounds.size * scale_factor
	for lamp: Dictionary in detail.get("lanterns", []):
		var footprint := {"id": lamp.id, "base": lamp.base,
			"size": [size.x, size.y, size.z], "yaw_deg": lamp.get("yaw_deg", 0.0)}
		var error := _footprint_error(parent, footprint, world)
		if not error.is_empty():
			return error
	return ""


static func _build_detail(parent: Node3D, detail: Dictionary, materials: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "MasonryAndLanterns"
	parent.add_child(root)
	var trim := (materials["masonry"] as Material).duplicate() as Material
	if trim is ShaderMaterial:
		(trim as ShaderMaterial).set_shader_parameter("tint", Color(str(detail.get("trim_tint", "#e4d7b9"))))
	for piece: Dictionary in detail.get("masonry", []):
		var mesh := BoxMesh.new()
		mesh.size = _vector(piece.size)
		var instance := MeshInstance3D.new()
		instance.name = str(piece.id)
		instance.mesh = mesh
		instance.material_override = trim
		instance.position = _vector(piece.base) + Vector3.UP * mesh.size.y * 0.5
		root.add_child(instance)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(str(detail.get("lantern_colour", "#ffc47e")))
	glow.emission_enabled = true
	glow.emission = glow.albedo_color
	glow.emission_energy_multiplier = float(detail.get("lantern_core_emission", 2.5))
	for lamp: Dictionary in detail.get("lanterns", []):
		_build_lantern(root, lamp, detail, glow)


static func _build_lantern(parent: Node3D, lamp: Dictionary, detail: Dictionary,
		glow: Material) -> void:
	var source := LANTERN.instantiate() as Node3D
	var bounds: AABB = BOUNDS.new().combined_aabb(source)
	var height := float(detail.get("lantern_height_m", 1.6))
	var factor := height / bounds.size.y
	var anchor := Node3D.new()
	anchor.name = str(lamp.id)
	anchor.position = _vector(lamp.base)
	anchor.rotation.y = deg_to_rad(float(lamp.get("yaw_deg", 0.0)))
	parent.add_child(anchor)
	# Copy only mesh resources and visual transforms. Imported scene collision,
	# animation, scripts or other nonvisual nodes can never enter the candidate.
	var housing := Node3D.new()
	housing.name = "InstalledLanternHousing"
	housing.scale = Vector3.ONE * factor
	housing.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	anchor.add_child(housing)
	_copy_meshes(source, housing, Transform3D.IDENTITY)
	source.free()
	var core_at := _vector(detail.get("lantern_core_offset", [0.0, 0.27, 0.2])) * height
	var core := MeshInstance3D.new()
	core.name = "LanternFlame"
	var flame := CylinderMesh.new()
	flame.top_radius = float(detail.get("lantern_core_radius_m", 0.09))
	flame.bottom_radius = flame.top_radius
	flame.height = float(detail.get("lantern_core_height_m", 0.25))
	flame.radial_segments = 8
	core.mesh = flame
	core.material_override = glow
	core.position = core_at
	anchor.add_child(core)
	var light := OmniLight3D.new()
	light.name = "WarmArcadeOutline"
	light.position = core_at + Vector3.BACK * float(detail.get("lantern_light_outset_m", 0.3))
	light.light_color = Color(str(detail.get("lantern_colour", "#ffc47e")))
	light.light_energy = float(detail.get("lantern_energy", 3.4))
	light.omni_range = float(detail.get("lantern_range_m", 12.0))
	light.shadow_enabled = false
	anchor.add_child(light)


static func _copy_meshes(source: Node, target: Node3D, local: Transform3D) -> void:
	if source is MeshInstance3D:
		var original := source as MeshInstance3D
		var copy := MeshInstance3D.new()
		copy.name = original.name
		copy.mesh = original.mesh
		copy.material_override = original.material_override
		copy.transform = local
		target.add_child(copy)
	for child: Node in source.get_children():
		var child_transform := local
		if child is Node3D:
			child_transform = local * (child as Node3D).transform
		_copy_meshes(child, target, child_transform)


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
