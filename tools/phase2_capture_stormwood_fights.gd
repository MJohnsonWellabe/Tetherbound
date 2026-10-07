extends "res://tests/capture_stormwood_b_named_fights.gd"

## Reuse the installed production Stormwood named-wild fight recorder while
## constraining its output to this report and pinning the random seed. Its
## declared party/placement/storm-clock fixtures remain disclosed in the log.
var _capture_party_level := 80
const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}
var _capture_failures: Array[String] = []
var _native_frames: Array[Dictionary] = []
var _named_preset := false

func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_named_preset = true
		if arg.begins_with("--out="):
			target = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--party-level="):
			_capture_party_level = int(arg.trim_prefix("--party-level="))
	if _capture_party_level not in [42, 80]:
		push_error("Use --party-level=42 for the original loss fixture or 80 for the win fixture")
		quit(1)
		return
	var normalized := ProjectSettings.globalize_path(target).replace("\\", "/").simplify_path()
	var approved := false
	for directory: String in ["res://ralph/reports/VISUAL/phase2/stormwood/", "res://.tmp/stormwood-phase2/"]:
		var root_path := ProjectSettings.globalize_path(directory).replace("\\", "/").trim_suffix("/")
		approved = approved or normalized == root_path or normalized.begins_with(root_path + "/")
	if not approved:
		push_error("Stormwood fight frames must stay in its Phase 2 report or local capture directory")
		quit(1)
		return
	if _named_preset:
		_graphics_capture = BOOTSTRAP.prepare(self, "--out=")
		if _graphics_capture.is_empty():
			quit(1)
			return
	seed(capture_seed)
	_note("capture seed=%d party_level=%d; original loss fixture=42, win fixture=80" % [capture_seed, _capture_party_level])
	await super._run()
	if _named_preset:
		if _native_frames.is_empty():
			_capture_failures.append("No native fight frames captured")
		var receipt := FileAccess.open(target.path_join("lookdev_fight.json"), FileAccess.WRITE)
		if receipt == null:
			_capture_failures.append("Cannot open look-dev fight receipt")
		else:
			receipt.store_string(JSON.stringify({"graphics_capture": _graphics_capture,
				"party_level": _capture_party_level, "seed": capture_seed,
				"frames": _native_frames, "failures": _capture_failures,
				"complete": _capture_failures.is_empty(),
				"scope": "Existing production named-wild controller pilot; five directly created creatures, placement/neighbour suppression, Calm clock pin and healing disclosed by capture_log.json. No earned campaign, balance or device claim."}, "\t") + "\n")
			receipt.flush()
			var error := receipt.get_error()
			receipt.close()
			if error != OK:
				_capture_failures.append("Look-dev fight receipt write failed")
		for failure: String in _capture_failures:
			push_error(failure)
		quit(0 if _capture_failures.is_empty() else 1)


## The default level-42 footage party loses the long Hollows duel before
## reaching the requested win/aftermath beats. Raise only this in-memory
## capture party to 80 by default, keeping the normal input fight and cap.
## --party-level=42 restores the original loss sighting's fixture explicitly.
func _capture(id: String) -> Dictionary:
	for member: RefCounted in (_game.get("party").call("members") as Array):
		member.call("set_level", _capture_party_level, PROGRESSION.config())
	var row: Dictionary = await super._capture(id)
	if _named_preset and (not bool(row.get("started", false)) or int(row.get("frames", 0)) == 0):
		_capture_failures.append("%s: requested real fight did not start/capture" % id)
	if bool(row.get("started", false)) and not bool(_manager.call("is_fighting")):
		await _save("100-aftermath")
	return row


func _save(tag: String) -> void:
	await super._save(tag)
	if not _named_preset:
		return
	var path := _out.path_join("%s-%s.png" % [_id, tag])
	var image := Image.new()
	var raster: Array = _graphics_capture.resolution
	if image.load(path) != OK or image.get_size() != Vector2i(int(raster[0]), int(raster[1])):
		_capture_failures.append("%s: declared native preset raster PNG missing or unreadable" % path)
		return
	_native_frames.append({"path": path, "size": [image.get_width(), image.get_height()],
		"named_id": _id, "tag": tag, "fighting": bool(_manager.call("is_fighting"))})
