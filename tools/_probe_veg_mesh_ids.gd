extends SceneTree

## VEG-WHITECARD. Boots the REAL meadows_playground scene (same shape as
## tools/survey_band2.gd) and checks every LIVE MultiMeshInstance3D the
## vegetation scatter produced for a surface with no bound texture -- the
## "blank white cross-quad billboard" defect archive/reports/docs-reviews-full/band2/round-06
## found, four of eight day frames.
##
## Root cause (see vegetation.gd::_register_mesh_assets' own comment): a
## live, terrain-bound Terrain3DAssets reassigns ids on set_mesh_list() in
## ways that do not match whatever id the caller asked for, up to and
## including two different Terrain3DMeshAsset resources both reporting the
## same id at once. vegetation.gd now always reads the real id back by
## name after registering, rather than trusting the id it asked for -- this
## script is the regression check for that: 0 bad nodes/instances is the
## expected, healthy state on every future run.
##
##   godot --headless --path . --script tools/_probe_veg_mesh_ids.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	call_deferred("_after_settle", world)


func _after_settle(world: Node) -> void:
	for i in 240:
		await physics_frame

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("NO Terrain node found")
		quit(1)
		return

	var instancer: Object = terrain.call("get_instancer")
	var assets: Object = terrain.call("get_assets")
	print("instancer = ", instancer)
	print("assets = ", assets)

	var mesh_list: Array = assets.call("get_mesh_list")
	print("mesh_list count = ", mesh_list.size())
	for a: Object in mesh_list:
		var name: String = str(a.get("name"))
		var id: int = int(a.get("id"))
		var gm: Mesh = a.call("get_mesh", 0)
		var surf_info := ""
		if gm != null:
			for s in gm.get_surface_count():
				var mat := gm.surface_get_material(s)
				var std := mat as StandardMaterial3D
				surf_info += "[s%d tex=%s] " % [s, (std.albedo_texture if std != null else "N/A(mat=%s)" % mat)]
		else:
			surf_info = "get_mesh(0)=NULL"
		print("  id=%-3d name=%-28s %s" % [id, name, surf_info])

	print("")
	print("--- Scanning every live MultiMeshInstance3D for a surface with no texture ---")
	var stats := {"total_nodes": 0, "total_instances": 0, "bad_nodes": 0, "bad_instances": 0}
	_scan_mmis(terrain, stats)
	print("")
	print("TOTAL nodes=%d instances=%d  BAD nodes=%d BAD instances=%d" % [
		stats["total_nodes"], stats["total_instances"], stats["bad_nodes"], stats["bad_instances"]
	])

	quit(0)


func _scan_mmis(node: Node, stats: Dictionary) -> void:
	if node is MultiMeshInstance3D:
		var mmi := node as MultiMeshInstance3D
		var mm := mmi.multimesh
		var mesh := mm.mesh if mm != null else null
		var count: int = mm.instance_count if mm != null else 0
		stats["total_nodes"] = int(stats["total_nodes"]) + 1
		stats["total_instances"] = int(stats["total_instances"]) + count
		if count > 0 and mesh != null:
			var bad := false
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				var std := mat as StandardMaterial3D
				if mat == null or (std != null and std.albedo_texture == null):
					bad = true
			if bad:
				stats["bad_nodes"] = int(stats["bad_nodes"]) + 1
				stats["bad_instances"] = int(stats["bad_instances"]) + count
				var origins := PackedVector3Array()
				for i in count:
					origins.append(mmi.global_transform * mm.get_instance_transform(i).origin)
				print("BAD  %s  instances=%d  mesh=%s  positions=%s" % [
					mmi.get_path(), count, mesh.resource_path, origins
				])
	for child in node.get_children():
		_scan_mmis(child, stats)
