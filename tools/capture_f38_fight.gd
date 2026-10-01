extends "res://tools/art_pipeline/capture_named_fight.gd"

## Pending native fixture: existing prompt/dialogue/production-camera combat
## with real attack/dodge inputs. Inherits fixture party/debug travel, so this
## proves live combat presentation only, never earned opening/progression.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _f38_records: Array[Dictionary] = []


func _run() -> void:
	var preset := "High"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f38-preset="):
			preset = arg.trim_prefix("--f38-preset=")
	if not ["Low", "Medium", "High"].has(preset):
		quit(1)
		return
	GRAPHICS.load_preferences()
	GRAPHICS._base = preset
	GRAPHICS._choice = preset
	GRAPHICS._custom = {}
	if GRAPHICS.restart_required():
		push_error("F38 fight launch renderer does not match preset")
		quit(1)
		return
	seed(2042)
	await super._run()


func _save(tag: String) -> void:
	await super._save(tag)
	var path := "%s/%s-%s.png" % [_out, _tid, tag]
	if not FileAccess.file_exists(path):
		return
	_f38_records.append({"file": path, "trainer": _tid, "state": tag,
		"preset": GRAPHICS.selected(), "renderer": RenderingServer.get_current_rendering_method(),
		"candidate": OS.get_cmdline_user_args().has("--f38-candidate"),
		"live_fight": bool(_manager.call("is_fighting")) if _manager != null else false,
		"fixture_limit": "Inherited fixture party/debug travel and automatic input taps; no forced win/keep-alive is requested. Not earned or player-preference evidence."})
	var file := FileAccess.open(_out + "/f38-fight-manifest.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_f38_records, "\t"))
