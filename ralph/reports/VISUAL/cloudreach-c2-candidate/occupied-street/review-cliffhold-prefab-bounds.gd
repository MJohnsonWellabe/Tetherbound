extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var prefabs := preload("res://scripts/world/building_prefabs.gd").new()
	prefabs.load_recipes()
	for key: String in ["cottage_b", "cottage_a"]:
		var model: Node3D = prefabs.instantiate(key)
		root.add_child(model)
		var local_bounds: AABB = prefabs.combined_aabb(model)
		var x := -7.0 if key == "cottage_b" else 7.0
		var placed := Transform3D(Basis(Vector3.UP, PI), Vector3(x,4.2,22.0)) * local_bounds
		print("PREFAB_BOUNDS ",key," local=",local_bounds," occupied=",placed)
		model.free()
	quit()
