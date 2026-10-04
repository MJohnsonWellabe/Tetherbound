extends "res://tests/smoke_f19_veridian_functional.gd"

## Diagnostic counterfactual, never an acceptance witness: two invocations of
## the original space-accept scenario. The second detaches actual chamber
## caption render bases during PREDELETE, before native label RID teardown.
## Original controller, choice, receipts and save/reload code is inherited.
const LABEL_DELETE_PROBE := preload("res://tests/helpers/f19_label_base_teardown_probe.gd")
var _detach_labels := false
var _observed_mesh_paths: Array[String] = []
var _observed_label_paths: Array[String] = []

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
	for detach: bool in [false, true]:
		_detach_labels = detach
		print("F19 CHAMBER MATERIAL BEGIN " + JSON.stringify({
			"detach_label_base_on_predelete": detach, "acceptance": false,
			"scenario": "Original space-accept including actual save/reload; declared original gameplay fixtures"}))
		await _scenario("label-base-detached" if detach else "label-baseline", 4, "accept", "")
		for frame in 3: await process_frame
		print("F19 CHAMBER MATERIAL RELEASE " + JSON.stringify({
			"label_paths": _observed_label_paths, "mesh_paths": _observed_mesh_paths}))
		_observed_mesh_paths.clear()
		_observed_label_paths.clear()
		for frame in 3: await process_frame
		print("F19 CHAMBER MATERIAL END " + JSON.stringify({"failures": _failures}))
	print("F19 CHAMBER MATERIAL DIAGNOSTIC ONLY; deletion counterfactual cannot count as a clean acceptance witness")
	quit(0 if _failures.is_empty() and _max_party_seen <= 5 else 1)

func _drive_to_choice(climax: Node, label: String) -> bool:
	var reached: bool = await super._drive_to_choice(climax, label)
	if reached:
		_observe_materials(climax)
		print("F19 CHAMBER MATERIAL AT CHOICE " + JSON.stringify({
			"detach_label_base_on_predelete": _detach_labels,
			"mesh_paths": _observed_mesh_paths, "label_paths": _observed_label_paths}))
	return reached

func _observe_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		_observed_mesh_paths.append(str(instance.get_path()))
	if node is Label3D:
		var label := node as Label3D
		_observed_label_paths.append(str(label.get_path()))
		if _detach_labels:
			if label.get_script() != null:
				_fail("Label counterfactual refuses to replace an existing product script")
			else:
				var before := _label_live_state(label)
				label.set_meta("f19_diagnostic_original_path", str(label.get_path()))
				label.set_script(LABEL_DELETE_PROBE)
				if _label_live_state(label) != before:
					_fail("Installing label deletion observer changed live rendering properties")
	for child: Node in node.get_children():
		_observe_materials(child)

func _label_live_state(label: Label3D) -> Dictionary:
	var state := {"base": label.get_base()}
	for property: String in ["text", "font", "font_size", "pixel_size", "outline_size",
			"fixed_size", "billboard", "modulate", "outline_modulate", "no_depth_test",
			"shaded", "visible", "cast_shadow", "transform", "material_override", "material_overlay"]:
		state[property] = label.get(property)
	return state
