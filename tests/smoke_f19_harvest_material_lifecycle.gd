extends SceneTree

## Actual authored Cloudreach crops. Observer state is IDs and WeakRefs only.
const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value: _failures.append(message)

func _run() -> void:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "gl_compatibility":
		quit(2)
		return
	RenderingServer.render_loop_enabled = false
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 3, 8)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var holder := Node3D.new()
	world.add_child(holder)
	for authored: Dictionary in PATCH.gatherable_nodes():
		var crop := HARVEST.new()
		holder.add_child(crop)
		crop.call("setup", PATCH.harvest_spec(authored, 1))
	for frame in 3: await process_frame
	var snapshots := _snapshot(holder)
	world.remove_child(holder)
	_compare(holder, snapshots, "detached")
	world.add_child(holder)
	for frame in 3: await process_frame
	_compare(holder, snapshots, "re-entered")
	holder.queue_free()
	for frame in 4: await process_frame
	for state: Dictionary in snapshots:
		_check((state["material"] as WeakRef).get_ref() == null, "Retint expires after actual deletion")
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 HARVEST MATERIAL LIFECYCLE RESULT " + JSON.stringify({"checks": _checks,
		"failures": _failures, "observer_state": "IDs and WeakRefs only",
		"renderer": RenderingServer.get_current_rendering_method(), "drawing": false,
		"earned_campaign": false, "stock_or_gathering_supplied": false}))
	quit(0 if _failures.is_empty() else 1)

func _snapshot(holder: Node3D) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	_check(holder.get_child_count() == PATCH.gatherable_nodes().size(), "Every authored crop is present")
	for node: Node in holder.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null: continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_surface_override_material(surface)
			if material == null: continue
			_check(material == instance.get_active_material(surface), "Actual harvest retint is active")
			var base := instance.mesh.surface_get_material(surface)
			_check(material != base, "Imported source material is preserved")
			snapshots.append({"path": str(holder.get_path_to(instance)), "surface": surface,
				"id": material.get_instance_id(), "material": weakref(material),
				"mesh_id": instance.mesh.get_instance_id(),
				"base_id": base.get_instance_id() if base != null else 0})
	_check(snapshots.size() == 15, "All fifteen authored active retints are observed")
	return snapshots

func _compare(holder: Node3D, snapshots: Array[Dictionary], phase: String) -> void:
	for state: Dictionary in snapshots:
		var instance := holder.get_node(NodePath(state["path"])) as MeshInstance3D
		var material := instance.get_active_material(state["surface"])
		var base := instance.mesh.surface_get_material(state["surface"])
		_check(material != null and material.get_instance_id() == state["id"], phase + " retains active retint identity")
		_check(instance.mesh.get_instance_id() == state["mesh_id"], phase + " retains imported mesh identity")
		_check((base.get_instance_id() if base != null else 0) == state["base_id"], phase + " preserves imported source material")
