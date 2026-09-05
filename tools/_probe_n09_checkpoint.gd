extends SceneTree

## N09-BRIDGE-CHECKPOINT-0905 measurement probe. Prints, from the REAL built
## world, every number this lane's placement decisions are made against: where
## the checkpoint archway, the barricade frames, the banners, the lantern and
## the posted sentry actually stand in the crossing's own local metres, how far
## each barricade reaches into the 3.0m roadway, and what the clear gap down the
## centreline is. Also dumps the hero gate `.glb`'s material list (the evidence
## behind this lane's banner-consistency routing) and a BoxMesh's UV bounds (the
## barricade timbers are BoxMeshes, and a trim-sheet material has to know which
## band those UVs land in).
##
##   godot --headless --path . --script tools/_probe_n09_checkpoint.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HERO_GATE := "res://assets/environment/team_tether/south_bridge_gate.glb"
const FENCE := "res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Single.gltf"
const SETTLE_FRAMES := 120
const ROAD_HALF := 1.5


func _init() -> void:
	_run()


func _run() -> void:
	_dump_box_uvs()
	_dump_material(HERO_GATE, "hero checkpoint gate")
	_dump_material(FENCE, "kit wooden fence (MI_WoodTrim source)")

	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var bridge: Node3D = world.get_node_or_null(^"SouthBridge") as Node3D
	if bridge == null:
		print("no SouthBridge node")
		quit(1)
		return
	print("\n== South Bridge, crossing-local metres (local +x = toward the far bank) ==")
	print("  bridge global position: %s" % bridge.global_position)
	var leaf: Node3D = bridge.get_node_or_null(^"GateLeaf") as Node3D
	for child in bridge.get_children():
		if child is Node3D and child.name.begins_with("Checkpoint"):
			print("  %-22s local %s" % [child.name, (child as Node3D).position])
	if leaf != null:
		print("  GateLeaf               local %s" % leaf.position)

	var occ: Node3D = bridge.get_node_or_null(^"Occupation") as Node3D
	if occ == null:
		print("  no Occupation node")
	else:
		for child in occ.get_children():
			if child is Node3D:
				print("  %-22s local %s" % [child.name, (child as Node3D).position])
		for side in ["A", "B"]:
			var frame: Node3D = occ.get_node_or_null("Barricade_%s" % side) as Node3D
			if frame == null:
				continue
			var shape: CollisionShape3D = frame.get_node_or_null(^"BarricadeCollision/CollisionShape3D") as CollisionShape3D
			if shape == null:
				for c in frame.get_children():
					if c is StaticBody3D:
						for cc in (c as Node).get_children():
							if cc is CollisionShape3D:
								shape = cc
			if shape == null or not shape.shape is BoxShape3D:
				continue
			var box: BoxShape3D = shape.shape
			var yaw: float = frame.rotation.y
			var half_z: float = absf(box.size.x * 0.5 * sin(yaw)) + absf(box.size.z * 0.5 * cos(yaw))
			var half_x: float = absf(box.size.x * 0.5 * cos(yaw)) + absf(box.size.z * 0.5 * sin(yaw))
			var centre_z: float = frame.position.z + shape.position.z
			var inner: float = absf(centre_z) - half_z
			print("  Barricade_%s: centre z %+.2f, yaw %+.1f deg, collision half-extent z %.2f" % [
				side, centre_z, rad_to_deg(yaw), half_z])
			print("      inner edge at |z| = %.2f  (road half-width %.2f -> reaches %.2fm INTO the road)" % [
				inner, ROAD_HALF, maxf(0.0, ROAD_HALF - inner)])
			print("      x range %.2f .. %.2f" % [frame.position.x - half_x, frame.position.x + half_x])

	var sentry: Node3D = bridge.get_node_or_null(^"Occupation/Sentries/Bridge Sentry") as Node3D
	if sentry != null:
		var local: Vector3 = bridge.global_transform.affine_inverse() * sentry.global_position
		print("  Bridge Sentry          local %s (world %s)" % [local, sentry.global_position])
	quit(0)


func _dump_box_uvs() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.14, 1.8)
	var arrays: Array = box.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for uv in uvs:
		lo = lo.min(uv)
		hi = hi.max(uv)
	print("== BoxMesh(0.14, 0.14, 1.8) UV bounds: %s .. %s (%d verts) ==" % [lo, hi, uvs.size()])


func _dump_material(path: String, label: String) -> void:
	print("\n== %s: %s ==" % [label, path])
	if not ResourceLoader.exists(path):
		print("  MISSING")
		return
	var scene: PackedScene = load(path)
	var node: Node = scene.instantiate()
	_walk_materials(node, "  ")
	node.queue_free()


func _walk_materials(node: Node, indent: String) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh != null:
			for s in mesh.get_surface_count():
				var mat: Material = mesh.surface_get_material(s)
				var name := "<null>" if mat == null else mat.resource_name
				var extra := ""
				if mat is StandardMaterial3D:
					var std: StandardMaterial3D = mat
					extra = " albedo=%s albedo_tex=%s normal_tex=%s rough_tex=%s roughness=%.2f metallic=%.2f" % [
						std.albedo_color.to_html(false),
						"yes" if std.albedo_texture != null else "no",
						"yes" if std.normal_texture != null else "no",
						"yes" if std.roughness_texture != null else "no",
						std.roughness, std.metallic]
				print("%s%s surface %d: '%s'%s" % [indent, node.name, s, name, extra])
	for child in node.get_children():
		_walk_materials(child, indent)
