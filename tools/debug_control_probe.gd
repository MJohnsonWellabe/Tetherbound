extends SceneTree

const DATA_DIR := "res://data/terrain/playground"

func _init() -> void:
	_run()

func _run() -> void:
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", 256)
	terrain.set("vertex_spacing", 1.0)
	terrain.set("data_directory", DATA_DIR)
	root.add_child(terrain)
	await process_frame

	var data: Object = terrain.get("data")
	if data == null:
		push_error("no data object")
		quit(1)
		return

	var centre := Vector2(140.0, -90.0)
	var bearing := Vector2(1.0, 0.0)
	for d in [0.0, 20.0, 30.0, 38.0, 42.0, 45.0, 50.0, 55.0, 58.0, 60.0, 65.0, 70.0]:
		var p: Vector2 = centre + bearing * d
		var pos := Vector3(p.x, 0.0, p.y)
		var base = data.call("get_control_base_id", pos)
		var overlay = data.call("get_control_overlay_id", pos)
		var blend = data.call("get_control_blend", pos)
		var auto = data.call("get_control_auto", pos)
		print("d=%5.1f base=%s overlay=%s blend=%s auto=%s" % [d, base, overlay, blend, auto])
	quit(0)
