extends SceneTree

## Diagnostic only. Actual committed Meadows regions and production terrain
## node/material factories; camera and isolated host are fixtures. No actors,
## campaign, earned save or acceptance claim. No region generation or writes.
const HOST := preload("res://tests/helpers/f19_populated_terrain_host.gd")
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		print("F19 POPULATED TERRAIN FAIL: installed extension unavailable")
		quit(2)
		return
	for drawing: bool in [true, false]:
		RenderingServer.render_loop_enabled = drawing
		for production_material: bool in [false, true]:
			print("F19 POPULATED TERRAIN BEGIN " + JSON.stringify({
				"drawing": drawing, "production_material": production_material,
				"acceptance": false}))
			var host := HOST.new()
			host.name = "PopulatedTerrainComponent"
			root.add_child(host)
			var camera := Camera3D.new()
			host.add_child(camera)
			camera.position = Vector3(-16.5, 8, 12)
			camera.look_at(Vector3(-16.5, 0, 0))
			camera.current = true
			var terrain: Node3D = host.call("_build_terrain") as Node3D
			if terrain == null:
				_failures.append("Production terrain factory returned null")
				host.queue_free()
				await process_frame
				continue
			host.set("_terrain", terrain)
			terrain.call("set_camera", camera)
			await process_frame
			terrain.set("data_directory", HOST.DATA_DIR)
			await process_frame
			if production_material: host.call("_apply_ground_materials")
			for frame in 6: await process_frame
			var data: Object = terrain.get("data")
			var regions := int(data.call("get_region_count")) if data != null else 0
			var material: Object = terrain.get("material")
			var material_rid: RID = material.call("get_material_rid") if material != null else RID()
			if regions <= 0: _failures.append("Committed terrain has no resident regions")
			if not material_rid.is_valid(): _failures.append("Actual terrain material RID unavailable")
			print("F19 POPULATED TERRAIN OBSERVED " + JSON.stringify({
				"regions": regions, "data_directory": str(terrain.get("data_directory")),
				"terrain_version": str(terrain.call("get_version")),
				"material_rid": str(material_rid), "drawing": drawing,
				"production_material": production_material}))
			# Drop our Object handles before deleting the actual component, so
			# these observations do not retain native material/region ownership.
			material = null
			data = null
			host.queue_free()
			for frame in 6: await process_frame
			print("F19 POPULATED TERRAIN END " + JSON.stringify({
				"drawing": drawing, "production_material": production_material}))
	RenderingServer.render_loop_enabled = true
	for frame in 3: await process_frame
	print("F19 POPULATED TERRAIN DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures}))
	quit(0 if _failures.is_empty() else 1)
