extends SceneTree

## Diagnostic only: actual Cloudreach harvest specs and shipping visual factory.
## No Game, stock, gathering, rewards, choice or earned route is supplied.
const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")
var _held: Array[Material] = []
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

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
	for treatment: String in ["baseline", "retain-active-surface-overrides"]:
		print("F19 CLOUDREACH HARVEST MATERIAL BEGIN " + treatment)
		var holder := Node3D.new()
		world.add_child(holder)
		for authored: Dictionary in PATCH.gatherable_nodes():
			var spec := PATCH.harvest_spec(authored, 1)
			if spec.is_empty():
				_failures.append("Actual harvest spec is missing")
				continue
			var crop := HARVEST.new()
			holder.add_child(crop)
			crop.call("setup", spec)
		for frame in 3: await process_frame
		_observe(holder, treatment)
		for frame in 3: await process_frame
		print("F19 CLOUDREACH HARVEST MATERIAL DELETE " + treatment)
		holder.queue_free()
		for frame in 4: await process_frame
		_held.clear()
		for frame in 3: await process_frame
		print("F19 CLOUDREACH HARVEST MATERIAL END " + treatment)
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 CLOUDREACH HARVEST MATERIAL DIAGNOSTIC ONLY " + JSON.stringify({
		"failures": _failures, "acceptance": false, "earned_play": false,
		"scope": "Actual harvest visual factories; no Game or gathering; Materials retained only in the declared counterfactual"}))
	quit(0 if _failures.is_empty() else 1)

func _observe(holder: Node3D, treatment: String) -> void:
	var surfaces := 0
	var owners: Array[String] = []
	var seen: Dictionary = {}
	for node: Node in holder.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null: continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_surface_override_material(surface)
			if material == null or material != instance.get_active_material(surface): continue
			surfaces += 1
			var id := material.get_instance_id()
			if seen.has(id): continue
			seen[id] = true
			owners.append("%s:%d:%s" % [holder.get_path_to(instance), surface, material.resource_name])
			if treatment == "retain-active-surface-overrides": _held.append(material)
	if holder.get_child_count() != PATCH.gatherable_nodes().size() or surfaces == 0:
		_failures.append("Actual authored crops or active surface overrides are missing")
	print("F19 CLOUDREACH HARVEST MATERIAL OBSERVED " + JSON.stringify({
		"treatment": treatment, "crops": holder.get_child_count(), "surfaces": surfaces,
		"unique_active_materials": seen.size(), "held": _held.size(), "owners": owners}))
