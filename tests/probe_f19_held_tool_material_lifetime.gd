extends SceneTree

## Component diagnostic: the authored axe/pickaxe model loader and the actual
## finish function used by ToolHold._rebuild_prop. No Game, equip input or gather
## is simulated; this tests only prop deletion and an explicit material hold.
const FINISH := preload("res://scripts/build/build_material_finish.gd")
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
	var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	for treatment: String in ["baseline", "retain-active-surface-overrides"]:
		for item: String in ["axe", "pickaxe"]:
			print("F19 HELD TOOL MATERIAL BEGIN " + treatment + " " + item)
			var definition: Dictionary = items.get("items", {}).get(item, {})
			var model_path := str(definition.get("held_model", ""))
			var source: Resource = load(model_path) if not model_path.is_empty() else null
			var prop: Node3D = null
			if source is PackedScene:
				prop = (source as PackedScene).instantiate() as Node3D
			elif source is Mesh:
				var instance := MeshInstance3D.new()
				instance.mesh = source as Mesh
				prop = instance
			if prop == null:
				_failures.append("Authored tool model missing: " + item)
				continue
			world.add_child(prop)
			FINISH.apply(prop)
			for frame in 3: await process_frame
			_observe(prop, treatment, item, model_path)
			for frame in 3: await process_frame
			print("F19 HELD TOOL MATERIAL DELETE " + treatment + " " + item)
			prop.queue_free()
			for frame in 4: await process_frame
			_held.clear()
			for frame in 3: await process_frame
			print("F19 HELD TOOL MATERIAL END " + treatment + " " + item)
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 HELD TOOL MATERIAL DIAGNOSTIC ONLY " + JSON.stringify({
		"failures": _failures, "acceptance": false, "earned_play": false,
		"scope": "Authored axe/pickaxe model loader and shipping finish; deletion only. No Game, input, gather, reward or route fixture."}))
	quit(0 if _failures.is_empty() else 1)

func _observe(prop: Node3D, treatment: String, item: String, model_path: String) -> void:
	var nodes: Array[Node] = prop.find_children("*", "MeshInstance3D", true, false)
	if prop is MeshInstance3D: nodes.append(prop)
	var surfaces := 0
	var seen: Dictionary = {}
	var owners: Array[String] = []
	for node: Node in nodes:
		var instance := node as MeshInstance3D
		if instance.mesh == null: continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_surface_override_material(surface)
			if material == null or material != instance.get_active_material(surface): continue
			surfaces += 1
			var id := material.get_instance_id()
			if seen.has(id): continue
			seen[id] = true
			owners.append("%s:%d:%s" % [prop.get_path_to(instance), surface, material.resource_name])
			if treatment == "retain-active-surface-overrides": _held.append(material)
	if surfaces == 0: _failures.append("Actual active tool finish missing: " + item)
	print("F19 HELD TOOL MATERIAL OBSERVED " + JSON.stringify({
		"treatment": treatment, "item": item, "model_path": model_path,
		"surfaces": surfaces, "unique_active_materials": seen.size(), "held": _held.size(), "owners": owners}))
