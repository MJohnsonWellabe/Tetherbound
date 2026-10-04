extends SceneTree

## Actual installed Terrain3D component lifetime diagnostic. Empty terrain and
## a camera are disclosed fixtures; no world, route or acceptance claim. Each
## counterfactual changes only the native MouseQuad's permanent teardown.
var _failures: Array[String] = []
var _held: Array[Material] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		print("F19 TERRAIN MATERIAL FAIL: installed Terrain3D class unavailable")
		quit(2)
		return
	for drawing: bool in [true, false]:
		RenderingServer.render_loop_enabled = drawing
		for treatment: String in ["baseline", "retain-quad-material", "detach-quad-base"]:
			print("F19 TERRAIN MATERIAL BEGIN " + JSON.stringify({
				"drawing": drawing, "treatment": treatment, "acceptance": false}))
			var world := Node3D.new()
			root.add_child(world)
			var camera := Camera3D.new()
			world.add_child(camera)
			camera.position = Vector3(0, 5, 12)
			camera.look_at(Vector3.ZERO)
			camera.current = true
			var terrain: Node3D = ClassDB.instantiate("Terrain3D") as Node3D
			world.add_child(terrain)
			for frame in 3: await process_frame
			var quads: Array[MeshInstance3D] = []
			_find_quads(terrain, quads)
			if quads.size() != 1:
				_failures.append("Expected one actual Terrain3D MouseQuad; observed %d" % quads.size())
			for quad: MeshInstance3D in quads:
				if quad.get_active_material(0) == null:
					_failures.append("Actual Terrain3D MouseQuad has no active material")
				print("F19 TERRAIN MATERIAL QUAD " + JSON.stringify({
					"path": str(quad.get_path()), "terrain_version": str(terrain.call("get_version")),
					"material_present": quad.get_active_material(0) != null}))
				if treatment == "retain-quad-material":
					var material := quad.get_active_material(0)
					if material != null: _held.append(material)
				elif treatment == "detach-quad-base":
					quad.set_base(RID())
			# The actual add-on's EXIT_TREE destructor frees its MouseQuad. Keep
			# material references until that destruction and pending work finish.
			world.queue_free()
			for frame in 3: await process_frame
			print("F19 TERRAIN MATERIAL WORLD FREED " + treatment)
			_held.clear()
			for frame in 3: await process_frame
			print("F19 TERRAIN MATERIAL END " + treatment)
	RenderingServer.render_loop_enabled = true
	for frame in 3: await process_frame
	print("F19 TERRAIN MATERIAL DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures}))
	quit(0 if _failures.is_empty() else 1)

func _find_quads(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.name == "MouseQuad":
		output.append(node as MeshInstance3D)
	for child: Node in node.get_children(true):
		_find_quads(child, output)
