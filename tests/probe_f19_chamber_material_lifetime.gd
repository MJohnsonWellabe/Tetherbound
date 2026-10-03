extends "res://tests/smoke_f19_veridian_functional.gd"

## Diagnostic counterfactual, never an acceptance witness: two invocations of
## the original space-accept scenario. The second retains active chamber
## materials across teardown to test the known last-reference RID mechanism.
## Original controller, choice, receipts and save/reload code is inherited.
var _retain_chamber := false
var _held_materials: Array[Material] = []
var _observed_mesh_paths: Array[String] = []

func _run() -> void:
	# Parent startup invokes _run during construction. Defer this diagnostic
	# until its own member initializers have run.
	_run_diagnostic.call_deferred()

func _run_diagnostic() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("veridian_material_diagnostic"):
		quit(2)
		return
	await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		quit(2)
		return
	for hold: bool in [false, true]:
		_retain_chamber = hold
		print("F19 CHAMBER MATERIAL BEGIN " + JSON.stringify({
			"retain_active_chamber_materials": hold, "acceptance": false,
			"scenario": "Original space-accept including actual save/reload; declared original gameplay fixtures"}))
		await _scenario("material-held" if hold else "material-baseline", 4, "accept", "")
		for frame in 3: await process_frame
		print("F19 CHAMBER MATERIAL RELEASE " + JSON.stringify({
			"retained_materials": _held_materials.size(), "mesh_paths": _observed_mesh_paths}))
		_held_materials.clear()
		_observed_mesh_paths.clear()
		for frame in 3: await process_frame
		print("F19 CHAMBER MATERIAL END " + JSON.stringify({"failures": _failures}))
	print("F19 CHAMBER MATERIAL DIAGNOSTIC ONLY; material retention cannot count as a clean acceptance witness")
	quit(0 if _failures.is_empty() and _max_party_seen <= 5 else 1)

func _drive_to_choice(climax: Node, label: String) -> bool:
	var reached: bool = await super._drive_to_choice(climax, label)
	if reached:
		_observe_materials(climax)
		print("F19 CHAMBER MATERIAL AT CHOICE " + JSON.stringify({
			"retain": _retain_chamber, "mesh_paths": _observed_mesh_paths,
			"retained_materials": _held_materials.size()}))
	return reached

func _observe_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		_observed_mesh_paths.append(str(instance.get_path()))
		if _retain_chamber:
			var mesh: Mesh = instance.mesh
			for surface in (mesh.get_surface_count() if mesh != null else 0):
				var active: Material = instance.get_active_material(surface)
				if active != null: _held_materials.append(active)
			if instance.material_overlay != null: _held_materials.append(instance.material_overlay)
	for child: Node in node.get_children():
		_observe_materials(child)
