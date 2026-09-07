extends SceneTree
## How many cover instances actually stand near a stand, by layer. Counts real
## MultiMesh instance transforms, not patch bookkeeping.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const STANDS := {
	"05-upper-cloudreach-cliffhold": Vector2(-400.0, 3890.0),
	"01-arrival-first-reveal": Vector2(0.0, -260.0),
}


func _initialize() -> void:
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var instances: Array = []
	_collect(world, instances)
	print("MultiMeshInstance3D nodes found: %d" % instances.size())
	for name: String in STANDS.keys():
		var at: Vector2 = STANDS[name]
		print("\n=== %s at %s ===" % [name, str(at)])
		for radius: float in [8.0, 20.0, 50.0, 120.0]:
			var per_layer := {}
			for raw: Variant in instances:
				var mmi: MultiMeshInstance3D = raw
				var mm := mmi.multimesh
				if mm == null:
					continue
				var key := mmi.name.substr(0, 12)
				var origin := mmi.global_position
				for i in mm.instance_count:
					var p: Vector3 = mm.get_instance_transform(i).origin + origin
					if Vector2(p.x - at.x, p.z - at.y).length() <= radius:
						per_layer[key] = int(per_layer.get(key, 0)) + 1
			var total := 0
			for v: int in per_layer.values():
				total += v
			print("  r=%5.0f m: %6d instances  %s" % [radius, total, str(per_layer)])
	quit(0)


func _collect(node: Node, out: Array) -> void:
	if node is MultiMeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect(child, out)
