extends SceneTree

## Native regression on actual glow/siphon factories. No Material references
## survive a helper call: teardown observes IDs and WeakRefs only.
const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const OCCUPATION := preload("res://scripts/world/stronghold_occupation.gd")
var _checks := 0
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
	var factory := STRONGHOLD.new()
	factory.set("_config", JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold.json")))
	var occupation := OCCUPATION.new()
	var holder := _build_siphons(factory)
	var glow: MeshInstance3D = factory.call("_glow_card", STRONGHOLD.WALL_TORCH_GLOW_M, STRONGHOLD.FIRE_COLOUR, 0.45)
	glow.name = "TorchGlow"
	holder.add_child(glow)
	world.add_child(holder)
	for frame in 3: await process_frame
	var snapshots := _darken_and_check(holder, occupation)
	for frame in 3: await process_frame
	world.remove_child(holder)
	_check_ids(holder, snapshots, "outside tree")
	world.add_child(holder)
	for frame in 3: await process_frame
	_check_ids(holder, snapshots, "re-entered tree")
	holder.queue_free()
	for frame in 4: await process_frame
	for state: Dictionary in snapshots:
		_check((state["copy"] as WeakRef).get_ref() == null, "Owned unlit copy expired with its mesh node")
	factory.free()
	occupation.free()
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 OCCUPATION OVERRIDE RESULT " + JSON.stringify({"checks": _checks,
		"failures": _failures, "renderer": RenderingServer.get_current_rendering_method(),
		"drawing": false, "observer_state": "IDs and WeakRefs only", "earned_campaign": false}))
	quit(0 if _failures.is_empty() else 1)

func _build_siphons(factory: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "TetherRetrofit"
	var authored: Dictionary = factory.call("_occupation")
	for entry: Variant in authored.get("retrofit", []):
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

func _darken_and_check(holder: Node3D, occupation: Node) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var meshes: Array[MeshInstance3D] = []
	for node: Node in holder.get_children():
		var core := node as MeshInstance3D if node is MeshInstance3D else node.find_child(STRONGHOLD.SIPHON_CORE_NODE, true, false) as MeshInstance3D
		if core != null: meshes.append(core)
	_check(meshes.size() == 4, "Actual three siphons and glow are present")
	for mesh: MeshInstance3D in meshes:
		var original := mesh.get_active_material(0) as BaseMaterial3D
		_check(original != null and original.emission_enabled, "Actual source emits before withdrawal")
		var before := _appearance(original)
		var changed: int = occupation.call("_unlight", mesh)
		var active := mesh.get_active_material(0) as BaseMaterial3D
		_check(changed == mesh.mesh.get_surface_count(), "Withdrawal reports every affected surface")
		_check(active != null and not active.emission_enabled and active.emission_energy_multiplier == 0.0, "Active material stops emitting")
		_check(active != original, "Withdrawal owns a new copy")
		_check(original.emission_enabled and original.emission_energy_multiplier > 0.0, "Source material remains emissive")
		_check(_appearance(active) == before, "Non-emission appearance stays unchanged")
		_check(mesh.get_surface_override_material(0) == null, "No masked surface copy is created")
		var copy_id := active.get_instance_id()
		_check(int(occupation.call("_unlight", mesh)) == 0 and mesh.get_active_material(0).get_instance_id() == copy_id, "Repeated withdrawal does not replace the copy")
		snapshots.append({"path": str(holder.get_path_to(mesh)), "id": copy_id, "copy": weakref(active)})
	return snapshots

func _appearance(material: BaseMaterial3D) -> Dictionary:
	var result := {}
	for key: String in ["albedo_color", "albedo_texture", "roughness", "metallic", "transparency",
			"shading_mode", "blend_mode", "billboard_mode", "cull_mode", "depth_draw_mode"]:
		var value: Variant = material.get(key)
		result[key] = (value as Object).get_instance_id() if value is Object else value
	return result

func _check_ids(holder: Node3D, snapshots: Array[Dictionary], phase: String) -> void:
	for state: Dictionary in snapshots:
		var mesh := holder.get_node(NodePath(state["path"])) as MeshInstance3D
		_check(mesh.get_active_material(0).get_instance_id() == state["id"], "Unlit copy preserved " + phase)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
