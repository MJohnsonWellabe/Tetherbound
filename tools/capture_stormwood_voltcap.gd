extends "res://tools/capture_stormwood_f10_matrix.gd"

## One authored Voltcap site, one fixed view and one phase per process.
## Full production world is retained: this is not a reduced-memory surrogate.
## --view=approach|side|reverse --phase=calm|break [--voltcap-finish-preview]
## [--shared-look-preview] holds the shared rig/material look constant for a pair.
## Parent bootstrap requires fresh --out, named --preset and exact --source-commit.
const FINISH := preload("res://scripts/world/stormwood_voltcap_finish.gd")
const BIOME_LOOK := preload("res://scripts/world/stormwood_look.gd")
const CAMERA_SET := "res://tools/visual_judge/camera_sets/P2-046-voltcap.json"
var _fixed: Dictionary = {}
var _selected: Dictionary = {}
var _phase_choice := "calm"
var _preview := false
var _shared_look_preview := false


func _run() -> void:
	_fixed = JSON.parse_string(FileAccess.get_file_as_string(CAMERA_SET))
	var selection := "approach"
	var preset := ""
	var seen: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var key := arg.get_slice("=", 0)
		if key in ["--stands", "--phases", "--custom", "--clock-hour", "--aftermath-only", "--look-candidate", "--ground-readability", "--road-readability"]:
			push_error("Voltcap piece requires its own fixed --view and --phase only")
			quit(2)
			return
		if key in ["--view", "--phase", "--preset"]:
			if not arg.contains("=") or seen.has(key):
				push_error("Invalid or repeated Voltcap capture selector: " + key)
				quit(2)
				return
			seen[key] = true
			var value := arg.substr(key.length() + 1)
			if key == "--view": selection = value
			elif key == "--phase": _phase_choice = value
			else: preset = value
	for view: Dictionary in _fixed.views:
		if str(view.id) == selection:
			_selected = view
	if _selected.is_empty() or _phase_choice not in _fixed.phases or preset not in _fixed.presets:
		push_error("Voltcap capture requires a fixed view, Calm/Break and Medium/High")
		quit(2)
		return
	_preview = OS.get_cmdline_user_args().has("--voltcap-finish-preview")
	_shared_look_preview = OS.get_cmdline_user_args().has("--shared-look-preview")
	FINISH.capture_preview = _preview
	BIOME_LOOK.capture_preview = _shared_look_preview
	# Refuse silently promoted config flags: every treatment is explicit in
	# the command/receipt. Preview switches change only in-memory state.
	if bool(FINISH.read_config().get("enabled", false)) != _preview \
			or bool(BIOME_LOOK.read_config().get("enabled", false)) != _shared_look_preview:
		push_error("Committed look flags differ from the requested capture treatment")
		quit(2)
		return
	_aftermath_on = false
	_hud = true
	_phases_only.assign([_phase_choice])
	await super._run()


func _matrix_stands() -> Array:
	var at: Array = _selected.at
	var focus: Array = _selected.focus
	return [{"id": _selected.id, "at": Vector2(float(at[0]), float(at[1])),
		"focus": Vector3(float(focus[0]), float(_world.call("ground_height_at", float(focus[0]), float(focus[2]))) + float(focus[1]), float(focus[2])),
		"pitch": float(_selected.pitch), "text": "authored Voltcap harvest site, " + str(_selected.id)}]


func _pin_day() -> void:
	var cycle: RefCounted = _look.get("_cycle")
	_look.call("resume_at_elapsed", float(cycle.call("elapsed_for_hour", float(_fixed.clock_hour))))
	_look.call("set_clock_frozen", true)
	_note("fixed 12:00 clock; purple Stormwood presentation")


func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float, probe_above: float = 4.0) -> void:
	await super._stand(xz, look_at, pitch_deg, probe_above)
	_camera.fov = float(_fixed.fov)


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var biome_look := _world.get_node_or_null("StormwoodLook")
	if biome_look == null or bool((biome_look.get("config") as Dictionary).get("enabled", false)) != _shared_look_preview:
		_failures.append("shared Stormwood look does not match requested treatment")
		return
	if _shared_look_preview:
		for _frame in 240:
			if (biome_look.get("_pending") as Array).is_empty():
				break
			await process_frame
		if not (biome_look.get("_pending") as Array).is_empty() \
				or (biome_look.get("_meshes") as Dictionary).is_empty():
			_failures.append("shared look material walk incomplete or vegetation adaptation absent")
			return
	var site := _world.get_node_or_null("StormwoodHarvests/" + str(_fixed.site)) as Node3D
	if site == null or not site.is_visible_in_tree():
		_failures.append("authored Voltcap site missing or not visible")
		return
	var visual := site.get("_visual") as Node3D
	if visual == null or not visual.is_visible_in_tree():
		_failures.append("Voltcap model missing or hidden")
		return
	var surfaces := int(site.get_meta("voltcap_finish_surfaces", 0))
	var actual_surfaces := _finish_surface_count(visual)
	if (_preview and surfaces < 1) or (not _preview and surfaces != 0) or actual_surfaces != surfaces:
		_failures.append("Voltcap material does not match requested treatment")
		return
	var expected := Vector2(float(_fixed.site_xz[0]), float(_fixed.site_xz[1]))
	if Vector2(site.global_position.x, site.global_position.z).distance_to(expected) > 0.01:
		_failures.append("Voltcap site moved from authored position")
		return
	await super._capture(frame_id, description, full_size, extra.merged({
		"voltcap_finish_preview": _preview, "adapted_surfaces": surfaces, "observed_finish_surfaces": actual_surfaces,
		"shared_look_preview": _shared_look_preview,
		"shared_look_material_variants": (biome_look.get("_materials") as Dictionary).size(),
		"shared_look_mesh_variants": (biome_look.get("_meshes") as Dictionary).size(),
		"shared_look_config_sha256": FileAccess.get_file_as_string(BIOME_LOOK.CONFIG_PATH).sha256_text(),
		"site_id": _fixed.site, "site_position": _vec3(site.global_position),
		"visual_scale": _vec3(visual.scale), "clock_hour": float(_look.call("hour")), "fov": _camera.fov,
		"camera_set_sha256": FileAccess.get_file_as_string(CAMERA_SET).sha256_text(),
		"finish_config_sha256": FileAccess.get_file_as_string(FINISH.CONFIG_PATH).sha256_text(),
		"scope": "One production Voltcap site; staged player position/Surge, full world retained. No gather, route, all-resource or biome acceptance claim."
	}, true))


func _finish_surface_count(visual: Node3D) -> int:
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	if visual is MeshInstance3D:
		meshes.push_front(visual)
	var count := 0
	for child: Node in meshes:
		var mesh_node := child as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for surface in mesh_node.mesh.get_surface_count():
			var material := mesh_node.get_active_material(surface) as ShaderMaterial
			if material != null and material.shader == FINISH.SURFACE:
				count += 1
	return count


func _done() -> void:
	var expected := str(_selected.get("id", "")) + "_" + _phase_choice
	if _frames.size() != 1 or str(_frames[0].get("id", "")) != expected:
		_failures.append("Voltcap piece did not capture its exact one requested frame")
	super._done()
