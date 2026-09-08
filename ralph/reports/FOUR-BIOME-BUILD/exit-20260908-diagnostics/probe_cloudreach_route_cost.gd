extends SceneTree
class MeasuredWorld:
	extends "res://scripts/world/cloudreach_world.gd"
	var geological_usec := 0
	var geological_calls := 0
	func _add_geological_face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, out_a: Vector3, out_b: Vector3, relief: float) -> void:
		var started := Time.get_ticks_usec()
		super._add_geological_face(tool,a,b,c,d,out_a,out_b,relief)
		geological_usec += Time.get_ticks_usec()-started
		geological_calls += 1
func _init() -> void:
	call_deferred("run")
func run() -> void:
	await process_frame
	var world := MeasuredWorld.new()
	world.set("_config", JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json")))
	world.set("_visual_config", JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json")))
	world.call("_build_materials")
	world.call("_collect_all_route_lines")
	var parent := Node3D.new()
	root.add_child(parent)
	var cfg: Dictionary = world.get("_config")
	var route: Dictionary = cfg.routes[0]
	var a: Vector3 = world.call("_vec3",route.polyline[0])
	var b: Vector3 = world.call("_vec3",route.polyline[1])
	var landmass: Dictionary = (world.get("_visual_config") as Dictionary).landmass
	var width := maxf(float(landmass.get("route_shoulder_min_half_width_m",24.0)),float(route.get("width_m",7.5))*float(landmass.get("route_shoulder_path_multiplier",3.8)))
	var began := Time.get_ticks_usec()
	world.call("_route_ridge",parent,"MeasuredRidge",a,b,width,int(route.get("order",0))*17,(world.get("_materials") as Dictionary).upland,landmass,str(route.id))
	var elapsed := Time.get_ticks_usec()-began
	var mesh: ArrayMesh = parent.get_node("MeasuredRidge").mesh
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	var vertices := 0
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		vertices += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		digest.update(var_to_bytes(arrays))
	var collision: ConcavePolygonShape3D = parent.get_node("MeasuredRidge/Collision").get_child(0).shape
	digest.update(collision.get_faces().to_byte_array())
	print("ROUTE COST total_usec=",elapsed," geological_usec=",world.geological_usec," calls=",world.geological_calls," vertices=",vertices," digest=",digest.finish().hex_encode())
	world.free()
	parent.free()
	quit()
