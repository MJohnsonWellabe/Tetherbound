extends "res://tools/_capture_creature_roster.gd"

## ROOT queue only. Explicit --candidate previews flag-off recipes on one
## stage body. Capture the same command without it for the matched baseline.
## This stage is deformation evidence, not an ordinary-input traversal proof.
const ROLES := ["hit", "faint", "swim", "fly_grip", "ride"]
const PHASES := [0.0, 0.25, 0.5, 0.75, 1.0]


func _run() -> void:
	var id := "terrapup"
	var candidate := false
	var out := "res://ralph/reports/R2-F36/frames"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			id = arg.trim_prefix("--species=")
		elif arg == "--candidate":
			candidate = true
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if DisplayServer.get_name() == "headless" or not SPECIES.has(id):
		push_error("F36 needs a native renderer and a current species id")
		quit(1)
		return
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for frame in BOOT_FRAMES:
		await physics_frame
	var body := _spawn_creature(id, false, PAIR_CREATURE_POS, 90.0)
	body.set_physics_process(false)
	if candidate:
		body.set_meta("f36_pose_preview", true)
		body.call("_build_placeholder")
	if candidate and not bool(body.get_meta("f36_pose_candidate_installed", false)):
		push_error("F36 candidate did not install; refusing baseline-labelled candidate frames")
		quit(1)
		return
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if players.size() != 1:
		quit(1)
		return
	var player := players[0] as AnimationPlayer
	player.process_mode = Node.PROCESS_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var look: Dictionary = SPECIES.placeholder(id)
	var map: Dictionary = look.get("animations", {})
	var receipt: Array = []
	for role: String in ROLES:
		var clip := "f36_candidate/%s" % role if candidate else str(map.get(role, ""))
		if clip.is_empty() or not player.has_animation(clip):
			receipt.append({"role": role, "status": "missing_baseline_clip"})
			continue
		for phase: float in PHASES:
			player.play(clip)
			player.seek(player.get_animation(clip).length * phase, true)
			player.pause()
			for frame in 3:
				await process_frame
			var path := "%s/%s-%s-%03d.png" % [out, id, role, int(phase * 100)]
			var captured := await _capture(path)
			receipt.append({"role": role, "phase": phase, "path": path, "captured": captured})
	var file := FileAccess.open("%s/%s-receipt.json" % [out, id], FileAccess.WRITE)
	file.store_string(JSON.stringify({"species": id, "candidate": candidate, "stage_only": true, "frames": receipt}, "\t"))
	quit(0)
