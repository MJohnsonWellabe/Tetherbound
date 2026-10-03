extends "res://tests/smoke_f19_solmane_functional.gd"

## Diagnostic only: the original first Cloudreach boot, first scenario reset,
## and second boot. Census ALL root children, including the automatic project
## scene and Game's menu. Do not exercise or claim any choice/earned route.
var _held: Array[Material] = []
var _held_ids: Dictionary = {}
var _candidate_ids: Dictionary = {}
var _samples: Array[String] = []
var _retained_samples: Array[String] = []
var _active_owner_counts: Dictionary = {}

func _run() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("solmane_cold_material_diagnostic"):
		quit(2)
		return
	# Preserve the original initial boot timing; new fields are used only after
	# the inherited asynchronous boot returns and member initialization ends.
	print("F19 SOLMANE COLD BEGIN " + _treatment())
	await super._boot_world()
	_observe("initial-world-ready")
	if _game == null:
		quit(2)
		return
	print("F19 SOLMANE COLD RESET BEGIN")
	super._reset_state(4)
	_observe("after-original-reset")
	print("F19 SOLMANE COLD SECOND BOOT BEGIN")
	await super._boot_world()
	_observe("second-world-ready")
	_held.clear()
	_held_ids.clear()
	for frame in 3: await process_frame
	print("F19 SOLMANE COLD ORIGINAL TRANSITION END")
	_observe("before-final-delete")
	for child: Node in root.get_children():
		if child.name != "Game": child.queue_free()
	for frame in 4: await process_frame
	_held.clear()
	_held_ids.clear()
	for frame in 3: await process_frame
	print("F19 SOLMANE COLD DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures,
		"acceptance": false, "treatment": _treatment(), "choice_or_earned_play": false}))
	quit(0 if _failures.is_empty() else 1)

func _treatment() -> String:
	if OS.get_cmdline_user_args().has("--retain-active-surface-overrides"):
		return "retain-active-surface-overrides"
	return "retain-masked-materials" if OS.get_cmdline_user_args().has("--retain-masked-materials") else "baseline"

func _observe(phase: String) -> void:
	_candidate_ids.clear()
	_samples.clear()
	_retained_samples.clear()
	_active_owner_counts.clear()
	_scan(root)
	var roots: Array[String] = []
	for child: Node in root.get_children(): roots.append(str(child.get_path()))
	print("F19 SOLMANE COLD OBSERVED " + JSON.stringify({"phase": phase,
		"treatment": _treatment(), "root_children": roots,
		"unique_material_candidates": _candidate_ids.size(), "held_materials": _held.size(),
		"owner_samples": _samples, "sample_limit": 32,
		"new_retained_owner_samples": _retained_samples, "retained_sample_limit": 128}))
	print("F19 SOLMANE COLD ACTIVE OWNER GROUPS " + JSON.stringify({"phase": phase,
		"counts": _active_owner_counts, "selection_args": OS.get_cmdline_user_args()}))

func _scan(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var active := instance.get_active_material(surface)
				var override := instance.get_surface_override_material(surface)
				var base := instance.mesh.surface_get_material(surface)
				if override != active: _note(instance, surface, "surface-override", override)
				else: _note(instance, surface, "active-surface-override", override)
				if base != active: _note(instance, surface, "mesh-surface", base)
	elif node is MultiMeshInstance3D:
		var instance := node as MultiMeshInstance3D
		if instance.material_override != null and instance.multimesh != null and instance.multimesh.mesh != null:
			for surface in instance.multimesh.mesh.get_surface_count():
				var base := instance.multimesh.mesh.surface_get_material(surface)
				if base != instance.material_override: _note(instance, surface, "multimesh-surface", base)
	for child: Node in node.get_children(true): _scan(child)

func _note(node: Node, surface: int, kind: String, material: Material) -> void:
	if material == null: return
	var path := str(node.get_path())
	var parts := path.split("/")
	var owner := str(parts[3]) if parts.size() > 3 else path
	if kind == "active-surface-override":
		_active_owner_counts[owner] = int(_active_owner_counts.get(owner, 0)) + 1
	var id := material.get_instance_id()
	if not _candidate_ids.has(id):
		_candidate_ids[id] = true
		if _samples.size() < 32:
			_samples.append("%s:%s:%d:%d:%s:%s" % [str(node.get_path()), kind,
				surface, id, material.get_class(), material.resource_name])
	var retain := (_treatment() == "retain-masked-materials" and kind != "active-surface-override") \
		or (_treatment() == "retain-active-surface-overrides" and kind == "active-surface-override")
	if kind == "active-surface-override":
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--active-owner-root="):
				retain = retain and owner == argument.trim_prefix("--active-owner-root=")
			elif argument.begins_with("--active-owner-roots="):
				retain = retain and argument.trim_prefix("--active-owner-roots=").split(",").has(owner)
			elif argument.begins_with("--exclude-active-owner-root="):
				retain = retain and owner != argument.trim_prefix("--exclude-active-owner-root=")
	if retain and not _held_ids.has(id):
		_held_ids[id] = true
		_held.append(material)
		if _retained_samples.size() < 128:
			_retained_samples.append("%s:%s:%d:%d:%s:%s" % [str(node.get_path()), kind,
				surface, id, material.get_class(), material.resource_name])
