extends SceneTree

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var world := Node3D.new()
	root.add_child(world)

	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	world.add_child(body)
	body.call("setup", "trailpup", false)
	body.call("set_aspect_variant", "stormtrail", "trailpup")

	var model: Node3D = body.get_node(^"Model")
	_walk(model)
	quit()


func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var mat: Material = instance.get_active_material(surface)
			print("surface %d resource_name=%s" % [surface, mat.resource_name if mat else "null"])
			if mat is BaseMaterial3D:
				var b := mat as BaseMaterial3D
				print("  albedo_texture path: %s" % (b.albedo_texture.resource_path if b.albedo_texture else "null"))
				print("  emission_texture path: %s" % (b.emission_texture.resource_path if b.emission_texture else "null"))
	for child in node.get_children():
		_walk(child)
