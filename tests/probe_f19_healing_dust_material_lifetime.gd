extends SceneTree

## Actual post-freeing dust factory and authored dust settings. Camera, bounds
## and direct invocation are component fixtures; the full healing/progression
## setup is omitted. No flags, party, saved state or pylon outcomes are changed.
const HEALING := preload("res://scripts/world/meadow_healing.gd")
var _held: Array[Resource] = []
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HEALING.CONFIG_PATH))
	var spec: Dictionary = config.get("pylons", {}).get("dust", {})
	if spec.is_empty() or not bool(spec.get("enabled", false)):
		quit(2)
		return
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 4, 8)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	for treatment: String in ["baseline", "retain-dust-materials"]:
		for deletion: String in ["early-parent", "authored-timer"]:
			var phase := treatment + ":" + deletion
			print("F19 HEALING DUST BEGIN " + phase)
			var healing := HEALING.new()
			world.add_child(healing)
			for burst in 3:
				healing.call("_raise_dust", Transform3D.IDENTITY,
					AABB(Vector3(-2, 0, -1), Vector3(4, 2, 2)), spec)
			if healing.get_child_count() != 3: _failures.append("Actual dust factory did not create three bursts")
			if treatment == "retain-dust-materials":
				for child: Node in healing.get_children():
					if child is CPUParticles3D and (child as CPUParticles3D).mesh != null:
						var mesh := (child as CPUParticles3D).mesh
						for surface in mesh.get_surface_count():
							var material := mesh.surface_get_material(surface)
							if material != null: _held.append(material)
				if _held.size() != 3: _failures.append("Retained counterfactual missing actual dust materials")
			if deletion == "authored-timer":
				print("F19 HEALING DUST WAIT TIMER " + phase)
				await create_timer(float(spec["lifetime"]) + 1.5).timeout
				if healing.get_child_count() != 0: _failures.append("Production dust timer did not free bursts")
			else:
				for frame in 30: await physics_frame
			print("F19 HEALING DUST DELETE PARENT " + phase)
			healing.queue_free()
			for frame in 4: await process_frame
			_held.clear()
			for frame in 3: await process_frame
			print("F19 HEALING DUST END " + phase)
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 HEALING DUST DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures,
		"acceptance": false, "authored_spec": HEALING.CONFIG_PATH, "mesh_retention": false}))
	quit(0 if _failures.is_empty() else 1)
