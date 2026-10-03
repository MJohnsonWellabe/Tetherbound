extends SceneTree

## Authored prop fixture, shipping ToolHold replacement/destruction paths.
## No Game, input or gather is supplied. Observer retains IDs/WeakRefs only.
const TOOL := preload("res://scripts/player/tool_hold.gd")
const FINISH := preload("res://scripts/build/build_material_finish.gd")
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
	var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	for deletion: String in ["replace", "delete-owner", "delete-player-with-external-prop"]:
		for item: String in ["axe", "pickaxe"]:
			var player := Node3D.new()
			world.add_child(player)
			var mount := Node3D.new()
			player.add_child(mount)
			var tool := TOOL.new()
			player.add_child(tool)
			tool.set_process(false)
			var definition: Dictionary = items["items"][item]
			var source := load(str(definition["held_model"])) as PackedScene
			var prop := source.instantiate() as Node3D
			if deletion == "delete-player-with-external-prop": mount.add_child(prop)
			else: tool.add_child(prop)
			FINISH.apply(prop)
			tool.set("_prop", prop)
			for frame in 3: await process_frame
			var snapshots := _snapshot(prop)
			world.remove_child(player)
			_compare(prop, snapshots, "detached")
			world.add_child(player)
			tool.set_process(false)
			for frame in 3: await process_frame
			_compare(prop, snapshots, "re-entered")
			print("F19 HELD TOOL LIFECYCLE DELETE " + deletion + " " + item)
			if deletion == "replace":
				tool.call("_rebuild_prop")
				_check(tool.call("prop_node") == null, "Shipping replacement clears prop ownership")
			elif deletion == "delete-owner":
				tool.queue_free()
			else:
				player.queue_free()
			for frame in 4: await process_frame
			for state: Dictionary in snapshots:
				_check((state["material"] as WeakRef).get_ref() == null, "Private finish expires after " + deletion)
			if deletion != "delete-player-with-external-prop": player.queue_free()
			for frame in 4: await process_frame
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 HELD TOOL LIFECYCLE RESULT " + JSON.stringify({"checks": _checks,
		"failures": _failures, "observer_state": "IDs and WeakRefs only",
		"earned_campaign": false, "fixture": "Authored axe/pickaxe props assigned to shipping ToolHold; no Game/input/gather"}))
	quit(0 if _failures.is_empty() else 1)

func _snapshot(prop: Node3D) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for node: Node in prop.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null: continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_surface_override_material(surface)
			if material == null: continue
			var base := instance.mesh.surface_get_material(surface)
			_check(material == instance.get_active_material(surface), "Authored finish is active")
			_check(material != base, "Imported source material is preserved")
			snapshots.append({"path": str(prop.get_path_to(instance)), "surface": surface,
				"id": material.get_instance_id(), "material": weakref(material),
				"mesh_id": instance.mesh.get_instance_id(), "base_id": base.get_instance_id()})
	_check(snapshots.size() == 1, "One actual authored tool finish is present")
	return snapshots

func _compare(prop: Node3D, snapshots: Array[Dictionary], phase: String) -> void:
	for state: Dictionary in snapshots:
		var instance := prop.get_node(NodePath(state["path"])) as MeshInstance3D
		var material := instance.get_active_material(state["surface"])
		var base := instance.mesh.surface_get_material(state["surface"])
		_check(material != null and material.get_instance_id() == state["id"], phase + " retains finish identity")
		_check(instance.mesh.get_instance_id() == state["mesh_id"], phase + " retains imported mesh identity")
		_check(base.get_instance_id() == state["base_id"], phase + " retains source material identity")
