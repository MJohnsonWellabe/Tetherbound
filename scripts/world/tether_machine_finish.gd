extends RefCounted
## Presentation only. Model remains the unchanged cage-measurement authority.

static func apply(machine: Node3D, spec: Dictionary) -> void:
	var finish: Dictionary = spec.get("finish", {})
	if finish.is_empty():
		return
	var model := machine.get_node_or_null(^"Model")
	if model == null:
		return
	var path := str(finish.get("hardware", ""))
	if path.is_empty():
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var hardware := packed.instantiate() as Node3D
	hardware.name = "Hardware"
	for mesh: MeshInstance3D in hardware.find_children("*", "MeshInstance3D", true, false):
		mesh.set_script(preload("res://scripts/world/tether_machine_hardware_mesh.gd"))
	# Authored in the measured 19.5 m frame, outside Model so cage probes never
	# mistake a decorative fitting for the prisoner's dais/crown/plinth.
	hardware.scale = Vector3.ONE * float(spec.get("height", 19.5)) / 19.5
	machine.add_child(hardware)
