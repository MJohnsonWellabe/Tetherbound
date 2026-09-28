extends "res://tools/art_pipeline/capture_named_fight.gd"

## Keep the installed named-fight capture's real prompt, dialogue, ally AI and
## combat path. This wrapper only pins randomness and writes an evidence
## manifest after each saved production-camera frame.

var _phase2_seed := 2042
var _requested_trainers: PackedStringArray = []
var _phase2_args: Array[String] = []
var _phase2_frames: Array[Dictionary] = []


func _run() -> void:
	var requested_output := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			_phase2_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--trainer="):
			_requested_trainers = arg.trim_prefix("--trainer=").split(",", false)
		elif arg.begins_with("--out="):
			requested_output = arg.trim_prefix("--out=")
		else:
			_phase2_args.append(arg)
	if not requested_output.begins_with("res://ralph/reports/VISUAL/phase2/meadows/"):
		push_error("Phase 2 fight output must be under the Meadows evidence directory")
		quit(1)
		return
	seed(_phase2_seed)
	await super._run()


func _save(tag: String) -> void:
	await super._save(tag)
	var file := "%s/%s-%s.png" % [_out, _tid, tag]
	if not FileAccess.file_exists(file):
		return
	_phase2_frames.append({
		"id": "%s-%s" % [_tid, tag],
		"trainer": _tid,
		"state": tag,
		"file": file,
		"fighting": bool(_manager.call("is_fighting")) if _manager != null else false,
		"panel_open": bool(_panel.call("is_open")) if _panel != null else false,
	})
	_write_phase2_manifest()


func _write_phase2_manifest() -> void:
	var completed := true
	for trainer_id: String in _requested_trainers:
		var found := false
		for row: Dictionary in _phase2_frames:
			if str(row.trainer) == trainer_id and str(row.state) == "99-after":
				found = true
				break
		if not found:
			completed = false
	var manifest := {
		"biome": "meadows", "system": "fight", "seed": _phase2_seed,
		"scene": SCENE, "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Installed real named-fight prompt and combat path; see capture args for any disclosed resolve or keep-alive option",
		"repro_args": ["--trainer=%s" % ",".join(_requested_trainers)] + _phase2_args + ["--seed=%d" % _phase2_seed],
		"output_option": "--out",
		"frames": _phase2_frames,
		"complete": completed,
	}
	var stream := FileAccess.open("%s/manifest.json" % _out, FileAccess.WRITE)
	if stream != null:
		stream.store_string(JSON.stringify(manifest, "\t") + "\n")
		stream.close()
