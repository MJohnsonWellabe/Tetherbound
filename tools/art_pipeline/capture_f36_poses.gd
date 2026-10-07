extends "res://tools/_capture_creature_roster.gd"

## Existing pose/scale stage. Explicit --candidate previews flag-off recipes on one
## stage body. Capture the same command without it for the matched baseline.
## This stage is deformation evidence, not an ordinary-input traversal proof.
const ROLES := ["hit", "faint", "swim", "fly_grip", "ride"]
const PHASES := [0.0, 0.25, 0.5, 0.75, 1.0]
var _pose_failures: Array[String] = []
var _scale_only := false
var _material_candidate := false
var _selected_roles: Array[String] = []
var _selected_phases: Array[float] = []


func _run() -> void:
	var ids: Array[String] = ["terrapup"]
	var candidate := false
	var whole_body := false
	var out := "res://ralph/reports/R2-F36/frames"
	var source := ""
	var all_roster := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			ids.assign(arg.trim_prefix("--species=").split(",", false))
		elif arg == "--candidate":
			candidate = true
		elif arg == "--whole-body":
			whole_body = true
		elif arg == "--scale-only":
			_scale_only = true
			whole_body = true
		elif arg == "--all":
			all_roster = true
		elif arg == "--material-candidate":
			_material_candidate = true
		elif arg.begins_with("--roles="):
			var values := arg.trim_prefix("--roles=").split(",", true)
			for value: String in values:
				if value not in ROLES or value in _selected_roles:
					_pose_failures.append("F36 needs unique supported pose roles")
				else:
					_selected_roles.append(value)
		elif arg.begins_with("--phases="):
			for value: String in arg.trim_prefix("--phases=").split(",", true):
				var phase := value.to_float()
				if not value.is_valid_float() or not is_finite(phase) or phase < 0.0 or phase > 1.0:
					_pose_failures.append("F36 phases must be finite values in0..1")
				elif _selected_phases.any(func(prior: float) -> bool: return int(prior * 100) == int(phase * 100)):
					_pose_failures.append("F36 phase filenames must be unique")
				else:
					_selected_phases.append(phase)
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--source-commit="):
			source = arg.trim_prefix("--source-commit=")
	if all_roster:
		ids.assign(SPECIES.table().keys())
		ids.sort()
	if _scale_only and (not _selected_roles.is_empty() or not _selected_phases.is_empty()):
		_pose_failures.append("Installed scale audit keeps its standing/end-point coverage")
	if not _pose_failures.is_empty():
		for failure: String in _pose_failures:
			push_error(failure)
		quit(1)
		return
	if _material_candidate:
		var finish_config: Dictionary = preload("res://scripts/creatures/creature_visual.gd").config()
		(finish_config["f36_material_finish"] as Dictionary)["enabled"] = true
	if _scale_only and candidate:
		push_error("Installed scale audit cannot preview pose candidates")
		quit(1)
		return
	var seen := {}
	for id: String in ids:
		if not SPECIES.has(id) or seen.has(id):
			push_error("F36 needs unique current species ids")
			quit(1)
			return
		seen[id] = true
	var sha_pattern := RegEx.new()
	sha_pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or ids.is_empty() \
			or (not source.is_empty() and sha_pattern.search(source) == null):
		push_error("F36 needs a native renderer and a current species id")
		quit(1)
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(out)):
		push_error("F36 needs a fresh output folder; existing frames preserved")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		quit(1)
		return
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for frame in BOOT_FRAMES:
		await physics_frame
	for id: String in ids:
		await _capture_species_poses(id, candidate, whole_body, out, source)
	for failure: String in _pose_failures:
		push_error(failure)
	quit(0 if _pose_failures.is_empty() else 1)


func _capture_species_poses(id: String, candidate: bool, whole_body: bool, out: String, source: String) -> void:
	var body := _spawn_creature(id, false, PAIR_CREATURE_POS, 90.0)
	body.set_physics_process(false)
	var measured_height := _measured_height(body)
	var measured_trainer := RENDER_BOUNDS.measure(_trainer).size.y
	var resting_bounds := RENDER_BOUNDS.measure(body)
	if whole_body:
		# One conservative standing-envelope camera per species, shared by both
		# variants and every sampled pose. Never rescale the creature or change
		# FOV to fit; this is a full-body diagnostic stage, not gameplay framing.
		var radius := resting_bounds.size.length() * 0.8 + measured_trainer
		var target := Vector3(CAM_LOOK.x, measured_height * 0.75, CAM_LOOK.z)
		var distance := radius / tan(deg_to_rad(FOV * 0.5))
		_camera.global_position = target + (CAM_POS - CAM_LOOK).normalized() * distance
		_camera.look_at(target, Vector3.UP)
	if measured_height <= TRAINER_HEIGHT:
		_pose_failures.append("%s: rendered height %.3fm does not clear trainer %.2fm" %
			[id, measured_height, TRAINER_HEIGHT])
	if _scale_only and not bool(body.call("has_model")):
		_pose_failures.append("%s: installed model missing; capsule cannot establish visual scale" % id)
	if _scale_only and absf(measured_trainer - TRAINER_HEIGHT) > 0.02:
		_pose_failures.append("%s: trainer ruler renders %.3fm rather than %.2fm" % [id, measured_trainer, TRAINER_HEIGHT])
	if candidate:
		body.set_meta("f36_pose_preview", true)
		body.call("_build_placeholder")
	if candidate and not bool(body.get_meta("f36_pose_candidate_installed", false)):
		_pose_failures.append("%s: F36 candidate did not install" % id)
		body.queue_free()
		await process_frame
		return
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if not _scale_only and players.size() != 1:
		_pose_failures.append("%s: expected one AnimationPlayer, found %d" % [id, players.size()])
		body.queue_free()
		await process_frame
		return
	var player := players[0] as AnimationPlayer if players.size() == 1 else null
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	var look: Dictionary = SPECIES.placeholder(id)
	var map: Dictionary = look.get("animations", {})
	var receipt: Array = []
	var roles: Array = ["standing"] if _scale_only else ROLES
	var phases: Array = [0.0, 1.0] if _scale_only else PHASES
	if not _selected_roles.is_empty():
		roles = _selected_roles
	if not _selected_phases.is_empty():
		phases = _selected_phases
	for role: String in roles:
		var clip := "f36_candidate/%s" % role if candidate else str(map.get(role, ""))
		if not _scale_only and (clip.is_empty() or not player.has_animation(clip)):
			receipt.append({"role": role, "status": "missing_baseline_clip"})
			_pose_failures.append("%s: missing %s clip" % [id, role])
			continue
		for phase: float in phases:
			if _scale_only:
				body.rotation.y = deg_to_rad(phase * 180.0)
			else:
				player.play(clip)
				player.seek(player.get_animation(clip).length * phase, true)
				player.pause()
			for frame in 3:
				await process_frame
			var path := "%s/%s-%s-%03d.png" % [out, id, role, int(phase * 100)]
			var captured := await _capture(path)
			receipt.append({"role": role, "phase": phase, "path": path, "captured": captured})
			if not captured:
				_pose_failures.append("%s: PNG capture failed" % path)
	var file := FileAccess.open("%s/%s-receipt.json" % [out, id], FileAccess.WRITE)
	if file == null:
		_pose_failures.append("%s: receipt could not be opened" % id)
	else:
		file.store_string(JSON.stringify({"species": id, "candidate": candidate, "stage_only": true,
			"material_candidate": _material_candidate,
			"scale_only": _scale_only, "installed_model": bool(body.call("has_model")),
			"source_commit": source, "renderer": RenderingServer.get_current_rendering_method(),
			"standing_height_m": measured_height, "trainer_reference_height_m": TRAINER_HEIGHT,
			"trainer_measured_height_m": measured_trainer, "scale_scope": "Installed standing stage; no fight-scale claim",
			"whole_body_camera": whole_body, "camera_position": [_camera.global_position.x, _camera.global_position.y, _camera.global_position.z],
			"camera_fov": _camera.fov, "resting_size_m": [resting_bounds.size.x, resting_bounds.size.y, resting_bounds.size.z],
			"resolution": [root.size.x, root.size.y], "planned_frames": roles.size() * phases.size(),
			"selected_roles": roles, "selected_phases": phases,
			"frames": receipt}, "\t"))
		file.flush()
		if file.get_error() != OK:
			_pose_failures.append("%s: receipt flush failed" % id)
		file.close()
	body.queue_free()
	await process_frame
