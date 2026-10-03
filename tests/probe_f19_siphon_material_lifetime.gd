extends "res://tests/probe_f19_occupation_material_lifetime.gd"

## Actual three imported Hall siphons share their native mesh. The procedural
## one-glow fixture does not exercise that ownership relationship. Construct
## through shipping factories/config, darken through actual withdrawal, and
## retain only the masked surface copies in the counterfactual case.
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
	var factory := STRONGHOLD.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold.json"))
	factory.set("_config", config)
	var occupation := OCCUPATION.new()
	for treatment: String in ["before-withdrawal", "baseline", "retain-masked-surface"]:
		print("F19 SIPHON MATERIAL BEGIN " + treatment)
		var holder := _build_siphons(factory, config)
		world.add_child(holder)
		for frame in 3: await process_frame
		if treatment != "before-withdrawal":
			var report := {"lights_out": 0, "flames_out": 0, "surfaces_unlit": 0}
			occupation.call("_darken", holder, report)
			if int(report["surfaces_unlit"]) != 3:
				_failures.append("Actual three siphons did not report three changed surfaces")
		_observe_siphons(holder, treatment == "retain-masked-surface")
		for frame in 3: await process_frame
		print("F19 SIPHON MATERIAL DELETE " + treatment)
		holder.queue_free()
		for frame in 4: await process_frame
		_held.clear()
		for frame in 3: await process_frame
		print("F19 SIPHON MATERIAL END " + treatment)
	factory.free()
	occupation.free()
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 SIPHON MATERIAL DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures,
		"acceptance": false, "renderer": RenderingServer.get_current_rendering_method(), "drawing": false}))
	quit(0 if _failures.is_empty() else 1)

func _build_siphons(factory: Node3D, config: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "TetherRetrofit"
	for entry: Variant in (config.get("site", {}) as Dictionary).get("retrofit", []):
		var spec := entry as Dictionary
		if not str(spec.get("model", "")).begins_with("rift_siphon"): continue
		var node: Node3D = factory.call("_load_prop", STRONGHOLD.HALL_PROPS, spec["model"])
		if node == null:
			_failures.append("Actual siphon model failed to load")
			continue
		holder.add_child(node)
		factory.call("_reserve_tether_oxblood", node)
		factory.call("_light_the_siphon", node, spec)
	return holder

func _observe_siphons(holder: Node3D, retain: bool) -> void:
	var mesh_ids: Array[int] = []
	for node: Node in holder.get_children():
		var core := node.find_child(STRONGHOLD.SIPHON_CORE_NODE, true, false) as MeshInstance3D
		if core == null or core.mesh == null:
			_failures.append("Actual siphon lacked its imported core mesh")
			continue
		mesh_ids.append(core.mesh.get_instance_id())
		_observe(core, retain)
	if mesh_ids.size() != 3 or mesh_ids[0] != mesh_ids[1] or mesh_ids[1] != mesh_ids[2]:
		_failures.append("Actual three siphons did not share the imported mesh")
	print("F19 SIPHON MATERIAL OBSERVED " + JSON.stringify({"mesh_ids": mesh_ids, "held": _held.size()}))
